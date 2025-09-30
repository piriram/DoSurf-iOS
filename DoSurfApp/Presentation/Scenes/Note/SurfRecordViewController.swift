import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - ViewController
final class SurfRecordViewController: BaseViewController {
    // UI
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let headerCard = UIView()
    private let tableCard = UIView()
    private let ratingCardView = SurfRatingCardView()
    private let commentCard = UIView()
    private let addMemoButton = UIButton(type: .system)
    private let memoTextView = UITextView()
    private let saveButton = UIButton(type: .system)
    
    private let datePicker = UIDatePicker()
    private let startTimePicker = UIDatePicker()
    private let endTimePicker = UIDatePicker()
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var charts: [Chart] = []
    private var tableCardHeightConstraint: Constraint?
    private let chartDateLabel = UILabel()
    private let tableContainer = UIStackView()
    
    // State
    private var memoOpened = false
    private let disposeBag = DisposeBag()
    
    // VM
    private let viewModel = SurfRecordViewModel()
    
    // 서핑 시간 데이터
    private var surfStartTime: Date?
    private var surfEndTime: Date?
    
    /// 서핑 시작/종료 시간을 받아 초기화하는 메서드
    convenience init(startTime: Date?, endTime: Date?) {
        self.init()
        self.surfStartTime = startTime
        self.surfEndTime = endTime
    }
    
    override func configureUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        configureHierarchy()
        configureStyles()
        // 처음엔 스크롤 비활성화
        //        scrollView.isScrollEnabled = false
        
        // Ensure navigation bar is visible and back button available when pushed
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.hidesBackButton = false
        if title == nil || title?.isEmpty == true {
            title = "서핑 기록"
        }
        
        // If presented modally as the root of a navigation controller, add a close button
        if presentingViewController != nil && navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissSelf))
        }
    }
    
    override func configureBind() {
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Unhide navigation bar in case previous screen hid it
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.hidesBackButton = false
        
        // 서핑 시간 정보 디버깅 출력
        if let startTime = surfStartTime, let endTime = surfEndTime {
            print("🏄‍♂️ 서핑 기록 화면으로 시간 전달됨:")
            print("   시작 시간: \(startTime)")
            print("   종료 시간: \(endTime)")
            let duration = endTime.timeIntervalSince(startTime)
            let hours = Int(duration) / 3600
            let minutes = Int(duration) % 3600 / 60
            print("   서핑 지속 시간: \(hours)시간 \(minutes)분")
        } else {
            print("⚠️ 서핑 시간 정보가 전달되지 않았습니다. 기본값 사용.")
        }
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    private func configureHierarchy() {
        // 하단 고정 버튼
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.left.right.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-12) // 키보드 위에 고정
            $0.height.equalTo(54)
        }
        
        // 스크롤 영역
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.top.left.right.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(saveButton.snp.top).offset(-12)
        }
        
        content.axis = .vertical
        content.spacing = 12
        scrollView.addSubview(content)
        content.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
            $0.width.equalTo(scrollView.snp.width).offset(-32) // 가로 고정
        }
        
        // --- Header (날짜/시작/종료) 카드
        headerCard.layer.cornerRadius = 12
        headerCard.backgroundColor = .white
        content.addArrangedSubview(headerCard)
        
        // Configure inline pickers
        datePicker.datePickerMode = .date
        startTimePicker.datePickerMode = .time
        endTimePicker.datePickerMode = .time
        
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .compact
            startTimePicker.preferredDatePickerStyle = .compact
            endTimePicker.preferredDatePickerStyle = .compact
        }
        
        // 서핑 시간이 전달되었다면 해당 시간으로 설정, 아니면 기본값 사용
        let baseDate: Date
        let defaultStart: Date
        let defaultEnd: Date
        
        if let startTime = surfStartTime, let endTime = surfEndTime {
            baseDate = startTime
            defaultStart = startTime
            defaultEnd = endTime
        } else {
            baseDate = Date()
            defaultStart = date(bySettingHour: 13, minute: 0, on: baseDate)
            defaultEnd = date(bySettingHour: 15, minute: 0, on: baseDate)
        }
        
        datePicker.date = baseDate
        startTimePicker.date = defaultStart
        endTimePicker.date = defaultEnd
        endTimePicker.minimumDate = defaultStart
        
        // React to changes
        datePicker.addTarget(self, action: #selector(handleDateChanged), for: .valueChanged)
        startTimePicker.addTarget(self, action: #selector(handleStartTimeChanged), for: .valueChanged)
        endTimePicker.addTarget(self, action: #selector(handleEndTimeChanged), for: .valueChanged)
        
        let dateRow = makePickerRow(title: "서핑 한 날짜", picker: datePicker)
        let startRow = makePickerRow(title: "시작 시간", picker: startTimePicker)
        let endRow = makePickerRow(title: "종료 시간", picker: endTimePicker)
        let headerStack = UIStackView(arrangedSubviews: [dateRow, startRow, endRow])
        headerStack.axis = .vertical
        headerStack.spacing = 0
        headerCard.addSubview(headerStack)
        headerStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        
        // --- 표 카드 (샘플 자리)
        tableCard.layer.cornerRadius = 12
        tableCard.backgroundColor = .white
        content.addArrangedSubview(tableCard)
        tableCard.snp.makeConstraints { make in
            tableCardHeightConstraint = make.height.equalTo(140).constraint
        }
        
        // TableView + Date header + Column header inside card
        tableCard.layer.masksToBounds = true
        
        // Container stack
        tableContainer.axis = .vertical
        tableContainer.spacing = 0
        tableCard.addSubview(tableContainer)
        tableContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Date header
        let dateHeaderView = UIView()
        chartDateLabel.font = .systemFont(ofSize: 18, weight: .bold)
        chartDateLabel.textColor = .surfBlue
        chartDateLabel.textAlignment = .center
        dateHeaderView.addSubview(chartDateLabel)
        chartDateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(12)
        }
        
        // Column header
        let headerRow = UIView()
        headerRow.backgroundColor = .secondarySystemGroupedBackground
        let columnHeaderStack = UIStackView()
        columnHeaderStack.axis = .horizontal
        columnHeaderStack.distribution = .equalSpacing
        columnHeaderStack.alignment = .center
        columnHeaderStack.spacing = 8
        ["시간", "바람", "파도", "수온", "날씨"].forEach { text in
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            columnHeaderStack.addArrangedSubview(label)
        }
        headerRow.addSubview(columnHeaderStack)
        columnHeaderStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        headerRow.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        
        // TableView config
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 56
        tableView.isScrollEnabled = false // avoid nested scrolling inside outer scrollView
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        
        // Build stack
        tableContainer.addArrangedSubview(dateHeaderView)
        tableContainer.addArrangedSubview(headerRow)
        tableContainer.addArrangedSubview(tableView)
        
        // Prepare initial data and layout
        updateChartDateLabel()
        self.charts = buildSampleCharts()
        reloadChartTable()
        
        // --- 파도 평가 카드
        content.addArrangedSubview(ratingCardView)
        
        // --- 코멘트 카드
        commentCard.layer.cornerRadius = 12
        commentCard.backgroundColor = .white
        content.addArrangedSubview(commentCard)
        
        let commentTitle = UILabel()
        commentTitle.text = "파도 코멘트"
        commentTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        
        addMemoButton.setTitle("메모 추가  ", for: .normal)
        addMemoButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addMemoButton.tintColor = .surfBlue
        addMemoButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        addMemoButton.backgroundColor = .surfBlue.withAlphaComponent(0.08)
        addMemoButton.layer.cornerRadius = 20
        addMemoButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        
        memoTextView.isHidden = true
        memoTextView.font = .systemFont(ofSize: 15)
        memoTextView.backgroundColor = UIColor.secondarySystemBackground
        memoTextView.layer.cornerRadius = 10
        memoTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        memoTextView.snp.makeConstraints { $0.height.greaterThanOrEqualTo(100) }
        
        let cStack = UIStackView(arrangedSubviews: [commentTitle, addMemoButton, memoTextView])
        cStack.axis = .vertical
        cStack.spacing = 12
        
        commentCard.addSubview(cStack)
        cStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
    }
    
    private func configureStyles() {
        saveButton.setTitle("기록 저장", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = .surfBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 20
    }
    
    private func bind() {
        // 메모 추가 버튼 → 입력창 표시 + 스크롤 활성화 + 포커스
        addMemoButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                if !self.memoOpened {
                    self.memoOpened = true
                    self.memoTextView.isHidden = false
                    self.scrollView.isScrollEnabled = true
                    
                    // 애니메이션로 펼치기
                    UIView.animate(withDuration: 0.25) {
                        self.view.layoutIfNeeded()
                    } completion: { _ in
                        self.memoTextView.becomeFirstResponder()
                        // 입력창이 보이도록 스크롤
                        let rect = self.commentCard.convert(self.memoTextView.frame, to: self.scrollView)
                        self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -20), animated: true)
                    }
                } else {
                    // 이미 열려 있으면 포커스만
                    self.memoTextView.becomeFirstResponder()
                }
            })
            .disposed(by: disposeBag)
        
        
    }
    
    // MARK: - Date/Time Picker Helpers
    private func makePickerRow(title: String, picker: UIDatePicker) -> UIView {
        let row = UIView()
        let left = UILabel()
        left.text = title
        left.font = .systemFont(ofSize: 14, weight: .regular)
        
        row.addSubview(left)
        row.addSubview(picker)
        
        left.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        picker.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.centerY.equalTo(left)
        }
        
        row.snp.makeConstraints { $0.height.equalTo(44) }
        
        let sep = UIView()
        sep.backgroundColor = .separator
        row.addSubview(sep)
        sep.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        
        return row
    }
    
    private func date(bySettingHour hour: Int, minute: Int, on base: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: base)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? base
    }
    
    private func combine(date: Date, withTimeOf time: Date) -> Date {
        let calendar = Calendar.current
        let d = calendar.dateComponents([.year, .month, .day], from: date)
        let t = calendar.dateComponents([.hour, .minute, .second], from: time)
        var comps = DateComponents()
        comps.year = d.year
        comps.month = d.month
        comps.day = d.day
        comps.hour = t.hour
        comps.minute = t.minute
        comps.second = t.second
        return calendar.date(from: comps) ?? date
    }
    
    @objc private func handleDateChanged() {
        // Keep start/end times but move them to the selected date
        let newStart = combine(date: datePicker.date, withTimeOf: startTimePicker.date)
        let newEnd = combine(date: datePicker.date, withTimeOf: endTimePicker.date)
        startTimePicker.date = newStart
        endTimePicker.date = newEnd
        endTimePicker.minimumDate = newStart
        if endTimePicker.date < newStart {
            endTimePicker.date = newStart
        }
        updateChartDateLabel()
    }
    
    @objc private func handleStartTimeChanged() {
        let start = startTimePicker.date
        endTimePicker.minimumDate = start
        if endTimePicker.date < start {
            endTimePicker.date = start
        }
    }
    
    @objc private func handleEndTimeChanged() {
        if endTimePicker.date < startTimePicker.date {
            endTimePicker.date = startTimePicker.date
        }
    }
    
    private func updateChartDateLabel() {
        chartDateLabel.text = datePicker.date.koreanMonthDayWeekday
    }
    
    // MARK: - Row Factory (좌측 타이틀 / 우측 값)
    private func makeRow(title: String, value: String) -> UIView {
        let row = UIView()
        let left = UILabel()
        left.text = title
        left.font = .systemFont(ofSize: 14, weight: .regular)
        
        let valueLabel = PaddingLabel(insets: .init(top: 6, left: 12, bottom: 6, right: 12))
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        valueLabel.backgroundColor = UIColor.surfBlue
        valueLabel.textColor = .surfBlue
        valueLabel.layer.cornerRadius = 16
        valueLabel.clipsToBounds = true
        
        row.addSubview(left)
        row.addSubview(valueLabel)
        left.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.centerY.equalTo(left)
        }
        row.snp.makeConstraints { $0.height.equalTo(44) }
        let sep = UIView()
        sep.backgroundColor = .separator
        row.addSubview(sep)
        sep.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        return row
    }
    
    // MARK: - Table Helpers
    private func reloadChartTable() {
        tableView.reloadData()
        tableView.layoutIfNeeded()
        let contentHeight = tableView.contentSize.height
        let headersHeight: CGFloat = 44 + 36 // date header + column header
        tableCardHeightConstraint?.update(offset: max(140, headersHeight + contentHeight))
    }
    
    private func buildSampleCharts() -> [Chart] {
        // Build a few sample rows relative to current pickers
        let baseDate = datePicker.date
        let start = startTimePicker.date
        // Generate 3 entries at 2-hour intervals starting from start time
        var items: [Chart] = []
        for i in 0..<3 {
            let time = Calendar.current.date(byAdding: .hour, value: i * 2, to: combine(date: baseDate, withTimeOf: start)) ?? Date()
            let chart = Chart(
                beachID: 4001,
                time: time,
                windDirection: 45,
                windSpeed: 2.7,
                waveDirection: 120,
                waveHeight: 1.2,
                wavePeriod: 6.2,
                waterTemperature: 28,
                weather: .rain,
                airTemperature: 30
            )
            items.append(chart)
        }
        return items
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension SurfRecordViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { charts.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChartTableViewCell.identifier, for: indexPath) as? ChartTableViewCell else {
            return UITableViewCell()
        }
        let chart = charts[indexPath.row]
        cell.configure(with: chart)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - 작은 유틸 라벨
final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets
    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}

