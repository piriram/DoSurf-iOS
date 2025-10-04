//
//  ChartListPage.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/2/25.
//
import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - Page 2 & 3: 차트 리스트 페이지
final class ChartListPage: UIView {
    
    private let showsTableHeader: Bool
    private let tableHeaderView: UIView
    private let tableContainerView = UIView()
    private let surfRecordUseCase: SurfRecordUseCaseProtocol
    private let disposeBag = DisposeBag()
    private var currentBeachID: Int = 4001
    private let isPinnedChart: Bool
    
    // MARK: - Initialization
    init(title: String, showsTableHeader: Bool = true, isPinnedChart: Bool = false, surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.showsTableHeader = showsTableHeader
        self.isPinnedChart = isPinnedChart
        self.tableHeaderView = isPinnedChart ? PinnedChartTableHeaderView() : ChartTableHeaderView()
        self.surfRecordUseCase = surfRecordUseCase
        super.init(frame: .zero)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        layer.cornerRadius = 20
        clipsToBounds = true
        
        if showsTableHeader {
            addSubview(tableHeaderView)
        }
        addSubview(tableContainerView)
    }
    
    private func configureLayout() {
        if showsTableHeader {
            tableHeaderView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(23)
            }
            tableContainerView.snp.makeConstraints { make in
                make.top.equalTo(tableHeaderView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            tableContainerView.snp.makeConstraints { make in
                make.top.leading.trailing.bottom.equalToSuperview()
            }
        }
    }
    
    // MARK: - Public Methods
    func configure(with charts: [Chart]) {
        // 기존 차트 뷰 제거
        tableContainerView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        
        // 차트가 없는 경우 처리
        guard !charts.isEmpty else {
            let emptyLabel = UILabel()
            emptyLabel.text = "차트 데이터가 없습니다"
            emptyLabel.textColor = .white.withAlphaComponent(0.7)
            emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
            emptyLabel.textAlignment = .center
            
            tableContainerView.addSubview(emptyLabel)
            emptyLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            return
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.distribution = .fillEqually
        
        // 최대 3개의 차트 표시
        let chartsToShow = Array(charts.prefix(3))
        
        chartsToShow.enumerated().forEach { index, chart in
            let rowView = RecentChartRowView()
            rowView.tag = index
            rowView.configure(with: chart)
            stackView.addArrangedSubview(rowView)
        }
        
        tableContainerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
    }
    
    // MARK: - Pinned Charts Methods
    func configureWithPinnedRecords(beachID: Int) {
        self.currentBeachID = beachID
        fetchPinnedRecords()
    }
    
    private func fetchPinnedRecords() {
        
        surfRecordUseCase.fetchSurfRecords(for: currentBeachID)
            .subscribe(
                onSuccess: { [weak self] records in
                    guard let self = self else { return }
                    
                    // isPin이 true인 기록만 필터링
                    let pinnedRecords = records.filter { $0.isPin }
                    
                    // 최근 날짜순으로 정렬하고 최대 3개만
                    let recentPinnedRecords = pinnedRecords
                        .sorted { $0.surfDate > $1.surfDate }
                        .prefix(3)
                    
                    DispatchQueue.main.async {
                        self.displayPinnedRecords(Array(recentPinnedRecords))
                    }
                },
                onFailure: { [weak self] error in
                    DispatchQueue.main.async {
                        self?.showEmptyState()
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func displayPinnedRecords(_ records: [SurfRecordData]) {
        
        // 기존 뷰 제거
        tableContainerView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        
        guard !records.isEmpty else {
            showEmptyState()
            return
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.distribution = .fillEqually
        
        records.enumerated().forEach { index, record in
            let rowView = PinnedChartRowView()
            rowView.tag = index
            rowView.configure(with: record)
            stackView.addArrangedSubview(rowView)
        }
        
        tableContainerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }
    
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "고정된 차트가 없습니다"
        emptyLabel.textColor = .white.withAlphaComponent(0.7)
        emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textAlignment = .center
        
        tableContainerView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

// MARK: - ChartListHeaderView
final class ChartListHeaderView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("모두 보기", for: .normal)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .white.withAlphaComponent(0.8)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        return button
    }()
    
    var filterToShow: String = "all" // "all" or "pinned"
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        configureUI()
        configureLayout()
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        addSubview(titleLabel)
        addSubview(moreButton)
    }
    
    private func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    @objc private func moreButtonTapped() {
        // 1) Switch tab to "기록 차트" (tag == 2)
        if let vc = findViewController(), let tbc = vc.tabBarController {
            if let vcs = tbc.viewControllers, let idx = vcs.firstIndex(where: { $0.tabBarItem.tag == 2 }) {
                tbc.selectedIndex = idx
            } else {
                tbc.selectedIndex = min(2, (tbc.viewControllers?.count ?? 1) - 1)
            }
        }
        // 2) Notify RecordHistory to apply the requested filter
        NotificationCenter.default.post(name: .recordHistoryApplyFilterRequested, object: nil, userInfo: ["filter": filterToShow])
    }

    private func findViewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        while let responder = nextResponder {
            if let vc = responder as? UIViewController { return vc }
            nextResponder = responder.next
        }
        return nil
    }
}

// MARK: - PinnedChartRowView (고정 차트용)
final class PinnedChartRowView: UIView {
    
    private let pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "pin.fill")
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let waveLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let ratingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: AssetImage.ratingStarFill) 
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var ratingStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [ratingImageView, ratingLabel])
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        
        addSubview(pinImageView)
        addSubview(windLabel)
        addSubview(waveLabel)
        addSubview(temperatureLabel)
        addSubview(ratingStack)

        // Keep star and text snug; prevent label from stretching
        ratingLabel.setContentHuggingPriority(.required, for: .horizontal)
        ratingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        ratingImageView.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    private func configureLayout() {
        // PinnedChartTableHeaderView와 동일한 레이아웃
        pinImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        
        windLabel.snp.makeConstraints { make in
            make.leading.equalTo(pinImageView.snp.trailing).offset(24) // 44 - 20 = 24
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        waveLabel.snp.makeConstraints { make in
            make.leading.equalTo(windLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.leading.equalTo(waveLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        ratingStack.snp.makeConstraints { make in
            make.leading.equalTo(temperatureLabel.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        
        ratingImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
    
    func configure(with record: SurfRecordData) {
        print("📌 PinnedChartRowView: Configuring with record date: \(record.surfDate)")
        
        // 기본값 설정
        var avgWindSpeed: Double = 0
        var avgWaveHeight: Double = 0
        var avgWavePeriod: Double = 0
        var avgWaterTemperature: Double = 0
        
        // 해당 기록의 모든 차트 데이터에서 평균 계산
        if !record.charts.isEmpty {
            avgWindSpeed = record.charts.map { $0.windSpeed }.reduce(0, +) / Double(record.charts.count)
            avgWaveHeight = record.charts.map { $0.waveHeight }.reduce(0, +) / Double(record.charts.count)
            avgWavePeriod = record.charts.map { $0.wavePeriod }.reduce(0, +) / Double(record.charts.count)
            avgWaterTemperature = record.charts.map { $0.waterTemperature }.reduce(0, +) / Double(record.charts.count)
        }
        
        // 바람 속도
        windLabel.text = String(format: "%.1fm/s", avgWindSpeed)
        
        // 파도 높이와 주기
        waveLabel.text = String(format: "%.1fm\n%.1fs", avgWaveHeight, avgWavePeriod)
        
        // 수온
        temperatureLabel.text = String(format: "%.0f°C", avgWaterTemperature)
        
        // 평가 점수 (SurfRecord의 rating 사용)
        let rating = Int(record.rating)
        ratingLabel.text = "\(rating)점"
    }
}


// MARK: - PinnedChartTableHeaderView (고정 차트용 테이블 헤더)
final class PinnedChartTableHeaderView: UIView {
    
    private let pinnedLabel: UILabel = {
        let label = UILabel()
        label.text = "고정"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemYellow
        label.textAlignment = .center
        return label
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.text = "바람"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let waveLabel: UILabel = {
        let label = UILabel()
        label.text = "파도"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "수온"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "평가"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        
        addSubview(pinnedLabel)
        addSubview(windLabel)
        addSubview(waveLabel)
        addSubview(temperatureLabel)
        addSubview(ratingLabel)
    }
    
    private func configureLayout() {
        // PinnedChartRowView와 동일한 레이아웃으로 정렬
        pinnedLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(44) // 핀 아이콘 + 텍스트 공간
        }
        
        windLabel.snp.makeConstraints { make in
            make.leading.equalTo(pinnedLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        waveLabel.snp.makeConstraints { make in
            make.leading.equalTo(windLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.leading.equalTo(waveLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        ratingLabel.snp.makeConstraints { make in
            make.leading.equalTo(temperatureLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }
}
