import Foundation
import RxSwift

final class WatchDataSyncCoordinator: NSObject {
    private let connectivity = iPhoneWatchConnectivity()
    private let syncService: SurfRecordSyncService
    private let disposeBag = DisposeBag()

    init(syncService: SurfRecordSyncService = SurfRecordSyncService()) {
        self.syncService = syncService
    }

    func start() {
        connectivity.delegate = self
        connectivity.activate()
    }
}

extension WatchDataSyncCoordinator: iPhoneWatchConnectivityDelegate {
    func didReceiveSurfSessions(_ sessions: [WatchSessionPayload]) {
        syncService.applyWatchPayloads(sessions)
            .subscribe(onSuccess: { _ in
                print("✅ Watch sync applied: \(sessions.count) sessions")
            }, onFailure: { error in
                print("⚠️ Watch sync failed: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    func didReceiveLegacySurfData(_ data: SurfSessionData) {
        let payload = WatchSessionPayload(
            recordId: data.recordId,
            distance: data.distance,
            duration: data.duration,
            startTime: data.startTime,
            endTime: data.endTime,
            waveCount: data.waveCount,
            maxHeartRate: data.maxHeartRate,
            avgHeartRate: data.avgHeartRate,
            activeCalories: data.activeCalories,
            strokeCount: data.strokeCount,
            lastModifiedAt: Date(),
            deviceId: "watch-legacy"
        )
        syncService.applyWatchPayloads([payload])
            .subscribe(onSuccess: { _ in
                print("✅ Legacy watch session synced")
            }, onFailure: { error in
                print("⚠️ Legacy watch sync failed: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    func watchConnectivityDidChangeReachability(_ isReachable: Bool) {
        print("📱 Watch reachability changed: \(isReachable)")
    }
}
