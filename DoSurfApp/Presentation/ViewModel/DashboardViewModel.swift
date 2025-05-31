import UIKit
import RxSwift
import RxCocoa

final class DashboardViewModel {

    // MARK: - Dependencies
    private let fetchBeachDataUseCase: FetchBeachDataUseCase
    private let surfRecordUseCase: SurfRecordUseCaseProtocol
    private let fetchBeachListUseCase: FetchBeachListUseCase

    // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let beachSelected: Observable<BeachDTO>
        let refreshTriggered: Observable<Void>
        let cardsLazyTrigger: Observable<Void>
    }

    // MARK: - Output
    struct Output {
        let beachData: Observable<BeachData>
        let dashboardCards: Observable<[DashboardCardData]>
        let groupedCharts: Observable<[(date: Date, charts: [Chart])]>
        let recentRecordCharts: Observable<[Chart]>
        let pinnedCharts: Observable<[Chart]>
        let allCharts: Observable<[Chart]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }

    // MARK: - State
    private let currentBeach = BehaviorRelay<BeachDTO?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    private let allChartsRelay = BehaviorRelay<[Chart]>(value: [])
    private var avgCardsCacheByRegion: [String: [DashboardCardData]] = [:]

    private let disposeBag = DisposeBag()

    // 선택: nil이면 최신 한 포인트, 숫자면 최근 N시간 이동평균
    private let movingWindowHours: Int? = nil // 필요시 6 등으로 바꿔도 됨

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
    init(
        fetchBeachDataUseCase: FetchBeachDataUseCase,
        surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase(),
        fetchBeachListUseCase: FetchBeachListUseCase
    ) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
        self.surfRecordUseCase = surfRecordUseCase
        self.fetchBeachListUseCase = fetchBeachListUseCase
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {
        let bg = ConcurrentDispatchQueueScheduler(qos: .userInitiated)

        let loadTrigger = Observable.merge(
            input.viewDidLoad.withLatestFrom(currentBeach.asObservable()).compactMap { $0 },
            input.beachSelected.do(onNext: { [weak self] in self?.currentBeach.accept($0) }),
            input.refreshTriggered.withLatestFrom(currentBeach.asObservable()).compactMap { $0 }
        )
        .debounce(.milliseconds(120), scheduler: MainScheduler.instance)
        .share(replay: 1)

        // 1) 현재 해변 데이터 (최근 7일만 조회하여 성능 최적화)
        let beachData = loadTrigger
            .do(onNext: { [weak self] _ in self?.isLoadingRelay.accept(true) })
            .flatMapLatest { [weak self] beach -> Observable<BeachData> in
                guard let self else { return .empty() }
                return self.fetchBeachDataUseCase.execute(beachId: beach.id, region: beach.region.slug, daysBack: 7)
                    .asObservable()
                    .subscribe(on: bg)
                    .do(onNext: { [weak self] data in
                        let flattened = data.charts.sorted { $0.time < $1.time }
                        self?.allChartsRelay.accept(flattened)
                        self?.isLoadingRelay.accept(false)
                    }, onError: { [weak self] e in
                        self?.isLoadingRelay.accept(false)
                        self?.errorRelay.accept(e)
                    })
                    .catch { [weak self] e in
                        self?.errorRelay.accept(e); return .empty()
                    }
            }
            .observe(on: MainScheduler.instance)
            .share(replay: 1)

        // 2) 빠른 카드 (현재 해변 최신값)
        let fastCard = beachData
            .map { data -> [DashboardCardData] in
                guard let last = data.charts.last else {
                    return [
                        .init(type: .wind, title: "바람", value: "0.0m/s", icon: "windFillIcon", color: .surfBlue),
                        .init(type: .wave, title: "파도", value: "0.0m", subtitle: "0.0s", icon: "waveFillIcon", color: .surfBlue)
                    ]
                }
                return [
                    .init(type: .wind, title: "바람",
                          value: String(format: "%.1fm/s", last.windSpeed),
                          directionDegrees: last.windDirection, icon: "windFillIcon", color: .surfBlue),
                    .init(type: .wave, title: "파도",
                          value: String(format: "%.1fm", last.waveHeight),
                          subtitle: String(format: "%.1fs", last.wavePeriod),
                          directionDegrees: last.waveDirection, icon: "waveFillIcon", color: .surfBlue),
                ]
            }
            .share(replay: 1)

        // 3) 동일 region의 모든 해변 조회
        let regionAllBeaches = loadTrigger
            .flatMapLatest { [weak self] beach -> Observable<(current: BeachDTO, all: [BeachDTO])> in
                guard let self else { return .just((beach, [])) }
                return self.fetchBeachListUseCase.execute(region: beach.region.slug)
                    .asObservable()
                    .map { (beach, $0) }
                    .catch { _ in .just((beach, [])) }
            }
            .share(replay: 1)

        // 4) 지역 평균 (지연 트리거 시 계산)
        let lazyAvgCard = input.cardsLazyTrigger
            .withLatestFrom(regionAllBeaches)
            .flatMapLatest { [weak self] (current, allInRegion) -> Observable<[DashboardCardData]> in
                guard let self else { return .just([]) }

                // 정책: 현재 해변 포함해서 지역 평균
                let targets = allInRegion.isEmpty ? [current] : allInRegion

                return Observable.from(targets)
                    .flatMapConcurrent(maxConcurrent: 10) { b -> Observable<BeachData?> in
                        self.fetchBeachDataUseCase.execute(beachId: b.id, region: b.region.slug, daysBack: 7)
                            .map { Optional($0) }
                            .asObservable()
                            .catch { _ in .just(nil) }
                    }
                    .toArray()
                    .asObservable()
                    .observe(on: bg)
                    .map { datas -> [DashboardCardData] in
                        let now = Date()
                        let perBeachStats: [(wSpeed: Double, wDir: Double?, h: Double, p: Double, wvDir: Double?)] =
                            datas.compactMap { $0 }.compactMap { data in
                                if let hrs = self.movingWindowHours {
                                    return self.averageOfLast(hours: hrs, charts: data.charts, now: now)
                                } else {
                                    guard let last = data.charts.last else { return nil }
                                    return (last.windSpeed, last.windDirection,
                                            last.waveHeight, last.wavePeriod, last.waveDirection)
                                }
                            }

                        guard !perBeachStats.isEmpty else { return [] }
                        let c = Double(perBeachStats.count)
                        let avgWind  = perBeachStats.map(\.wSpeed).reduce(0,+) / c
                        let avgWaveH = perBeachStats.map(\.h).reduce(0,+) / c
                        let avgWaveP = perBeachStats.map(\.p).reduce(0,+) / c
                        let avgWindDir = self.averageDirectionDegrees(perBeachStats.compactMap(\.wDir))
                        let avgWaveDir = self.averageDirectionDegrees(perBeachStats.compactMap(\.wvDir))

                        return [
                            .init(type: .wind, title: "지역 평균 바람",
                                  value: String(format: "%.1fm/s", avgWind),
                                  directionDegrees: avgWindDir, icon: "windFillIcon", color: .surfBlue),
                            .init(type: .wave, title: "지역 평균 파도",
                                  value: String(format: "%.1fm", avgWaveH),
                                  subtitle: String(format: "%.1fs", avgWaveP),
                                  directionDegrees: avgWaveDir, icon: "waveFillIcon", color: .surfBlue),
                        ]
                    }
                    .observe(on: MainScheduler.instance)
                    .do(onNext: { [weak self] cards in
                        // 선택: 캐시를 유지하려면 region slug를 키로 사용
                        if let regionKey = current.region.slug as String? {
                            self?.avgCardsCacheByRegion[regionKey] = cards
                        }
                    })
                    .catch { _ in .just([]) }
            }
            .share(replay: 1)

        let dashboardCards = Observable.merge(fastCard, lazyAvgCard)
            .share(replay: 1)

        let groupedCharts = beachData
            .observe(on: bg)
            .map { [weak self] in self?.groupChartsByDate($0.charts) ?? [] }
            .observe(on: MainScheduler.instance)
            .share(replay: 1)

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
            allCharts: allChartsRelay.asObservable(),
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
    private func fetchBeachDataDirectly(beachId: String, region: String, daysBack: Int = 7) -> Single<BeachData> {
        fetchBeachDataUseCase.execute(beachId: beachId, region: region, daysBack: daysBack)
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
        print("iconName:\(iconName)")
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

    // 이동평균 계산 helper (필요 시)
    private func averageOfLast(hours: Int, charts: [Chart], now: Date = Date())
    -> (wSpeed: Double, wDir: Double?, h: Double, p: Double, wvDir: Double?)? {
        let start = Calendar.current.date(byAdding: .hour, value: -hours, to: now)!
        let window = charts.filter { $0.time >= start && $0.time <= now }
        guard !window.isEmpty else { return nil }
        let wSpeed = window.map(\.windSpeed).reduce(0,+) / Double(window.count)
        let wDir   = averageDirectionDegrees(window.map(\.windDirection))
        let h      = window.map(\.waveHeight).reduce(0,+) / Double(window.count)
        let p      = window.map(\.wavePeriod).reduce(0,+) / Double(window.count)
        let wvDir  = averageDirectionDegrees(window.map(\.waveDirection))
        return (wSpeed, wDir, h, p, wvDir)
    }
}

// Rx 확장: 병렬 flatMap (없으면 그냥 flatMap으로 사용해도 OK)
private extension ObservableType {
    func flatMapConcurrent<R>(maxConcurrent: Int, _ selector: @escaping (Element) throws -> Observable<R>) -> Observable<R> {
        return flatMap { element in
            try selector(element).observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        }
        .buffer(timeSpan: .milliseconds(0), count: maxConcurrent, scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        .flatMap { Observable.from($0) }
    }
}
