//
//  SurfRecordViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import RxSwift
import RxCocoa
import Foundation

final class NoteViewModel {
    
    // MARK: - Input & Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let dateChanged: Observable<Date>
        let startTimeChanged: Observable<Date>
        let endTimeChanged: Observable<Date>
        let ratingChanged: Observable<Int>
        let memoChanged: Observable<String?>
        let saveTapped: Observable<Void>
    }
    
    struct Output {
        let mode: Driver<SurfRecordMode>
        let filteredCharts: Driver<[Chart]>
        let initialData: Driver<InitialData>
        let saveSuccess: Driver<Void>
        let saveError: Signal<Error>  // ✅ Error 타입으로 수정
        let isLoading: Driver<Bool>
    }
    
    struct InitialData {
        let date: Date
        let startTime: Date
        let endTime: Date
        let rating: Int
        let memo: String?
    }
    
    // MARK: - Properties
    private let mode: SurfRecordMode
    private let surfRecordUseCase: SurfRecordUseCaseProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - State
    private let chartsRelay = BehaviorRelay<[Chart]>(value: [])
    private let currentDateRelay = BehaviorRelay<Date>(value: Date())
    private let currentStartTimeRelay = BehaviorRelay<Date>(value: Date())
    private let currentEndTimeRelay = BehaviorRelay<Date>(value: Date())
    private let currentRatingRelay = BehaviorRelay<Int>(value: 3)
    private let currentMemoRelay = BehaviorRelay<String?>(value: nil)
    
    // MARK: - Initialization
    init(
        mode: SurfRecordMode,
        surfRecordUseCase: SurfRecordUseCaseProtocol
    ) {
        self.mode = mode
        self.surfRecordUseCase = surfRecordUseCase
        
        // 초기 차트 데이터 설정
        if let charts = mode.charts {
            chartsRelay.accept(charts)
        }
    }
    
    // MARK: - Transform
    func transform(_ input: Input) -> Output {
        let loadingRelay = BehaviorRelay<Bool>(value: false)
        let saveSuccessRelay = PublishRelay<Void>()
        let saveErrorRelay = PublishRelay<Error>()  // ✅ Error 타입
        
        // viewDidLoad 시 초기 데이터 설정
        let initialData = input.viewDidLoad
            .map { [weak self] _ -> InitialData in  // ✅ 타입 명시
                guard let self = self else {
                    return InitialData(
                        date: Date(),
                        startTime: Date(),
                        endTime: Date(),
                        rating: 3,
                        memo: nil
                    )
                }
                
                let now = Date()
                var date = now
                var startTime: Date
                var endTime: Date
                var rating = 3
                var memo: String?
                
                switch self.mode {
                case .new(let start, let end, _):
                    if let start = start {
                        date = start
                        startTime = self.stripSeconds(start)
                        endTime = end.map { self.stripSeconds($0) } ?? Calendar.current.date(byAdding: .hour, value: 2, to: startTime) ?? startTime
                    } else if let end = end {
                        endTime = self.stripSeconds(end)
                        startTime = Calendar.current.date(byAdding: .hour, value: -2, to: endTime) ?? endTime
                        date = startTime
                    } else {
                        startTime = self.date(bySettingHour: 13, minute: 0, on: now)
                        endTime = self.date(bySettingHour: 15, minute: 0, on: now)
                    }
                    
                case .edit(let record):
                    date = record.surfDate
                    startTime = record.startTime
                    endTime = record.endTime
                    rating = Int(record.rating)
                    memo = record.memo
                }
                
                // 상태 업데이트
                self.currentDateRelay.accept(date)
                self.currentStartTimeRelay.accept(startTime)
                self.currentEndTimeRelay.accept(endTime)
                self.currentRatingRelay.accept(rating)
                self.currentMemoRelay.accept(memo)
                
                return InitialData(
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    rating: rating,
                    memo: memo
                )
            }
            .asDriver(onErrorJustReturn: InitialData(
                date: Date(),
                startTime: Date(),
                endTime: Date(),
                rating: 3,
                memo: nil
            ))
        
        // 날짜 변경 처리
        input.dateChanged
            .subscribe(onNext: { [weak self] date in
                self?.currentDateRelay.accept(date)
            })
            .disposed(by: disposeBag)
        
        // 시작 시간 변경 처리
        input.startTimeChanged
            .subscribe(onNext: { [weak self] time in
                self?.currentStartTimeRelay.accept(time)
            })
            .disposed(by: disposeBag)
        
        // 종료 시간 변경 처리
        input.endTimeChanged
            .subscribe(onNext: { [weak self] time in
                self?.currentEndTimeRelay.accept(time)
            })
            .disposed(by: disposeBag)
        
        // 별점 변경 처리
        input.ratingChanged
            .subscribe(onNext: { [weak self] rating in
                self?.currentRatingRelay.accept(rating)
            })
            .disposed(by: disposeBag)
        
        // 메모 변경 처리
        input.memoChanged
            .subscribe(onNext: { [weak self] memo in
                self?.currentMemoRelay.accept(memo)
            })
            .disposed(by: disposeBag)
        
        // 필터링된 차트 데이터 (시작/종료 시간 변경 시 자동 필터링)
        let filteredCharts = Observable.combineLatest(
            chartsRelay.asObservable(),
            currentStartTimeRelay.asObservable(),
            currentEndTimeRelay.asObservable()
        )
            .map { [weak self] charts, startTime, endTime -> [Chart] in
                guard let self = self else { return [] }
                return self.filterCharts(charts: charts, startTime: startTime, endTime: endTime)
            }
            .asDriver(onErrorJustReturn: [])
        
        // 저장 처리
        input.saveTapped
            .withLatestFrom(Observable.combineLatest(
                currentDateRelay.asObservable(),
                currentStartTimeRelay.asObservable(),
                currentEndTimeRelay.asObservable(),
                currentRatingRelay.asObservable(),
                currentMemoRelay.asObservable(),
                filteredCharts.asObservable()
            ))
            .do(onNext: { _ in loadingRelay.accept(true) })
            .flatMapLatest { [weak self] date, startTime, endTime, rating, memo, charts -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                switch self.mode {
                case .new:
                    return self.saveNewRecord(
                        date: date,
                        startTime: startTime,
                        endTime: endTime,
                        rating: rating,
                        memo: memo,
                        charts: charts
                    )
                    
                case .edit(let record):
                    return self.updateRecord(
                        existing: record,
                        date: date,
                        startTime: startTime,
                        endTime: endTime,
                        rating: rating,
                        memo: memo,
                        charts: charts
                    )
                }
            }
            .do(onNext: { _ in loadingRelay.accept(false) })
            .subscribe(
                onNext: {
                    NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                    saveSuccessRelay.accept(())
                },
                onError: { error in
                    loadingRelay.accept(false)
                    saveErrorRelay.accept(error)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            mode: Driver.just(mode),
            filteredCharts: filteredCharts,
            initialData: initialData,
            saveSuccess: saveSuccessRelay.asDriver(onErrorDriveWith: .empty()),
            saveError: saveErrorRelay.asSignal(),  // ✅ Signal<Error>
            isLoading: loadingRelay.asDriver()
        )
    }
    
    // MARK: - Private Methods
    
    /// 새 기록 저장
    private func saveNewRecord(
        date: Date,
        startTime: Date,
        endTime: Date,
        rating: Int,
        memo: String?,
        charts: [Chart]
    ) -> Observable<Void> {
        let beachID = charts.first?.beachID ?? mode.charts?.first?.beachID ?? 0
        
        return surfRecordUseCase.saveSurfRecord(
            surfDate: date,
            startTime: startTime,
            endTime: endTime,
            beachID: beachID,
            rating: Int16(rating),
            memo: memo,
            isPin: false,
            charts: charts
        )
        .asObservable()
        .map { _ in () }
    }
    
    /// 기존 기록 업데이트
    private func updateRecord(
        existing: SurfRecordData,
        date: Date,
        startTime: Date,
        endTime: Date,
        rating: Int,
        memo: String?,
        charts: [Chart]
    ) -> Observable<Void> {
        let beachID = existing.beachID != 0 ? existing.beachID : (charts.first?.beachID ?? 0)
        
        let updated = SurfRecordData(
            beachID: beachID,
            id: existing.id,
            surfDate: date,
            startTime: startTime,
            endTime: endTime,
            rating: Int16(rating),
            memo: memo ?? existing.memo,
            isPin: existing.isPin,
            charts: charts.map { chart in
                SurfChartData(
                    time: chart.time,
                    windSpeed: chart.windSpeed,
                    windDirection: chart.windDirection,
                    waveHeight: chart.waveHeight,
                    wavePeriod: chart.wavePeriod,
                    waveDirection: chart.waveDirection,
                    airTemperature: chart.airTemperature,
                    waterTemperature: chart.waterTemperature,
                    weatherIconName: chart.weather.iconName
                )
            }
        )
        
        return surfRecordUseCase.updateSurfRecord(updated)
            .asObservable()
            .map { _ in () }
    }
    
    /// 차트 필터링 (KST 3시간 슬롯 기반)
    private func filterCharts(charts: [Chart], startTime: Date, endTime: Date) -> [Chart] {
        let lowerBound = alignDownTo3hKST(startTime)
        let upperBound = endTime
        
        return charts
            .filter { $0.time >= lowerBound && $0.time <= upperBound }
            .sorted { $0.time < $1.time }
    }
    
    // MARK: - Date Helpers
    
    private func stripSeconds(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return cal.date(from: comps) ?? date
    }
    
    private func date(bySettingHour hour: Int, minute: Int, on base: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: base)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? base
    }
    
    private func kstCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return cal
    }
    
    private func alignDownTo3hKST(_ date: Date) -> Date {
        let cal = kstCalendar()
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: date)
        guard let hour = comps.hour else { return date }
        let flooredHour = (hour / 3) * 3
        var aligned = DateComponents()
        aligned.year = comps.year
        aligned.month = comps.month
        aligned.day = comps.day
        aligned.hour = flooredHour
        aligned.minute = 0
        aligned.second = 0
        return cal.date(from: aligned) ?? date
    }
}
