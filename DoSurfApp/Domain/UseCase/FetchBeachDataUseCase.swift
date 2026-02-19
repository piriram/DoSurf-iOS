import UIKit
import RxSwift
import FirebaseFirestore

protocol FetchBeachDataUseCase {
    func execute(beachId: String, region: String, daysBack: Int) -> Observable<BeachData>
}

final class DefaultFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let repository: FirestoreProtocol

    init(repository: FirestoreProtocol) {
        self.repository = repository
    }

    func execute(beachId: String, region: String, daysBack: Int = 7) -> Observable<BeachData> {
        return fetch(beachId: beachId, region: region, daysBack: daysBack)
            .asObservable()
            .catch { error in
                if let apiError = error as? FirebaseAPIError {
                    return .error(apiError)
                }
                return .error(FirebaseAPIError.map(error))
            }
    }

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
