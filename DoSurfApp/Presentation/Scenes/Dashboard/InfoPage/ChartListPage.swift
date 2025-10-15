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
        self.tableHeaderView = ChartTableHeaderView(isTimeMode: !isPinnedChart)
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
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        // 최대 3개의 차트 표시
        let chartsToShow = Array(charts.prefix(3))
        
        chartsToShow.enumerated().forEach { index, chart in
            let rowView = ChartRowView(isTimeMode: true)
            rowView.tag = index
            rowView.configure(with: chart)
            stackView.addArrangedSubview(rowView)
        }
        
        tableContainerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
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
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        records.enumerated().forEach { index, record in
            let rowView = ChartRowView(isTimeMode: false)
            rowView.tag = index
            rowView.configure(with: record)
            stackView.addArrangedSubview(rowView)
        }
        
        tableContainerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "고정된 차트가 없습니다"
        emptyLabel.textColor = .white.withAlphaComponent(0.7)
        emptyLabel.font = .systemFont(ofSize: FontSize.body1, weight: FontSize.medium)
        emptyLabel.textAlignment = .center
        
        tableContainerView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}








