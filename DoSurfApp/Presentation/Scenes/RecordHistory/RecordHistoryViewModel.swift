import Foundation
import CoreData
import RxSwift
import RxCocoa
// MARK: - RecordFilter
enum RecordFilter: Equatable {
    case all
    case pinned
    case weather
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
        let selectedBeachID: Observable<Int>
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
    
    private let recordsRelay = BehaviorRelay<[SurfRecordData]>(value: [])
    private let filterRelay = BehaviorRelay<RecordFilter>(value: .all)
    private let sortTypeRelay = BehaviorRelay<SortType>(value: .latest)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    private let selectedBeachIDRelay = BehaviorRelay<Int?>(value: nil)
    
    // MARK: - Initializer
    init(useCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.useCase = useCase
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        input.selectedBeachID
            .bind(to: selectedBeachIDRelay)
            .disposed(by: disposeBag)
        
        // Load records when view loads or beach changes
        let loadTrigger = Observable.merge(
            input.viewDidLoad.map { () },
            selectedBeachIDRelay.asObservable().map { _ in () }
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
            .flatMapLatest { [weak self] _ -> Observable<[SurfRecordData]> in
                guard let self = self else { return .empty() }
                return self.useCase.fetchAllSurfRecords()
                    .asObservable()
                    .catch { _ in .just([]) }
            }
            .bind(to: recordsRelay)
            .disposed(by: disposeBag)
        
        // Handle pin record
        input.pinRecord
            .withLatestFrom(recordsRelay) { objectID, records in
                return (objectID, records)
            }
            .subscribe(onNext: { [weak self] objectID, records in
                // Toggle pin status - implementation needed in repository
            })
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
            case .weather:
                break
            case .rating(let minRating):
                filteredRecords = records.filter { $0.rating >= minRating }
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
