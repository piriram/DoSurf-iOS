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
        let beachSelected: Observable<String>
        let refreshTriggered: Observable<Void>
    }
    
    // MARK: - Output
    struct Output {
        let beachData: Observable<BeachData>  // 변경
        let dashboardCards: Observable<[DashboardCardData]>
        let groupedCharts: Observable<[(date: Date, charts: [Chart])]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
    
    // MARK: - Properties
    private let currentBeachId = BehaviorRelay<String>(value: "4001")
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialize
    init(fetchBeachDataUseCase: FetchBeachDataUseCase) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        input.beachSelected
            .bind(to: currentBeachId)
            .disposed(by: disposeBag)
        
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
        
        // 이미 Domain Chart를 사용
        let dashboardCards = beachData
            .map { beachData -> [DashboardCardData] in
                guard let latestChart = beachData.charts.first else {
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
        
        // 이미 Domain Chart를 사용
        let groupedCharts = beachData
            .map { beachData -> [(date: Date, charts: [Chart])] in
                return self.groupChartsByDate(beachData.charts)
            }
        
        return Output(
            beachData: beachData,
            dashboardCards: dashboardCards,
            groupedCharts: groupedCharts,
            isLoading: isLoadingRelay.asObservable(),
            error: errorRelay.asObservable()
        )
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
