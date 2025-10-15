//
//  DashboardViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/3/25.
//
import UIKit
import SnapKit
import RxSwift
import RxCocoa

// 대시보드가 보유한 차트를 외부로 전달하기 위한 프로토콜
protocol DashboardChartProviding: AnyObject {
    var allChartsSnapshot: [Chart] { get }
    func charts(from start: Date?, to end: Date?) -> [Chart]
}

class DashboardViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel: DashboardViewModel
    private let disposeBag = DisposeBag()
    private let storageService: SurfingRecordService = UserDefaultsManager()
    
    private var currentBeachData: BeachData?
    private let viewDidLoadSubject = PublishSubject<Void>()
    private let beachSelectedSubject = PublishSubject<String>()
    
    // 현재 선택된 해변의 모든 차트 스냅샷 (외부 전달용)
    private var currentCharts: [Chart] = []
    
    // MARK: - UI Components
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: AssetImage.backgroundMain)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
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
    
    // MARK: - Initialization
    init(viewModel: DashboardViewModel = DIContainer.shared.makeDashboardViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
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
            $0.leading.trailing.bottom.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        chartListView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
            beachSelected: beachSelectedSubject.asObservable(),
            refreshTriggered: refreshControl.rx.controlEvent(.valueChanged).asObservable()
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
                let beachID = beachData.metadata.beachID
                
                if let surfBeach = SurfBeach(rawValue: beachID) {
                    let title = surfBeach.displayName
                    self.headerView.updateBeachTitle(title)
                } else {
                    self.headerView.updateBeachTitle("\(beachData.metadata.name)해변")
                }
                
                if let page3 = self.headerView.getPage(at: 2) as? ChartListPage {
                    let beachIDInt = Int(beachID)
                    page3.configureWithPinnedRecords(beachID: beachIDInt)
                }
            })
            .disposed(by: disposeBag)
        
        output.dashboardCards
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] cards in
                guard let self = self else { return }
                if let page1 = self.headerView.getPage(at: 0) as? PreferredPage {
                    page1.configure(with: cards)
                }
            })
            .disposed(by: disposeBag)
        
        output.groupedCharts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] grouped in
                guard let self = self else { return }
                self.chartListView.update(groupedCharts: grouped)
                let flattened = grouped.flatMap { $0.charts }.sorted { $0.time < $1.time }
                self.currentCharts = flattened
            })
            .disposed(by: disposeBag)
        
        // 최근 기록 차트(모든 비치) 바인딩
        output.recentRecordCharts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] charts in
                guard let self = self else { return }
                if let page2 = self.headerView.getPage(at: 1) as? ChartListPage {
                    page2.configure(with: charts)
                }
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
        
        // Observe global surf record changes (add/edit/pin/delete) and refresh dashboard lists
        NotificationCenter.default.rx.notification(.surfRecordsDidChange)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                // trigger refresh flow used by dashboard to reload data
                self.refreshControl.beginRefreshing()
                self.refreshControl.sendActions(for: .valueChanged)
            })
            .disposed(by: disposeBag)
        
        if let savedID = storageService.readSelectedBeachID() {
            beachSelectedSubject.onNext(savedID)
            NotificationCenter.default.post(name: .selectedBeachIDDidChange, object: nil, userInfo: ["beachID": savedID])
        }
        
        viewDidLoadSubject.onNext(())
    }
    
    private func pushBeachChoose() {
        let viewModel = BeachSelectViewModel(fetchBeachDataUseCase: DIContainer.shared.makeFetchBeachDataUseCase())
        let vc = BeachSelectViewController(viewModel: viewModel)
        vc.hidesBottomBarWhenPushed = true
        vc.onBeachSelected = { [weak self] locationDTO in
            self?.beachSelectedSubject.onNext(locationDTO.id)
            // Broadcast selection change so RecordHistory can pick it up when user switches tabs
            NotificationCenter.default.post(name: .selectedBeachIDDidChange, object: nil, userInfo: ["beachID": locationDTO.id])
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "데이터 로드 실패", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Chart Providing
extension DashboardViewController: DashboardChartProviding {
    var allChartsSnapshot: [Chart] { currentCharts }
    func charts(from start: Date?, to end: Date?) -> [Chart] {
        guard !currentCharts.isEmpty else { return [] }
        guard let s = start, let e = end else { return currentCharts }
        return currentCharts.filter { $0.time >= s && $0.time <= e }
    }
}

extension DIContainer {
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(fetchBeachDataUseCase: makeFetchBeachDataUseCase())
    }
}

