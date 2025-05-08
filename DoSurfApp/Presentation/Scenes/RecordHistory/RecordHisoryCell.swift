//
//  RecordHisoryCell.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/5/25.
//

import UIKit
import SnapKit

final class RecordHistoryCell: UITableViewCell {
    
    static let identifier = "RecordHistoryCell"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        // Shadow wrapper view (does NOT clip its subviews)
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 5, height: 5)
        view.layer.shadowRadius = 8
        view.layer.masksToBounds = false
        return view
    }()
    
    private let roundedContentView: UIView = {
        // Actual content container that clips to rounded corners
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 24
        v.layer.masksToBounds = true
        return v
    }()
    
    private let topHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .surfBlue.withAlphaComponent(0.3)
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.bold)
        label.textColor = .surfBlue
        return label
    }()
    
    private let ratingBadgeView: RatingBadgeView = {
        let view = RatingBadgeView(badgeColor: .white.withAlphaComponent(0.6))
        return view
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
        button.setTitleColor(UIColor.black.withAlphaComponent(0.8), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .darkGray
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        return button
    }()
    
    private let addMemoButton: UIButton = {
        let button = UIButton()
        button.setTitle("메모 추가하기", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
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
    
    private let columnHeaderView: ChartHeaderView = {
        let view = ChartHeaderView()
        return view
    }()
    
    // MARK: - Callbacks
    var onMoreButtonTap: (() -> Void)?
    var onMemoButtonTap: (() -> Void)?
    var onAddMemoButtonTap: (() -> Void)?
    
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
        containerView.addSubview(roundedContentView)
        roundedContentView.addSubview(topHeaderView)
        topHeaderView.addSubview(dateLabel)
        topHeaderView.addSubview(ratingBadgeView)
        topHeaderView.addSubview(moreButton)
        topHeaderView.addSubview(memoButton)
        topHeaderView.addSubview(addMemoButton)
        roundedContentView.addSubview(columnHeaderView)
        roundedContentView.addSubview(chartTableView)
        
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
        
        roundedContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        topHeaderView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(88)
        }
        
        columnHeaderView.snp.makeConstraints {
            $0.top.equalTo(topHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(22)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(21)
        }
        
        ratingBadgeView.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        
        moreButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.height.equalTo(32)
        }
        
        memoButton.snp.makeConstraints {
            $0.top.equalTo(moreButton.snp.bottom).offset(8)
            $0.trailing.equalTo(moreButton)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        addMemoButton.snp.makeConstraints {
            $0.top.equalTo(moreButton.snp.bottom).offset(8)
            $0.trailing.equalTo(moreButton)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        chartTableView.snp.makeConstraints {
            $0.top.equalTo(columnHeaderView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        memoButton.addTarget(self, action: #selector(memoButtonTapped), for: .touchUpInside)
        addMemoButton.addTarget(self, action: #selector(addMemoButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func moreButtonTapped() {
        onMoreButtonTap?()
    }
    
    @objc private func memoButtonTapped() {
        onMemoButtonTap?()
    }
    
    @objc private func addMemoButtonTapped() {
        onAddMemoButtonTap?()
    }
    
    // MARK: - Configuration
    func configure(with viewModel: RecordCardViewModel) {
        dateLabel.text = "\(viewModel.date) \(viewModel.dayOfWeek)"
        
        ratingBadgeView.configure(rating: viewModel.rating, ratingText: viewModel.ratingText, starColor: .surfBlue)
        
        let hasMemo = !(viewModel.memo?.isEmpty ?? true)
        memoButton.isHidden = !hasMemo
        addMemoButton.isHidden = hasMemo
        
        charts = viewModel.charts
        chartTableView.reloadData()
        chartTableView.layoutIfNeeded()
        let height = chartTableView.contentSize.height
        chartTableView.snp.remakeConstraints {
            $0.top.equalTo(columnHeaderView.snp.bottom)
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
extension RecordHistoryCell: UITableViewDataSource {
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
extension RecordHistoryCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
