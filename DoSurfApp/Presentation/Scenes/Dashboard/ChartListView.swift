import UIKit
import SnapKit

final class ChartListView: UIView {
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

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.sectionHeaderTopPadding = 0
        tableView.showsVerticalScrollIndicator = false
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
        addSubview(tableView)

        dateHeaderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(dateHeaderView.snp.bottom)
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        dateLabel.text = formatter.string(from: date)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ChartListView: UITableViewDataSource, UITableViewDelegate {
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
