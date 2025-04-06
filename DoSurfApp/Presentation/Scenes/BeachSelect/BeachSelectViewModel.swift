//
//  BeachChooseViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

// MARK: - ViewModel
final class BeachSelectViewModel {
    
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
    }
    
    // MARK: - Properties
    private let categories = BehaviorRelay<[CategoryDTO]>(value: [])
    private let locations = BehaviorRelay<[LocationDTO]>(value: [])
    private let selectedCategoryIndex = BehaviorRelay<Int>(value: 0)
    private let selectedLocations = BehaviorRelay<Set<String>>(value: [])
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialize
    init() {
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
        
        // 지역 선택 처리
        input.locationSelected
            .withLatestFrom(filteredLocations) { indexPath, locations -> LocationDTO? in
                guard indexPath.row < locations.count else { return nil }
                return locations[indexPath.row]
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] location in
                // 단일 선택: 선택한 항목만 유지
                self?.selectedLocations.accept([location.id])
            })
            .disposed(by: disposeBag)
        
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
            dismiss: dismiss
        )
    }
    
    // MARK: - Mock Data
    private func setupMockData() {
        let mockCategories = [
            CategoryDTO(id: "yangyang", name: "양양"),
            CategoryDTO(id: "jeju", name: "제주"),
            CategoryDTO(id: "busan", name: "부산"),
            CategoryDTO(id: "goseong", name: "고성/속초"),
            CategoryDTO(id: "incheon", name: "인천/충청/강원"),
            CategoryDTO(id: "pohang", name: "포항/울산"),
            CategoryDTO(id: "jinhae", name: "지해/남해")
        ]
        
        let mockLocations = [
            LocationDTO(id: "1", categoryId: "yangyang", region: "양양", place: "죽도서핑비치"),
            LocationDTO(id: "2", categoryId: "yangyang", region: "양양", place: "죽도해변 C"),
            LocationDTO(id: "3", categoryId: "yangyang", region: "양양", place: "인구해변"),
            LocationDTO(id: "4", categoryId: "yangyang", region: "양양", place: "기사문해변A"),
            LocationDTO(id: "5", categoryId: "yangyang", region: "양양", place: "기사문해변B"),
            LocationDTO(id: "6", categoryId: "yangyang", region: "양양", place: "기사문해변"),
            LocationDTO(id: "7", categoryId: "yangyang", region: "양양", place: "남애해변파워A"),
            LocationDTO(id: "8", categoryId: "yangyang", region: "양양", place: "플라자해변"),
            LocationDTO(id: "9", categoryId: "yangyang", region: "양양", place: "싱잉타워해변"),
            LocationDTO(id: "10", categoryId: "yangyang", region: "양양", place: "동산해변"),
            LocationDTO(id: "11", categoryId: "yangyang", region: "양양", place: "하조대해변"),
        ]
        
        categories.accept(mockCategories)
        locations.accept(mockLocations)
    }
}
