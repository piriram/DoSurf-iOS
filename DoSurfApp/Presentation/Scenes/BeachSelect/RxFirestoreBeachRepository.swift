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
    func fetchBeachList(region: String) -> Single<[BeachDTO]>
    func fetchAllBeaches() -> Single<[BeachDTO]>
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
    
    func fetchBeachList(region: String) -> Single<[BeachDTO]> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(FirebaseAPIError.internalError))
                return Disposables.create()
            }
            
            print("🔍 [BeachList] Fetching beaches for region: \(region)")
            
            self.db.collection("regions")
                .document(region)
                .collection("_region_metadata")
                .document("beaches")
                .getDocument { document, error in
                    if let error = error {
                        print("❌ [BeachList] Firestore error: \(error.localizedDescription)")
                        // Firestore 에러 발생 시 Mock 데이터로 폴백
                        let mockBeaches = Self.getMockBeaches(for: region)
                        print("⚠️ [BeachList] Using mock data: \(mockBeaches.count) beaches")
                        single(.success(mockBeaches))
                        return
                    }
                    
                    guard let document = document else {
                        print("❌ [BeachList] Document is nil for region: \(region)")
                        let mockBeaches = Self.getMockBeaches(for: region)
                        single(.success(mockBeaches))
                        return
                    }
                    
                    guard document.exists else {
                        print("⚠️ [BeachList] Document does not exist at: regions/\(region)/_region_metadata/beaches")
                        let mockBeaches = Self.getMockBeaches(for: region)
                        print("⚠️ [BeachList] Using mock data: \(mockBeaches.count) beaches")
                        single(.success(mockBeaches))
                        return
                    }
                    
                    guard let data = document.data() else {
                        print("⚠️ [BeachList] Document exists but has no data")
                        let mockBeaches = Self.getMockBeaches(for: region)
                        single(.success(mockBeaches))
                        return
                    }
                    
                    print("✅ [BeachList] Document found with keys: \(data.keys)")
                    
                    guard let beachIds = data["beach_ids"] as? [Int] else {
                        print("⚠️ [BeachList] beach_ids field missing or wrong type")
                        let mockBeaches = Self.getMockBeaches(for: region)
                        single(.success(mockBeaches))
                        return
                    }
                    
                    guard let displayNameMapping = data["display_name_mapping"] as? [String: String] else {
                        print("⚠️ [BeachList] display_name_mapping field missing or wrong type")
                        let mockBeaches = Self.getMockBeaches(for: region)
                        single(.success(mockBeaches))
                        return
                    }
                    
                    guard let regionEnum = BeachRegion(rawValue: region) else {
                        print("⚠️ [BeachList] Invalid region enum: \(region)")
                        let mockBeaches = Self.getMockBeaches(for: region)
                        single(.success(mockBeaches))
                        return
                    }
                    
                    print("✅ [BeachList] Found \(beachIds.count) beaches in \(region)")
                    
                    let beaches = beachIds.map { beachId -> BeachDTO in
                        let beachIdStr = String(beachId)
                        let displayName = displayNameMapping[beachIdStr] ?? "알 수 없음"
                        return BeachDTO(
                            id: beachIdStr,
                            region: regionEnum,
                            place: displayName
                        )
                    }
                    
                    print("✅ [BeachList] Successfully created \(beaches.count) BeachDTOs")
                    single(.success(beaches))
                }
            
            return Disposables.create()
        }
    }
    
    func fetchAllBeaches() -> Single<[BeachDTO]> {
        let regions = BeachRegion.allCases.map { $0.rawValue }
        let requests = regions.map { fetchBeachList(region: $0) }
        
        return Single.zip(requests)
            .map { beachLists in
                beachLists.flatMap { $0 }
            }
    }
    
    // MARK: - Mock Data Helper
    private static func getMockBeaches(for region: String) -> [BeachDTO] {
        guard let regionEnum = BeachRegion(rawValue: region) else { return [] }
        
        switch regionEnum {
        case .gangreung:
            return [
                BeachDTO(id: "1001", region: .gangreung, place: "죽도"),
                BeachDTO(id: "1002", region: .gangreung, place: "사천진"),
                BeachDTO(id: "1003", region: .gangreung, place: "사근진"),
                BeachDTO(id: "1004", region: .gangreung, place: "사천")
            ]
        case .pohang:
            return [
                BeachDTO(id: "2001", region: .pohang, place: "월포"),
                BeachDTO(id: "2002", region: .pohang, place: "신항만")
            ]
        case .jeju:
            return [
                BeachDTO(id: "3001", region: .jeju, place: "중문")
            ]
        case .busan:
            return [
                BeachDTO(id: "4001", region: .busan, place: "송정")
            ]
        }
    }
    
    private static func estimateWavePeriod(
        windSpeed: Double?,
        waveHeight: Double?,
        omWaveHeight: Double?
    ) -> Double? {
        guard let u = windSpeed, u.isFinite, u > 0 else { return nil }
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
        
        if pty != 0 {
            switch pty {
            case 1, 4: return WeatherType.rain.rawValue
            case 2, 3: return WeatherType.snow.rawValue
            default: break
            }
        }
        
        let h = humidity ?? -1
        let w = windSpeed ?? Double.greatestFiniteMagnitude
        if h >= 95, w <= 2.0 {
            return WeatherType.fog.rawValue
        }
        
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
