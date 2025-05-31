import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - ViewController
final class NoteViewController: BaseViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let topCard = NoteTopCardView()
    private let bottomCard = NoteBottomCardView()
    private let saveButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let viewModel: NoteViewModel
    private let mode: SurfRecordMode
    private let time: TimeProvider
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    init(viewModel: NoteViewModel, mode: SurfRecordMode,time: TimeProvider = .shared ) {
        self.viewModel = viewModel
        self.mode = mode
        self.time = time
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:mode:) instead")
    }
    
    // MARK: - Lifecycle
    override func configureUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        configureHierarchy()
        configureStyles()
        
        // 네비게이션 설정
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.hidesBackButton = false
        title = mode.navigationTitle
        
        // 모달 루트로 표시된 경우 닫기 버튼
        if presentingViewController != nil && navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(dismissSelf)
            )
        }
    }
    
    override func configureBind() {
        bindViewModel()
        bindUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.hidesBackButton = false
    }
    
    override func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .backgroundWhite
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.surfBlue]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.surfBlue]
        
        guard let navBar = navigationController?.navigationBar else { return }
        navBar.standardAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.isTranslucent = false
        navBar.tintColor = .surfBlue
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    // MARK: - UI Build
    private func configureHierarchy() {
        // 저장 버튼
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
        topCard.tableView.dataSource = self
        topCard.tableView.delegate = self
        
        // Bottom Card
        content.addArrangedSubview(bottomCard)
    }
    
    private func configureStyles() {
        saveButton.setTitle("기록 저장", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = .surfBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 20
    }
    
    private func bindViewModel() {
        let input = NoteViewModel.Input(
            viewDidLoad: Observable.just(()),
            dateChanged: topCard.dateChanged.asObservable(),
            startTimeChanged: topCard.startTimeChanged.asObservable(),
            endTimeChanged: topCard.endTimeChanged.asObservable(),
            ratingChanged: bottomCard.ratingChanged,
            memoChanged: bottomCard.memoChanged,
            saveTapped: saveButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        output.initialData
            .drive(onNext: { [weak self] (data: NoteViewModel.InitialData) in
                guard let self = self else { return }
                
                // Top Card 설정
                self.topCard.setupPickers(
                    date: data.date,
                    startTime: data.startTime,
                    endTime: data.endTime
                )
                
                let dayStart = self.time.startOfDay(for: data.date)
                let dayEnd = self.time.endOfDay(for: data.date)
                self.topCard.updatePickerBounds(
                    dayStart: dayStart,
                    dayEnd: dayEnd,
                    startTime: data.startTime
                )
                
                self.topCard.updateChartDateLabel()
                
                // Bottom Card 설정
                self.bottomCard.setupRating(data.rating)
                if let memo = data.memo, !memo.isEmpty {
                    self.bottomCard.setupMemo(memo)
                }
            })
            .disposed(by: disposeBag)
        
        // 필터링된 차트 업데이트
        output.filteredCharts
            .drive(onNext: { [weak self] charts in
                self?.topCard.charts = charts
            })
            .disposed(by: disposeBag)
        
        // 저장 성공
        output.saveSuccess
            .drive(onNext: { [weak self] in
                self?.handleSaveSuccess()
            })
            .disposed(by: disposeBag)
        
        output.saveError
            .emit(onNext: { [weak self] (error: Error) in
                self?.showErrorAlert(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        // 로딩 상태
        output.isLoading
            .map { !$0 }  // isLoading을 isEnabled로 변환
            .drive(saveButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func bindUI() {
        // Top Card - Date Changed
        topCard.dateChanged
            .subscribe(onNext: { [weak self] date in
                self?.handleDateChanged(date)
            })
            .disposed(by: disposeBag)
        
        // Top Card - Start Time Changed
        topCard.startTimeChanged
            .subscribe(onNext: { [weak self] time in
                self?.handleStartTimeChanged(time)
            })
            .disposed(by: disposeBag)
        
        // Top Card - End Time Changed
        topCard.endTimeChanged
            .subscribe(onNext: { [weak self] time in
                self?.handleEndTimeChanged(time)
            })
            .disposed(by: disposeBag)
        
        // Bottom Card - Memo Button Tapped
        bottomCard.memoButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.handleMemoButtonTapped()
            })
            .disposed(by: disposeBag)
        
        // Bottom Card - Request scroll to memo
        bottomCard.requestScrollToMemo
            .asSignal()
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
                
                let targetView = self.bottomCard.memoTextView
                let rectInScroll = targetView.convert(targetView.bounds, to: self.scrollView)
                let visibleRect = rectInScroll.insetBy(dx: 0, dy: -20)
                self.scrollView.scrollRectToVisible(visibleRect, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Event Handlers
    
    private func handleDateChanged(_ date: Date) {
        let dayStart = time.startOfDay(for: date)
        let dayEnd = time.endOfDay(for: date)
        
        let newStart = time.calendar.combine(date, withTimeOf: topCard.startTimePicker.date)
        let newEnd = time.calendar.combine(date, withTimeOf: topCard.endTimePicker.date)
        
        let clampedStart = min(max(newStart, dayStart), dayEnd)
        let clampedEnd = min(max(newEnd, clampedStart), dayEnd)
        
        topCard.updatePickerBounds(dayStart: dayStart, dayEnd: dayEnd, startTime: clampedStart)
        topCard.startTimePicker.date = clampedStart
        topCard.endTimePicker.date = clampedEnd
        
        topCard.updateChartDateLabel()
    }
    
    private func handleStartTimeChanged(_ time: Date) {
        let dayEnd = self.time.endOfDay(for: topCard.datePicker.date)
        let start = time
        
        topCard.updatePickerBounds(
            dayStart: self.time.startOfDay(for: topCard.datePicker.date),
            dayEnd: dayEnd,
            startTime: start
        )
        
        if topCard.endTimePicker.date < start {
            topCard.endTimePicker.date = start
        } else if topCard.endTimePicker.date > dayEnd {
            topCard.endTimePicker.date = dayEnd
        }
    }
    
    private func handleEndTimeChanged(_ time: Date) {
        let start = topCard.startTimePicker.date
        let dayEnd = self.time.endOfDay(for: topCard.datePicker.date)
        
        if time < start {
            topCard.endTimePicker.date = start
        } else if time > dayEnd {
            topCard.endTimePicker.date = dayEnd
        }
    }
    
    private func handleMemoButtonTapped() {
        if !bottomCard.isMemoOpened {
            bottomCard.showMemoTextView()
            scrollView.isScrollEnabled = true
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.bottomCard.memoTextView.becomeFirstResponder()
            }
        } else {
            bottomCard.memoTextView.becomeFirstResponder()
        }
    }
    //TODO: Coordinator 만들기
    private func handleSaveSuccess() {
        if let nav = navigationController {
            if nav.viewControllers.first === self, presentingViewController != nil {
                dismiss(animated: true)
            } else {
                nav.popViewController(animated: true)
            }
        } else if presentingViewController != nil {
            dismiss(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension NoteViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topCard.charts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChartTableViewCell.identifier,
            for: indexPath
        ) as? ChartTableViewCell else {
            return UITableViewCell()
        }
        let chart = topCard.charts[indexPath.row]
        cell.configure(with: chart)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
