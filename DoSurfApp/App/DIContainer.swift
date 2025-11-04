//
//  DIContainer.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import Foundation

final class DIContainer {
    static let shared = DIContainer()
    private init() {}
    
    // MARK: - Repository Factories
    func makeBeachRepository() -> FirestoreProtocol {
        return FirestoreRepository()
    }
    
    func makeSurfRecordRepository() -> NoteRepositoryProtocol {
        return SurfRecordRepository()
    }
    
    // MARK: - UseCase Factories
    func makeFetchBeachDataUseCase() -> FetchBeachDataUseCase {
        return DefaultFetchBeachDataUseCase(
            repository: makeBeachRepository()
        )
    }
    
    func makeFetchBeachListUseCase() -> FetchBeachListUseCase {
        return DefaultFetchBeachListUseCase(
            repository: makeBeachRepository()
        )
    }
    
    func makeSurfRecordUseCase() -> SurfRecordUseCaseProtocol {
        return SurfRecordUseCase(repository: makeSurfRecordRepository())
    }
    
    // MARK: - Service Factories
    func makeStorageService() -> SurfingRecordService {
        return UserDefaultsManager()
    }
    
  
    
    
    // MARK: - ViewModel Factories
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(fetchBeachDataUseCase: makeFetchBeachDataUseCase())
    }
    
    func makeSurfRecordViewModel(mode: SurfRecordMode) -> NoteViewModel {
        return NoteViewModel(
            mode: mode,
            surfRecordUseCase: makeSurfRecordUseCase()
        )
    }
    
    func makeBeachSelectViewModel() -> BeachSelectViewModel {
        return BeachSelectViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase(),
            storageService: makeStorageService()
        )
    }
    
    func makeBeachSelectViewModel(initialSelectedBeach: BeachDTO?) -> BeachSelectViewModel {
        return BeachSelectViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase(),
            storageService: makeStorageService(),
            initialSelectedBeach: initialSelectedBeach
        )
    }
    
    func makeRecordHistoryViewModel() -> RecordHistoryViewModel {
        return RecordHistoryViewModel(
            surfRecordUseCase: makeSurfRecordUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase(),
            storageService: makeStorageService()
        )
    }
    
    func makeButtonTabBarViewModel() -> ButtonTabBarViewModel {
        return ButtonTabBarViewModel(storageService: makeStorageService())
    }
    
    // MARK: - ViewController Factories
    
    /// 새 기록 생성용 ViewController
    func makeSurfRecordViewController(
        startTime: Date?,
        endTime: Date?,
        charts: [Chart]?
    ) -> NoteViewController {
        let mode = SurfRecordMode.new(
            startTime: startTime,
            endTime: endTime,
            charts: charts
        )
        let viewModel = makeSurfRecordViewModel(mode: mode)
        return NoteViewController(
            viewModel: viewModel,
            mode: mode
        )
    }
//
//    /// 기존 기록 편집용 ViewController
//    func makeSurfRecordViewController(editing record: SurfRecordData) -> NoteViewController {
//        let mode = SurfRecordMode.edit(record: record)
//        let viewModel = makeSurfRecordViewModel(mode: mode)
//        return NoteViewController(
//            viewModel: viewModel,
//            mode: mode
//        )
//    }
    
//    /// 일반 생성용 ViewController (mode로 생성)
//    func makeSurfRecordViewController(mode: SurfRecordMode) -> NoteViewController {
//        let viewModel = makeSurfRecordViewModel(mode: mode)
//        return NoteViewController(
//            viewModel: viewModel,
//            mode: mode
//        )
//    }
//    
//    /// RecordHistory ViewController 생성
//    func makeRecordHistoryViewController() -> RecordHistoryViewController {
//        let viewModel = makeRecordHistoryViewModel()
//        return RecordHistoryViewController(
//            viewModel: viewModel
//        )
//    }
    
    func makeTabBarViewController() -> ButtonTabBarController{
        let viewModel = makeButtonTabBarViewModel()
        return ButtonTabBarController(viewModel: viewModel)
    }
}
