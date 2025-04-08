import UIKit
import SnapKit

// MARK: - RecordCardCell
final class RecordCardCell: UITableViewCell {
    
    static let identifier = "RecordCardCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.91, green: 0.95, blue: 1.0, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .surfBlue
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .darkGray
        return label
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .darkGray
        return button
    }()
    
    private let memoButton: UIButton = {
        let button = UIButton()
        button.setTitle("메모 확인하기", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .darkGray
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        return button
    }()
    
    private let chartTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        return tableView
    }()
    
    // MARK: - Callbacks
    var onMoreButtonTap: (() -> Void)?
    var onMemoButtonTap: (() -> Void)?
    
    // MARK: - Properties
    private var charts: [Chart] = []
    
    // MARK: - Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(headerView)
        headerView.addSubview(dateLabel)
        headerView.addSubview(ratingLabel)
        headerView.addSubview(moreButton)
        headerView.addSubview(memoButton)
        containerView.addSubview(chartTableView)
        
        chartTableView.dataSource = self
        chartTableView.delegate = self
        chartTableView.rowHeight = UITableView.automaticDimension
        chartTableView.estimatedRowHeight = 56
        
        containerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-4)
        }
        
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        
        ratingLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(4)
            $0.leading.equalTo(dateLabel)
        }
        
        moreButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.height.equalTo(32)
        }
        
        memoButton.snp.makeConstraints {
            $0.centerY.equalTo(moreButton)
            $0.trailing.equalTo(moreButton.snp.leading).offset(-8)
        }
        
        chartTableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        memoButton.addTarget(self, action: #selector(memoButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func moreButtonTapped() {
        onMoreButtonTap?()
    }
    
    @objc private func memoButtonTapped() {
        onMemoButtonTap?()
    }
    
    // MARK: - Configuration
    func configure(with viewModel: RecordCardViewModel) {
        dateLabel.text = "\(viewModel.date) \(viewModel.dayOfWeek)"
        
        let ratingStars = String(repeating: "⭐", count: viewModel.rating)
        ratingLabel.text = "\(ratingStars) \(viewModel.rating)점, \(viewModel.ratingText)"
        
        memoButton.isHidden = (viewModel.memo == nil || viewModel.memo?.isEmpty == true)
        
        charts = viewModel.charts
        chartTableView.reloadData()
        chartTableView.layoutIfNeeded()
        let height = chartTableView.contentSize.height
        chartTableView.snp.remakeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(height)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        charts = []
        chartTableView.reloadData()
    }
}

// MARK: - RecordCardCell + UITableViewDataSource
extension RecordCardCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChartTableViewCell.identifier,
            for: indexPath
        ) as? ChartTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: charts[indexPath.row])
        return cell
    }
}

// MARK: - RecordCardCell + UITableViewDelegate
extension RecordCardCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
