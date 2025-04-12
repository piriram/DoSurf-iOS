import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - ViewController
final class SurfRecordViewController: BaseViewController {
    // UI
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let topCard = SurfRecordTopCard()
    private let bottomCard = SurfRecordBottomCard()
    private let saveButton = UIButton(type: .system)
    
    private var charts: [Chart] = []
    private var injectedCharts: [Chart]?
    
    // State
    private var editingRecord: SurfRecordData?
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
    
    /// 편집 모드 이니셜라이저 (기존 기록 주입)
    convenience init(editing record: SurfRecordData, surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()) {
        self.init(surfRecordUseCase: surfRecordUseCase)
        self.editingRecord = record
        // 초기 값 주입
        self.surfStartTime = record.startTime
        self.surfEndTime = record.endTime
        // 차트 복원 (SurfChartData -> Chart)
        let charts: [Chart] = record.charts.map { data in
            Chart(
                beachID: record.beachID,
                time: data.time,
                windDirection: data.windDirection,
                windSpeed: data.windSpeed,
                waveDirection: data.waveDirection,
                waveHeight: data.waveHeight,
                wavePeriod: data.wavePeriod,
                waterTemperature: data.waterTemperature,
                weather: WeatherType(rawValue: Int(data.weatherIconName) ?? 999) ?? .unknown,
                airTemperature: data.airTemperature
            )
        }
        self.injectedCharts = charts
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
        if editingRecord != nil {
            title = "기록 수정"
        }
        
        // 모달 루트로 표시된 경우 닫기 버튼
        if presentingViewController != nil && navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissSelf))
        }
    }
    
    override func configureBind() {
        bind()
        saveButton.rx.tap
            .bind(onNext: { [weak self] in self?.saveOrUpdateRecord() })
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
        
        // Top Card
        content.addArrangedSubview(topCard)
        setupTopCard()
        
        // Bottom Card
        content.addArrangedSubview(bottomCard)
        setupBottomCard()
        
        // TableView DataSource/Delegate
        topCard.tableView.dataSource = self
        topCard.tableView.delegate = self
        
        // 초기 데이터 설정
        setupInitialData()
    }
    
    private func configureStyles() {
        saveButton.setTitle("기록 저장", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = .surfBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 20
    }
    
    private func setupTopCard() {
        // 피커 초기값 설정
        setupPickersWithInitialTimes(start: surfStartTime, end: surfEndTime)
        
        if let injected = injectedCharts, !injected.isEmpty {
            filterAndApplyCharts()
        }
    }
    
    private func setupBottomCard() {
        if let existing = editingRecord {
            // 편집 모드: 기존 값 복원
            bottomCard.setupRating(Int(existing.rating))
            bottomCard.setupMemo(existing.memo)
        } else {
            // 새 기록: 기본 별점 3점
            bottomCard.setupRating(3)
        }
    }
    
    private func setupInitialData() {
        // 편집 모드인 경우 추가 설정은 이미 완료됨
        topCard.updateChartDateLabel()
    }
    
    private func bind() {
        // Top Card - Date Changed
        topCard.dateChanged
            .subscribe(onNext: { [weak self] _ in
                self?.handleDateChanged()
            })
            .disposed(by: disposeBag)
        
        // Top Card - Start Time Changed
        topCard.startTimeChanged
            .subscribe(onNext: { [weak self] _ in
                self?.handleStartTimeChanged()
            })
            .disposed(by: disposeBag)
        
        // Top Card - End Time Changed
        topCard.endTimeChanged
            .subscribe(onNext: { [weak self] _ in
                self?.handleEndTimeChanged()
            })
            .disposed(by: disposeBag)
        
        // Bottom Card - Memo Button Tapped
        bottomCard.memoButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.handleMemoButtonTapped()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Event Handlers
    private func handleDateChanged() {
        let dayStart = startOfDayKST(for: topCard.datePicker.date)
        let dayEnd   = endOfDayKST(for: topCard.datePicker.date)

        // 선택 날짜로 start/end를 같은 날짜선상으로 이동
        let newStart = combine(date: topCard.datePicker.date, withTimeOf: topCard.startTimePicker.date)
        let newEnd   = combine(date: topCard.datePicker.date, withTimeOf: topCard.endTimePicker.date)

        // 클램프
        let clampedStart = min(max(newStart, dayStart), dayEnd)
        let clampedEnd   = min(max(newEnd, clampedStart), dayEnd)

        // 피커 경계 갱신
        topCard.updatePickerBounds(dayStart: dayStart, dayEnd: dayEnd, startTime: clampedStart)
        topCard.startTimePicker.date = clampedStart
        topCard.endTimePicker.date = clampedEnd

        topCard.updateChartDateLabel()
        filterAndApplyCharts()
    }
    
    private func handleStartTimeChanged() {
        let dayEnd = endOfDayKST(for: topCard.datePicker.date)
        let start = topCard.startTimePicker.date

        // 종료 시간은 시작 이상, 같은 날의 끝 이하
        topCard.updatePickerBounds(dayStart: startOfDayKST(for: topCard.datePicker.date), dayEnd: dayEnd, startTime: start)

        if topCard.endTimePicker.date < start {
            topCard.endTimePicker.date = start
        } else if topCard.endTimePicker.date > dayEnd {
            topCard.endTimePicker.date = dayEnd
        }

        filterAndApplyCharts()
    }
    
    private func handleEndTimeChanged() {
        let start = topCard.startTimePicker.date
        let dayEnd = endOfDayKST(for: topCard.datePicker.date)

        if topCard.endTimePicker.date < start {
            topCard.endTimePicker.date = start
        } else if topCard.endTimePicker.date > dayEnd {
            topCard.endTimePicker.date = dayEnd
        }

        filterAndApplyCharts()
    }
    
    private func handleMemoButtonTapped() {
        if !bottomCard.isMemoOpened {
            bottomCard.showMemoTextView()
            scrollView.isScrollEnabled = true
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.bottomCard.memoTextView.becomeFirstResponder()
                // 입력창이 보이도록 스크롤
                let rect = self.bottomCard.convert(self.bottomCard.memoTextView.frame, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -20), animated: true)
            }
        } else {
            bottomCard.memoTextView.becomeFirstResponder()
        }
    }
    
    // MARK: - Date/Time Helpers
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
    
    // MARK: - Table Helpers
    private func reloadChartTable() {
        topCard.charts = charts
    }
    
    // MARK: - Data Persistence
    private func saveSurfRecordToCoreData() {
        let beachID = charts.first?.beachID ?? injectedCharts?.first?.beachID ?? 0
        surfRecordUseCase.saveSurfRecord(
            surfDate: topCard.datePicker.date,
            startTime: topCard.startTimePicker.date,
            endTime: topCard.endTimePicker.date,
            beachID: beachID,
            rating: Int16(bottomCard.getRating()),
            memo: bottomCard.getMemo(),
            isPin: false,
            charts: charts
        )
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] in
                print("✅ 기록이 성공적으로 저장되었습니다.")
                // 대시보드 '최근 기록 차트' 갱신 트리거
                NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                self?.handleSaveSuccess()
            },
            onFailure: { error in
                print("❌ 기록 저장 실패: \(error.localizedDescription)")
                // TODO: 사용자에게 에러 알림 표시
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func saveOrUpdateRecord() {
        if let existing = editingRecord {
            updateSurfRecordInCoreData(existing: existing)
        } else {
            saveSurfRecordToCoreData()
        }
    }
    
    private func updateSurfRecordInCoreData(existing: SurfRecordData) {
        // beachID 유지 또는 차트에서 추론
        let beachID = existing.beachID != 0 ? existing.beachID : (charts.first?.beachID ?? injectedCharts?.first?.beachID ?? 0)
        let updated = SurfRecordData(
            beachID: beachID,
            id: existing.id,
            surfDate: topCard.datePicker.date,
            startTime: topCard.startTimePicker.date,
            endTime: topCard.endTimePicker.date,
            rating: Int16(bottomCard.getRating()),
            memo: bottomCard.getMemo() ?? existing.memo,
            isPin: existing.isPin,
            charts: charts.map { c in
                SurfChartData(
                    time: c.time,
                    windSpeed: c.windSpeed,
                    windDirection: c.windDirection,
                    waveHeight: c.waveHeight,
                    wavePeriod: c.wavePeriod,
                    waveDirection: c.waveDirection,
                    airTemperature: c.airTemperature,
                    waterTemperature: c.waterTemperature,
                    weatherIconName: c.weather.iconName
                )
            }
        )
        surfRecordUseCase.updateSurfRecord(updated)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                // 갱신 알림 브로드캐스트
                NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                self?.handleSaveSuccess()
            }, onFailure: { [weak self] error in
                let alert = UIAlertController(title: "수정 실패", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            })
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
        
        if let existing = editingRecord {
            // 우선 날짜를 기존 surfDate로 설정
            baseDate = existing.surfDate
        }
        
        var startTime: Date
        var endTime: Date
        
        switch (start, end) {
        case let (s?, e?):
            startTime = stripSeconds(s)
            endTime   = stripSeconds(e)
            // 종료 시간이 시작 시간보다 이르면 같은 날 범위를 유지하도록 종료 시간을 시작 시간으로 맞춤
            if endTime < startTime {
                endTime = startTime
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
        
        // 날짜 설정
        let pickerDate = editingRecord?.surfDate ?? baseDate
        let normalizedStart = combine(date: pickerDate, withTimeOf: startTime)
        let candidateEnd    = combine(date: pickerDate, withTimeOf: endTime)

        // 같은 날짜 안에서만 허용 (하루를 넘길 수 없음)
        let dayStart = startOfDayKST(for: pickerDate)
        let dayEnd   = endOfDayKST(for: pickerDate)

        // 시작/종료 값을 날짜 경계 내로 클램프
        let clampedStart = min(max(normalizedStart, dayStart), dayEnd)
        let clampedEnd   = min(max(candidateEnd, clampedStart), dayEnd)

        // TopCard에 설정
        topCard.setupPickers(date: pickerDate, startTime: clampedStart, endTime: clampedEnd)
        topCard.updatePickerBounds(dayStart: dayStart, dayEnd: dayEnd, startTime: clampedStart)

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
    
    /// KST 기준 선택 날짜의 시작과 끝
    private func startOfDayKST(for date: Date) -> Date {
        kstCalendar().startOfDay(for: date)
    }
    private func endOfDayKST(for date: Date) -> Date {
        let cal = kstCalendar()
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }
    
    /// 3시간 간격(10800초) 점검용 디버그
    private func debugCheckThreeHourSpacing(_ charts: [Chart]) {
        guard charts.count > 1 else { return }
        let threeHours: TimeInterval = 3 * 3600
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd HH:mm"
    }
    
    /// ✅ 시작시간을 3시간 슬롯으로 내림(KST), 종료시간 이하는 포함(<=)
    func filterAndApplyCharts() {
        print("[Debug] filterAndApplyCharts called. injectedCharts count: \(injectedCharts?.count ?? -1)")
        guard let all = injectedCharts, !all.isEmpty else {
            self.charts = []
            reloadChartTable()
            return
        }
        let start = topCard.startTimePicker.date
        let end   = topCard.endTimePicker.date
        
        let lowerBound = alignDownTo3hKST(start) // 시작은 같거나 빠른 슬롯부터
        let upperBound = end                     // 종료는 end 이하
        
        let filtered = all
            .filter { $0.time >= lowerBound && $0.time <= upperBound }
            .sorted { $0.time < $1.time }
        
        if filtered.isEmpty {
            print("[Debug] No chart data after filtering.\nStart: \(topCard.startTimePicker.date)\nEnd: \(topCard.endTimePicker.date)")
        }
        
        self.charts = filtered
        reloadChartTable()
        
        // 디버그: 한국시로 슬롯/리스트 출력
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        
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
