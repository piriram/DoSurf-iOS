//
//  DashboardViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
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
    private let storageService: SurfingStorageService = UserDefaultsSurfingStorageService()
    
    private var currentBeachData: BeachData?
    private let viewDidLoadSubject = PublishSubject<Void>()
    private let beachSelectedSubject = PublishSubject<String>()
    
    // 현재 선택된 해변의 모든 차트 스냅샷 (외부 전달용)
    private var currentCharts: [Chart] = []
    
    // MARK: - UI Components
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "backgroundMain")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var beachSelectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("해변 선택", for: .normal)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        return button
    }()
    
    private lazy var locationHeaderView: UIView = {
        let view = UIView()
        view.addSubview(beachSelectButton)
        beachSelectButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
    private lazy var statisticsHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.tag = 1001 // for lookup
        titleLabel.text = "선호하는 차트 통계"
        titleLabel.font = .systemFont(ofSize: 21, weight: .bold)
        titleLabel.textColor = .white
        
        let infoButton = UIButton(type: .system)
        infoButton.tag = 1002 // for lookup
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = .white
        
        let seeAllButton = UIButton(type: .system)
        seeAllButton.tag = 1003 // for lookup
        seeAllButton.setTitle("모두 보기", for: .normal)
        seeAllButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        seeAllButton.tintColor = .white
        seeAllButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        seeAllButton.semanticContentAttribute = .forceRightToLeft
        seeAllButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        seeAllButton.isHidden = true // default hidden on page 0
        
        view.addSubview(titleLabel)
        view.addSubview(infoButton)
        view.addSubview(seeAllButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        seeAllButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        return view
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .white.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.hidesForSinglePage = true
        return pageControl
    }()
    
    // cardCollectionView 대신 사용
    private lazy var dashboardPageView: DashboardPageView = {
        let pageView = DashboardPageView()
        return pageView
    }()
    
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
        
        // 초기 페이지 상태 확실히 설정
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pageControl.currentPage = 0
            self.updateStatisticsHeader(for: 0)
        }
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
        view.addSubview(locationHeaderView)
        view.addSubview(statisticsHeaderView)
        view.addSubview(dashboardPageView)
        view.addSubview(pageControl)
        view.addSubview(chartContainerView)
        chartContainerView.addSubview(chartListView)
        chartListView.attachRefreshControl(refreshControl)
    }
    override func configureLayout() {
        backgroundImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        locationHeaderView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        statisticsHeaderView.snp.makeConstraints {
            $0.top.equalTo(locationHeaderView.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(28)
        }
        dashboardPageView.snp.makeConstraints {
            $0.top.equalTo(statisticsHeaderView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(200)
        }
        pageControl.snp.makeConstraints {
            $0.top.equalTo(dashboardPageView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
        }
        chartContainerView.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        chartListView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    override func configureAction() {
        beachSelectButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
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
        
        // 페이지 구성 - 명확한 순서 보장
        let surfRecordUseCase = DIContainer.shared.makeSurfRecordUseCase()
        let page1 = PreferredChartPage() // 첫 번째: 선호하는 차트 통계
        let page2 = ChartListPage(title: "최근 기록 차트", showsHeader: false, surfRecordUseCase: surfRecordUseCase) // 두 번째: 최근 기록 차트
        let page3 = ChartListPage(title: "고정 차트", showsHeader: false, surfRecordUseCase: surfRecordUseCase) // 세 번째: 고정 차트
        dashboardPageView.configure(pages: [page1, page2, page3])

        // 페이지 컨트롤 초기 설정
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        updateStatisticsHeader(for: 0)

        // 페이지 변경 감지 및 동기화
        dashboardPageView.currentPage
            .distinctUntilChanged() // 중복 이벤트 방지
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] page in
                guard let self = self else { return }
                // 페이지 컨트롤과 헤더를 동시에 업데이트
                self.pageControl.currentPage = page
                self.updateStatisticsHeader(for: page)
            })
            .disposed(by: disposeBag)

        // 페이지 컨트롤 터치 이벤트 처리
        pageControl.rx.controlEvent(.valueChanged)
            .throttle(.milliseconds(100), scheduler: MainScheduler.instance) // 빠른 탭 방지
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let targetPage = self.pageControl.currentPage
                self.dashboardPageView.scrollToPage(targetPage)
                self.updateStatisticsHeader(for: targetPage)
            })
            .disposed(by: disposeBag)
        
        // 해변 이름 및 고정 차트 업데이트
        output.beachData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] beachData in
                guard let self = self else { return }
                
                self.currentBeachData = beachData
                let beachID = beachData.metadata.beachID
                if let surfBeach = SurfBeach(rawValue: beachID) {
                    let title = "\(surfBeach.region.displayName) \(surfBeach.displayName)해변"
                    self.beachSelectButton.setTitle(title, for: .normal)
                } else {
                    self.beachSelectButton.setTitle("\(beachData.metadata.name)해변", for: .normal)
                }
                
                // 최근 기록 차트 페이지에 새 데이터 요청
                if let page2 = self.dashboardPageView.getPage(at: 1) as? ChartListPage {
                    let beachIDInt = Int(beachID) ?? 4001
                    page2.configureWithRecentRecords(beachID: beachIDInt)
                    print("📊 Updated recent charts for beachID: \(beachIDInt)")
                }
                
                // 고정 차트 페이지에 새 데이터 요청
                if let page3 = self.dashboardPageView.getPage(at: 2) as? ChartListPage {
                    let beachIDInt = Int(beachID) ?? 4001
                    page3.configureWithPinnedRecords(beachID: beachIDInt)
                    print("📌 Updated pinned charts for beachID: \(beachIDInt)")
                }
            })
            .disposed(by: disposeBag)
        
        // 데이터 바인딩
        output.dashboardCards
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { cards in
                page1.configure(with: cards)
            })
            .disposed(by: disposeBag)
        
        // 차트 그룹 + 스냅샷
        output.groupedCharts
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] grouped in
                guard let self = self else { return }
                self.chartListView.update(groupedCharts: grouped)
                let flattened = grouped.flatMap { $0.charts }.sorted { $0.time < $1.time }
                self.currentCharts = flattened
            })
            .disposed(by: disposeBag)
        
        // 로딩/에러
        output.isLoading
            .observe(on: MainScheduler.instance)
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        output.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.showErrorAlert(error: $0) })
            .disposed(by: disposeBag)
        
        if let savedID = storageService.loadSelectedBeachID() {
            beachSelectedSubject.onNext(savedID)
        }
        
        viewDidLoadSubject.onNext(())
    }
    
    private func pushBeachChoose() {
        let viewModel = BeachSelectViewModel(fetchBeachDataUseCase: DIContainer.shared.makeFetchBeachDataUseCase())
        let vc = BeachSelectViewController(viewModel: viewModel)
        vc.hidesBottomBarWhenPushed = true
        vc.onBeachSelected = { [weak self] locationDTO in
            self?.beachSelectedSubject.onNext(locationDTO.id)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "데이터 로드 실패", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func updateStatisticsHeader(for page: Int) {
        guard let titleLabel = statisticsHeaderView.viewWithTag(1001) as? UILabel,
              let infoButton = statisticsHeaderView.viewWithTag(1002) as? UIButton,
              let seeAllButton = statisticsHeaderView.viewWithTag(1003) as? UIButton else { return }
        
        // 페이지별 헤더 설정 (0: 선호하는 차트 통계, 1: 최근 기록 차트, 2: 고정 차트)
        switch page {
        case 0: // 첫 번째 페이지: 선호하는 차트 통계
            titleLabel.text = "선호하는 차트 통계"
            infoButton.isHidden = false
            seeAllButton.isHidden = true
            
        case 1: // 두 번째 페이지: 최근 기록 차트
            titleLabel.text = "최근 기록 차트"
            infoButton.isHidden = true
            seeAllButton.isHidden = false
            
        case 2: // 세 번째 페이지: 고정 차트
            titleLabel.text = "고정 차트"
            infoButton.isHidden = true
            seeAllButton.isHidden = false
            
        default:
            // 예상 범위를 벗어난 경우 첫 번째 페이지로 처리
            titleLabel.text = "선호하는 차트 통계"
            infoButton.isHidden = false
            seeAllButton.isHidden = true
        }
        
        // UI 업데이트를 애니메이션과 함께 처리
        UIView.transition(with: statisticsHeaderView, duration: 0.2, options: [.transitionCrossDissolve], animations: {
            // 변경사항이 즉시 반영되도록 레이아웃 업데이트
            self.statisticsHeaderView.layoutIfNeeded()
        }, completion: nil)
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
        DashboardViewModel(
            fetchBeachDataUseCase: makeFetchBeachDataUseCase(),
            surfRecordUseCase: makeSurfRecordUseCase()
        )
    }
    
    func makeSurfRecordUseCase() -> SurfRecordUseCaseProtocol {
        SurfRecordUseCase(repository: makeSurfRecordRepository())
    }
    
    func makeSurfRecordRepository() -> SurfRecordRepositoryProtocol {
        SurfRecordRepository()
    }
}

