import Foundation
import RxSwift

protocol FetchBeachListUseCase {
    func execute(region: String) -> Single<[BeachDTO]>
    func executeAll() -> Single<[BeachDTO]>
}

final class DefaultFetchBeachListUseCase: FetchBeachListUseCase {
    private let repository: FirestoreProtocol
    
    init(repository: FirestoreProtocol) {
        self.repository = repository
    }
    
    func execute(region: String) -> Single<[BeachDTO]> {
        return repository.fetchBeachList(region: region)
            .catch { error in
                    .error(FirebaseAPIError.map(error))
            }
    }
    
    func executeAll() -> Single<[BeachDTO]> {
        return repository.fetchAllBeaches()
            .catch { error in
                    .error(FirebaseAPIError.map(error))
            }
    }
}
