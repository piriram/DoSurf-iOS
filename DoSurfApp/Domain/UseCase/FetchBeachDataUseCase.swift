//
//  FetchBeachDataUseCase.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import UIKit
import RxSwift
import FirebaseFirestore

// MARK: - UseCase
protocol FetchBeachDataUseCase {
    /// beachId와 region을 알고 있을 때 사용하는 메서드
    func execute(beachId: String, region: String) -> Single<BeachData>
}

final class DefaultFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let repository: RxBeachRepository
    
    init(repository: RxBeachRepository) {
        self.repository = repository
    }
    
    // MARK: - Execute
    func execute(beachId: String, region: String) -> Single<BeachData> {
        return fetch(beachId: beachId, region: region)
            .catch { error in
                if let apiError = error as? FirebaseAPIError {
                    return .error(apiError)
                }
                return .error(FirebaseAPIError.map(error))
            }
    }
    
    // MARK: - Private
    private func fetch(beachId: String, region: String) -> Single<BeachData> {
        let since = Date().addingTimeInterval(-48*60*60)
        
        return Single.zip(
            repository.fetchMetadata(beachId: beachId, region: region),
            repository.fetchForecasts(beachId: beachId, region: region, since: since, limit: 20)
        )
        .map { metadataDTO, forecastDTOs in
            guard let metadataDTO = metadataDTO else {
                throw FirebaseAPIError.notFound
            }
            let metadata = metadataDTO.toDomain()
            let charts = forecastDTOs
                .map { $0.toDomain() }
                .sorted { $0.time < $1.time }
            
            return BeachData(
                metadata: metadata,
                charts: charts,
                lastUpdated: Date()
            )
        }
    }
}




