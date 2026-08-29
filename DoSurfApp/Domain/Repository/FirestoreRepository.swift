import Foundation
import RxSwift
import FirebaseFirestore

final class FirestoreRepository: FirestoreProtocol {
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
                            
                            // 백엔드 Phase 1부터 파랑모델의 실제 파주기가 wave.period_s 로 들어온다.
                            // 없는 문서(Phase 1 배포 전 수집분)만 풍속 기반 추정으로 떨어진다.
                            let wave = data["wave"] as? [String: Any]
                            let wavePeriod = (wave?["period_s"] as? Double)
                                ?? Self.estimateWavePeriod(
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
        return fetchAllBeaches()
            .map { beaches in
                beaches.filter { $0.region.slug == region }
            }
    }
    
    func fetchAllBeaches() -> Single<[BeachDTO]> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(FirebaseAPIError.internalError))
                return Disposables.create()
            }
            
            print("🔍 [BeachList] Fetching all beaches from _global_metadata/all_beaches")
            
            self.db.collection("_global_metadata")
                .document("all_beaches")
                .getDocument { document, error in
                    if let error = error {
                        print("❌ [BeachList] Firestore error: \(error.localizedDescription)")
                        single(.failure(FirebaseAPIError.map(error)))
                        return
                    }
                    
                    guard let document = document else {
                        print("❌ [BeachList] Document is nil")
                        single(.failure(FirebaseAPIError.notFound))
                        return
                    }
                    
                    guard document.exists else {
                        print("⚠️ [BeachList] Document does not exist at: _global_metadata/all_beaches")
                        single(.failure(FirebaseAPIError.notFound))
                        return
                    }
                    
                    guard let data = document.data() else {
                        print("⚠️ [BeachList] Document exists but has no data")
                        single(.failure(FirebaseAPIError.notFound))
                        return
                    }
                    
                    print("✅ [BeachList] Document found with keys: \(data.keys)")
                    
                    guard let beachesArray = data["beaches"] as? [[String: Any]] else {
                        print("⚠️ [BeachList] beaches field missing or wrong type")
                        single(.failure(FirebaseAPIError.decodingFailed(message: "beaches field not found")))
                        return
                    }
                    
                    print("✅ [BeachList] Found \(beachesArray.count) beaches")
                    
                    // BeachRegion 정보를 수집 (중복 제거)
                    var regionMap: [String: BeachRegion] = [:]
                    
                    var beaches: [BeachDTO] = []
                    for beachData in beachesArray {
                        guard let id = beachData["id"] as? String,
                              let regionSlug = beachData["region"] as? String,
                              let regionName = beachData["region_name"] as? String,
                              let regionOrder = beachData["region_order"] as? Int,
                              let displayName = beachData["display_name"] as? String else {
                            print("⚠️ [BeachList] Invalid beach data: \(beachData)")
                            continue
                        }
                        
                        // BeachRegion 객체 생성 또는 재사용
                        if regionMap[regionSlug] == nil {
                            regionMap[regionSlug] = BeachRegion(
                                slug: regionSlug,
                                displayName: regionName,
                                order: regionOrder
                            )
                        }
                        
                        guard let region = regionMap[regionSlug] else { continue }
                        
                        let beach = BeachDTO(
                            id: id,
                            region: region,
                            regionName: regionName,
                            place: displayName
                        )
                        beaches.append(beach)
                    }
                    
                    print("✅ [BeachList] Successfully created \(beaches.count) BeachDTOs with \(regionMap.count) regions")
                    single(.success(beaches))
                }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Helper Methods
    
    /// 풍속에서 파주기를 유도하는 폴백. `wave.period_s` 가 없는 문서에만 쓴다.
    ///
    /// 이 값을 믿지 말 것. 2026-08-29 실측(5개 해변 120시각)에서 실제 파주기와
    /// 평균 3.89초 어긋났고 92%가 3초 이상 틀렸다. 원인은 두 가지다.
    /// - clamp 바닥에 걸린다: 풍속이 2.41 m/s 이하면 결과가 항상 2.0이 된다.
    ///   실측 풍속이 0.1~5.8 m/s라 120시각 중 77%가 2.0으로 고정됐다.
    /// - 그라운드 스웰을 원리적으로 못 잡는다: 동해는 풍파 성분이 대부분 0인데
    ///   스웰만으로 5~6.8초가 나온다. 바람이 없어도 먼바다 스웰은 들어온다.
    private static func estimateWavePeriod(
        windSpeed: Double?,
        waveHeight: Double?,
        omWaveHeight: Double?
    ) -> Double? {
        guard let u = windSpeed, u.isFinite, u > 0 else { return nil }
        // Pierson–Moskowitz fully developed sea approximation: Tp ≈ 0.83 * U10
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
