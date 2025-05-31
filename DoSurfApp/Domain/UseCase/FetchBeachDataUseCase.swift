import UIKit
import RxSwift
import FirebaseFirestore

// MARK: - UseCase
protocol FetchBeachDataUseCase {
    /// beachId와 region을 알고 있을 때 사용하는 메서드
    /// - Parameters:
    ///   - beachId: 해변 ID
    ///   - region: 지역 slug
    ///   - daysBack: 몇 일 전 데이터까지 가져올지 (기본값: 7일)
    func execute(beachId: String, region: String, daysBack: Int) -> Single<BeachData>
}

final class DefaultFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let repository: FirestoreProtocol

    init(repository: FirestoreProtocol) {
        self.repository = repository
    }

    // MARK: - Execute
    func execute(beachId: String, region: String, daysBack: Int = 7) -> Single<BeachData> {
        return fetch(beachId: beachId, region: region, daysBack: daysBack)
            .catch { error in
                if let apiError = error as? FirebaseAPIError {
                    return .error(apiError)
                }
                return .error(FirebaseAPIError.map(error))
            }
    }

    // MARK: - Private
    private func fetch(beachId: String, region: String, daysBack: Int) -> Single<BeachData> {
        let since = Date().addingTimeInterval(-Double(daysBack) * 24 * 60 * 60)
        
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
                .filter { chart in
                    // 바람, 파주기, 날씨가 모두 0이면 유효하지 않은 데이터로 간주하여 제외
                    let hasValidWind = chart.windSpeed > 0
                    let hasValidWave = chart.wavePeriod > 0
                    let hasValidWeather = chart.weather.rawValue != 0
                    return hasValidWind || hasValidWave || hasValidWeather
                }
                .sorted { $0.time < $1.time }

            return BeachData(
                metadata: metadata,
                charts: charts,
                lastUpdated: Date()
            )
        }
    }
}




