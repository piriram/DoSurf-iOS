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
        let beachSelected: Observable<BeachDTO>
        let refreshTriggered: Observable<Void>
    }
    
    // MARK: - Output
    struct Output {
        let beachData: Observable<BeachData>
        let dashboardCards: Observable<[DashboardCardData]>
        let groupedCharts: Observable<[(date: Date, charts: [Chart])]>
        let recentRecordCharts: Observable<[Chart]>
        let pinnedCharts: Observable<[Chart]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
    
    // MARK: - Properties
    private let currentBeach = BehaviorRelay<BeachDTO?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    
    private let disposeBag = DisposeBag()
    
    // 모든 비치 평균 계산 시 사용될 고정된 지역-해변 매핑
    private let knownBeaches: [(beachId: String, region: String)] = [
        ("1001", "gangreung"),
        ("1002", "gangreung"),
        ("1003", "gangreung"),
        ("1004", "gangreung"),
        ("2001", "pohang"),
        ("2002", "pohang"),
        ("3001", "jeju"),
        ("3002", "jeju"),
        ("3003", "jeju"),
        ("4001", "busan")
    ]
    
    // MARK: - Initialize
    init(fetchBeachDataUseCase: FetchBeachDataUseCase, surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
        self.surfRecordUseCase = surfRecordUseCase
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        // 새로운 해변이 선택될 때마다 currentBeach 업데이트
        input.beachSelected
            .bind(to: currentBeach)
            .disposed(by: disposeBag)
        
        // 데이터를 불러오는 트리거들:
        // 1. 뷰 로드 시 - currentBeach가 설정될 때까지 대기
        // 2. 해변 선택 시
        // 3. 새로고침 시
        let loadTrigger = Observable.merge(
            input.viewDidLoad.withLatestFrom(currentBeach.asObservable()).compactMap { $0 },
            input.beachSelected,
            input.refreshTriggered.withLatestFrom(currentBeach.asObservable()).compactMap { $0 }
        )
        
        // 단일 해변(현재 선택) 데이터 로드
        let beachData = loadTrigger
            .do(onNext: { [weak self] _ in
                self?.isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] beach -> Observable<BeachData> in
                guard let self = self else { return .empty() }
                
                return self.fetchBeachDataUseCase.execute(beachId: beach.id, region: beach.region.slug)
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
                
                // 각 (beachId, region)를 이용해 직접 Fetch
                let requests: [Single<BeachData?>] = self.knownBeaches.map { pair in
                    self.fetchBeachDataDirectly(beachId: pair.beachId, region: pair.region)
                        .map { $0 as BeachData? }
                        .catch { _ in .just(nil) }
                }
                
                return Single.zip(requests)
                    .asObservable()
                    .map { beachDatas -> [DashboardCardData] in
                        let latestCharts: [Chart] = beachDatas
                            .compactMap { $0 }
                            .compactMap { $0.charts.last }
                        
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
                        print("Failed to fetch known beaches for averages: \(error)")
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
                        .sorted { $0.time > $1.time }
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
                        .sorted { $0.time > $1.time }
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
    
    private func fetchBeachDataDirectly(beachId: String, region: String) -> Single<BeachData> {
        return fetchBeachDataUseCase.execute(beachId: beachId, region: region)
    }
    
    private func averageDirectionDegrees(_ degrees: [Double]) -> Double? {
        guard !degrees.isEmpty else { return nil }
        let radians = degrees.map { $0 * .pi / 180.0 }
        let sumX = radians.reduce(0.0) { $0 + cos($1) }
        let sumY = radians.reduce(0.0) { $0 + sin($1) }
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
    
    static func from(
        skyCondition: Int,
        precipitationType: Int,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        precipitationProbability: Double? = nil
    ) -> WeatherType {
        if precipitationType != 0 {
            switch precipitationType {
            case 1:
                return .rain
            case 2:
                return .snow
            case 3:
                return .snow
            case 4:
                return .rain
            default:
                return .unknown
            }
        }
        
        let h = humidity ?? -1
        let w = windSpeed ?? Double.greatestFiniteMagnitude
        if h >= 95, w <= 2.0 {
            return .fog
        }
        
        switch skyCondition {
        case 1:
            return .clear
        case 3:
            let p = precipitationProbability ?? 0
            let isMuch = (p >= 30) || (humidity ?? 0 >= 85)
            return isMuch ? .cloudMuchSun : .cloudLittleSun
        case 4:
            return .cloudy
        default:
            return .unknown
        }
    }
    
    static func from(firestoreData data: [String: Any]) -> WeatherType {
        let skyCondition = data["sky_condition"] as? Int ?? 0
        let precipitationType = data["precipitation_type"] as? Int ?? 0
        
        return from(skyCondition: skyCondition, precipitationType: precipitationType)
    }
}
