import UIKit
import SnapKit

final class BeachChartListView: UIView {
    // MARK: - Properties
    private var groupedCharts: [(date: Date, charts: [Chart])] = []
    private var currentDateIndex: Int = 0

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
    
    private lazy var columnHeaderView: UIView = {
        let headerView = UIView()
        headerView.backgroundColor = .backgroundHeader.withAlphaComponent(0.5)

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
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
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
    
    private func updateDateForVisibleSectionByCount() {
        guard !groupedCharts.isEmpty else { return }
        guard let visible = tableView.indexPathsForVisibleRows, !visible.isEmpty else { return }

        // Count visible rows per section
        var counts: [Int: Int] = [:]
        for indexPath in visible {
            counts[indexPath.section, default: 0] += 1
        }

        // Choose the section with the highest visible row count.
        // In case of tie, prefer the one that appears earlier in the visible rows order (closer to top).
        var bestSection = currentDateIndex
        var bestCount = -1
        for (section, count) in counts {
            if count > bestCount {
                bestCount = count
                bestSection = section
            } else if count == bestCount {
                let firstIdxBest = visible.firstIndex(where: { $0.section == bestSection }) ?? Int.max
                let firstIdxCandidate = visible.firstIndex(where: { $0.section == section }) ?? Int.max
                if firstIdxCandidate < firstIdxBest {
                    bestSection = section
                }
            }
        }

        if bestSection != currentDateIndex && bestSection < groupedCharts.count {
            currentDateIndex = bestSection
            updateDateLabel(index: bestSection)
        }
    }
    
    private func scrollToUpcomingChart() {
        guard !groupedCharts.isEmpty else { return }
        let now = Date() // 현재 시간 기준으로 복구
        var targetIndexPath: IndexPath?

        // Find the first chart whose time is now or in the future
        outerLoop: for (sectionIndex, group) in groupedCharts.enumerated() {
            for (rowIndex, chart) in group.charts.enumerated() {
                if chart.time >= now {
                    targetIndexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    break outerLoop
                }
            }
        }

        // If everything is in the past, focus the last row of the last section
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
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }

    // Keep the date header in sync with the section that has more visible rows
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        updateDateForVisibleSectionByCount()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        updateDateForVisibleSectionByCount()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === tableView else { return }
        if !decelerate { updateDateForVisibleSectionByCount() }
    }
}

