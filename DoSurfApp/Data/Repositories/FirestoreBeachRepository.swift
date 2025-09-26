//
//  FirestoreBeachRepository.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/26/25.
//

import Foundation
import FirebaseFirestore

final class FirestoreBeachRepository: BeachRepository {
    private let db: Firestore
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func findRegion(for beachId: String, among regions: [String], completion: @escaping (Result<String?, FirebaseAPIError>) -> Void) {
        let group = DispatchGroup()
        var foundRegion: String?
        var firstError: FirebaseAPIError?

        for region in regions {
            group.enter()
            db.collection("regions")
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
                completion(.success(region))
            } else if let err = firstError {
                completion(.failure(err))
            } else {
                completion(.success(nil))
            }
        }
    }

    func fetchMetadata(beachId: String, region: String, completion: @escaping (Result<BeachMetadata?, FirebaseAPIError>) -> Void) {
        db.collection("regions")
            .document(region)
            .collection(beachId)
            .document("_metadata")
            .getDocument { document, error in
                if let error = error {
                    completion(.failure(FirebaseAPIError.map(error)))
                    return
                }
                var metadata: BeachMetadata? = nil
                if let document = document, document.exists, let data = document.data() {
                    metadata = BeachMetadata(
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
                completion(.success(metadata))
            }
    }

    func fetchForecasts(beachId: String, region: String, since: Date, limit: Int, completion: @escaping (Result<[ForecastData], FirebaseAPIError>) -> Void) {
        db.collection("regions")
            .document(region)
            .collection(beachId)
            .whereField("timestamp", isGreaterThan: Timestamp(date: since))
            .order(by: "timestamp", descending: false)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(FirebaseAPIError.map(error)))
                    return
                }
                var forecasts: [ForecastData] = []
                if let documents = snapshot?.documents {
                    for document in documents {
                        if document.documentID == "_metadata" { continue }
                        let data = document.data()
                        let forecast = ForecastData(
                            documentId: document.documentID,
                            beachId: data["beach_id"] as? Int ?? Int(beachId) ?? 0,
                            region: data["region"] as? String ?? region,
                            beach: data["beach"] as? String ?? "",
                            datetime: data["datetime"] as? String ?? "",
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                            windSpeed: data["wind_speed"] as? Double,
                            windDirection: data["wind_direction"] as? Double,
                            waveHeight: data["wave_height"] as? Double,
                            airTemperature: data["air_temperature"] as? Double,
                            precipitationProbability: data["precipitation_probability"] as? Double,
                            precipitationType: data["precipitation_type"] as? Int,
                            skyCondition: data["sky_condition"] as? Int,
                            humidity: data["humidity"] as? Double,
                            precipitation: data["precipitation"] as? Double,
                            snow: data["snow"] as? Double,
                            omWaveHeight: data["om_wave_height"] as? Double,
                            omWaveDirection: data["om_wave_direction"] as? Double,
                            omSeaSurfaceTemperature: data["om_sea_surface_temperature"] as? Double
                        )
                        forecasts.append(forecast)
                    }
                }
                completion(.success(forecasts))
            }
    }
}
