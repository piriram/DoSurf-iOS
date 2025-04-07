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
        let beachData: Observable<BeachDataDump>  // 추가
        let error: Observable<Error>               // 추가
        let isLoading: Observable<Bool>            // 추가
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
        
        // 카테고리 선택 처리
        input.categorySelected
            .map { $0.row }
            .bind(to: selectedCategoryIndex)
            .disposed(by: disposeBag)
        
        // 선택된 카테고리에 따른 지역 목록 필터링
        let filteredLocations = selectedCategoryIndex
            .withLatestFrom(categories) { index, categories in
                guard index < categories.count else { return "" }
                return categories[index].id
            }
            .map { [weak self] categoryId -> [LocationDTO] in
                guard let self = self else { return [] }
                return self.locations.value.filter { $0.categoryId == categoryId }
            }
            .asObservable()
        
        // 지역 선택 처리 및 데이터 로딩
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
            .flatMapLatest { [weak self] location -> Observable<BeachDataDump> in
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
        
        // 확인 버튼 활성화 여부
        let canConfirm = selectedLocations
            .map { !$0.isEmpty }
            .asObservable()
        
        // 확인 버튼 탭 처리
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
        let mockCategories = [
            CategoryDTO(id: "yangyang", name: "양양"),
            CategoryDTO(id: "jeju", name: "제주"),
            CategoryDTO(id: "busan", name: "부산"),
            CategoryDTO(id: "goseong", name: "고성/속초"),
            CategoryDTO(id: "incheon", name: "강릉/동해/삼척"),
            CategoryDTO(id: "pohang", name: "포항/울산"),
            CategoryDTO(id: "jinhae", name: "서해/남해")
        ]
        
        let mockLocations = [
            LocationDTO(id: "1001", categoryId: "yangyang", region: "양양", place: "죽도서핑비치"),
            LocationDTO(id: "1002", categoryId: "yangyang", region: "양양", place: "죽도해변 C"),
            LocationDTO(id: "2001", categoryId: "jeju", region: "제주", place: "중문"),
            LocationDTO(id: "3001", categoryId: "busan", region: "부산", place: "해운대"),
        ]
        
        categories.accept(mockCategories)
        locations.accept(mockLocations)
    }
}
