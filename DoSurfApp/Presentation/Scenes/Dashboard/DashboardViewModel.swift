//
//  DashboardViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import UIKit
import RxSwift
import RxCocoa

final class DashboardViewModel {
    
    // MARK: - Dependencies
    private let fetchBeachDataUseCase: FetchBeachDataUseCase
    private let surfRecordUseCase: SurfRecordUseCaseProtocol
    
    // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let beachSelected: Observable<String>
        let refreshTriggered: Observable<Void>
    }
    
    // MARK: - Output
    struct Output {
        let beachData: Observable<BeachData>  // 변경
        let dashboardCards: Observable<[DashboardCardData]>
        let groupedCharts: Observable<[(date: Date, charts: [Chart])]>
        let recentRecordCharts: Observable<[Chart]>
        let pinnedCharts: Observable<[Chart]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
    
    // MARK: - Properties
    private let currentBeachId = BehaviorRelay<String>(value: "4001")
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    
    private let disposeBag = DisposeBag()
    
    // 모든 비치 평균 계산 대상 ID 목록 (필요 시 확장)
    private let allBeachIDs: [String] = ["1001", "2001", "3001", "4001"]
    
    // MARK: - Initialize
    init(fetchBeachDataUseCase: FetchBeachDataUseCase, surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
        self.surfRecordUseCase = surfRecordUseCase
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        // 새로운 해변이 선택될 때마다 currentBeachId 업데이트
        input.beachSelected
            .bind(to: currentBeachId)
            .disposed(by: disposeBag)
        
        // 데이터를 불러오는 트리거들:
        // 1. 뷰 로드 시 (기본 해변)
        // 2. 해변 선택 시 (새로운 차트 데이터 로드)
        // 3. 새로고침 시 (현재 해변 데이터 재로드)
        let loadTrigger = Observable.merge(
            input.viewDidLoad.map { [weak self] _ in self?.currentBeachId.value ?? "4001" },
            input.beachSelected,
            input.refreshTriggered.withLatestFrom(currentBeachId.asObservable())
        )
        
        let beachData = loadTrigger
            .do(onNext: { [weak self] _ in
                self?.isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] beachId -> Observable<BeachData> in
                guard let self = self else { return .empty() }
                
                return self.fetchBeachDataUseCase.execute(beachId: beachId)
                    .asObservable()
                    .do(
                        onNext: { [weak self] _ in
                            self?.isLoadingRelay.accept(false)
                        },
                        onError: { [weak self] error in
                            self?.isLoadingRelay.accept(false)
                            self?.errorRelay.accept(error)
                        }
                    )
                    .catch { [weak self] error in
                        self?.errorRelay.accept(error)
                        return .empty()
                    }
            }
            .do(onNext: { [weak self] data in
                self?.debugLogCharts("[BeachData]", charts: data.charts)
            })
            .share(replay: 1)
        
        // 모든 비치의 최신 데이터를 기준으로 평균값 계산
        let dashboardCards = loadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[DashboardCardData]> in
                guard let self = self else { return .just([]) }
                let requests: [Single<BeachData>] = self.allBeachIDs.map { self.fetchBeachDataUseCase.execute(beachId: $0) }
                return Single.zip(requests)
                    .asObservable()
                    .map { beachDatas -> [DashboardCardData] in
                        // 각 비치의 최신 차트(가장 최근 시간)를 사용
                        let latestCharts: [Chart] = beachDatas.compactMap { $0.charts.last }
                        guard !latestCharts.isEmpty else {
                            return [
                                DashboardCardData(
                                    type: .wind,
                                    title: "바람",
                                    value: String(format: "%.1fm/s", 0.0),
                                    icon: "windFillIcon",
                                    color: .surfBlue
                                ),
                                DashboardCardData(
                                    type: .wave,
                                    title: "파도",
                                    value: String(format: "%.1fm", 0.0),
                                    subtitle: String(format: "%.1fs", 0.0),
                                    icon: "waveFillIcon",
                                    color: .surfBlue
                                )
                            ]
                        }
                        
                        let count = Double(latestCharts.count)
                        let avgWind = latestCharts.map { $0.windSpeed }.reduce(0, +) / count
                        let avgWaveH = latestCharts.map { $0.waveHeight }.reduce(0, +) / count
                        let avgWaveP = latestCharts.map { $0.wavePeriod }.reduce(0, +) / count
                        let avgWindDir = self.averageDirectionDegrees(latestCharts.map { $0.windDirection })
                        let avgWaveDir = self.averageDirectionDegrees(latestCharts.map { $0.waveDirection })
                        
                        return [
                            DashboardCardData(
                                type: .wind,
                                title: "바람",
                                value: String(format: "%.1fm/s", avgWind),
                                subtitle: nil,
                                directionDegrees: avgWindDir,
                                icon: "windFillIcon",
                                color: .surfBlue
                            ),
                            DashboardCardData(
                                type: .wave,
                                title: "파도",
                                value: String(format: "%.1fm", avgWaveH),
                                subtitle: String(format: "%.1fs", avgWaveP),
                                directionDegrees: avgWaveDir,
                                icon: "waveFillIcon",
                                color: .surfBlue
                            )
                        ]
                    }
                    .catch { error in
                        print("Failed to fetch all beaches for averages: \(error)")
                        let zeroCards: [DashboardCardData] = [
                            DashboardCardData(
                                type: .wind,
                                title: "바람",
                                value: String(format: "%.1fm/s", 0.0),
                                icon: "windFillIcon",
                                color: .surfBlue
                            ),
                            DashboardCardData(
                                type: .wave,
                                title: "파도",
                                value: String(format: "%.1fm", 0.0),
                                subtitle: String(format: "%.1fs", 0.0),
                                icon: "waveFillIcon",
                                color: .surfBlue
                            )
                        ]
                        return .just(zeroCards)
                    }
            }
            .share(replay: 1)
        
        // 이미 Domain Chart를 사용
        let groupedCharts = beachData
            .map { beachData -> [(date: Date, charts: [Chart])] in
                return self.groupChartsByDate(beachData.charts)
            }
        
        // CoreData에서 모든 비치의 최근 기록 차트 가져오기
        let recentRecordCharts = loadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[Chart]> in
                guard let self = self else { return .just([]) }
                return self.surfRecordUseCase.fetchAllSurfRecords()
                    .asObservable()
                    .map { records -> [Chart] in
                        // 서핑 날짜 기준 최신 기록 순으로 정렬 후, 최근 10개 기록만 사용
                        let recentRecords = records.sorted { $0.surfDate > $1.surfDate }.prefix(10)
                        return recentRecords.flatMap { record in
                            record.charts.map { chartData in
                                Chart(
                                    beachID: record.beachID,
                                    time: chartData.time,
                                    windDirection: chartData.windDirection,
                                    windSpeed: chartData.windSpeed,
                                    waveDirection: chartData.waveDirection,
                                    waveHeight: chartData.waveHeight,
                                    wavePeriod: chartData.wavePeriod,
                                    waterTemperature: chartData.waterTemperature,
                                    weather: self.convertWeatherIconNameToWeatherType(chartData.weatherIconName),
                                    airTemperature: chartData.airTemperature
                                )
                            }
                        }
                        .sorted { $0.time > $1.time } // 최신 순으로 정렬
                    }
                    .catch { error in
                        print("Failed to fetch recent record charts (all beaches): \(error)")
                        return .just([])
                    }
            }
            .do(onNext: { [weak self] charts in
                self?.debugLogCharts("[RecentRecords]", charts: charts)
            })
            .share(replay: 1)
        
        // CoreData에서 전체 비치의 고정 차트 가져오기
        let pinnedCharts = loadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[Chart]> in
                guard let self = self else { return .just([]) }
                return self.surfRecordUseCase.fetchAllSurfRecords()
                    .asObservable()
                    .map { records -> [Chart] in
                        // 고정된 기록만 필터링 (전체 비치)
                        let pinnedRecords = records.filter { $0.isPin }
                        return pinnedRecords.flatMap { record in
                            record.charts.map { chartData in
                                Chart(
                                    beachID: record.beachID,
                                    time: chartData.time,
                                    windDirection: chartData.windDirection,
                                    windSpeed: chartData.windSpeed,
                                    waveDirection: chartData.waveDirection,
                                    waveHeight: chartData.waveHeight,
                                    wavePeriod: chartData.wavePeriod,
                                    waterTemperature: chartData.waterTemperature,
                                    weather: self.convertWeatherIconNameToWeatherType(chartData.weatherIconName),
                                    airTemperature: chartData.airTemperature
                                )
                            }
                        }
                        .sorted { $0.time > $1.time } // 최신 순으로 정렬
                    }
                    .catch { error in
                        print("Failed to fetch pinned charts (all beaches): \(error)")
                        return .just([])
                    }
            }
            .do(onNext: { [weak self] charts in
                self?.debugLogCharts("[PinnedRecords]", charts: charts)
            })
            .share(replay: 1)
        
        return Output(
            beachData: beachData,
            dashboardCards: dashboardCards,
            groupedCharts: groupedCharts,
            recentRecordCharts: recentRecordCharts,
            pinnedCharts: pinnedCharts,
            isLoading: isLoadingRelay.asObservable(),
            error: errorRelay.asObservable()
        )
    }
    
    // MARK: - Private Helpers
    // 원형 평균(벡터 평균)으로 각도(degree) 평균 계산 (0~360°)
    private func averageDirectionDegrees(_ degrees: [Double]) -> Double? {
        guard !degrees.isEmpty else { return nil }
        let radians = degrees.map { $0 * .pi / 180.0 }
        let sumX = radians.reduce(0.0) { $0 + cos($1) }
        let sumY = radians.reduce(0.0) { $0 + sin($1) }
        // 합 벡터의 크기가 매우 작으면 방향이 정의되지 않음
        if abs(sumX) < 1e-6 && abs(sumY) < 1e-6 { return nil }
        var angle = atan2(sumY, sumX) * 180.0 / .pi
        if angle < 0 { angle += 360.0 }
        return angle
    }
    
    private func convertWeatherIconNameToWeatherType(_ iconName: String) -> WeatherType {
        let type: WeatherType
        switch iconName {
        case "sun":
            type = .clear
        case "cloudLittleSun":
            type = .cloudLittleSun
        case "cloudMuchSun":
            type = .cloudMuchSun
        case "cloud":
            type = .cloudy
        case "rain":
            type = .rain
        case "fog", "forg":
            type = .fog
        case "snow":
            type = .snow
        default:
            type = .unknown
        }
        print("[WeatherIconMap] iconName=\(iconName) -> type=\(type) asset=\(type.iconName)")
        return type
    }
    
    private func groupChartsByDate(_ charts: [Chart]) -> [(date: Date, charts: [Chart])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: charts) { chart in
            calendar.startOfDay(for: chart.time)
        }
        
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, charts: $0.value.sorted { $0.time < $1.time }) }
    }
    
    private func debugLogCharts(_ tag: String, charts: [Chart]) {
        let counts = Dictionary(grouping: charts, by: { $0.weather.iconName }).mapValues { $0.count }
        let iconSet = Set(charts.map { $0.weather.iconName })
        let samples = charts.prefix(5).map { $0.weather.iconName }
        print("[WeatherDebug] \(tag) total=\(charts.count) counts=\(counts) icons=\(iconSet) samples=\(samples)")
    }
}
// MARK: - Weather Type Enum
enum WeatherType: Int, CaseIterable, Codable {
    case clear = 1
    case rain = 4
    case snow = 5
    case cloudy = 3
    case cloudLittleSun = 9
    case cloudMuchSun = 10
    case forg = 13
    case fog = 14
    case unknown = 999
    
    static func fromPtype(_ ptype: Double) -> WeatherType {
        switch ptype {
        case 0: return .clear
        case 1: return .rain
        case 2: return .snow
        case 3: return .cloudy
        default: return .clear
        }
    }
    
    var description: String {
        switch self {
        case .clear: return "맑음"
        case .rain: return "비"
        case .snow: return "눈"
        case .cloudy: return "구름많음"
        case .fog: return "안개"
        default: return "알수없음"
        }
    }
    var iconName: String {
        switch self {
        case .clear:
            return "sun"
        case .cloudLittleSun:
            return "cloudLittleSun"
        case .cloudMuchSun:
            return "cloudMuchSun"
        case .cloudy:
            return "cloudy"
        case .rain:
            return "rain"
        case .fog:
            return "forg"
        case .forg:
            return "forg"
        case .snow:
            return "snow"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - WeatherType Enum Extension
extension WeatherType {
    
    /// Firestore 데이터의 sky_condition과 precipitation_type을 기반으로 WeatherType 계산
    /// - Parameters:
    ///   - skyCondition: 하늘 상태 (1: 맑음, 3: 구름많음, 4: 흐림)
    ///   - precipitationType: 강수 형태 (0: 없음, 1: 비, 2: 비/눈, 3: 눈, 4: 소나기)
    /// - Returns: 계산된 WeatherType
    static func from(
        skyCondition: Int,
        precipitationType: Int,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        precipitationProbability: Double? = nil
    ) -> WeatherType {
        // 1) 강수 우선 로직 유지
        if precipitationType != 0 {
            switch precipitationType {
            case 1: // 비
                return .rain
            case 2: // 비/눈 (눈으로 처리)
                return .snow
            case 3: // 눈
                return .snow
            case 4: // 소나기
                return .rain
            default:
                return .unknown
            }
        }

        // 2) 안개 휴리스틱 (습도 높고, 바람 약할 때)
        //    임계값은 필요시 조정 가능: 습도 ≥ 95%, 풍속 ≤ 2.0 m/s
        let h = humidity ?? -1
        let w = windSpeed ?? Double.greatestFiniteMagnitude
        if h >= 95, w <= 2.0 {
            return .fog
        }

        // 3) 하늘 상태 기반
        switch skyCondition {
        case 1: // 맑음
            return .clear
        case 3: // 구름많음 → 습도/강수확률로 세분화
            let p = precipitationProbability ?? 0
            let isMuch = (p >= 30) || (humidity ?? 0 >= 85)
            return isMuch ? .cloudMuchSun : .cloudLittleSun
        case 4: // 흐림
            return .cloudy
        default:
            return .unknown
        }
    }
    
    /// Firestore Document Dictionary에서 직접 WeatherType 계산
    /// - Parameter data: Firestore document data
    /// - Returns: 계산된 WeatherType
    static func from(firestoreData data: [String: Any]) -> WeatherType {
        let skyCondition = data["sky_condition"] as? Int ?? 0
        let precipitationType = data["precipitation_type"] as? Int ?? 0
        
        return from(skyCondition: skyCondition, precipitationType: precipitationType)
    }
}

// MARK: - Usage Example
/*
 
 // 예제 1: 직접 값으로 계산
 let weatherType = WeatherType.from(skyCondition: 3, precipitationType: 0)
 print(weatherType.description) // "구름많음"
 print(weatherType.iconName)    // "cloudMuchSun"
 
 // 예제 2: Firestore 데이터로 계산
 let firestoreData: [String: Any] = [
     "sky_condition": 3,
     "precipitation_type": 0,
     "wind_speed": 3.3,
     // ... 기타 필드들
 ]
 
 let weatherType = WeatherType.from(firestoreData: firestoreData)
 
 // 예제 3: 비가 오는 경우
 let rainyWeather = WeatherType.from(skyCondition: 4, precipitationType: 1)
 print(rainyWeather.description) // "비"
 
 */

// MARK: - 계산 로직 정리
/*
 
 기상청 단기예보 API 기준:
 
 SKY (하늘상태):
 - 1: 맑음
 - 3: 구름많음
 - 4: 흐림
 
 PTY (강수형태):
 - 0: 없음
 - 1: 비
 - 2: 비/눈
 - 3: 눈
 - 4: 소나기
 
 우선순위:
 1. PTY ≠ 0 → 강수 타입으로 결정
 2. PTY == 0 → SKY로 결정
 
 매핑:
 PTY 1, 4 → WeatherType.rain
 PTY 2, 3 → WeatherType.snow
 SKY 1 → WeatherType.clear
 SKY 3 → WeatherType.cloudMuchSun
 SKY 4 → WeatherType.cloudy
 
 */

