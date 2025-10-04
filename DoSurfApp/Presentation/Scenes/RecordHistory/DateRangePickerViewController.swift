import UIKit
import SnapKit

final class DateRangePickerViewController: UIViewController {
    
    // MARK: - Properties
    
    var initialStart: Date?
    var initialEnd: Date?
    var onApply: ((Date, Date) -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let rangeCardView = UIView()
    private let startDateLabel = UILabel()
    private let endDateLabel = UILabel()
    private let periodLabel = UILabel()
    private let dividerView = UIView()
    
    private let segmentControl = UISegmentedControl(items: ["시작 날짜", "종료 날짜"])
    private let datePicker = UIDatePicker()
    
    private var startDate: Date
    private var endDate: Date
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()
    
    // MARK: - Initialization
    
    init() {
        let now = Date()
        self.startDate = now
        self.endDate = now
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startDate = initialStart ?? Date()
        endDate = initialEnd ?? Date()
        
        setupViews()
        setupLayout()
        setupNavigationBar()
        updateRangeCard()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = "기간 선택"
        
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupRangeCard()
        setupSegmentControl()
        setupDatePicker()
    }
    
    private func setupRangeCard() {
        rangeCardView.backgroundColor = .secondarySystemBackground
        rangeCardView.layer.cornerRadius = 12
        rangeCardView.layer.masksToBounds = true
        contentView.addSubview(rangeCardView)
        
        let startContainer = makeDateContainer(titleLabel: "시작", dateLabel: startDateLabel)
        let endContainer = makeDateContainer(titleLabel: "종료", dateLabel: endDateLabel)
        
        dividerView.backgroundColor = .separator
        
        periodLabel.font = .systemFont(ofSize: 14, weight: .medium)
        periodLabel.textColor = .secondaryLabel
        periodLabel.textAlignment = .center
        
        rangeCardView.addSubview(startContainer)
        rangeCardView.addSubview(dividerView)
        rangeCardView.addSubview(endContainer)
        rangeCardView.addSubview(periodLabel)
        
        startContainer.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalTo(dividerView.snp.leading).offset(-16)
        }
        
        dividerView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(startContainer)
            $0.width.equalTo(1)
            $0.height.equalTo(40)
        }
        
        endContainer.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.leading.equalTo(dividerView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.equalTo(startContainer)
        }
        
        periodLabel.snp.makeConstraints {
            $0.top.equalTo(startContainer.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(16)
        }
    }
    
    private func makeDateContainer(titleLabel text: String, dateLabel: UILabel) -> UIView {
        let container = UIView()
        
        let title = UILabel()
        title.text = text
        title.font = .systemFont(ofSize: 13, weight: .medium)
        title.textColor = .secondaryLabel
        
        dateLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        dateLabel.textColor = .label
        dateLabel.numberOfLines = 1
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.minimumScaleFactor = 0.8
        
        container.addSubview(title)
        container.addSubview(dateLabel)
        
        title.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(6)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        return container
    }
    
    private func setupSegmentControl() {
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        contentView.addSubview(segmentControl)
    }
    
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        datePicker.date = startDate
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        contentView.addSubview(datePicker)
    }
    
    private func setupLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        rangeCardView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        segmentControl.snp.makeConstraints {
            $0.top.equalTo(rangeCardView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        datePicker.snp.makeConstraints {
            $0.top.equalTo(segmentControl.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().inset(16)
        }
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "적용",
            style: .done,
            target: self,
            action: #selector(applyTapped)
        )
    }
    
    // MARK: - Actions
    
    @objc private func segmentChanged() {
        let isStartMode = segmentControl.selectedSegmentIndex == 0
        datePicker.date = isStartMode ? startDate : endDate
        
        if isStartMode {
            datePicker.minimumDate = nil
            datePicker.maximumDate = endDate
        } else {
            datePicker.minimumDate = startDate
            datePicker.maximumDate = nil
        }
    }
    
    @objc private func dateChanged() {
        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: datePicker.date)
        
        if segmentControl.selectedSegmentIndex == 0 {
            startDate = selectedDate
            if endDate < startDate {
                endDate = startDate
            }
        } else {
            endDate = selectedDate
            if endDate < startDate {
                endDate = startDate
            }
        }
        
        updateRangeCard()
    }
    
    @objc private func applyTapped() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        onApply?(start, end)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Helpers
    
    private func updateRangeCard() {
        startDateLabel.text = dateFormatter.string(from: startDate)
        endDateLabel.text = dateFormatter.string(from: endDate)
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        periodLabel.text = "\(days + 1)일"
        
        segmentChanged()
    }
}
