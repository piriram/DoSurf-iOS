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
    private var injectedCharts: [Chart]?
    private var tableCardHeightConstraint: Constraint?
    private let chartDateLabel = UILabel()
    private let tableContainer = UIStackView()
    
    private let emptyChartLabel: UILabel = {
        let label = UILabel()
        label.text = "차트 데이터가 없습니다."
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    // State
    private var memoOpened = false
    private let disposeBag = DisposeBag()
    
    // Dependencies
    private let surfRecordUseCase: SurfRecordUseCaseProtocol
    private let viewModel = SurfRecordViewModel()
    
    // MARK: - Dependency Injection Initializer
    init(surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.surfRecordUseCase = surfRecordUseCase
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.surfRecordUseCase = SurfRecordUseCase()
        super.init(coder: coder)
    }
    
    // 서핑 시간 데이터
    private var surfStartTime: Date?
    private var surfEndTime: Date?
    
    // 테이블 고정 높이
    private let tableFixedHeight: CGFloat = 260
    
    // MARK: - Convenience Initializers
    /// 서핑 시작/종료 + 차트 목록 주입 이니셜라이저
    convenience init(startTime: Date?, endTime: Date?, charts: [Chart], surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.init(surfRecordUseCase: surfRecordUseCase)
        self.surfStartTime = startTime
        self.surfEndTime = endTime
        self.injectedCharts = charts
    }
    
    /// 필요 시 2-파라미터 이니셜라이저도 지원
    convenience init(startTime: Date?, endTime: Date?, surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.init(surfRecordUseCase: surfRecordUseCase)
        self.surfStartTime = startTime
        self.surfEndTime = endTime
        self.injectedCharts = nil
    }
    
    // 외부에서 차트를 나중에 주입/갱신하고 싶을 때 사용
    func applyInjectedCharts(_ charts: [Chart]) {
        self.injectedCharts = charts
        if isViewLoaded { filterAndApplyCharts() }
    }
    
    // MARK: - Lifecycle
    override func configureUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        configureHierarchy()
        configureStyles()
        
        // 네비게이션 표시
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.hidesBackButton = false
        if title == nil || title?.isEmpty == true {
            title = "서핑 기록"
        }
        
        // 모달 루트로 표시된 경우 닫기 버튼
        if presentingViewController != nil && navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissSelf))
        }
    }
    
    override func configureBind() {
        bind()
        saveButton.rx.tap
            .bind(onNext: { [weak self] in self?.saveSurfRecordToCoreData() })
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.hidesBackButton = false
        
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
    
    // MARK: - UI Build
    private func configureHierarchy() {
        // 하단 고정 버튼
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints {
            $0.left.right.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-12)
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
            $0.width.equalTo(scrollView.snp.width).offset(-32)
        }
        
        // --- Header (날짜/시작/종료) 카드
        headerCard.layer.cornerRadius = 12
        headerCard.backgroundColor = .white
        content.addArrangedSubview(headerCard)
        
        // Configure inline pickers
        datePicker.datePickerMode = .date
        startTimePicker.datePickerMode = .time
        endTimePicker.datePickerMode = .time
        
        // 타임존을 명시적으로 KST로 지정 (표시 일관성)
        datePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        startTimePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        endTimePicker.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .compact
            startTimePicker.preferredDatePickerStyle = .compact
            endTimePicker.preferredDatePickerStyle = .compact
        }
        
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
        
        // >>> 전달된 start/end를 기준으로 3개 피커 정렬
        setupPickersWithInitialTimes(start: surfStartTime, end: surfEndTime)
        
        // --- 표 카드
        tableCard.layer.cornerRadius = 12
        tableCard.backgroundColor = .white
        content.addArrangedSubview(tableCard)
        tableCard.snp.makeConstraints { make in
            // ✅ 고정 높이 + 스크롤
            tableCardHeightConstraint = make.height.equalTo(tableFixedHeight).constraint
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
        tableView.isScrollEnabled = true           // ✅ 내부 수직 스크롤 허용
        tableView.showsVerticalScrollIndicator = true
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: ChartTableViewCell.identifier)
        
        tableView.backgroundView = emptyChartLabel
        emptyChartLabel.isHidden = true
        
        // Build stack
        tableContainer.addArrangedSubview(dateHeaderView)
        tableContainer.addArrangedSubview(headerRow)
        tableContainer.addArrangedSubview(tableView)
        
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
        addMemoButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 10)
        
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
        
        if let injected = injectedCharts, !injected.isEmpty {
            filterAndApplyCharts()
        }
        
        updateChartDateLabel()
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
                    
                    UIView.animate(withDuration: 0.25) {
                        self.view.layoutIfNeeded()
                    } completion: { _ in
                        self.memoTextView.becomeFirstResponder()
                        // 입력창이 보이도록 스크롤
                        let rect = self.commentCard.convert(self.memoTextView.frame, to: self.scrollView)
                        self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -20), animated: true)
                    }
                } else {
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
        // 선택 날짜로 start/end를 같은 날짜선상으로 이동
        let newStart = combine(date: datePicker.date, withTimeOf: startTimePicker.date)
        let newEnd   = combine(date: datePicker.date, withTimeOf: endTimePicker.date)
        startTimePicker.date = newStart
        endTimePicker.minimumDate = newStart
        if endTimePicker.date < newStart {
            endTimePicker.date = newStart
        }
        updateChartDateLabel()
        filterAndApplyCharts()          // ✅ 날짜 변경 시 재필터
    }
    
    @objc private func handleStartTimeChanged() {
        let start = startTimePicker.date
        endTimePicker.minimumDate = start
        if endTimePicker.date < start {
            endTimePicker.date = start
        }
        filterAndApplyCharts()          // ✅ 시작 변경 시 재필터
    }
    
    @objc private func handleEndTimeChanged() {
        if endTimePicker.date < startTimePicker.date {
            endTimePicker.date = startTimePicker.date
        }
        filterAndApplyCharts()          // ✅ 종료 변경 시 재필터
    }
    
    private func updateChartDateLabel() {
        chartDateLabel.text = datePicker.date.koreanMonthDayWeekday
    }
    
    // MARK: - Table Helpers
    private func reloadChartTable() {
        tableView.reloadData()
        tableView.layoutIfNeeded()
        // ✅ 고정 높이 유지 (자동 변경 없음)
        
        emptyChartLabel.isHidden = !charts.isEmpty
    }
    
    // MARK: - Data Persistence
    private func saveSurfRecordToCoreData() {
        let beachID = charts.first?.beachID ?? injectedCharts?.first?.beachID ?? 0
        surfRecordUseCase.saveSurfRecord(
            surfDate: datePicker.date,
            startTime: startTimePicker.date,
            endTime: endTimePicker.date,
            beachID: beachID,
            rating: Int16(ratingCardView.selectedRating.value),
            memo: memoTextView.text.isEmpty ? nil : memoTextView.text,
            isPin: false,
            charts: charts
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] in
                print("✅ 기록이 성공적으로 저장되었습니다.")
                self?.handleSaveSuccess()
            },
            onFailure: { error in
                print("❌ 기록 저장 실패: \(error.localizedDescription)")
                // TODO: 사용자에게 에러 알림 표시
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func handleSaveSuccess() {
        // 저장 성공 시 화면 닫기 (pop 또는 dismiss)
        if let nav = navigationController {
            // 네비게이션 스택에 있을 경우 pop
            if nav.viewControllers.first === self, presentingViewController != nil {
                // 모달 네비게이션의 루트인 경우 dismiss
                dismiss(animated: true)
            } else {
                nav.popViewController(animated: true)
            }
        } else if presentingViewController != nil {
            // 네비게이션이 없고 모달로 표시된 경우 dismiss
            dismiss(animated: true)
        }
    }
}

// MARK: - Initial Time Setup & Filtering
private extension SurfRecordViewController {
    func setupPickersWithInitialTimes(start: Date?, end: Date?) {
        let now = Date()
        var baseDate = start ?? now
        
        var startTime: Date
        var endTime: Date
        
        switch (start, end) {
        case let (s?, e?):
            startTime = stripSeconds(s)
            endTime   = stripSeconds(e)
            if endTime < startTime {
                endTime = Calendar.current.date(byAdding: .day, value: 1, to: endTime) ?? endTime
            }
            baseDate = startTime
            
        case let (s?, nil):
            startTime = stripSeconds(s)
            endTime   = Calendar.current.date(byAdding: .hour, value: 2, to: startTime) ?? startTime
            baseDate  = startTime
            
        case let (nil, e?):
            endTime   = stripSeconds(e)
            startTime = Calendar.current.date(byAdding: .hour, value: -2, to: endTime) ?? endTime
            baseDate  = startTime
            
        default:
            baseDate  = now
            startTime = date(bySettingHour: 13, minute: 0, on: baseDate)
            endTime   = date(bySettingHour: 15, minute: 0, on: baseDate)
        }
        
        // datePicker의 날짜를 기준으로 동일한 날짜선상에 정렬
        datePicker.date = baseDate
        let normalizedStart = combine(date: datePicker.date, withTimeOf: startTime)
        var normalizedEnd   = combine(date: datePicker.date, withTimeOf: endTime)
        
        if normalizedEnd < normalizedStart {
            normalizedEnd = Calendar.current.date(byAdding: .day, value: 1, to: normalizedEnd) ?? normalizedEnd
        }
        
        startTimePicker.date = normalizedStart
        endTimePicker.minimumDate = normalizedStart
        endTimePicker.date = max(normalizedEnd, normalizedStart)
        
        updateChartDateLabel()
        filterAndApplyCharts() // ✅ 초기에도 필터 적용
    }
    
    func stripSeconds(_ date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return cal.date(from: comps) ?? date
    }
    
    // MARK: KST 3시간 그리드 정렬/필터 유틸
    /// KST 캘린더
    private func kstCalendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return cal
    }
    /// KST 기준 3시간 슬롯(00,03,06,...)으로 내림
    private func alignDownTo3hKST(_ date: Date) -> Date {
        let cal = kstCalendar()
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: date)
        guard let hour = comps.hour else { return date }
        let flooredHour = (hour / 3) * 3
        var aligned = DateComponents()
        aligned.year = comps.year
        aligned.month = comps.month
        aligned.day = comps.day
        aligned.hour = flooredHour
        aligned.minute = 0
        aligned.second = 0
        return cal.date(from: aligned) ?? date
    }
    /// 3시간 간격(10800초) 점검용 디버그
    private func debugCheckThreeHourSpacing(_ charts: [Chart]) {
        guard charts.count > 1 else { return }
        let threeHours: TimeInterval = 3 * 3600
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        print("🧪 3시간 간격 점검 시작")
        for i in 1..<charts.count {
            let dt = charts[i].time.timeIntervalSince(charts[i-1].time)
            if abs(dt - threeHours) > 1 {
                print("⚠️ 간격 이상: \(f.string(from: charts[i-1].time)) -> \(f.string(from: charts[i].time)) = \(dt/3600)시간")
            }
        }
    }
    
    /// ✅ 시작시간을 3시간 슬롯으로 내림(KST), 종료시간 이하는 포함(<=)
    func filterAndApplyCharts() {
        print("[Debug] filterAndApplyCharts called. injectedCharts count: \(injectedCharts?.count ?? -1)")
        guard let all = injectedCharts, !all.isEmpty else {
            self.charts = []
            reloadChartTable()
            return
        }
        let start = startTimePicker.date
        let end   = endTimePicker.date
        
        let lowerBound = alignDownTo3hKST(start) // 시작은 같거나 빠른 슬롯부터
        let upperBound = end                     // 종료는 end 이하
        
        let filtered = all
            .filter { $0.time >= lowerBound && $0.time <= upperBound }
            .sorted { $0.time < $1.time }
        
        if filtered.isEmpty {
            print("[Debug] No chart data after filtering.\nStart: \(startTimePicker.date)\nEnd: \(endTimePicker.date)")
        }
        
        self.charts = filtered
        reloadChartTable()
        
        // 디버그: 한국시로 슬롯/리스트 출력
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        print("⏱ 경계(KST) start(slot↓): \(f.string(from: lowerBound))  ~  end(≤): \(f.string(from: upperBound))")
        print("📊 필터링된 차트 시간대(KST):")
        filtered.forEach { print(" - \(f.string(from: $0.time))") }
        
        // (선택) 간격 검증
        debugCheckThreeHourSpacing(filtered)
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

