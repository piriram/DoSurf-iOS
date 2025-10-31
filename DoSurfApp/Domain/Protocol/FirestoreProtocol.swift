//
//  FirestoreProtocol.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import Foundation
import RxSwift

protocol FirestoreProtocol {
    func findRegion(for beachId: String, among regions: [String]) -> Single<String?>
    func fetchMetadata(beachId: String, region: String) -> Single<BeachMetadataDTO?>
    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int) -> Single<[FirestoreChartDTO]>
    func fetchBeachList(region: String) -> Single<[BeachDTO]>
    func fetchAllBeaches() -> Single<[BeachDTO]>
}
