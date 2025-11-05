import Foundation
import CoreData
import RxSwift
import RxCocoa

// MARK: - RecordHistoryViewModel
final class RecordHistoryViewModel {
    
    // MARK: - Input/Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let filterSelection: Observable<RecordFilter>
        let sortSelection: Observable<SortType>
        let locationSelection: Observable<Int?>
        let recordSelection: Observable<RecordCardViewModel>
        let deleteRecord: Observable<NSManagedObjectID>
        let pinRecord: Observable<NSManagedObjectID>
        let editRecord: Observable<NSManagedObjectID>
    }
    
    struct Output {
        let records: Driver<[RecordCardViewModel]>
        let beaches: Driver<[BeachDTO]>
        let selectedBeach: Driver<BeachDTO?>
        let isEmpty: Driver<Bool>
        let isLoading: Driver<Bool>
        let error: Signal<Error>
        let selectedFilter: Driver<RecordFilter>
        let selectedSort: Driver<SortType>
    }
    
    // MARK: - Properties
    private let surfRecordUseCase: SurfRecordUseCaseProtocol
    private let fetchBeachListUseCase: FetchBeachListUseCase
    private let storageService: SurfingRecordService
    private let disposeBag = DisposeBag()
    
    private let recordsRelay = BehaviorRelay<[SurfRecordData]>(value: [])
    let beachesRelay = BehaviorRelay<[BeachDTO]>(value: [])
    private let filterRelay = BehaviorRelay<RecordFilter>(value: .all)
    private let sortTypeRelay = BehaviorRelay<SortType>(value: .latest)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    let selectedBeachIDRelay = BehaviorRelay<Int?>(value: nil)
    
    // MARK: - Initializer
    init(
        surfRecordUseCase: SurfRecordUseCaseProtocol,
        fetchBeachListUseCase: FetchBeachListUseCase,
        storageService: SurfingRecordService
    ) {
        self.surfRecordUseCase = surfRecordUseCase
        self.fetchBeachListUseCase = fetchBeachListUseCase
        self.storageService = storageService
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        // Load beach list on first load
        input.viewDidLoad
            .take(1)
            .flatMapLatest { [weak self] _ -> Observable<[BeachDTO]> in
                guard let self = self else { return .empty() }
                return self.fetchBeachListUseCase.executeAll()
                    .asObservable()
                    .catch { [weak self] error in
                        self?.errorRelay.accept(error)
                        return .just([])
                    }
            }
            .bind(to: beachesRelay)
            .disposed(by: disposeBag)
        
        // Seed selected beach from persistent storage on first load
        input.viewDidLoad
            .take(1)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                if let savedID = self.storageService.readSelectedBeachID(),
                   let beachID = Int(savedID) {
                    self.selectedBeachIDRelay.accept(beachID)
                }
            })
            .disposed(by: disposeBag)
        
        // Handle location selection
        input.locationSelection
            .subscribe(onNext: { [weak self] beachID in
                self?.selectedBeachIDRelay.accept(beachID)
                if let id = beachID {
                    self?.storageService.createSelectedBeachID(String(id))
                }
            })
            .disposed(by: disposeBag)
        
        // Observe beach selection changes broadcast from Dashboard
        NotificationCenter.default.rx.notification(.selectedBeachIDDidChange)
            .compactMap { $0.userInfo?["beachID"] as? String }
            .compactMap { Int($0) }
            .subscribe(onNext: { [weak self] beachID in
                self?.selectedBeachIDRelay.accept(beachID)
            })
            .disposed(by: disposeBag)
        
        // Load records when view loads, beach changes, or records change notification
        let loadTrigger = Observable.merge(
            input.viewDidLoad.map { () },
            selectedBeachIDRelay.asObservable().skip(1).map { _ in () },
            NotificationCenter.default.rx.notification(.surfRecordsDidChange).map { _ in () }
        )
        
        loadTrigger
            .withLatestFrom(selectedBeachIDRelay.asObservable())
            .flatMapLatest { [weak self] beachIDOption -> Observable<[SurfRecordData]> in
                guard let self = self else { return .empty() }
                self.isLoadingRelay.accept(true)
                
                let fetchObservable: Single<[SurfRecordData]>
                if let beachID = beachIDOption {
                    fetchObservable = self.surfRecordUseCase.fetchSurfRecords(for: beachID)
                } else {
                    fetchObservable = self.surfRecordUseCase.fetchAllSurfRecords()
                }
                
                return fetchObservable
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
                        return .just([])
                    }
            }
            .bind(to: recordsRelay)
            .disposed(by: disposeBag)
        
        // Handle filter selection
        input.filterSelection
            .bind(to: filterRelay)
            .disposed(by: disposeBag)
        
        // Handle sort selection
        input.sortSelection
            .bind(to: sortTypeRelay)
            .disposed(by: disposeBag)
        
        // Handle delete record
        input.deleteRecord
            .flatMapLatest { [weak self] objectID -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.surfRecordUseCase.deleteSurfRecord(by: objectID)
                    .asObservable()
                    .do(onError: { [weak self] error in
                        self?.errorRelay.accept(error)
                    })
                    .catch { _ in .empty() }
            }
            .withLatestFrom(selectedBeachIDRelay.asObservable())
            .flatMapLatest { [weak self] selectedBeachID -> Observable<[SurfRecordData]> in
                guard let self = self else { return .empty() }
                
                let fetchObservable: Single<[SurfRecordData]>
                if let beachID = selectedBeachID {
                    fetchObservable = self.surfRecordUseCase.fetchSurfRecords(for: beachID)
                } else {
                    fetchObservable = self.surfRecordUseCase.fetchAllSurfRecords()
                }
                
                return fetchObservable
                    .asObservable()
                    .catch { _ in .just([]) }
            }
            .bind(to: recordsRelay)
            .disposed(by: disposeBag)
        
        // Handle pin record (toggle isPin and persist to Core Data)
        input.pinRecord
            .withLatestFrom(
                Observable.combineLatest(
                    recordsRelay.asObservable(),
                    selectedBeachIDRelay.asObservable()
                )
            ) { objectID, combined in
                let (records, selectedBeachID) = combined
                return (objectID, records, selectedBeachID)
            }
            .flatMapLatest { [weak self] objectID, records, selectedBeachID -> Observable<[SurfRecordData]> in
                guard let self = self else { return .empty() }
                guard let current = records.first(where: { $0.id == objectID }) else {
                    return .empty()
                }
                
                // Toggle pin status
                let updatedRecord = SurfRecordData(
                    beachID: current.beachID,
                    id: current.id,
                    surfDate: current.surfDate,
                    startTime: current.startTime,
                    endTime: current.endTime,
                    rating: current.rating,
                    memo: current.memo,
                    isPin: !current.isPin,
                    charts: current.charts
                )
                
                let updateObservable = self.surfRecordUseCase.updateSurfRecord(updatedRecord)
                    .asObservable()
                
                let fetchObservable: Single<[SurfRecordData]>
                if let beachID = selectedBeachID {
                    fetchObservable = self.surfRecordUseCase.fetchSurfRecords(for: beachID)
                } else {
                    fetchObservable = self.surfRecordUseCase.fetchAllSurfRecords()
                }
                
                return updateObservable
                    .flatMapLatest { fetchObservable.asObservable() }
                    .do(onNext: { _ in
                        NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                    })
                    .catch { [weak self] error in
                        self?.errorRelay.accept(error)
                        return .empty()
                    }
            }
            .bind(to: recordsRelay)
            .disposed(by: disposeBag)
        
        // Combine records with filter and sort
        let filteredAndSortedRecords = Observable.combineLatest(
            recordsRelay.asObservable(),
            filterRelay.asObservable(),
            sortTypeRelay.asObservable()
        )
            .map { records, filter, sortType -> [SurfRecordData] in
                var filteredRecords = records
                
                // Apply filter
                filteredRecords = self.applyFilter(filter, to: records)
                
                // Apply sort
                filteredRecords = self.applySort(sortType, to: filteredRecords)
                
                return filteredRecords
            }
        
        // Map to view models
        let recordViewModels = filteredAndSortedRecords
            .map { records -> [RecordCardViewModel] in
                records.map { RecordCardViewModel(record: $0) }
            }
            .asDriver(onErrorJustReturn: [])
        
        let isEmpty = recordViewModels
            .map { $0.isEmpty }
        
        let selectedBeach = Observable.combineLatest(
            beachesRelay.asObservable(),
            selectedBeachIDRelay.asObservable()
        )
            .map { beaches, beachIDOption -> BeachDTO? in
                guard let beachID = beachIDOption else { return nil }
                return beaches.first { Int($0.id) == beachID }
            }
            .asDriver(onErrorJustReturn: nil)
        
        return Output(
            records: recordViewModels,
            beaches: beachesRelay.asDriver(),
            selectedBeach: selectedBeach,
            isEmpty: isEmpty,
            isLoading: isLoadingRelay.asDriver(),
            error: errorRelay.asSignal(),
            selectedFilter: filterRelay.asDriver(),
            selectedSort: sortTypeRelay.asDriver()
        )
    }
    
    // MARK: - Private Methods
    private func applyFilter(_ filter: RecordFilter, to records: [SurfRecordData]) -> [SurfRecordData] {
        switch filter {
        case .all:
            return records
            
        case .pinned:
            return records.filter { $0.isPin }
            
        case .datePreset(let preset):
            let calendar = Calendar.current
            let now = Date()
            let (start, endBound) = calculateDateRange(for: preset, calendar: calendar, now: now)
            return records.filter { record in
                let date = record.surfDate
                return date >= start && date < endBound
            }
            
        case .dateRange(let startRaw, let endRaw):
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: startRaw)
            let endBound = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endRaw)) ?? endRaw
            return records.filter { record in
                let date = record.surfDate
                return date >= start && date < endBound
            }
            
        case .rating(let exactRating):
            return records.filter { Int($0.rating) == exactRating }
        }
    }
    
    private func calculateDateRange(
        for preset: DatePreset,
        calendar: Calendar,
        now: Date
    ) -> (start: Date, end: Date) {
        switch preset {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return (start, end)
            
        case .last7Days:
            let todayStart = calendar.startOfDay(for: now)
            let start = calendar.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart
            let end = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
            return (start, end)
            
        case .thisMonth:
            let start = startOfMonth(for: now, calendar: calendar)
            let end = startOfNextMonth(after: now, calendar: calendar)
            return (start, end)
            
        case .lastMonth:
            let thisMonthStart = startOfMonth(for: now, calendar: calendar)
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? thisMonthStart
            let end = thisMonthStart
            return (start, end)
        }
    }
    
    private func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)
            .map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: date)
    }
    
    private func startOfNextMonth(after date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        let nextMonth = calendar.date(
            from: DateComponents(
                year: components.year,
                month: (components.month ?? 1) + 1
            )
        ) ?? date
        return calendar.startOfDay(for: nextMonth)
    }
    
    private func applySort(_ sortType: SortType, to records: [SurfRecordData]) -> [SurfRecordData] {
        var sortedRecords = records
        
        switch sortType {
        case .latest:
            sortedRecords.sort { $0.surfDate > $1.surfDate }
        case .oldest:
            sortedRecords.sort { $0.surfDate < $1.surfDate }
        case .highRating:
            sortedRecords.sort { $0.rating > $1.rating }
        case .lowRating:
            sortedRecords.sort { $0.rating < $1.rating }
        }
        
        return sortedRecords
    }
    
    func resetToDefaults(resetBeach: Bool = false) {
        filterRelay.accept(.all)
        sortTypeRelay.accept(.latest)
        if resetBeach {
            selectedBeachIDRelay.accept(nil)
        }
    }
}
