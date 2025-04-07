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
    
    // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let beachSelected: Observable<String>  // beachId
        let refreshTriggered: Observable<Void>
    }
    
    // MARK: - Output
    struct Output {
        let beachData: Observable<BeachDataDump>
        let dashboardCards: Observable<[DashboardCardData]>
        let groupedCharts: Observable<[(date: Date, charts: [Chart])]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
    
    // MARK: - Properties
    private let currentBeachId = BehaviorRelay<String>(value: "4001") // 기본값
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialize
    init(fetchBeachDataUseCase: FetchBeachDataUseCase) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        // beachId 변경 감지
        input.beachSelected
            .bind(to: currentBeachId)
            .disposed(by: disposeBag)
        
        // 데이터 로드 트리거 (viewDidLoad, beachSelected, refresh)
        let loadTrigger = Observable.merge(
            input.viewDidLoad.map { [weak self] _ in self?.currentBeachId.value ?? "4001" },
            input.beachSelected,
            input.refreshTriggered.withLatestFrom(currentBeachId.asObservable())
        )
        
        // 데이터 로드
        let beachData = loadTrigger
            .do(onNext: { [weak self] _ in
                self?.isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] beachId -> Observable<BeachDataDump> in
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
        
        // 대시보드 카드 데이터 생성
        let dashboardCards = beachData
            .map { dump -> [DashboardCardData] in
                guard let latestChart = dump.forecasts.first?.toDomain() else {
                    return []
                }
                
                return [
                    DashboardCardData(
                        type: .wind,
                        title: "바람",
                        value: String(format: "%.1fm/s", latestChart.windSpeed),
                        icon: "wind",
                        color: .systemBlue
                    ),
                    DashboardCardData(
                        type: .wave,
                        title: "파도",
                        value: String(format: "%.1fm", latestChart.waveHeight),
                        subtitle: String(format: "%.1fs", latestChart.wavePeriod),
                        icon: "water.waves",
                        color: .systemBlue
                    ),
                    DashboardCardData(
                        type: .temperature,
                        title: "수온",
                        value: String(format: "%.0f°C", latestChart.waterTemperature),
                        icon: "thermometer.medium",
                        color: .systemOrange
                    )
                ]
            }
        
        // 날짜별 그룹화된 차트
        let groupedCharts = beachData
            .map { dump -> [(date: Date, charts: [Chart])] in
                let charts = dump.forecasts.compactMap { $0.toDomain() }
                return self.groupChartsByDate(charts)
            }
        
        return Output(
            beachData: beachData,
            dashboardCards: dashboardCards,
            groupedCharts: groupedCharts,
            isLoading: isLoadingRelay.asObservable(),
            error: errorRelay.asObservable()
        )
    }
    
    // MARK: - Private Methods
    private func groupChartsByDate(_ charts: [Chart]) -> [(date: Date, charts: [Chart])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: charts) { chart in
            calendar.startOfDay(for: chart.time)
        }
        
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, charts: $0.value.sorted { $0.time < $1.time }) }
    }
}
