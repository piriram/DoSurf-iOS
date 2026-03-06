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
    }
}
