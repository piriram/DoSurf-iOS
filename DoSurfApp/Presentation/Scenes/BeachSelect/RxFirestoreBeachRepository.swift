//
//  RxFirestoreBeachRepository.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import Foundation
import RxSwift
import FirebaseFirestore

protocol RxBeachRepository {
    func findRegion(for beachId: String, among regions: [String]) -> Single<String?>
    func fetchMetadata(beachId: String, region: String) -> Single<BeachMetadataDTO?>
    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int) -> Single<[FirestoreChartDTO]>
}

final class RxFirestoreBeachRepository: RxBeachRepository {
    private let db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func findRegion(for beachId: String, among regions: [String]) -> Single<String?> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(FirebaseAPIError.internalError))
                return Disposables.create()
            }
            
            let group = DispatchGroup()
            var foundRegion: String?
            var firstError: FirebaseAPIError?
            
            for region in regions {
                group.enter()
                self.db.collection("regions")
                    .document(region)
                    .collection(beachId)
                    .document("_metadata")
                    .getDocument { document, error in
                        if let error = error, firstError == nil {
                            firstError = FirebaseAPIError.map(error)
                        }
                        if document?.exists == true {
                            foundRegion = region
                        }
                        group.leave()
                    }
            }
            
            group.notify(queue: .global()) {
                if let region = foundRegion {
                    single(.success(region))
                } else if let error = firstError {
                    single(.failure(error))
                } else {
                    single(.success(nil))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchMetadata(beachId: String, region: String) -> Single<BeachMetadataDTO?> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(FirebaseAPIError.internalError))
                return Disposables.create()
            }
            
            self.db.collection("regions")
                .document(region)
                .collection(beachId)
                .document("_metadata")
                .getDocument { document, error in
                    if let error = error {
                        single(.failure(FirebaseAPIError.map(error)))
                        return
                    }
                    
                    var metadata: BeachMetadataDTO?
                    if let document = document, document.exists, let data = document.data() {
                        metadata = BeachMetadataDTO(
                            beachId: data["beach_id"] as? Int ?? Int(beachId) ?? 0,
                            region: data["region"] as? String ?? region,
                            beach: data["beach"] as? String ?? "",
                            lastUpdated: (data["last_updated"] as? Timestamp)?.dateValue() ?? Date(),
                            totalForecasts: data["total_forecasts"] as? Int ?? 0,
                            status: data["status"] as? String ?? "",
                            earliestForecast: (data["earliest_forecast"] as? Timestamp)?.dateValue(),
                            latestForecast: (data["latest_forecast"] as? Timestamp)?.dateValue(),
                            nextForecastTime: (data["next_forecast_time"] as? Timestamp)?.dateValue()
                        )
                    }
                    single(.success(metadata))
                }
            
            return Disposables.create()
        }
    }
    
    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int) -> Single<[FirestoreChartDTO]> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(FirebaseAPIError.internalError))
                return Disposables.create()
            }
            
            self.db.collection("regions")
                .document(region)
                .collection(beachId)
                .order(by: "timestamp", descending: false)
                .getDocuments { snapshot, error in
                    if let error = error {
                        single(.failure(FirebaseAPIError.map(error)))
                        return
                    }
                    
                    var forecasts: [FirestoreChartDTO] = []
                    if let documents = snapshot?.documents {
                        for document in documents {
                            if document.documentID == "_metadata" { continue }
                            let data = document.data()
                            
                            let rawWaveHeight = data["wave_height"] as? Double
                            let waveHeight = (rawWaveHeight != nil && (rawWaveHeight! <= -900 || rawWaveHeight! >= 900)) ? nil : rawWaveHeight
                            
                            let computedWeatherCode = Self.computeWeatherCode(
                                skyCondition: data["sky_condition"] as? Int,
                                precipitationType: data["precipitation_type"] as? Int,
                                humidity: data["humidity"] as? Double,
                                windSpeed: data["wind_speed"] as? Double,
                                precipitationProbability: data["precipitation_probability"] as? Double
                            )
                            
                            let wavePeriod = Self.estimateWavePeriod(
                                windSpeed: data["wind_speed"] as? Double,
                                waveHeight: waveHeight,
                                omWaveHeight: data["om_wave_height"] as? Double
                            )
                            
                            let forecast = FirestoreChartDTO(
                                documentId: document.documentID,
                                beachId: data["beach_id"] as? Int ?? Int(beachId) ?? 0,
                                region: data["region"] as? String ?? region,
                                beach: data["beach"] as? String ?? "",
                                datetime: data["datetime"] as? String ?? "",
                                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                windSpeed: data["wind_speed"] as? Double,
                                windDirection: data["wind_direction"] as? Double,
                                waveHeight: waveHeight,
                                wavePeriod: wavePeriod,
                                airTemperature: data["air_temperature"] as? Double,
                                precipitationProbability: data["precipitation_probability"] as? Double,
                                precipitationType: data["precipitation_type"] as? Int,
                                skyCondition: data["sky_condition"] as? Int,
                                humidity: data["humidity"] as? Double,
                                precipitation: data["precipitation"] as? Double,
                                snow: data["snow"] as? Double,
                                omWaveHeight: data["om_wave_height"] as? Double,
                                omWaveDirection: data["om_wave_direction"] as? Double,
                                omSeaSurfaceTemperature: data["om_sea_surface_temperature"] as? Double,
                                weatherCode: computedWeatherCode
                            )
                            forecasts.append(forecast)
                        }
                    }
                    single(.success(forecasts))
                }
            
            return Disposables.create()
        }
    }
    
    private static func estimateWavePeriod(
        windSpeed: Double?,
        waveHeight: Double?,
        omWaveHeight: Double?
    ) -> Double? {
        guard let u = windSpeed, u.isFinite, u > 0 else { return nil }
        // Pierson–Moskowitz fully developed sea approximation:
        // Tp ≈ 0.83 * U10 (seconds), clamped to 2–18s typical surf range
        let raw = 0.83 * u
        let clamped = max(2.0, min(18.0, raw))
        return clamped
    }
    
    private static func computeWeatherCode(
        skyCondition: Int?,
        precipitationType: Int?,
        humidity: Double?,
        windSpeed: Double?,
        precipitationProbability: Double?
    ) -> Int? {
        let sky = skyCondition ?? 0
        let pty = precipitationType ?? 0

        // 1) Precipitation priority
        if pty != 0 {
            switch pty {
            case 1, 4: return WeatherType.rain.rawValue
            case 2, 3: return WeatherType.snow.rawValue
            default: break
            }
        }

        // 2) Fog heuristic: humidity ≥ 95 and wind ≤ 2.0 m/s
        let h = humidity ?? -1
        let w = windSpeed ?? Double.greatestFiniteMagnitude
        if h >= 95, w <= 2.0 {
            return WeatherType.fog.rawValue
        }

        // 3) Sky-based
        switch sky {
        case 1:
            return WeatherType.clear.rawValue
        case 3:
            let p = precipitationProbability ?? 0
            let isMuch = (p >= 30) || (h >= 85)
            return (isMuch ? WeatherType.cloudMuchSun : WeatherType.cloudLittleSun).rawValue
        case 4:
            return WeatherType.cloudy.rawValue
        default:
            return WeatherType.unknown.rawValue
        }
    }
}
