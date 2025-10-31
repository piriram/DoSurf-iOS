//
//  DIContainer.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//

import Foundation
final class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // Repository
    func makeBeachRepository() -> RxBeachRepository {
        return RxFirestoreBeachRepository()
    }
    
    // UseCase
    func makeFetchBeachDataUseCase() -> FetchBeachDataUseCase {
        return DefaultFetchBeachDataUseCase(
            repository: makeBeachRepository()
        )
    }
    
    func makeFetchBeachListUseCase() -> FetchBeachListUseCase {
        return DefaultFetchBeachListUseCase(
            repository: makeBeachRepository()
        )
    }
    
    // ViewModel
    func makeBeachSelectViewModel() -> BeachSelectViewModel {
        return BeachSelectViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase()
        )
    }
}
