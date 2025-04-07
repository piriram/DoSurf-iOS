//
//  BeachDataService.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/27/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Firebase
import FirebaseFirestore

// MARK: - Service
protocol BeachDataServiceProtocol {
    func fetchBeachData(beachId: String, completion: @escaping (Result<BeachDataDump, FirebaseAPIError>) -> Void)
    func searchBeachInAllRegions(beachId: String, completion: @escaping (Result<String?, FirebaseAPIError>) -> Void)
}


class BeachDataService: BeachDataServiceProtocol {
    private let repository: BeachRepository
    private let knownRegions: [String]

    init(repository: BeachRepository = FirestoreBeachRepository(),
         knownRegions: [String] = ["gangreung", "pohang", "jeju", "busan"]) {
        self.repository = repository
        self.knownRegions = knownRegions
    }

    func fetchBeachData(beachId: String, completion: @escaping (Result<BeachDataDump, FirebaseAPIError>) -> Void) {
        repository.findRegion(for: beachId, among: knownRegions) { [weak self] result in
            guard let self = self else {
                completion(.failure(.internalError))
                return
            }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let foundRegion):
                guard let region = foundRegion else {
                    completion(.failure(.beachNotFoundInAnyRegion(beachId: beachId)))
                    return
                }

                let since = Date().addingTimeInterval(-48*60*60)
                let beachInfo = BeachInfo.availableBeaches.first { $0.id == beachId } ?? BeachInfo(id: beachId, name: "Unknown", region: region)

                var metadataResult: BeachMetadata?
                var forecastsResult: [FirestoreChartDTO] = []
                var firstError: FirebaseAPIError?
                let group = DispatchGroup()

                group.enter()
                self.repository.fetchMetadata(beachId: beachId, region: region) { res in
                    switch res {
                    case .failure(let error):
                        if firstError == nil { firstError = error }
                    case .success(let metadata):
                        metadataResult = metadata
                    }
                    group.leave()
                }

                group.enter()
                self.repository.fetchForecasts(beachId: beachId, region: region, since: since, limit: 20) { res in
                    switch res {
                    case .failure(let error):
                        if firstError == nil { firstError = error }
                    case .success(let forecasts):
                        forecastsResult = forecasts
                    }
                    group.leave()
                }

                group.notify(queue: .global()) {
                    if let error = firstError {
                        completion(.failure(error))
                        return
                    }

                    let sortedForecasts = forecastsResult.sorted { $0.timestamp < $1.timestamp }
                    let dump = BeachDataDump(
                        beachInfo: beachInfo,
                        metadata: metadataResult,
                        forecasts: sortedForecasts,
                        lastUpdated: Date(),
                        foundInRegion: region
                    )
                    completion(.success(dump))
                }
            }
        }
    }

    func searchBeachInAllRegions(beachId: String, completion: @escaping (Result<String?, FirebaseAPIError>) -> Void) {
        repository.findRegion(for: beachId, among: knownRegions, completion: completion)
    }
}




