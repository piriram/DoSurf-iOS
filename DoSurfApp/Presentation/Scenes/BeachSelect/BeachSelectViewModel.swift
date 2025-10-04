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
    private let selectedLocation = BehaviorRelay<String?>(value: nil)
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
        
        // 카테고리 변경 시 선택된 해변 초기화
        selectedCategoryIndex
            .subscribe(onNext: { [weak self] _ in
                self?.selectedLocation.accept(nil)
            })
            .disposed(by: disposeBag)
        
        let filteredLocations: Observable<[LocationDTO]> = selectedCategoryIndex
            .withLatestFrom(categories) { (index, categories) -> BeachRegion in
                guard index < categories.count else { return .gangreung }
                return categories[index].region
            }
            .map { [weak self] (selectedRegion: BeachRegion) -> [LocationDTO] in
                guard let self = self else { return [] }
                return self.locations.value.filter { $0.region == selectedRegion }
            }
            .asObservable()
        
        // 해변 선택 처리
        input.locationSelected
            .withLatestFrom(filteredLocations) { indexPath, locations -> LocationDTO? in
                guard indexPath.row < locations.count else { return nil }
                return locations[indexPath.row]
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] location in
                self?.selectedLocation.accept(location.id)
            })
            .disposed(by: disposeBag)
        
        let beachData = selectedLocation
            .compactMap { $0 }
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in
                self?.isLoadingRelay.accept(true)
            })
            .flatMapLatest { [weak self] locationId -> Observable<BeachData> in
                guard let self = self else { return .empty() }
                
                return self.fetchBeachDataUseCase.execute(beachId: locationId)
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
        
        let canConfirm = selectedLocation
            .map { $0 != nil }
            .asObservable()
        
        let dismiss = input.confirmButtonTapped
            .withLatestFrom(Observable.combineLatest(
                locations.asObservable(),
                selectedLocation.asObservable()
            ))
            .map { (locations: [LocationDTO], selectedId: String?) -> [LocationDTO] in
                guard let selectedId = selectedId else { return [] }
                return locations.filter { $0.id == selectedId }
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
            LocationDTO(id: "1001", region: .gangreung, place: "죽도 해변"),
            LocationDTO(id: "2001", region: .pohang, place: "월포 해변"),
            LocationDTO(id: "3001", region: .jeju, place: "중문 해변"),
            LocationDTO(id: "4001", region: .busan, place: "송정 해변"),
        ]
        
        categories.accept(mockCategories)
        locations.accept(mockLocations)
    }
}
