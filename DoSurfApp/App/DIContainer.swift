import Foundation

final class DIContainer {
    static let shared = DIContainer()

    private let environment: AppEnvironment
    private let chartCacheManager: ChartCacheManager

    private lazy var liveBeachRepository: FirestoreProtocol = FirestoreRepository()

    private lazy var surfRecordRepositoryInstance: NoteRepositoryProtocol = {
        if environment.dataSourceMode.usesMockData {
            return MockSurfRecordRepository()
        }
        return SurfRecordRepository()
    }()

    private lazy var fetchBeachDataUseCaseInstance: FetchBeachDataUseCase = {
        let scenarioMockUseCase = MockFetchBeachDataUseCase(scenario: environment.mockBeachScenario)
        let fallbackMockUseCase = MockFetchBeachDataUseCase(scenario: .normal)

        switch environment.dataSourceMode {
        case .live:
            return CachedFetchBeachDataUseCase(
                remote: DefaultFetchBeachDataUseCase(repository: liveBeachRepository),
                fallback: fallbackMockUseCase,
                cacheManager: chartCacheManager,
                useFallbackWhenRemoteFails: false
            )
        case .mock:
            return CachedFetchBeachDataUseCase(
                remote: scenarioMockUseCase,
                fallback: scenarioMockUseCase,
                cacheManager: chartCacheManager,
                useFallbackWhenRemoteFails: true
            )
        case .mockWithDelay(let seconds):
            let delayed = DelayedFetchBeachDataUseCase(base: scenarioMockUseCase, delaySeconds: seconds)
            return CachedFetchBeachDataUseCase(
                remote: delayed,
                fallback: scenarioMockUseCase,
                cacheManager: chartCacheManager,
                useFallbackWhenRemoteFails: true
            )
        }
    }()

    private lazy var fetchBeachListUseCaseInstance: FetchBeachListUseCase = {
        if environment.dataSourceMode.usesMockData {
            return MockFetchBeachListUseCase()
        }

        return DefaultFetchBeachListUseCase(repository: liveBeachRepository)
    }()

    private init(
        environment: AppEnvironment = .current,
        chartCacheManager: ChartCacheManager = ChartCacheManager()
    ) {
        self.environment = environment
        self.chartCacheManager = chartCacheManager

        print("[AppEnvironment] dataSource=\(environment.dataSourceMode.description)")
        if environment.dataSourceMode.usesMockData {
            print("[AppEnvironment] mockBeachScenario=\(environment.mockBeachScenario.description)")
        }
    }

    // MARK: - Repository Factories
    func makeBeachRepository() -> FirestoreProtocol {
        liveBeachRepository
    }

    func makeSurfRecordRepository() -> NoteRepositoryProtocol {
        surfRecordRepositoryInstance
    }

    // MARK: - UseCase Factories
    func makeFetchBeachDataUseCase() -> FetchBeachDataUseCase {
        fetchBeachDataUseCaseInstance
    }

    func makeFetchBeachListUseCase() -> FetchBeachListUseCase {
        fetchBeachListUseCaseInstance
    }

    func makeSurfRecordUseCase() -> SurfRecordUseCaseProtocol {
        SurfRecordUseCase(repository: makeSurfRecordRepository())
    }

    // MARK: - Service Factories
    func makeStorageService() -> SurfingRecordService {
        UserDefaultsManager()
    }

    // MARK: - ViewModel Factories
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase(),
            surfRecordUseCase: makeSurfRecordUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase()
        )
    }

    func makeSurfRecordViewModel(mode: SurfRecordMode) -> NoteViewModel {
        NoteViewModel(
            mode: mode,
            surfRecordUseCase: makeSurfRecordUseCase(),
            fetchBeachDataUseCase: makeFetchBeachDataUseCase()
        )
    }

    func makeBeachSelectViewModel() -> BeachSelectViewModel {
        BeachSelectViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase(),
            storageService: makeStorageService()
        )
    }

    func makeBeachSelectViewModel(initialSelectedBeach: BeachDTO?) -> BeachSelectViewModel {
        BeachSelectViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase(),
            storageService: makeStorageService(),
            initialSelectedBeach: initialSelectedBeach
        )
    }

    func makeRecordHistoryViewModel() -> RecordHistoryViewModel {
        RecordHistoryViewModel(
            surfRecordUseCase: makeSurfRecordUseCase(),
            fetchBeachListUseCase: makeFetchBeachListUseCase(),
            storageService: makeStorageService()
        )
    }

    func makeButtonTabBarViewModel() -> ButtonTabBarViewModel {
        ButtonTabBarViewModel(storageService: makeStorageService())
    }

    // MARK: - ViewController Factories

    /// 새 기록 생성용 ViewController
    func makeSurfRecordViewController(
        startTime: Date?,
        endTime: Date?,
        charts: [Chart]?,
        beach: BeachDTO?
    ) -> NoteViewController {
        let mode = SurfRecordMode.new(
            startTime: startTime,
            endTime: endTime,
            charts: charts,
            beach: beach
        )
        let viewModel = makeSurfRecordViewModel(mode: mode)
        return NoteViewController(
            viewModel: viewModel,
            mode: mode
        )
    }

    /// 기존 기록 편집용 ViewController
    func makeSurfRecordViewController(editing record: SurfRecordData) -> NoteViewController {
        let mode = SurfRecordMode.edit(record: record)
        let viewModel = makeSurfRecordViewModel(mode: mode)
        return NoteViewController(
            viewModel: viewModel,
            mode: mode
        )
    }

    func makeTabBarViewController() -> ButtonTabBarController {
        let viewModel = makeButtonTabBarViewModel()
        return ButtonTabBarController(viewModel: viewModel)
    }
}
