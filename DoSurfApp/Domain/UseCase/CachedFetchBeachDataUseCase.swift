import Foundation
import RxSwift

final class CachedFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let remote: FetchBeachDataUseCase
    private let fallback: FetchBeachDataUseCase
    private let cacheManager: ChartCacheManager
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .utility)
    private let prefetchDisposeBag = DisposeBag()

    init(
        remote: FetchBeachDataUseCase,
        fallback: FetchBeachDataUseCase,
        cacheManager: ChartCacheManager = ChartCacheManager()
    ) {
        self.remote = remote
        self.fallback = fallback
        self.cacheManager = cacheManager
    }

    func execute(beachId: String, region: String, daysBack: Int) -> Observable<BeachData> {
        let cacheKey = cacheManager.cacheKey(beachId: beachId, region: region, daysBack: daysBack)
        let cached = cacheManager.read(key: cacheKey)
        let shouldEmitCache = cached != nil

        let remoteObservable = remote
            .execute(beachId: beachId, region: region, daysBack: daysBack)
            .catch { [weak self] _ in
                if shouldEmitCache {
                    return .empty()
                }
                guard let self else { return .empty() }
                return self.fallback.execute(
                    beachId: beachId,
                    region: region,
                    daysBack: daysBack
                )
            }
            .observe(on: scheduler)
            .do(onNext: { [weak self] data in
                self?.cacheManager.write(data, for: cacheKey)
                self?.prefetchNeighbors(currentBeachId: beachId, region: region, daysBack: daysBack)
            })

        if let cachedData = cached {
            return remoteObservable
                .filter { [weak self] data in
                    guard let self else { return true }
                    return self.cacheManager.markIfUpdated(cacheKey, data: data)
                }
                .startWith(cachedData.data)
        }

        return remoteObservable
    }

    private func prefetchNeighbors(currentBeachId: String, region: String, daysBack: Int) {
        let candidates = cacheManager.prefetchCandidates(for: currentBeachId, region: region)
        guard !candidates.isEmpty else { return }

            candidates.forEach { neighbor in
                let key = cacheManager.cacheKey(beachId: neighbor, region: region, daysBack: daysBack)
                if cacheManager.read(key: key) != nil { return }

                _ = remote
                    .execute(beachId: neighbor, region: region, daysBack: daysBack)
                    .take(1)
                    .catch { [weak self] _ in
                        guard let self else { return .empty() }
                        return self.fallback.execute(beachId: neighbor, region: region, daysBack: daysBack)
                    }
                    .subscribe(
                        onNext: { [weak self] data in
                            self?.cacheManager.write(data, for: key)
                        },
                    onError: { _ in }
                )
                .disposed(by: prefetchDisposeBag)
        }
    }

    private func executeFallback(beachId: String, region: String, daysBack: Int) -> Observable<BeachData> {
        fallback.execute(beachId: beachId, region: region, daysBack: daysBack)
    }
}
