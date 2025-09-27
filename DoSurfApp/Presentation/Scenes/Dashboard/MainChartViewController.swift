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


// MARK: - Main Chart View Controller
class MainChartViewController: UIViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let beachDataService: BeachDataServiceProtocol
    private var charts: [Chart] = []
    private var beachInfo: BeachInfo?
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 40
        tableView.sectionHeaderTopPadding = 0
        return tableView
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.text = "파도 예보"
        
        let subtitleLabel = UILabel()
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.text = "시간별 상세 예보"
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(16)
        }
        
        return view
    }()
    
    // MARK: - Initialization
    init(beachDataService: BeachDataServiceProtocol = BeachDataService()) {
        self.beachDataService = beachDataService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "파도 예보"
        
        // Navigation Bar
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        view.addSubview(headerView)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupBindings() {
        // 추가 바인딩이 필요한 경우 여기에 구현
    }
    
    // MARK: - Data Loading
    private func loadInitialData() {
        // 예시: 해운대 데이터 로드
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
        // FirestoreChartDTO를 Chart로 변환
        self.charts = dump.forecasts.compactMap { $0.toDomain() }
        self.tableView.reloadData()
        
        // Update header with beach info
        if let beachInfo = self.beachInfo {
            title = beachInfo.name
        }
    }
    
    private func handleDataLoadError(_ error: FirebaseAPIError) {
        // 에러 처리
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
extension MainChartViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChartTableViewCell.identifier, for: indexPath) as? ChartTableViewCell else {
            return UITableViewCell()
        }
        
        let chart = charts[indexPath.row]
        cell.configure(with: chart)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 셀 선택 시 상세 화면으로 이동하거나 추가 동작 구현
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemGroupedBackground
        
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemGroupedBackground
        containerView.layer.cornerRadius = 8
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 8
        
        let labels = ["시간", "바람", "파도", "기온/수온"]
        labels.forEach { text in
            let label = UILabel()
            label.text = text
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            stackView.addArrangedSubview(label)
        }
        
        containerView.addSubview(stackView)
        headerView.addSubview(containerView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(4)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return charts.isEmpty ? 0 : 40
    }
}

// MARK: - RxSwift Extensions
extension MainChartViewController {
    func bindData(with observable: Observable<[Chart]>) {
        observable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] charts in
                self?.charts = charts
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}
