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
            .share(replay: 1)
        
        // CoreData에서 고정 차트 가져오기
        let pinnedCharts = currentBeachId
            .distinctUntilChanged()
            .flatMapLatest { [weak self] beachID -> Observable<[Chart]> in
                guard let self = self else { return .just([]) }
                
                // beachID를 Int로 변환
                let beachIDInt = Int(beachID) ?? 0
                
                return self.surfRecordUseCase.fetchSurfRecords(for: beachIDInt)
                    .asObservable()
                    .map { records -> [Chart] in
                        // 고정된 기록만 필터링
                        let pinnedRecords = records.filter { $0.isPin }
                        
                        return pinnedRecords.flatMap { record in
                            record.charts.map { chartData in
                                Chart(
                                    beachID: beachIDInt,
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
                        }.sorted { $0.time > $1.time } // 최신 순으로 정렬
                    }
                    .catch { error in
                        print("Failed to fetch pinned charts: \(error)")
                        return .just([])
                    }
            }
            .share(replay: 1)
        
        return Output(
            beachData: beachData,
            dashboardCards: dashboardCards,
            groupedCharts: groupedCharts,
            recentRecordCharts: recentRecordCharts,
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
        switch iconName {
        case "sun":
            return .clear
        case "cloudLittleSun":
            return .cloudLittleSun
        case "cloudMuchSun":
            return .cloudMuchSun
        case "cloud":
            return .cloudy
        case "rain":
            return .rain
        case "forg":
            return .forg
        case "snow":
            return .snow
        default:
            return .unknown
        }
    }
    
    private func groupChartsByDate(_ charts: [Chart]) -> [(date: Date, charts: [Chart])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: charts) { chart in
            calendar.startOfDay(for: chart.time)
        }
        
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, charts: $0.value.sorted { $0.time < $1.time }) }
    }
}
