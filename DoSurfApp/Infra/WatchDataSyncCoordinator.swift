import Foundation
import RxSwift
import RxCocoa

final class WatchDataSyncCoordinator: NSObject {
    private let connectivity = iPhoneWatchConnectivity()
    private let syncService: SurfRecordSyncService
    private let repository: NoteRepositoryProtocol
    private let disposeBag = DisposeBag()

    init(
        syncService: SurfRecordSyncService = SurfRecordSyncService(),
        repository: NoteRepositoryProtocol = SurfRecordRepository()
    ) {
        self.syncService = syncService
        self.repository = repository
    }

    func start() {
        connectivity.delegate = self
        observeLocalMutations()
        connectivity.activate()
    }

    private func observeLocalMutations() {
        NotificationCenter.default.rx.notification(.surfRecordMutationCommitted)
            .compactMap { $0.userInfo?["recordId"] as? String }
            .flatMapLatest { [weak self] recordId -> Observable<WatchSessionPayload?> in
                guard let self else { return .just(nil) }
                return self.repository.fetchSurfRecord(byRecordId: recordId)
                    .asObservable()
                    .map { record in
                        guard let record else { return nil }
                        return Self.makePayload(from: record)
                    }
                    .catch { error in
                        print("⚠️ failed to load committed record for watch sync: \(error.localizedDescription)")
                        return .just(nil)
                    }
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] payload in
                self?.connectivity.pushDeltaToWatch([payload])
            })
            .disposed(by: disposeBag)
    }

    private func pushSnapshotToWatch() {
        repository.fetchAllSurfRecordsIncludingDeleted()
            .map { $0.map(Self.makePayload) }
            .subscribe(onSuccess: { [weak self] payloads in
                self?.connectivity.pushSnapshotToWatch(payloads)
            }, onFailure: { error in
                print("⚠️ failed to prepare watch snapshot: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    private static func makePayload(from record: SurfRecordData) -> WatchSessionPayload {
        let totalDistance = record.charts.reduce(0) { partial, chart in
            partial + max(0, chart.waveHeight) * 10
        }

        return WatchSessionPayload(
            payloadVersion: Int(record.payloadVersion),
            sessionId: record.recordId,
            beachID: record.beachID,
            distanceMeters: totalDistance,
            durationSeconds: max(0, record.endTime.timeIntervalSince(record.startTime)),
            startTime: record.startTime,
            endTime: record.endTime,
            waveCount: record.charts.count,
            maxHeartRate: 0,
            avgHeartRate: 0,
            activeCalories: 0,
            strokeCount: 0,
            lastModifiedAt: record.lastModifiedAt,
            deviceId: record.deviceId,
            sessionState: record.isDeleted ? .deleted : .completed,
            rating: Int(record.rating),
            memo: record.memo,
            isPinned: record.isPin,
            schemaVersion: WatchPayloadSchema.currentVersion
        )
    }
}

extension WatchDataSyncCoordinator: iPhoneWatchConnectivityDelegate {
    func watchConnectivityDidReceivePayloads(
        _ payloads: [WatchSessionPayload],
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        syncService.applyWatchPayloads(payloads)
            .subscribe(onSuccess: {
                print("✅ Watch sync applied: \(payloads.count) payloads")
                completion(.success(payloads.count))
            }, onFailure: { error in
                print("⚠️ Watch sync failed: \(error.localizedDescription)")
                completion(.failure(error))
            })
            .disposed(by: disposeBag)
    }

    func watchConnectivityDidChangeReachability(_ isReachable: Bool) {
        print("📱 Watch reachability changed: \(isReachable)")
        if isReachable {
            pushSnapshotToWatch()
        }
    }

    func watchConnectivityDidActivate() {
        pushSnapshotToWatch()
    }
}
