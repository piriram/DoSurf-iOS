import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - SurfRecordTopCard
/// 상단 카드: 날짜/시간 피커 + 차트 테이블
final class NoteTopCardView: UIView {
    
    // MARK: - UI Components
    private let containerStack = UIStackView()
    
    // Header (날짜/시간 피커)
    private let headerCard = UIView()
    private let dateButton = CustomPickerButton()
    private let startTimeButton = CustomPickerButton()
    private let endTimeButton = CustomPickerButton()

    // 내부 UIDatePicker (시트로 표시) - NoteViewController에서 접근 필요
    let datePicker = UIDatePicker()
    let startTimePicker = UIDatePicker()
    let endTimePicker = UIDatePicker()
    
    // Table (차트)
    private let tableCard = UIView()
    private let tableContainer = UIStackView()
    let chartDateLabel = UILabel()
    let tableView = UITableView(frame: .zero, style: .plain)
    
    private let emptyChartLabel: UILabel = {
        let label = UILabel()
        label.text = "차트 데이터가 없습니다."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    // MARK: - Properties
    private let tableFixedHeight: CGFloat = 260
    private var tableCardHeightConstraint: Constraint?
    
    var charts: [Chart] = [] {
        didSet {
            tableView.reloadData()
            emptyChartLabel.isHidden = !charts.isEmpty
        }
    }
    
    // MARK: - Rx
    let dateChanged = PublishRelay<Date>()
    let startTimeChanged = PublishRelay<Date>()
    let endTimeChanged = PublishRelay<Date>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        bind()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
        bind()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        // Container style
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = .white
        
        // Container stack
        containerStack.axis = .vertical
        containerStack.spacing = 12
        addSubview(containerStack)
        containerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        // Configure header
        configureHeaderCard()
        containerStack.addArrangedSubview(headerCard)
        
        // Configure table
        configureTableCard()
        containerStack.addArrangedSubview(tableCard)
    }
    
    private func configureHeaderCard() {
        headerCard.backgroundColor = .clear

        // Configure pickers
        configureDatePickers()

        // Configure button actions
        dateButton.addTarget(self, action: #selector(dateButtonTapped), for: .touchUpInside)
        startTimeButton.addTarget(self, action: #selector(startTimeButtonTapped), for: .touchUpInside)
        endTimeButton.addTarget(self, action: #selector(endTimeButtonTapped), for: .touchUpInside)

        // Set initial button text
        updateButtonTexts()

        // Create picker rows
        let dateRow = makePickerRow(title: "서핑 한 날짜", button: dateButton)
        let startRow = makePickerRow(title: "시작 시간", button: startTimeButton)
        let endRow = makePickerRow(title: "종료 시간", button: endTimeButton)

        let headerStack = UIStackView(arrangedSubviews: [dateRow, startRow, endRow])
        headerStack.axis = .vertical
        headerStack.spacing = 0

        headerCard.addSubview(headerStack)
        headerStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    private func configureDatePickers() {
        datePicker.datePickerMode = .date
        startTimePicker.datePickerMode = .time
        endTimePicker.datePickerMode = .time

        // 타임존을 명시적으로 KST로 지정
        datePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        startTimePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        endTimePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
    }
    
    private func configureTableCard() {
        tableCard.backgroundColor = .clear
        tableCard.layer.masksToBounds = true
        
        tableCard.snp.makeConstraints { make in
            tableCardHeightConstraint = make.height.equalTo(tableFixedHeight).constraint
        }
        
        // Container stack
        tableContainer.axis = .vertical
        tableContainer.spacing = 0
        tableCard.addSubview(tableContainer)
        tableContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        // Date header
        let dateHeaderView = makeDateHeader()
        tableContainer.addArrangedSubview(dateHeaderView)
        
        // Column header
        let columnHeader = makeColumnHeader()
        tableContainer.addArrangedSubview(columnHeader)
        
        // TableView
        configureTableView()
        tableContainer.addArrangedSubview(tableView)
    }
    
    private func makeDateHeader() -> UIView {
        let headerView = UIView()
        chartDateLabel.font = .systemFont(ofSize: 18, weight: .bold)
        chartDateLabel.textColor = .surfBlue
        chartDateLabel.textAlignment = .center
        
        headerView.addSubview(chartDateLabel)
        chartDateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(12)
        }
        
        return headerView
    }
    
    private func makeColumnHeader() -> UIView {
        let header = ChartHeaderView()
        header.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        return header
    }
    
    private func configureTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = true
        tableView.tableFooterView = UIView()
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        
        tableView.backgroundView = emptyChartLabel
        emptyChartLabel.isHidden = true
    }
    
    private func makePickerRow(title: String, button: CustomPickerButton) -> UIView {
        let row = UIView()
        let left = UILabel()
        left.text = title
        left.font = .systemFont(ofSize: 14, weight: .regular)

        row.addSubview(left)
        row.addSubview(button)

        left.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        button.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.centerY.equalTo(left)
        }

        row.snp.makeConstraints { $0.height.equalTo(54) }

        let separator = UIView()
        separator.backgroundColor = .separator
        row.addSubview(separator)
        separator.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        return row
    }

    // MARK: - Button Actions
    @objc private func dateButtonTapped() {
        showDatePicker(datePicker, mode: .date) { [weak self] selectedDate in
            guard let self = self else { return }
            self.datePicker.date = selectedDate
            self.updateButtonTexts()
            self.dateChanged.accept(selectedDate)
        }
    }

    @objc private func startTimeButtonTapped() {
        showDatePicker(startTimePicker, mode: .time) { [weak self] selectedDate in
            guard let self = self else { return }
            self.startTimePicker.date = selectedDate
            self.updateButtonTexts()
            self.startTimeChanged.accept(selectedDate)
        }
    }

    @objc private func endTimeButtonTapped() {
        showDatePicker(endTimePicker, mode: .time) { [weak self] selectedDate in
            guard let self = self else { return }
            self.endTimePicker.date = selectedDate
            self.updateButtonTexts()
            self.endTimeChanged.accept(selectedDate)
        }
    }

    private func showDatePicker(_ picker: UIDatePicker, mode: UIDatePicker.Mode, completion: @escaping (Date) -> Void) {
        guard let viewController = self.findViewController() else { return }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let pickerView = UIDatePicker()
        pickerView.datePickerMode = mode
        pickerView.preferredDatePickerStyle = .wheels
        pickerView.date = picker.date
        pickerView.timeZone = TimeZone(identifier: "Asia/Seoul")
        pickerView.locale = Locale(identifier: "ko_KR")

        // 피커의 제약 조건 설정
        if mode == .time {
            pickerView.minimumDate = picker.minimumDate
            pickerView.maximumDate = picker.maximumDate
        }

        let pickerContainer = UIViewController()
        pickerContainer.view = pickerView
        pickerContainer.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 216)

        alert.setValue(pickerContainer, forKey: "contentViewController")

        let selectAction = UIAlertAction(title: "선택", style: .default) { _ in
            completion(pickerView.date)
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        alert.addAction(selectAction)
        alert.addAction(cancelAction)

        viewController.present(alert, animated: true, completion: nil)
    }

    func updateButtonTexts() {
        // 날짜 버튼: 2025.11.24 (수) 형식
        let dateText = datePicker.date.toFormattedString(
            format: "yyyy.MM.dd (E)",
            locale: Locale(identifier: "ko_KR")
        )
        dateButton.setText(dateText)

        // 시간 버튼: 17:00 형식
        let startTimeText = startTimePicker.date.toFormattedString(format: "HH:mm")
        startTimeButton.setText(startTimeText)

        let endTimeText = endTimePicker.date.toFormattedString(format: "HH:mm")
        endTimeButton.setText(endTimeText)
    }

    // MARK: - Bind
    private func bind() {
        // 버튼 액션에서 직접 처리하므로 여기서는 별도 바인딩 불필요
    }
    
    // MARK: - Public Methods
    func updateChartDateLabel() {
        chartDateLabel.text = datePicker.date.koreanMonthDayWeekday
    }
    
    func setupPickers(date: Date, startTime: Date, endTime: Date) {
        datePicker.date = date
        startTimePicker.date = startTime
        endTimePicker.date = endTime
        updateButtonTexts()
        updateChartDateLabel()
    }
    
    func updatePickerBounds(dayStart: Date, dayEnd: Date, startTime: Date) {
        startTimePicker.minimumDate = dayStart
        startTimePicker.maximumDate = dayEnd

        endTimePicker.minimumDate = startTime
        endTimePicker.maximumDate = dayEnd
    }

    private func findViewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        while let responder = nextResponder {
            if let vc = responder as? UIViewController { return vc }
            nextResponder = responder.next
        }
        return nil
    }
}
