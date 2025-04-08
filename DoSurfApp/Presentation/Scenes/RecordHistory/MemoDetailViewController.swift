import UIKit
import SnapKit

// MARK: - MemoDetailViewController
final class MemoDetailViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .surfBlue
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let memoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let memoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "메모"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let memoValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let chartTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        return tableView
    }()
    
    // MARK: - Properties
    private let viewModel: RecordCardViewModel
    
    // MARK: - Initializer
    init(viewModel: RecordCardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configure()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerView)
        headerView.addSubview(dateLabel)
        headerView.addSubview(closeButton)
        headerView.addSubview(ratingLabel)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(memoContainerView)
        memoContainerView.addSubview(memoTitleLabel)
        memoContainerView.addSubview(memoValueLabel)
        
        contentView.addSubview(chartTableView)
        
        chartTableView.dataSource = self
        chartTableView.delegate = self
        chartTableView.rowHeight = UITableView.automaticDimension
        chartTableView.estimatedRowHeight = 56
        
        setupConstraints()
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(80)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(20)
        }
        
        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(dateLabel)
            $0.trailing.equalToSuperview().offset(-20)
            $0.width.height.equalTo(28)
        }
        
        ratingLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(8)
            $0.leading.equalTo(dateLabel)
        }
        
        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        memoContainerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }
        
        memoTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        
        memoValueLabel.snp.makeConstraints {
            $0.top.equalTo(memoTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
        }
        
        chartTableView.snp.makeConstraints {
            $0.top.equalTo(memoContainerView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }
    
    // MARK: - Configuration
    private func configure() {
        dateLabel.text = "\(viewModel.date) \(viewModel.dayOfWeek)"
        
        let ratingStars = String(repeating: "⭐", count: viewModel.rating)
        ratingLabel.text = "\(ratingStars) \(viewModel.rating)점, \(viewModel.ratingText)"
        
        // Configure memo
        if let memo = viewModel.memo, !memo.isEmpty {
            memoValueLabel.text = memo
        } else {
            memoValueLabel.text = "메모가 없습니다."
        }
        
        // Update chart table view height using automatic dimension
        chartTableView.reloadData()
        chartTableView.layoutIfNeeded()
        let height = chartTableView.contentSize.height
        chartTableView.snp.makeConstraints {
            $0.height.equalTo(height)
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - MemoDetailViewController + UITableViewDataSource
extension MemoDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.charts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChartTableViewCell.identifier,
            for: indexPath
        ) as? ChartTableViewCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: viewModel.charts[indexPath.row])
        return cell
    }
}

// MARK: - MemoDetailViewController + UITableViewDelegate
extension MemoDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
