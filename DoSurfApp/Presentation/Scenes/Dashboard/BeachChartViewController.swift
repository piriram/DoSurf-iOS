//
//  MainChartViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/27/25.
//
import UIKit
import RxSwift
import RxCocoa
import SnapKit

class BeachChartViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let beachDataService: BeachDataServiceProtocol
    private var charts: [Chart] = []
    private var beachInfo: BeachInfo?
    private var currentDateIndex = 0
    private var groupedCharts: [(date: Date, charts: [Chart])] = []
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.sectionHeaderTopPadding = 0
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private lazy var dateHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.1
        
        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(16)
        }
        
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
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
        title = "파도 예보"
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func configureUI() {
        view.backgroundColor = .systemBackground
        tableView.refreshControl = refreshControl
        
        view.addSubview(dateHeaderView)
        view.addSubview(tableView)
    }

    override func configureLayout() {
        dateHeaderView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(dateHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func configureAction() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    override func configureBind() {
        // 스크롤 이벤트 바인딩
        tableView.rx.contentOffset
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.updateDateForVisibleSection()
            })
            .disposed(by: disposeBag)
        
        loadInitialData()
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
        
        self.tableView.reloadData()
        
        if let beachInfo = self.beachInfo {
            title = beachInfo.name
        }
    }
    
    private func groupChartsByDate(_ charts: [Chart]) -> [(date: Date, charts: [Chart])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: charts) { chart in
            calendar.startOfDay(for: chart.time)
        }
        
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, charts: $0.value.sorted { $0.time < $1.time }) }
    }
    
    private func updateDateForVisibleSection() {
        guard !groupedCharts.isEmpty else { return }
        
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        if let firstVisibleIndexPath = visibleIndexPaths.first {
            let newDateIndex = firstVisibleIndexPath.section
            if newDateIndex != currentDateIndex && newDateIndex < groupedCharts.count {
                updateCurrentDate(index: newDateIndex)
            }
        }
    }
    
    private func updateCurrentDate(index: Int) {
        guard index < groupedCharts.count else { return }
        currentDateIndex = index
        
        let date = groupedCharts[index].date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        
        dateLabel.text = formatter.string(from: date)
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
extension BeachChartViewController: UITableViewDataSource, UITableViewDelegate {
    
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
        return section == 0 ? 44 : 20  // 첫 섹션만 헤더 표시
    }
}


// MARK: - RxSwift Extensions
extension BeachChartViewController {
    func bindData(with observable: Observable<[Chart]>) {
        observable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] charts in
                self?.charts = charts
                self?.groupedCharts = self?.groupChartsByDate(charts) ?? []
                self?.updateCurrentDate(index: 0)
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

