//
//  BeachChooseViewModel.swift
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
    
    // MARK: - Input
    struct Input {
        let categorySelected: Observable<IndexPath>
        let locationSelected: Observable<IndexPath>
        let confirmButtonTapped: Observable<Void>
    }
    
    // MARK: - Output
    struct Output {
        let categories: Observable<[CategoryDTO]>
        let locations: Observable<[LocationDTO]>
        let selectedCategory: Observable<Int>
        let canConfirm: Observable<Bool>
        let dismiss: Observable<[LocationDTO]>
        let beachData: Observable<BeachData>
        let error: Observable<Error>
        let isLoading: Observable<Bool>
    }
    
    // MARK: - Properties
    private let categories = BehaviorRelay<[CategoryDTO]>(value: [])
    private let locations = BehaviorRelay<[LocationDTO]>(value: [])
    private let selectedCategoryIndex = BehaviorRelay<Int>(value: 0)
    private let selectedLocations = BehaviorRelay<Set<String>>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<Error>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialize
    init(fetchBeachDataUseCase: FetchBeachDataUseCase) {
        self.fetchBeachDataUseCase = fetchBeachDataUseCase
        setupMockData()
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        input.categorySelected
            .map { $0.row }
            .bind(to: selectedCategoryIndex)
            .disposed(by: disposeBag)
        
        let filteredLocations = selectedCategoryIndex
            .withLatestFrom(categories) { index, categories in
                guard index < categories.count else { return BeachRegion.yangyang }
                return categories[index].region
            }
            .map { [weak self] selectedRegion -> [LocationDTO] in
                guard let self = self else { return [] }
                return self.locations.value.filter { $0.region == selectedRegion }
            }
            .asObservable()
        
        let beachData = input.locationSelected
            .withLatestFrom(filteredLocations) { indexPath, locations -> LocationDTO? in
                guard indexPath.row < locations.count else { return nil }
                return locations[indexPath.row]
            }
            .compactMap { $0 }
            .do(onNext: { [weak self] location in
                self?.selectedLocations.accept([location.id])
                self?.isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] location -> Observable<BeachData> in
                guard let self = self else { return .empty() }
                
                return self.fetchBeachDataUseCase.execute(beachId: location.id)
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
        
        let canConfirm = selectedLocations
            .map { !$0.isEmpty }
            .asObservable()
        
        let dismiss = input.confirmButtonTapped
            .withLatestFrom(Observable.combineLatest(locations, selectedLocations))
            .map { locations, selectedIds in
                locations.filter { selectedIds.contains($0.id) }
            }
        
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
    
    // MARK: - Mock Data
    private func setupMockData() {
        let mockCategories = BeachRegion.allCases.map { CategoryDTO(region: $0) }
        
        let mockLocations = [
            LocationDTO(id: "1001", region: .yangyang, place: "죽도서핑비치"),
            LocationDTO(id: "1002", region: .yangyang, place: "죽도해변 C"),
            LocationDTO(id: "1003", region: .yangyang, place: "인구해변"),
            LocationDTO(id: "2001", region: .jeju, place: "중문"),
            LocationDTO(id: "3001", region: .busan, place: "해운대"),
            LocationDTO(id: "4001", region: .gangreung, place: "정동진"),
        ]
        
        categories.accept(mockCategories)
        locations.accept(mockLocations)
    }
}
