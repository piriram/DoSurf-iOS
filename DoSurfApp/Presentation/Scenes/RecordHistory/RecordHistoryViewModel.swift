import Foundation
import CoreData
import RxSwift
import RxCocoa

enum DatePreset: Equatable {
    case today
    case last7Days
    case thisMonth
    case lastMonth
}
// MARK: - RecordFilter
enum RecordFilter: Equatable {
    case all
    case pinned
    case datePreset(DatePreset)
    case dateRange(start: Date, end: Date)
    case rating(Int)
}
// MARK: - RecordHistoryViewModel
final class RecordHistoryViewModel {
    
    // MARK: - Input/Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let filterSelection: Observable<RecordFilter>
        let sortSelection: Observable<Void>
        let ratingSelection: Observable<Void>
        let recordSelection: Observable<RecordCardViewModel>
        let moreButtonTap: Observable<IndexPath>
        let deleteRecord: Observable<NSManagedObjectID>
        let pinRecord: Observable<NSManagedObjectID>
        let editRecord: Observable<NSManagedObjectID>
        let selectedBeachID: Observable<Int?>
    }
    
    struct Output {
        let records: Driver<[RecordCardViewModel]>
        let isEmpty: Driver<Bool>
        let isLoading: Driver<Bool>
        let error: Signal<Error>
        let selectedFilter: Driver<RecordFilter>
    }
    
    // MARK: - Properties
    private let useCase: SurfRecordUseCaseProtocol
    private let disposeBag = DisposeBag()
    private let storageService: SurfingRecordService
    
    private let recordsRelay = BehaviorRelay<[SurfRecordData]>(value: [])
    private let filterRelay = BehaviorRelay<RecordFilter>(value: .all)
    private let sortTypeRelay = BehaviorRelay<SortType>(value: .latest)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    private let selectedBeachIDRelay = BehaviorRelay<Int?>(value: nil)
    
    // MARK: - Initializer
    init(useCase: SurfRecordUseCaseProtocol = SurfRecordUseCase(), storageService: SurfingRecordService = UserDefaultsService()) {
        self.useCase = useCase
        self.storageService = storageService
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        // Seed selected beach from persistent storage on first load
        input.viewDidLoad
            .take(1)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                if let saved = self.storageService.readSelectedBeachID(), let id = Int(saved) {
                    self.selectedBeachIDRelay.accept(id)
                }
            })
            .disposed(by: disposeBag)
        
        // Observe beach selection changes broadcast from Dashboard
        NotificationCenter.default.rx.notification(.selectedBeachIDDidChange)
            .compactMap { $0.userInfo?["beachID"] as? String }
            .compactMap { Int($0) }
            .subscribe(onNext: { [weak self] id in
                self?.selectedBeachIDRelay.accept(id)
            })
            .disposed(by: disposeBag)
        
        input.selectedBeachID
            .bind(to: selectedBeachIDRelay)
            .disposed(by: disposeBag)
        
        // Load records when view loads or beach changes or records change notification
        let loadTrigger = Observable.merge(
            input.viewDidLoad.map { () },
            selectedBeachIDRelay.asObservable().map { _ in () },
            NotificationCenter.default.rx.notification(.surfRecordsDidChange).map { _ in () }
        )
        loadTrigger
            .withLatestFrom(selectedBeachIDRelay.asObservable())
            .flatMapLatest { [weak self] beachIDOpt -> Observable<[SurfRecordData]> in
                guard let self = self else { return .empty() }
                self.isLoadingRelay.accept(true)
                let fetch: Single<[SurfRecordData]>
                if let beachID = beachIDOpt {
                    fetch = self.useCase.fetchSurfRecords(for: beachID)
                } else {
                    fetch = self.useCase.fetchAllSurfRecords()
                }
                return fetch
                    .asObservable()
                    .do(onNext: { [weak self] _ in
                        self?.isLoadingRelay.accept(false)
                    }, onError: { [weak self] error in
                        self?.isLoadingRelay.accept(false)
                        self?.errorRelay.accept(error)
                    })
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
            .withLatestFrom(sortTypeRelay)
            .map { currentSort -> SortType in
                switch currentSort {
                case .latest: return .oldest
                case .oldest: return .highRating
                case .highRating: return .lowRating
                case .lowRating: return .latest
                }
            }
            .bind(to: sortTypeRelay)
            .disposed(by: disposeBag)
        
        // Handle delete record
        input.deleteRecord
            .flatMapLatest { [weak self] objectID -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.useCase.deleteSurfRecord(by: objectID)
                    .asObservable()
                    .do(onError: { [weak self] error in
                        self?.errorRelay.accept(error)
                    })
                    .catch { _ in .empty() }
            }
            .withLatestFrom(selectedBeachIDRelay.asObservable())
            .flatMapLatest { [weak self] selectedBeachID -> Observable<[SurfRecordData]> in
                guard let self = self else { return .empty() }
                if let beachID = selectedBeachID {
                    return self.useCase.fetchSurfRecords(for: beachID).asObservable().catch { _ in .just([]) }
                } else {
                    return self.useCase.fetchAllSurfRecords().asObservable().catch { _ in .just([]) }
                }
            }
            .bind(to: recordsRelay)
            .disposed(by: disposeBag)
        
        // Handle pin record (toggle isPin and persist to Core Data)
        input.pinRecord
            .withLatestFrom(Observable.combineLatest(recordsRelay.asObservable(), selectedBeachIDRelay.asObservable())) { objectID, combined in
                let (records, selectedBeachID) = combined
                return (objectID, records, selectedBeachID)
            }
            .flatMapLatest { [weak self] (objectID, records, selectedBeachID) -> Observable<[SurfRecordData]> in
                guard let self = self else { return .empty() }
                guard let current = records.first(where: { $0.id == objectID }) else {
                    return .empty()
                }
                // Toggle pin status
                let updated = SurfRecordData(
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
                
                let update = self.useCase.updateSurfRecord(updated).asObservable()
                
                let fetch: Observable<[SurfRecordData]>
                if let beachID = selectedBeachID {
                    fetch = self.useCase.fetchSurfRecords(for: beachID).asObservable()
                } else {
                    fetch = self.useCase.fetchAllSurfRecords().asObservable()
                }
                
                return update
                    .flatMapLatest { fetch }
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
            switch filter {
            case .all:
                break
            case .pinned:
                filteredRecords = records.filter { $0.isPin }
            case .datePreset(let preset):
                let cal = Calendar.current
                let now = Date()
                let start: Date
                let endBound: Date

                func startOfMonth(for date: Date) -> Date {
                    let comps = cal.dateComponents([.year, .month], from: date)
                    return cal.date(from: comps).map { cal.startOfDay(for: $0) } ?? cal.startOfDay(for: date)
                }
                func startOfNextMonth(after date: Date) -> Date {
                    let comps = cal.dateComponents([.year, .month], from: date)
                    let next = cal.date(from: DateComponents(year: comps.year, month: (comps.month ?? 1) + 1)) ?? date
                    return cal.startOfDay(for: next)
                }

                switch preset {
                case .today:
                    start = cal.startOfDay(for: now)
                    endBound = cal.date(byAdding: .day, value: 1, to: start) ?? now
                case .last7Days:
                    let todayStart = cal.startOfDay(for: now)
                    start = cal.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart
                    endBound = cal.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
                case .thisMonth:
                    start = startOfMonth(for: now)
                    endBound = startOfNextMonth(after: now)
                case .lastMonth:
                    let thisMonthStart = startOfMonth(for: now)
                    start = cal.date(byAdding: .month, value: -1, to: thisMonthStart) ?? thisMonthStart
                    endBound = thisMonthStart
                }

                filteredRecords = records.filter { d in
                    let date = d.surfDate
                    return date >= start && date < endBound
                }
            case .dateRange(let startRaw, let endRaw):
                let cal = Calendar.current
                let start = cal.startOfDay(for: startRaw)
                let endBound = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endRaw)) ?? endRaw
                filteredRecords = records.filter { d in
                    let date = d.surfDate
                    return date >= start && date < endBound
                }
            case .rating(let exactRating):
                filteredRecords = records.filter { Int($0.rating) == exactRating }
            }
            
            // Apply sort
            switch sortType {
            case .latest:
                filteredRecords.sort { $0.surfDate > $1.surfDate }
            case .oldest:
                filteredRecords.sort { $0.surfDate < $1.surfDate }
            case .highRating:
                filteredRecords.sort { $0.rating > $1.rating }
            case .lowRating:
                filteredRecords.sort { $0.rating < $1.rating }
            }
            
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
        
        return Output(
            records: recordViewModels,
            isEmpty: isEmpty,
            isLoading: isLoadingRelay.asDriver(),
            error: errorRelay.asSignal(),
            selectedFilter: filterRelay.asDriver()
        )
    }
}

// MARK: - SortType
enum SortType {
    case latest
    case oldest
    case highRating
    case lowRating
    
    var title: String {
        switch self {
        case .latest: return "최신순"
        case .oldest: return "과거순"
        case .highRating: return "높은 별점순"
        case .lowRating: return "낮은 별점순"
        }
    }
}

// MARK: - RecordCardViewModel
struct RecordCardViewModel {
    let objectID: NSManagedObjectID?
    let date: String
    let dayOfWeek: String
    let rating: Int
    let ratingText: String
    let isPin: Bool
    let charts: [Chart]
    let memo: String?
    
    init(record: SurfRecordData) {
        self.objectID = record.id
        self.isPin = record.isPin
        self.memo = record.memo
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월 d일"
        self.date = dateFormatter.string(from: record.surfDate)
        
        dateFormatter.dateFormat = "EEEE"
        self.dayOfWeek = dateFormatter.string(from: record.surfDate)
        
        // Rating
        self.rating = Int(record.rating)
        self.ratingText = Self.ratingToText(Int(record.rating))
        
        // Convert SurfChartData to Chart
        self.charts = record.charts.map { chartData in
            Chart(
                beachID: 0,
                time: chartData.time,
                windDirection: chartData.windDirection,
                windSpeed: chartData.windSpeed,
                waveDirection: chartData.waveDirection,
                waveHeight: chartData.waveHeight,
                wavePeriod: chartData.wavePeriod,
                waterTemperature: chartData.waterTemperature,
                weather: WeatherType(rawValue: Int(chartData.weatherIconName) ?? 999) ?? .unknown,
                airTemperature: chartData.airTemperature
            )
        }
    }
    
    private static func ratingToText(_ rating: Int) -> String {
        switch rating {
        case 5: return "최고예요"
        case 4: return "좋아요"
        case 3: return "보통이에요"
        case 2: return "별로예요"
        case 1: return "최악이에요"
        default: return ""
        }
    }
}

extension Notification.Name {
    static let selectedBeachIDDidChange = Notification.Name("selectedBeachIDDidChange")
}
