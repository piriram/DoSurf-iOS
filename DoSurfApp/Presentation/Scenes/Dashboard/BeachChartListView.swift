import UIKit
import SnapKit

final class BeachChartListView: UIView {
    // MARK: - Properties
    private var groupedCharts: [(date: Date, charts: [Chart])] = []
    private var currentDateIndex: Int = 0
    
    // 스크롤 중 헤더 업데이트 쓰로틀링
    private var lastHeaderUpdateTime: CFTimeInterval = 0
    private let headerUpdateInterval: CFTimeInterval = 0.1
    
    // MARK: - UI Components
    private lazy var dateHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(16)
        }
        return view
    }()
    
    private lazy var columnHeaderView: ChartHeaderView = {
        let view = ChartHeaderView()
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .surfBlue
        label.textAlignment = .center
        return label
    }()
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.sectionHeaderTopPadding = 0
        tableView.showsVerticalScrollIndicator = true
        tableView.isScrollEnabled = true
        tableView.alwaysBounceVertical = true
        tableView.estimatedRowHeight = 56 // 고정 높이 사용
        return tableView
    }()
    
    // Expose scroll enabling for host controller
    var isScrollEnabled: Bool {
        get { tableView.isScrollEnabled }
        set { tableView.isScrollEnabled = newValue }
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(dateHeaderView)
        addSubview(columnHeaderView)
        addSubview(tableView)
        
        dateHeaderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        columnHeaderView.snp.makeConstraints { make in
            make.top.equalTo(dateHeaderView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(28)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(columnHeaderView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public API
    func attachRefreshControl(_ refreshControl: UIRefreshControl) {
        tableView.refreshControl = refreshControl
    }

    func update(groupedCharts: [(date: Date, charts: [Chart])]) {
        self.groupedCharts = groupedCharts
        self.currentDateIndex = 0
        updateDateLabel(index: currentDateIndex)
        tableView.reloadData()

        DispatchQueue.main.async { [weak self] in
            self?.scrollToUpcomingChart()
        }
    }

    /// 현재 시간 기준으로 다가오는 차트에 포커스
    func focusOnUpcomingChart() {
        scrollToUpcomingChart()
    }
    
    func setCurrentDateIndex(_ index: Int) {
        guard index >= 0 && index < groupedCharts.count else { return }
        currentDateIndex = index
        updateDateLabel(index: index)
    }
    
    // MARK: - Private
    private func updateDateLabel(index: Int) {
        guard index < groupedCharts.count else {
            dateLabel.text = nil
            return
        }
        let date = groupedCharts[index].date
        dateLabel.text = date.koreanMonthDayWeekday
    }
    
    // 가벼운 방식: 화면 상단 첫 번째 보이는 인덱스로 섹션 판정 + 쓰로틀링
    private func updateDateForVisibleSectionLightweight() {
        let now = CACurrentMediaTime()
        guard now - lastHeaderUpdateTime >= headerUpdateInterval else { return }
        lastHeaderUpdateTime = now
        
        guard let first = tableView.indexPathsForVisibleRows?.min(),
              first.section < groupedCharts.count else { return }
        
        if currentDateIndex != first.section {
            currentDateIndex = first.section
            updateDateLabel(index: first.section)
        }
    }
    
    private func scrollToUpcomingChart() {
        guard !groupedCharts.isEmpty else { return }
        let now = Date()
        var targetIndexPath: IndexPath?
        
        outerLoop: for (sectionIndex, group) in groupedCharts.enumerated() {
            for (rowIndex, chart) in group.charts.enumerated() {
                if chart.time >= now {
                    targetIndexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    break outerLoop
                }
            }
        }
        
        if targetIndexPath == nil {
            if let lastSection = groupedCharts.indices.last, !groupedCharts[lastSection].charts.isEmpty {
                let lastRow = groupedCharts[lastSection].charts.count - 1
                targetIndexPath = IndexPath(row: lastRow, section: lastSection)
            }
        }
        
        guard let indexPath = targetIndexPath else { return }
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        currentDateIndex = indexPath.section
        updateDateLabel(index: indexPath.section)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension BeachChartListView: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        groupedCharts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedCharts[section].charts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChartTableViewCell.identifier,
            for: indexPath
        ) as? ChartTableViewCell else {
            return UITableViewCell()
        }
        let chart = groupedCharts[indexPath.section].charts[indexPath.row]
        cell.configure(with: chart)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // 섹션 헤더/푸터는 사용하지 않음
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.001 }
    
    // 스크롤 중 헤더 날짜 갱신(가벼운 방식 + 쓰로틀링)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        updateDateForVisibleSectionLightweight()
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        updateDateForVisibleSectionLightweight()
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === tableView else { return }
        if !decelerate { updateDateForVisibleSectionLightweight() }
    }
}
