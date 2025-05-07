//
//  BeachSelectViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//
import UIKit
import RxSwift
import RxCocoa

final class BeachSelectViewModel {
    
    // MARK: - Dependencies
    private let fetchBeachDataUseCase: FetchBeachDataUseCase
    private let fetchBeachListUseCase: FetchBeachListUseCase
    
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
        let selectedCategory: Observable<Int>
        let canConfirm: Observable<Bool>
        let dismiss: Observable<[BeachDTO]>
        let beachData: Observable<BeachData>
        let error: Observable<Error>
        let isLoading: Observable<Bool>
    }
    
    // MARK: - Properties
    private let categories = BehaviorRelay<[CategoryDTO]>(value: [])
    private let allBeaches = BehaviorRelay<[BeachDTO]>(value: [])
    private let selectedCategoryIndex = BehaviorRelay<Int>(value: 0)
    private let selectedBeach = BehaviorRelay<BeachDTO?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialize
    init(
        fetchBeachDataUseCase: FetchBeachDataUseCase,
        fetchBeachListUseCase: FetchBeachListUseCase
    ) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
        self.fetchBeachListUseCase = fetchBeachListUseCase
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
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
                            
                            // beaches에서 고유한 BeachRegion 추출하여 CategoryDTO 생성
                            let uniqueRegions = Dictionary(grouping: beaches, by: { $0.region.slug })
                                .compactMap { _, beachesInRegion -> CategoryDTO? in
                                    guard let firstBeach = beachesInRegion.first else { return nil }
                                    return CategoryDTO(region: firstBeach.region, regionName: firstBeach.regionName)
                                }
                                .sorted { $0.region.order < $1.region.order }
                            
                            self?.categories.accept(uniqueRegions)
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
        
        input.categorySelected
            .map { $0.row }
            .bind(to: selectedCategoryIndex)
            .disposed(by: disposeBag)
        
        selectedCategoryIndex
            .subscribe(onNext: { [weak self] _ in
                self?.selectedBeach.accept(nil)
            })
            .disposed(by: disposeBag)
        
        let filteredLocations: Observable<[BeachDTO]> = selectedCategoryIndex
            .withLatestFrom(categories) { (index, categories) -> BeachRegion? in
                guard index < categories.count else { return nil }
                return categories[index].region
            }
            .withLatestFrom(allBeaches) { (selectedRegion: BeachRegion?, beaches: [BeachDTO]) -> [BeachDTO] in
                guard let selectedRegion = selectedRegion else { return [] }
                return beaches.filter { $0.region.slug == selectedRegion.slug }
            }
            .asObservable()
        
        input.locationSelected
            .withLatestFrom(filteredLocations) { indexPath, locations -> BeachDTO? in
                guard indexPath.row < locations.count else { return nil }
                return locations[indexPath.row]
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] beach in
                self?.selectedBeach.accept(beach)
            })
            .disposed(by: disposeBag)
        
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
        
        let dismiss = input.confirmButtonTapped
            .withLatestFrom(selectedBeach.asObservable())
            .compactMap { $0 }
            .map { [$0] }
        
        return Output(
            categories: categories.asObservable(),
            locations: filteredLocations,
            selectedCategory: selectedCategoryIndex.asObservable(),
            canConfirm: canConfirm,
            dismiss: dismiss,
            beachData: beachData,
            error: errorRelay.asObservable(),
            isLoading: isLoadingRelay.asObservable()
        )
    }
}
