//
//  RxFirestoreBeachRepository.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import UIKit
import RxSwift

// 기존 completion handler 프로토콜 (그대로 유지)
protocol BeachRepository {
    func findRegion(for beachId: String, among regions: [String], completion: @escaping (Result<String?, FirebaseAPIError>) -> Void)
    func fetchMetadata(beachId: String, region: String, completion: @escaping (Result<BeachMetadata?, FirebaseAPIError>) -> Void)
    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int, completion: @escaping (Result<[FirestoreChartDTO], FirebaseAPIError>) -> Void)
}

// 새로운 Rx 프로토콜
protocol RxBeachRepository {
    func findRegion(for beachId: String, among regions: [String]) -> Single<String?>
    func fetchMetadata(beachId: String, region: String) -> Single<BeachMetadata?>
    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int) -> Single<[FirestoreChartDTO]>
}

// Rx 구현체
final class RxFirestoreBeachRepository: RxBeachRepository {
    private let repository: FirestoreBeachRepository
    
    init(repository: FirestoreBeachRepository = FirestoreBeachRepository()) {
        self.repository = repository
    }
    
    func findRegion(for beachId: String, among regions: [String]) -> Single<String?> {
        return Single.create { [weak self] single in
            self?.repository.findRegion(for: beachId, among: regions) { result in
                switch result {
                case .success(let region):
                    single(.success(region))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchMetadata(beachId: String, region: String) -> Single<BeachMetadata?> {
        return Single.create { [weak self] single in
            self?.repository.fetchMetadata(beachId: beachId, region: region) { result in
                switch result {
                case .success(let metadata):
                    single(.success(metadata))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int) -> Single<[FirestoreChartDTO]> {
        return Single.create { [weak self] single in
            self?.repository.fetchForecasts(beachId: beachId, region: region, since: since, limit: limit) { result in
                switch result {
                case .success(let forecasts):
                    single(.success(forecasts))
                case .failure(let error):
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
}
