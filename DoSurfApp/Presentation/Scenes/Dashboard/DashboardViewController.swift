import UIKit
import SnapKit
import RxSwift
import RxCocoa

class DashboardViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: DashboardViewModel
    private let fetchBeachListUseCase: FetchBeachListUseCase
    private let disposeBag = DisposeBag()
    private let storageService: SurfingRecordService = UserDefaultsManager()

    private var currentBeachData: BeachData?
    private var currentBeach: BeachDTO?
    private var allBeaches: [BeachDTO] = []

    private let viewDidLoadSubject = PublishSubject<Void>()
    private let beachSelectedSubject = PublishSubject<BeachDTO>()
    private let cardsLazyTrigger = PublishSubject<Void>()

    // MARK: - UI
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: AssetImage.backgroundMain)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let bottomBackgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        return v
    }()

    private let headerView = DashboardHeaderView()
    private lazy var chartContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    private let chartListView = BeachChartListView()
    private let refreshControl = UIRefreshControl()

    // MARK: - Init
    init(
        viewModel: DashboardViewModel = DIContainer.shared.makeDashboardViewModel(),
        fetchBeachListUseCase: FetchBeachListUseCase = DIContainer.shared.makeFetchBeachListUseCase()
    ) {
        self.viewModel = viewModel
        self.fetchBeachListUseCase = fetchBeachListUseCase
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBeachListAndRestoreSelection()
    }

    override func configureNavigationBar() {
        super.configureNavigationBar()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func configureUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundImageView)
        view.addSubview(headerView)
        view.addSubview(chartContainerView)
        view.addSubview(bottomBackgroundView)
        chartContainerView.addSubview(chartListView)
        chartListView.attachRefreshControl(refreshControl)
    }

    override func configureLayout() {
        backgroundImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
        }
        chartContainerView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(55)
        }
        chartListView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        bottomBackgroundView.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.top.equalTo(chartContainerView.snp.bottom)
            }
    }

    override func configureAction() {
        headerView.beachSelectTapped
            .bind(onNext: { [weak self] in self?.pushBeachChoose() })
            .disposed(by: disposeBag)
    }

    override func configureBind() {
        let input = DashboardViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            beachSelected: beachSelectedSubject.asObservable()
                .do(onNext: { [weak self] beach in self?.currentBeach = beach }),
            refreshTriggered: refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            cardsLazyTrigger: cardsLazyTrigger.asObservable()
        )
        let output = viewModel.transform(input: input)

        let page1 = PreferredPage()
        let page2 = ChartListPage(title: "최근 기록 차트", showsTableHeader: true, isPinnedChart: false)
        let page3 = ChartListPage(title: "고정 차트", showsTableHeader: true, isPinnedChart: true)
        headerView.configurePages([page1, page2, page3])

        output.beachData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] beachData in
                guard let self = self else { return }
                self.currentBeachData = beachData
                if let currentBeach = self.currentBeach {
                    self.headerView.updateBeachTitle(currentBeach.displayName)
                }
                if let page3 = self.headerView.getPage(at: 2) as? ChartListPage {
                    let beachIDInt = beachData.metadata.beachID
                    page3.configureWithPinnedRecords(beachID: beachIDInt)
                }
            })
            .disposed(by: disposeBag)

        // Trigger average cards lazy load once after first beachData arrives
        output.beachData
            .take(1)
            .subscribe(onNext: { [weak self] _ in self?.cardsLazyTrigger.onNext(()) })
            .disposed(by: disposeBag)

        output.dashboardCards
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] cards in
                (self?.headerView.getPage(at: 0) as? PreferredPage)?
                    .configure(with: cards)
            })
            .disposed(by: disposeBag)

        output.groupedCharts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] grouped in
                self?.chartListView.update(groupedCharts: grouped)
            })
            .disposed(by: disposeBag)

        output.recentRecordCharts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] charts in
                (self?.headerView.getPage(at: 1) as? ChartListPage)?
                    .configure(with: charts)
            })
            .disposed(by: disposeBag)

        output.isLoading
            .observe(on: MainScheduler.instance)
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)

        output.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.showErrorAlert(error: $0) })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(.surfRecordsDidChange)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.refreshControl.beginRefreshing()
                self?.refreshControl.sendActions(for: .valueChanged)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private
    private func loadBeachListAndRestoreSelection() {
        fetchBeachListUseCase.executeAll()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] beaches in
                guard let self = self else { return }
                self.allBeaches = beaches
                if let savedID = self.storageService.readSelectedBeachID(),
                   let beach = beaches.first(where: { $0.id == savedID }) {
                    self.selectBeach(beach)
                } else if let firstBeach = beaches.first {
                    self.selectBeach(firstBeach)
                }
                self.viewDidLoadSubject.onNext(())
            }, onFailure: { [weak self] error in
                print("Failed to load beach list: \(error)")
                self?.viewDidLoadSubject.onNext(())
            })
            .disposed(by: disposeBag)
    }

    private func selectBeach(_ beach: BeachDTO) {
        beachSelectedSubject.onNext(beach)
        storageService.createSelectedBeachID(beach.id)
        NotificationCenter.default.post(
            name: .selectedBeachIDDidChange, object: nil, userInfo: ["beachID": beach.id]
        )
    }

    private func pushBeachChoose() {
        let viewModel = DIContainer.shared.makeBeachSelectViewModel(
            initialSelectedBeach: currentBeach
        )
        let vc = BeachSelectViewController(viewModel: viewModel)
        vc.hidesBottomBarWhenPushed = true
        vc.onBeachSelected = { [weak self] beach in self?.selectBeach(beach) }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(
            title: "데이터 로드 실패",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
// DashboardViewController.swift

extension DashboardViewController {
    /// 현재 선택된 해변의 모든 차트 스냅샷
    func chartsSnapshot() -> [Chart] {
        return viewModel.charts(from: nil, to: nil)
    }

    /// 기간 필터링 차트가 필요하면 이 메서드를 사용하세요.
    func charts(from start: Date?, to end: Date?) -> [Chart] {
        return viewModel.charts(from: start, to: end)
    }
}

