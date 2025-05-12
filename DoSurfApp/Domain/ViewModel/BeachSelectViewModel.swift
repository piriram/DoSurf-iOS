//
//  BeachSelectViewModel.swift
//  DoSurfApp
//
//  Created by 잘만보김쥬디 on 9/29/25.
//
import UIKit
import RxSwift
import RxCocoa

final class BeachSelectViewModel {
    
    // MARK: - Dependencies
    private let fetchBeachDataUseCase: FetchBeachDataUseCase
    private let fetchBeachListUseCase: FetchBeachListUseCase
    private let storageService: SurfingRecordService
    let initialSelectedBeach: BeachDTO?
    
    // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let categorySelected: Observable<IndexPath>
        let locationSelected: Observable<IndexPath>
        let confirmButtonTapped: Observable<Void>
    }
    
    // MARK: - Output
    struct Output {
        let categories: Observable<[CategoryDTO]>
        let locations: Observable<[BeachDTO]>
        let selectedCategoryIndex: Observable<Int>
        let selectedBeachId: Observable<String?>
        let shouldScrollToCategory: Observable<IndexPath>
        let shouldReloadBeachTable: Observable<Void>
        let canConfirm: Observable<Bool>
        let dismiss: Observable<BeachDTO>
        let beachData: Observable<BeachData>
        let error: Observable<Error>
        let isLoading: Observable<Bool>
    }
    
    // MARK: - Properties
    private let categories = BehaviorRelay<[CategoryDTO]>(value: [])
    private let allBeaches = BehaviorRelay<[BeachDTO]>(value: [])
    private let selectedCategoryIndex = BehaviorRelay<Int>(value: 0)
    private let selectedBeach = BehaviorRelay<BeachDTO?>(value: nil)
    private let selectedBeachId = BehaviorRelay<String?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    private let shouldReloadBeachTableRelay = PublishRelay<Void>()
    
    private let disposeBag = DisposeBag()
    private var hasInitialLoadCompleted = false
    private var hasSetInitialSelection = false
    private var didEmitInitialCategorySelection = false
    
    private let lastRegionsIndexKey = "BeachSelectViewController.lastCategoryIndex"
    
    var isInitialLoad: Bool {
        !hasInitialLoadCompleted
    }
    
    // MARK: - Initialize
    init(
        fetchBeachDataUseCase: FetchBeachDataUseCase,
        fetchBeachListUseCase: FetchBeachListUseCase,
        storageService: SurfingRecordService,
        initialSelectedBeach: BeachDTO? = nil
    ) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
        self.fetchBeachListUseCase = fetchBeachListUseCase
        self.storageService = storageService
        self.initialSelectedBeach = initialSelectedBeach
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        // viewDidLoad: 해변 데이터 로드
        input.viewDidLoad
            .do(onNext: { [weak self] _ in
                self?.isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<[BeachDTO]> in
                guard let self = self else { return .empty() }
                
                return self.fetchBeachListUseCase.executeAll()
                    .asObservable()
                    .do(
                        onNext: { [weak self] beaches in
                            self?.isLoadingRelay.accept(false)
                            self?.allBeaches.accept(beaches)
                            
                            let uniqueRegions = Dictionary(grouping: beaches, by: { $0.region.slug })
                                .compactMap { _, beachesInRegion -> CategoryDTO? in
                                    guard let firstBeach = beachesInRegion.first else { return nil }
                                    return CategoryDTO(region: firstBeach.region)
                                }
                                .sorted { $0.region.order < $1.region.order }
                            
                            self?.categories.accept(uniqueRegions)
                            self?.setupInitialSelection(uniqueRegions: uniqueRegions)
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
            .subscribe()
            .disposed(by: disposeBag)
        
        // 카테고리 선택 처리
        let manualCategorySelection = input.categorySelected
            .do(onNext: { [weak self] indexPath in
                self?.hasSetInitialSelection = true
                self?.saveCategoryIndex(indexPath.row)
            })
        
        manualCategorySelection
            .map { $0.row }
            .bind(to: selectedCategoryIndex)
            .disposed(by: disposeBag)
        
        manualCategorySelection
            .subscribe(onNext: { [weak self] _ in
                self?.selectedBeach.accept(nil)
                self?.selectedBeachId.accept(nil)
            })
            .disposed(by: disposeBag)
        
        // 카테고리 변경에 따른 해변 필터링
        let initialTrigger = categories
            .filter { !$0.isEmpty }
            .take(1)
            .map { _ in () }
        
        let categoryChangeTrigger = selectedCategoryIndex
            .map { _ in () }
        
        let filterTrigger = Observable.merge(initialTrigger, categoryChangeTrigger)
        
        let filteredLocations: Observable<[BeachDTO]> = filterTrigger
            .withLatestFrom(Observable.combineLatest(selectedCategoryIndex, categories, allBeaches))
            .map { [weak self] (index, categories, beaches) -> [BeachDTO] in
                guard index < categories.count else { return [] }
                let selectedRegion = categories[index].region
                
                if self?.hasInitialLoadCompleted == false {
                    self?.hasInitialLoadCompleted = true
                }
                
                return beaches.filter { $0.region.slug == selectedRegion.slug }
            }
            .do(onNext: { [weak self] locations in
                guard let self = self else { return }
                
                // 초기 선택된 해변이 현재 필터링된 목록에 있는지 확인
                if !self.hasSetInitialSelection,
                   let initialBeach = self.initialSelectedBeach,
                   locations.contains(where: { $0.id == initialBeach.id }) {
                    self.selectedBeachId.accept(initialBeach.id)
                    self.selectedBeach.accept(initialBeach)
                    self.hasSetInitialSelection = true
                    self.shouldReloadBeachTableRelay.accept(())
                } else if self.hasSetInitialSelection {
                    // 카테고리 변경 시 선택 초기화
                    if self.selectedBeach.value != nil {
                        self.selectedBeachId.accept(nil)
                        self.shouldReloadBeachTableRelay.accept(())
                    }
                }
            })
            .asObservable()
        
        // 해변 선택 처리
        input.locationSelected
            .withLatestFrom(filteredLocations) { indexPath, locations -> BeachDTO? in
                guard indexPath.row < locations.count else { return nil }
                return locations[indexPath.row]
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] beach in
                self?.selectedBeach.accept(beach)
                self?.selectedBeachId.accept(beach.id)
                self?.shouldReloadBeachTableRelay.accept(())
            })
            .disposed(by: disposeBag)
        
        // 선택된 해변 데이터 가져오기
        let beachData = selectedBeach
            .compactMap { $0 }
            .distinctUntilChanged { $0.id == $1.id }
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
            .share(replay: 1)
        
        let canConfirm = selectedBeach
            .map { $0 != nil }
            .asObservable()
        
        // 확인 버튼 탭 처리
        let dismiss = input.confirmButtonTapped
            .withLatestFrom(selectedBeach.asObservable())
            .compactMap { [weak self] beach -> BeachDTO? in
                guard let beach = beach else { return nil }
                self?.storageService.createSelectedBeachID(beach.id)
                return beach
            }
        
        let shouldScrollToCategory = selectedCategoryIndex
            .map { IndexPath(row: $0, section: 0) }
            .asObservable()
        
        return Output(
            categories: categories.asObservable(),
            locations: filteredLocations,
            selectedCategoryIndex: selectedCategoryIndex.asObservable(),
            selectedBeachId: selectedBeachId.asObservable(),
            shouldScrollToCategory: shouldScrollToCategory,
            shouldReloadBeachTable: shouldReloadBeachTableRelay.asObservable(),
            canConfirm: canConfirm,
            dismiss: dismiss,
            beachData: beachData,
            error: errorRelay.asObservable(),
            isLoading: isLoadingRelay.asObservable()
        )
    }
    
    // MARK: - Private Methods
    private func setupInitialSelection(uniqueRegions: [CategoryDTO]) {
        guard !uniqueRegions.isEmpty else { return }
        
        if let initialBeach = initialSelectedBeach,
           let index = uniqueRegions.firstIndex(where: { $0.region.slug == initialBeach.region.slug }) {
            selectedCategoryIndex.accept(index)
            selectedBeach.accept(initialBeach)
            selectedBeachId.accept(initialBeach.id)
        } else {
            let savedIndex = loadSavedCategoryIndex()
            let clampedIndex = max(0, min(savedIndex, uniqueRegions.count - 1))
            selectedCategoryIndex.accept(clampedIndex)
        }
        
        didEmitInitialCategorySelection = true
    }
    
    private func loadSavedCategoryIndex() -> Int {
        (UserDefaults.standard.object(forKey: lastRegionsIndexKey) as? Int) ?? 0
    }
    
    private func saveCategoryIndex(_ index: Int) {
        UserDefaults.standard.set(index, forKey: lastRegionsIndexKey)
    }
}
