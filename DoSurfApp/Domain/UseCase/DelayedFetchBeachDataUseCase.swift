import Foundation
import RxSwift

final class DelayedFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let base: FetchBeachDataUseCase
    private let delay: RxTimeInterval
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)

    init(base: FetchBeachDataUseCase, delaySeconds: TimeInterval) {
        self.base = base
        self.delay = .milliseconds(max(0, Int(delaySeconds * 1000)))
    }

    func execute(beachId: String, region: String, daysBack: Int) -> Observable<BeachData> {
        base.execute(beachId: beachId, region: region, daysBack: daysBack)
            .delaySubscription(delay, scheduler: scheduler)
    }
}
