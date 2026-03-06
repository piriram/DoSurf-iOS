import Foundation
import RxSwift

final class CachedFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let remote: FetchBeachDataUseCase
    private let fallback: FetchBeachDataUseCase
    private let cacheManager: ChartCacheManager
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .utility)
    private let prefetchDisposeBag = DisposeBag()
    private let useFallbackWhenRemoteFails: Bool

    init(
        remote: FetchBeachDataUseCase,
        fallback: FetchBeachDataUseCase,
        cacheManager: ChartCacheManager = ChartCacheManager(),
        useFallbackWhenRemoteFails: Bool = true
    ) {
        self.remote = remote
        self.fallback = fallback
        self.cacheManager = cacheManager
        self.useFallbackWhenRemoteFails = useFallbackWhenRemoteFails
    }

    func execute(beachId: String, region: String, daysBack: Int) -> Observable<BeachData> {
        cacheManager.noteAccess(beachId: beachId, region: region)

        let cacheKey = cacheManager.cacheKey(beachId: beachId, region: region, daysBack: daysBack)
        let cached = cacheManager.read(key: cacheKey)

        let remoteObservable = remote
            .execute(beachId: beachId, region: region, daysBack: daysBack)
            .observe(on: scheduler)
            .catch { [weak self] error in
                guard let self else { return .error(error) }

                if let cached {
                    self.cacheManager.notifyStaleFallback(
                        key: cacheKey,
                        age: cached.age,
                        underlyingError: error
                    )
                    return .empty()
                }

                guard self.useFallbackWhenRemoteFails else {
                    return .error(error)
                }

                return self.fallback.execute(
                    beachId: beachId,
                    region: region,
                    daysBack: daysBack
                )
            }
            .do(onNext: { [weak self] data in
                self?.cacheManager.write(data, for: cacheKey)
                self?.prefetchNeighbors(currentBeachId: beachId, region: region, daysBack: daysBack)
            })

        if let cached {
            return remoteObservable
                .filter { [weak self] data in
                    guard let self else { return true }
                    return self.cacheManager.markIfUpdated(cacheKey, data: data)
                }
                .startWith(cached.data)
        }

        return remoteObservable
    }

    private func prefetchNeighbors(currentBeachId: String, region: String, daysBack: Int) {
        let candidates = cacheManager.prefetchCandidates(for: currentBeachId, region: region)
        guard !candidates.isEmpty else { return }

        candidates.forEach { neighbor in
            let key = cacheManager.cacheKey(beachId: neighbor, region: region, daysBack: daysBack)
            if let cached = cacheManager.read(key: key), !cacheManager.isStale(cached) {
                return
            }

            _ = remote
                .execute(beachId: neighbor, region: region, daysBack: daysBack)
                .take(1)
                .catch { [weak self] error in
                    guard let self else { return .error(error) }
                    guard self.useFallbackWhenRemoteFails else { return .error(error) }
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
}
