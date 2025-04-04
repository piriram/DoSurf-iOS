//
//  BeachRepository.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/26/25.
//

import Foundation

// MARK: - Repository
protocol BeachRepository {
    func findRegion(for beachId: String, among regions: [String], completion: @escaping (Result<String?, FirebaseAPIError>) -> Void)
    func fetchMetadata(beachId: String, region: String, completion: @escaping (Result<BeachMetadata?, FirebaseAPIError>) -> Void)
    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int, completion: @escaping (Result<[FirestoreChartDTO], FirebaseAPIError>) -> Void)
}
