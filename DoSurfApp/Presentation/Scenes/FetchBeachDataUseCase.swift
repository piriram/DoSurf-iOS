//
//  FetchBeachDataUseCase.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//

import UIKit
import RxSwift
protocol FetchBeachDataUseCase {
    func execute(beachId: String) -> Single<BeachDataDump>
}

final class DefaultFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let repository: RxBeachRepository  // 👈 여기 변경
    private let knownRegions: [String]
    
    init(
        repository: RxBeachRepository,  // 👈 여기 변경
        knownRegions: [String] = ["gangreung", "pohang", "jeju", "busan"]
    ) {
        self.repository = repository
        self.knownRegions = knownRegions
    }
    
    func execute(beachId: String) -> Single<BeachDataDump> {
        return repository.findRegion(for: beachId, among: knownRegions)
            .flatMap { [weak self] foundRegion -> Single<BeachDataDump> in
                guard let self = self, let region = foundRegion else {
                    return .error(FirebaseAPIError.beachNotFoundInAnyRegion(beachId: beachId))
                }
                
                let since = Date().addingTimeInterval(-48*60*60)
                let beachInfo = BeachInfo.availableBeaches.first { $0.id == beachId }
                    ?? BeachInfo(id: beachId, name: "Unknown", region: region)
                
                return Single.zip(
                    self.repository.fetchMetadata(beachId: beachId, region: region),
                    self.repository.fetchForecasts(beachId: beachId, region: region, since: since, limit: 20)
                )
                .map { metadata, forecasts in
                    let sortedForecasts = forecasts.sorted { $0.timestamp < $1.timestamp }
                    return BeachDataDump(
                        beachInfo: beachInfo,
                        metadata: metadata,
                        forecasts: sortedForecasts,
                        lastUpdated: Date(),
                        foundInRegion: region
                    )
                }
            }
    }
}
