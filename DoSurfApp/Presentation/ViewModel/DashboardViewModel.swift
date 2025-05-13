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
        let allCharts: Observable<[Chart]>                 // ✅ 추가: 뷰가 스냅샷이 필요할 때 구독
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }

    // MARK: - State
    private let currentBeach = BehaviorRelay<BeachDTO?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    private let allChartsRelay = BehaviorRelay<[Chart]>(value: []) // ✅ 뷰 대신 보관

    private let disposeBag = DisposeBag()

    // 고정 매핑
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

    // MARK: - Init
    init(fetchBeachDataUseCase: FetchBeachDataUseCase,
         surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
        self.surfRecordUseCase = surfRecordUseCase
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        // 선택/로드/새로고침 트리거
        let loadTrigger = Observable.merge(
            input.viewDidLoad.withLatestFrom(currentBeach.asObservable()).compactMap { $0 },
            input.beachSelected.do(onNext: { [weak self] in self?.currentBeach.accept($0) }),
            input.refreshTriggered.withLatestFrom(currentBeach.asObservable()).compactMap { $0 }
        )

        // 단일 비치 데이터
        let beachData = loadTrigger
            .do(onNext: { [weak self] _ in self?.isLoadingRelay.accept(true) })
            .flatMapLatest { [weak self] beach -> Observable<BeachData> in
                guard let self = self else { return .empty() }
                return self.fetchBeachDataUseCase.execute(beachId: beach.id, region: beach.region.slug)
                    .asObservable()
                    .do(onNext: { [weak self] _ in self?.isLoadingRelay.accept(false) },
                        onError: { [weak self] e in
                            self?.isLoadingRelay.accept(false)
                            self?.errorRelay.accept(e)
                        })
                    .catch { [weak self] e in
                        self?.errorRelay.accept(e)
                        return .empty()
                    }
            }
            .do(onNext: { [weak self] data in
                // ✅ VC에서 하던 flatten/정렬을 VM이 수행하고 보관
                let flattened = data.charts.sorted { $0.time < $1.time }
                self?.allChartsRelay.accept(flattened)
                self?.debugLogCharts("[BeachData]", charts: flattened)
            })
            .share(replay: 1)

        // 평균 카드
        let dashboardCards = loadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[DashboardCardData]> in
                guard let self = self else { return .just([]) }
                let requests: [Single<BeachData?>] = self.knownBeaches.map { pair in
                    self.fetchBeachDataDirectly(beachId: pair.beachId, region: pair.region)
                        .map { $0 as BeachData? }
                        .catch { _ in .just(nil) }
                }

                return Single.zip(requests).asObservable()
                    .map { beachDatas -> [DashboardCardData] in
                        let latestCharts = beachDatas.compactMap { $0?.charts.last }
                        guard !latestCharts.isEmpty else {
                            return [
                                DashboardCardData(type: .wind, title: "바람",
                                                  value: String(format: "%.1fm/s", 0.0),
                                                  icon: "windFillIcon", color: .surfBlue),
                                DashboardCardData(type: .wave, title: "파도",
                                                  value: String(format: "%.1fm", 0.0),
                                                  subtitle: String(format: "%.1fs", 0.0),
                                                  icon: "waveFillIcon", color: .surfBlue)
                            ]
                        }
                        let count = Double(latestCharts.count)
                        let avgWind = latestCharts.map(\.windSpeed).reduce(0, +) / count
                        let avgWaveH = latestCharts.map(\.waveHeight).reduce(0, +) / count
                        let avgWaveP = latestCharts.map(\.wavePeriod).reduce(0, +) / count
                        let avgWindDir = self.averageDirectionDegrees(latestCharts.map(\.windDirection))
                        let avgWaveDir = self.averageDirectionDegrees(latestCharts.map(\.waveDirection))
                        return [
                            DashboardCardData(type: .wind, title: "바람",
                                              value: String(format: "%.1fm/s", avgWind),
                                              subtitle: nil, directionDegrees: avgWindDir,
                                              icon: "windFillIcon", color: .surfBlue),
                            DashboardCardData(type: .wave, title: "파도",
                                              value: String(format: "%.1fm", avgWaveH),
                                              subtitle: String(format: "%.1fs", avgWaveP),
                                              directionDegrees: avgWaveDir,
                                              icon: "waveFillIcon", color: .surfBlue)
                        ]
                    }
                    .catch { _ in
                        let zero = [
                            DashboardCardData(type: .wind, title: "바람",
                                              value: String(format: "%.1fm/s", 0.0),
                                              icon: "windFillIcon", color: .surfBlue),
                            DashboardCardData(type: .wave, title: "파도",
                                              value: String(format: "%.1fm", 0.0),
                                              subtitle: String(format: "%.1fs", 0.0),
                                              icon: "waveFillIcon", color: .surfBlue)
                        ]
                        return .just(zero)
                    }
            }
            .share(replay: 1)

        let groupedCharts = beachData
            .map { [weak self] in self?.groupChartsByDate($0.charts) ?? [] }

        let recentRecordCharts = loadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[Chart]> in
                guard let self = self else { return .just([]) }
                return self.surfRecordUseCase.fetchAllSurfRecords()
                    .asObservable()
                    .map { records in
                        let recent = records.sorted { $0.surfDate > $1.surfDate }.prefix(10)
                        return recent.flatMap { record in
                            record.charts.map {
                                Chart(beachID: record.beachID, time: $0.time,
                                      windDirection: $0.windDirection, windSpeed: $0.windSpeed,
                                      waveDirection: $0.waveDirection, waveHeight: $0.waveHeight,
                                      wavePeriod: $0.wavePeriod, waterTemperature: $0.waterTemperature,
                                      weather: self.convertWeatherIconNameToWeatherType($0.weatherIconName),
                                      airTemperature: $0.airTemperature)
                            }
                        }.sorted { $0.time > $1.time }
                    }
                    .catch { _ in .just([]) }
            }
            .do(onNext: { [weak self] in self?.debugLogCharts("[RecentRecords]", charts: $0) })
            .share(replay: 1)

        let pinnedCharts = loadTrigger
            .flatMapLatest { [weak self] _ -> Observable<[Chart]> in
                guard let self = self else { return .just([]) }
                return self.surfRecordUseCase.fetchAllSurfRecords()
                    .asObservable()
                    .map { records in
                        let pinned = records.filter { $0.isPin }
                        return pinned.flatMap { record in
                            record.charts.map {
                                Chart(beachID: record.beachID, time: $0.time,
                                      windDirection: $0.windDirection, windSpeed: $0.windSpeed,
                                      waveDirection: $0.waveDirection, waveHeight: $0.waveHeight,
                                      wavePeriod: $0.wavePeriod, waterTemperature: $0.waterTemperature,
                                      weather: self.convertWeatherIconNameToWeatherType($0.weatherIconName),
                                      airTemperature: $0.airTemperature)
                            }
                        }.sorted { $0.time > $1.time }
                    }
                    .catch { _ in .just([]) }
            }
            .do(onNext: { [weak self] in self?.debugLogCharts("[PinnedRecords]", charts: $0) })
            .share(replay: 1)

        return Output(
            beachData: beachData,
            dashboardCards: dashboardCards,
            groupedCharts: groupedCharts,
            recentRecordCharts: recentRecordCharts,
            pinnedCharts: pinnedCharts,
            allCharts: allChartsRelay.asObservable(),   // ✅ 추가
            isLoading: isLoadingRelay.asObservable(),
            error: errorRelay.asObservable()
        )
    }

    // MARK: - Public (이관된 비즈니스 로직)
    /// VC가 필요 시 직접 호출해 기간 필터링된 차트를 가져갑니다.
    func charts(from start: Date?, to end: Date?) -> [Chart] {
        let charts = allChartsRelay.value
        guard !charts.isEmpty else { return [] }
        guard let s = start, let e = end else { return charts }
        return charts.filter { $0.time >= s && $0.time <= e }
    }

    // MARK: - Private Helpers
    private func fetchBeachDataDirectly(beachId: String, region: String) -> Single<BeachData> {
        fetchBeachDataUseCase.execute(beachId: beachId, region: region)
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
        switch iconName {
        case "sun": return .clear
        case "cloudLittleSun": return .cloudLittleSun
        case "cloudMuchSun": return .cloudMuchSun
        case "cloud": return .cloudy
        case "rain": return .rain
        case "fog", "forg": return .fog
        case "snow": return .snow
        default: return .unknown
        }
    }

    private func groupChartsByDate(_ charts: [Chart]) -> [(date: Date, charts: [Chart])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: charts) { calendar.startOfDay(for: $0.time) }
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
