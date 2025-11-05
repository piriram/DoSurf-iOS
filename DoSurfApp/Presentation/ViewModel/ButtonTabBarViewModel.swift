//
//  ButtonTabBarViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 11/4/25.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - ButtonTabBar ViewModel
final class ButtonTabBarViewModel {
    
    // MARK: - Properties
    private let storageService: SurfingRecordService
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    struct Input {
        let centerButtonTapped: Observable<Void>
        let chartButtonTapped: Observable<Void>
        let recordButtonTapped: Observable<Void>
    }
    
    // MARK: - Outputs
    struct Output {
        let currentTab: Driver<TabType>
        let isSurfing: Driver<Bool>
        let centerButtonAction: Driver<CenterButtonAction>
        let shouldShowStartOverlay: Driver<Void>
        let shouldShowEndOverlay: Driver<Void>
    }
    
    // MARK: - State
    private let currentTab = BehaviorRelay<TabType>(value: .chart)
    private let isSurfing = BehaviorRelay<Bool>(value: false)
    private let centerButtonAction = PublishRelay<CenterButtonAction>()
    
    // MARK: - Initialization
    init(storageService: SurfingRecordService) {
        self.storageService = storageService
        loadSurfingState()
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        // Chart 버튼 탭
        input.chartButtonTapped
            .map { TabType.chart }
            .bind(to: currentTab)
            .disposed(by: disposeBag)
        
        // Record 버튼 탭
        input.recordButtonTapped
            .map { TabType.record }
            .bind(to: currentTab)
        
        // Center 버튼 탭
        let centerButtonActionDriver = input.centerButtonTapped
            .withLatestFrom(isSurfing.asObservable())
            .map { isSurfing -> CenterButtonAction in
                return isSurfing ? .showEndOverlay : .showStartOverlay
            }
            .do(onNext: { [weak self] action in
                self?.centerButtonAction.accept(action)
            })
            .asDriver(onErrorDriveWith: .empty())
        
        let shouldShowStartOverlay = centerButtonActionDriver
            .filter { $0 == .showStartOverlay }
            .map { _ in () }
        
        let shouldShowEndOverlay = centerButtonActionDriver
            .filter { $0 == .showEndOverlay }
            .map { _ in () }
        
        return Output(
            currentTab: currentTab.asDriver(),
            isSurfing: isSurfing.asDriver(),
            centerButtonAction: centerButtonAction.asDriver(onErrorDriveWith: .empty()),
            shouldShowStartOverlay: shouldShowStartOverlay,
            shouldShowEndOverlay: shouldShowEndOverlay
        )
    }
    
    // MARK: - Public Methods
    
    /// 서핑 시작
    func startSurfing() {
        storageService.createSurfingStartTime(Date())
        storageService.createSurfingState(true)
        isSurfing.accept(true)
    }
    
    /// 서핑 종료
    func endSurfing() {
        storageService.createSurfingEndTime(Date())
        storageService.createSurfingState(false)
        isSurfing.accept(false)
    }
    
    /// 서핑 취소
    func cancelSurfing() {
        storageService.createSurfingState(false)
        storageService.createSurfingStartTime(nil)
        storageService.createSurfingEndTime(nil)
        isSurfing.accept(false)
    }
    
    /// 기록 화면에 전달할 데이터 가져오기
    func getRecordData() -> (startTime: Date?, endTime: Date?) {
        let startTime = storageService.readSurfingStartTime()
        let endTime = storageService.readSurfingEndTime()
        return (startTime, endTime)
    }
    
    /// 탭 전환
    func switchTab(to tab: TabType) {
        guard currentTab.value != tab else { return }
        currentTab.accept(tab)
    }
    
    // MARK: - Private Methods
    
    private func loadSurfingState() {
        let isRecording = storageService.readSurfingState()
        isSurfing.accept(isRecording)
    }
}
