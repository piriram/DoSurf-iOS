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
        view.backgroundColor = .backgroundSkyblue
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .surfBlue
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .darkGray
        return label
    }()
    
    private let ratingBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
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
        button.setTitleColor(.darkGray, for: .normal)
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
    
    private let columnHeaderView: ColumnHeaderView = {
        let view = ColumnHeaderView()
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
        containerView.addSubview(headerView)
        headerView.addSubview(dateLabel)
        headerView.addSubview(ratingBackgroundView)
        headerView.addSubview(ratingLabel)
        headerView.addSubview(moreButton)
        headerView.addSubview(memoButton)
        headerView.addSubview(addMemoButton)
        containerView.addSubview(columnHeaderView)
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
        
        columnHeaderView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(28)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
        }
        
        ratingLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(4)
            $0.leading.equalTo(dateLabel)
        }
        
        ratingBackgroundView.snp.makeConstraints {
            $0.top.equalTo(ratingLabel).offset(-4)
            $0.leading.equalTo(ratingLabel).offset(-8)
            $0.bottom.equalTo(ratingLabel).offset(4)
            $0.trailing.equalTo(ratingLabel).offset(8)
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
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: ratingLabel.font.pointSize, weight: .medium)
        let starImage = UIImage(systemName: "star.fill", withConfiguration: symbolConfig)?
            .withTintColor(.surfBlue, renderingMode: .alwaysOriginal)

        if let starImage = starImage {
            let attachment = NSTextAttachment()
            attachment.image = starImage
            // Optional baseline tweak for alignment:
            // attachment.bounds = CGRect(x: 0, y: -1, width: starImage.size.width, height: starImage.size.height)

            let attachmentString = NSMutableAttributedString(attachment: attachment)
            let space = NSAttributedString(string: " ")

            let text = "\(viewModel.rating)점, \(viewModel.ratingText)"
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: ratingLabel.font as Any,
                .foregroundColor: ratingLabel.textColor as Any
            ]
            let textString = NSAttributedString(string: text, attributes: textAttributes)

            let finalString = NSMutableAttributedString()
            finalString.append(attachmentString)
            finalString.append(space)
            finalString.append(textString)

            ratingLabel.attributedText = finalString
        } else {
            ratingLabel.text = "\(viewModel.rating)점, \(viewModel.ratingText)"
        }
        
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
