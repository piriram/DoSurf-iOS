import Foundation
import RxSwift
import RxCocoa

final class WatchDataSyncCoordinator: NSObject {
    private let connectivity = iPhoneWatchConnectivity()
    private let syncService: SurfRecordSyncService
    private let repository: NoteRepositoryProtocol
    private let beachRepository: FirestoreProtocol
    private let disposeBag = DisposeBag()
    private let beachMetadataLock = NSLock()
    private var beachNamesById: [Int: String]

    init(
        syncService: SurfRecordSyncService = SurfRecordSyncService(),
        repository: NoteRepositoryProtocol = SurfRecordRepository(),
        beachRepository: FirestoreProtocol = FirestoreRepository()
    ) {
        self.syncService = syncService
        self.repository = repository
        self.beachRepository = beachRepository
        self.beachNamesById = Self.fallbackBeachNames
    }

    func start() {
        connectivity.delegate = self
        preloadBeachMetadata()
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
                        return self.makePayload(from: record)
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
            .map { [weak self] records in
                guard let self else { return [] }
                return records.map(self.makePayload)
            }
            .subscribe(onSuccess: { [weak self] payloads in
                self?.connectivity.pushSnapshotToWatch(payloads)
            }, onFailure: { error in
                print("⚠️ failed to prepare watch snapshot: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    private func preloadBeachMetadata() {
        beachRepository.fetchAllBeaches()
            .subscribe(onSuccess: { [weak self] beaches in
                guard let self else { return }
                let resolved = Dictionary(uniqueKeysWithValues: beaches.map { beach in
                    (Int(beach.id) ?? 0, "\(beach.regionName) \(beach.place) 해변")
                })
                self.beachMetadataLock.lock()
                self.beachNamesById.merge(resolved) { _, new in new }
                self.beachMetadataLock.unlock()
            }, onFailure: { error in
                print("⚠️ failed to preload beach metadata for watch sync: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    private func makePayload(from record: SurfRecordData) -> WatchSessionPayload {
        let totalDistance = record.charts.reduce(0) { partial, chart in
            partial + max(0, chart.waveHeight) * 10
        }
        let summary = Self.makeChartSummary(from: record.charts)
        let beachName = resolvedBeachName(for: record.beachID)

        return WatchSessionPayload(
            payloadVersion: Int(record.payloadVersion),
            sessionId: record.recordId,
            beachID: record.beachID,
            beachName: beachName,
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
            avgWaveHeight: summary.avgWaveHeight,
            maxWaveHeight: summary.maxWaveHeight,
            avgWavePeriod: summary.avgWavePeriod,
            avgWaterTemperature: summary.avgWaterTemperature,
            avgWindSpeed: summary.avgWindSpeed,
            schemaVersion: WatchPayloadSchema.currentVersion
        )
    }

    private func resolvedBeachName(for beachID: Int) -> String? {
        guard beachID != 0 else { return nil }
        beachMetadataLock.lock()
        defer { beachMetadataLock.unlock() }
        return beachNamesById[beachID]
    }

    private static func makeChartSummary(from charts: [SurfChartData]) -> WatchChartSummary {
        guard !charts.isEmpty else { return WatchChartSummary() }

        func average(_ values: [Double]) -> Double? {
            guard !values.isEmpty else { return nil }
            return values.reduce(0, +) / Double(values.count)
        }

        let waveHeights = charts.map(\.waveHeight).filter { $0 > 0 }
        let wavePeriods = charts.map(\.wavePeriod).filter { $0 > 0 }
        let waterTemps = charts.map(\.waterTemperature).filter { $0 > 0 }
        let windSpeeds = charts.map(\.windSpeed).filter { $0 > 0 }

        return WatchChartSummary(
            avgWaveHeight: average(waveHeights),
            maxWaveHeight: waveHeights.max(),
            avgWavePeriod: average(wavePeriods),
            avgWaterTemperature: average(waterTemps),
            avgWindSpeed: average(windSpeeds)
        )
    }
}

private struct WatchChartSummary {
    let avgWaveHeight: Double?
    let maxWaveHeight: Double?
    let avgWavePeriod: Double?
    let avgWaterTemperature: Double?
    let avgWindSpeed: Double?

    init(
        avgWaveHeight: Double? = nil,
        maxWaveHeight: Double? = nil,
        avgWavePeriod: Double? = nil,
        avgWaterTemperature: Double? = nil,
        avgWindSpeed: Double? = nil
    ) {
        self.avgWaveHeight = avgWaveHeight
        self.maxWaveHeight = maxWaveHeight
        self.avgWavePeriod = avgWavePeriod
        self.avgWaterTemperature = avgWaterTemperature
        self.avgWindSpeed = avgWindSpeed
    }
}

private extension WatchDataSyncCoordinator {
    static let fallbackBeachNames: [Int: String] = [
        1001: "강릉 죽도 해변",
        1002: "강릉 강촌 해변",
        1003: "강릉 안현 해변",
        1004: "강릉 도항 해변",
        2001: "포항 간절곶 해변",
        2002: "포항 청해 해변",
        3001: "제주 협재 해변",
        3002: "제주 중문 해변",
        3003: "제주 함덕 해변",
        4001: "부산 송도 해변"
    ]
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
