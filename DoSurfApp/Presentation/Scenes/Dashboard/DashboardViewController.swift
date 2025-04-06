//
//  DashboardViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//
import UIKit
import RxSwift
import RxCocoa
import SnapKit

class DashboardViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let beachDataService: BeachDataServiceProtocol
    private var charts: [Chart] = []
    private var beachInfo: BeachInfo?
    private var currentDateIndex = 0
    private var groupedCharts: [(date: Date, charts: [Chart])] = []
    private var dashboardData: [DashboardCardData] = []
    
    // MARK: - UI Components
    // Removed scrollView and contentView declarations
    
    // Dashboard Header
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "backgroundMain")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("안양 중도해변 B", for: .normal)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        return button
    }()
    
    private lazy var locationHeaderView: UIView = {
        let view = UIView()

        view.addSubview(locationButton)
        locationButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        return view
    }()
    
    private lazy var statisticsHeaderView: UIView = {
        let view = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = "선호하는 차트 통계"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        
        let infoButton = UIButton(type: .system)
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = .white.withAlphaComponent(0.8)
        
        view.addSubview(titleLabel)
        view.addSubview(infoButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        return view
    }()
    
    // Dashboard Cards
    private lazy var cardCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = false // 커스텀 페이징 사용
        collectionView.decelerationRate = .fast
        collectionView.register(DashboardCardCell.self, forCellWithReuseIdentifier: DashboardCardCell.identifier)
        return collectionView
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
    
    // Chart Table Container
    private lazy var chartContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let chartListView = ChartListView()
    private let refreshControl = UIRefreshControl()
    
    // MARK: - Initialization
    init(beachDataService: BeachDataServiceProtocol = BeachDataService()) {
        self.beachDataService = beachDataService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides from BaseViewController
    override func configureNavigationBar() {
        super.configureNavigationBar()
        // 네비게이션 바 숨기기 (커스텀 헤더 사용)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func configureUI() {
        view.backgroundColor = .systemBackground
        
        setupDashboardCards()
        
        // Removed scrollView and contentView hierarchy additions
        // Instead add views directly to view
        
        view.addSubview(backgroundImageView)
        view.addSubview(locationHeaderView)
        view.addSubview(statisticsHeaderView)
        view.addSubview(cardCollectionView)
        view.addSubview(pageControl)
        
        view.addSubview(chartContainerView)
        chartContainerView.addSubview(chartListView)
        chartListView.attachRefreshControl(refreshControl)
    }

    override func configureLayout() {
        // Removed scrollView constraints
        // Removed contentView constraints
        
        // Dashboard layout
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(380)
        }
        
        locationHeaderView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        statisticsHeaderView.snp.makeConstraints { make in
            make.top.equalTo(locationHeaderView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }
        
        cardCollectionView.snp.makeConstraints { make in
            make.top.equalTo(statisticsHeaderView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(cardCollectionView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
        
        // Chart container layout
        chartContainerView.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        chartListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func configureAction() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        // Push BeachChooseViewController when tapping the location button
        locationButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                self?.pushBeachChoose()
            })
            .disposed(by: disposeBag)
    }

    override func configureBind() {
        // Collection view 바인딩
        cardCollectionView.rx.setDelegate(self).disposed(by: disposeBag)
        
        Observable.just(dashboardData)
            .bind(to: cardCollectionView.rx.items(cellIdentifier: DashboardCardCell.identifier, cellType: DashboardCardCell.self)) { index, data, cell in
                cell.configure(with: data)
            }
            .disposed(by: disposeBag)
        
        loadInitialData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 레이아웃이 완료된 후 페이지 컨트롤 바인딩 설정
        setupPageControlBinding()
    }
    
    private func setupPageControlBinding() {
        // 이미 바인딩되어 있으면 중복 방지
        guard cardCollectionView.frame.width > 0 else { return }
        
        // Page control 스크롤 바인딩
        cardCollectionView.rx.contentOffset
            .throttle(.milliseconds(100), scheduler: MainScheduler.instance) // 성능 최적화
            .map { [weak self] offset -> Int in
                guard let self = self else { return 0 }
                let pageWidth = self.cardCollectionView.frame.width
                
                // pageWidth가 0이면 계산하지 않고 0 반환
                guard pageWidth > 0 else { return 0 }
                
                // offset.x가 유효한 값인지 확인
                guard offset.x.isFinite else { return 0 }
                
                let calculatedPage = (offset.x + pageWidth / 2) / pageWidth
                
                // 계산 결과가 유효한지 확인
                guard calculatedPage.isFinite else { return 0 }
                
                // 페이지 범위 제한
                let pageIndex = Int(calculatedPage)
                return max(0, min(pageIndex, self.pageControl.numberOfPages - 1))
            }
            .distinctUntilChanged()
            .bind(to: pageControl.rx.currentPage)
            .disposed(by: disposeBag)
    }
    
    private func pushBeachChoose() {
        let viewModel = BeachSelectViewModel()
        let vc = BeachSelectViewController(viewModel: viewModel)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Data Setup
    private func setupDashboardCards() {
        dashboardData = [
            DashboardCardData(type: .wind, title: "바람", value: "2.7m/s", icon: "wind", color: .systemBlue),
            DashboardCardData(type: .wave, title: "파도", value: "1.2m", subtitle: "6.2s", icon: "water.waves", color: .systemBlue),
            DashboardCardData(type: .temperature, title: "수온", value: "28°C", icon: "thermometer.medium", color: .systemOrange)
        ]
    }
    
    // MARK: - Data Loading
    private func loadInitialData() {
        loadBeachData(beachId: "4001")
    }
    
    private func loadBeachData(beachId: String) {
        beachDataService.fetchBeachData(beachId: beachId) { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                
                switch result {
                case .success(let dump):
                    self?.handleSuccessfulDataLoad(dump)
                case .failure(let error):
                    self?.handleDataLoadError(error)
                }
            }
        }
    }
    
    private func handleSuccessfulDataLoad(_ dump: BeachDataDump) {
        self.beachInfo = dump.beachInfo
        self.charts = dump.forecasts.compactMap { $0.toDomain() }
        
        // 날짜별로 그룹화
        self.groupedCharts = groupChartsByDate(charts)
        
        // 첫 번째 날짜로 초기화
        updateCurrentDate(index: 0)
        
        // 대시보드 데이터 업데이트
        updateDashboardData()
        
        self.chartListView.update(groupedCharts: self.groupedCharts)
        
        if let beachInfo = self.beachInfo {
            // Location button title update logic here
        }
    }
    
    private func updateDashboardData() {
        guard let latestChart = charts.first else { return }
        
        dashboardData = [
            DashboardCardData(
                type: .wind,
                title: "바람",
                value: String(format: "%.1fm/s", latestChart.windSpeed),
                icon: "wind",
                color: .systemBlue
            ),
            DashboardCardData(
                type: .wave,
                title: "파도",
                value: String(format: "%.1fm", latestChart.waveHeight),
                subtitle: String(format: "%.1fs", latestChart.wavePeriod),
                icon: "water.waves",
                color: .systemBlue
            ),
            DashboardCardData(
                type: .temperature,
                title: "수온",
                value: String(format: "%.0f°C", latestChart.waterTemperature),
                icon: "thermometer.medium",
                color: .systemOrange
            )
        ]
        
        // 페이지 수 업데이트
        let cardsPerPage = 2
        pageControl.numberOfPages = Int(ceil(Double(dashboardData.count) / Double(cardsPerPage)))
        
        cardCollectionView.reloadData()
    }
    
    private func groupChartsByDate(_ charts: [Chart]) -> [(date: Date, charts: [Chart])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: charts) { chart in
            calendar.startOfDay(for: chart.time)
        }
        
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, charts: $0.value.sorted { $0.time < $1.time }) }
    }
    
    private func updateCurrentDate(index: Int) {
        guard index < groupedCharts.count else { return }
        currentDateIndex = index
        chartListView.setCurrentDateIndex(index)
    }
    
    private func handleDataLoadError(_ error: FirebaseAPIError) {
        let alert = UIAlertController(title: "데이터 로드 실패",
                                    message: error.localizedDescription,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func refreshData() {
        if let beachInfo = beachInfo {
            loadBeachData(beachId: beachInfo.id)
        } else {
            loadInitialData()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension DashboardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedCharts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedCharts[section].charts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChartTableViewCell.identifier, for: indexPath) as? ChartTableViewCell else {
            return UITableViewCell()
        }
        
        let chart = groupedCharts[indexPath.section].charts[indexPath.row]
        cell.configure(with: chart)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .secondarySystemGroupedBackground

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 8

        let labels = ["시간", "바람", "파도", "수온", "날씨"]
        labels.forEach { text in
            let label = UILabel()
            label.text = text
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            stackView.addArrangedSubview(label)
        }

        headerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 44 : 20
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DashboardViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 16
        let insets: CGFloat = 40
        let width = (collectionView.frame.width - insets - spacing) / 2
        return CGSize(width: width, height: 120)
    }
    
    // 더 정확한 페이징을 위한 스크롤 종료 처리
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == cardCollectionView else { return }
        
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        let targetPage: Int
        
        if velocity.x > 0.5 {
            targetPage = currentPage + 1
        } else if velocity.x < -0.5 {
            targetPage = currentPage - 1
        } else {
            targetPage = currentPage
        }
        
        let clampedPage = max(0, min(targetPage, pageControl.numberOfPages - 1))
        targetContentOffset.pointee.x = CGFloat(clampedPage) * pageWidth
        
        // 페이지 컨트롤 즉시 업데이트
        pageControl.currentPage = clampedPage
    }
}

// MARK: - Dashboard Card Data Model
struct DashboardCardData {
    enum CardType {
        case wind
        case wave
        case temperature
    }
    
    let type: CardType
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: UIColor
    
    init(type: CardType, title: String, value: String, subtitle: String? = nil, icon: String, color: UIColor) {
        self.type = type
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
}

// MARK: - Dashboard Card Cell
class DashboardCardCell: UICollectionViewCell {
    static let identifier = "DashboardCardCell"
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(valueLabel)
        cardView.addSubview(subtitleLabel)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(16)
        }
    }
    
    func configure(with data: DashboardCardData) {
        iconView.image = UIImage(systemName: data.icon)
        titleLabel.text = data.title
        valueLabel.text = data.value
        subtitleLabel.text = data.subtitle
        subtitleLabel.isHidden = data.subtitle == nil
    }
}

