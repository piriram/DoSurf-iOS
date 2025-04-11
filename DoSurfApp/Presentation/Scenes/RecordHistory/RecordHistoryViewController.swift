import UIKit
import RxSwift
import RxCocoa
import RxRelay
import SnapKit
import CoreData
import Foundation

// MARK: - RecordHistoryViewController
final class RecordHistoryViewController: BaseViewController {
    
    // MARK: - UI Components
    private let locationButton: UIButton = {
        let button = UIButton()
        button.setTitle("\(SurfBeach.songjeong.region.displayName) \(SurfBeach.songjeong.displayName)해변", for: .normal)
        button.setTitleColor(.black.withAlphaComponent(0.7), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .label
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        return button
    }()
    
    private lazy var filterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return scrollView
    }()
    
    private let filterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    private let allFilterButton = FilterButton(title: "전체")
    private let pinnedFilterButton = FilterButton(title: "핀 고정")
    private let weatherFilterButton = FilterButton(title: "날짜 선택")
    private let ratingFilterButton = FilterButton(title: "별점", hasDropdown: true)
    private let sortButton = FilterButton(title: "최신순", hasDropdown: true)
    private let createMemoButton = FilterButton(title: "메모 작성")
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.register(RecordCardCell.self, forCellReuseIdentifier: RecordCardCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        return tableView
    }()
    
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Properties
    private let viewModel: RecordHistoryViewModel
    private let disposeBag = DisposeBag()
    
    private let selectedBeachIDRelay = BehaviorRelay<Int?>(value: SurfBeach.songjeong.rawValue)
    private let ratingFilterSubject = PublishSubject<RecordFilter>()
    private let dateFilterSubject = PublishSubject<RecordFilter>()
    private var customStartDate: Date?
    private var customEndDate: Date?
    private let surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()
    private let storageService: SurfingRecordService = UserDefaultsService()
    
    // MARK: - Initializer
    init(viewModel: RecordHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplyFilterNotification(_:)), name: .recordHistoryApplyFilterRequested, object: nil)

        // Seed initial selected beach from persistent storage
        if let saved = storageService.readSelectedBeachID(), let id = Int(saved) {
            selectedBeachIDRelay.accept(id)
            updateLocationButtonTitle(for: id)
        }
        
        // Observe beach changes coming from Dashboard
        NotificationCenter.default.addObserver(self, selector: #selector(handleSelectedBeachChanged(_:)), name: .selectedBeachIDDidChange, object: nil)
    }
    
    // MARK: - BaseViewController Overrides
    override func configureUI() {
        view.backgroundColor = .backgroundWhite
        
        navigationItem.title = ""
        
        view.addSubview(locationButton)
        view.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        
        [allFilterButton, pinnedFilterButton, weatherFilterButton,
         ratingFilterButton, sortButton, createMemoButton].forEach {
            filterStackView.addArrangedSubview($0)
        }
        
        emptyStateView.isHidden = true
        allFilterButton.isSelected = true
        
        if let navigationBar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .backgroundWhite
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.isTranslucent = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Refresh records whenever this tab becomes visible again
        selectedBeachIDRelay.accept(selectedBeachIDRelay.value)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func configureLayout() {
        
        locationButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(0)
            $0.leading.equalToSuperview().offset(16)
            $0.height.equalTo(32)
        }
        
        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(locationButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(36)
        }
        
        filterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyStateView.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.width.equalTo(200)
        }
    }
    
    override func configureAction() {
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
        ratingFilterButton.addTarget(self, action: #selector(ratingButtonTapped), for: .touchUpInside)
        weatherFilterButton.addTarget(self, action: #selector(dateFilterButtonTapped), for: .touchUpInside)
        createMemoButton.addTarget(self, action: #selector(createMemoButtonTapped), for: .touchUpInside)
    }
    
    override func configureBind() {
        let deleteSubject = PublishSubject<NSManagedObjectID>()
        let pinSubject = PublishSubject<NSManagedObjectID>()
        let editSubject = PublishSubject<NSManagedObjectID>()
        
        let input = RecordHistoryViewModel.Input(
            viewDidLoad: Observable.just(()) ,
            filterSelection: Observable.merge(
                allFilterButton.rx.tap.map { RecordFilter.all },
                pinnedFilterButton.rx.tap.map { RecordFilter.pinned },
                dateFilterSubject.asObservable(),
                ratingFilterSubject.asObservable()
            ),
            sortSelection: sortButton.rx.tap.asObservable(),
            ratingSelection: ratingFilterButton.rx.tap.asObservable(),
            recordSelection: tableView.rx.modelSelected(RecordCardViewModel.self).asObservable(),
            moreButtonTap: tableView.rx.itemSelected.asObservable(),
            deleteRecord: deleteSubject.asObservable(),
            pinRecord: pinSubject.asObservable(),
            editRecord: editSubject.asObservable(),
            selectedBeachID: selectedBeachIDRelay.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.records
            .drive(tableView.rx.items(
                cellIdentifier: RecordCardCell.identifier,
                cellType: RecordCardCell.self
            )) { [weak self] index, viewModel, cell in
                cell.configure(with: viewModel)
                cell.onMoreButtonTap = { [weak self] in
                    self?.showActionSheet(for: viewModel, deleteSubject: deleteSubject, pinSubject: pinSubject, editSubject: editSubject)
                }
                cell.onMemoButtonTap = { [weak self] in
                    self?.handleMemoTap(for: viewModel)
                }
                cell.onAddMemoButtonTap = { [weak self] in
                    self?.handleMemoTap(for: viewModel)
                }
            }
            .disposed(by: disposeBag)
        
        output.isEmpty
            .drive(onNext: { [weak self] isEmpty in
                self?.emptyStateView.isHidden = !isEmpty
                self?.tableView.isHidden = isEmpty
            })
            .disposed(by: disposeBag)
        
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                // Show/hide loading indicator if needed
            })
            .disposed(by: disposeBag)
        
        output.error
            .emit(onNext: { [weak self] error in
                self?.showErrorAlert(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        output.selectedFilter
            .drive(onNext: { [weak self] filter in
                self?.updateFilterButtons(selectedFilter: filter)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helper Methods
    private func updateFilterButtons(selectedFilter: RecordFilter) {
        allFilterButton.isSelected = (selectedFilter == .all)
        pinnedFilterButton.isSelected = (selectedFilter == .pinned)

        switch selectedFilter {
        case .datePreset(let preset):
            weatherFilterButton.isSelected = true
            let title: String
            switch preset {
            case .today: title = "오늘"
            case .last7Days: title = "최근 7일"
            case .thisMonth: title = "이번 달"
            case .lastMonth: title = "지난 달"
            }
            weatherFilterButton.setTitle(title, for: .normal)

            ratingFilterButton.isSelected = false
            ratingFilterButton.setTitle("별점", for: .normal)

        case .dateRange(let start, let end):
            weatherFilterButton.isSelected = true
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy.MM.dd"
            let title = "\(fmt.string(from: start)) - \(fmt.string(from: end))"
            weatherFilterButton.setTitle(title, for: .normal)

            ratingFilterButton.isSelected = false
            ratingFilterButton.setTitle("별점", for: .normal)

        case .rating(let r):
            ratingFilterButton.isSelected = true
            ratingFilterButton.setTitle("\(r)점", for: .normal)

            weatherFilterButton.isSelected = false
            weatherFilterButton.setTitle("날짜 선택", for: .normal)

        default:
            weatherFilterButton.isSelected = false
            weatherFilterButton.setTitle("날짜 선택", for: .normal)
            ratingFilterButton.isSelected = false
            ratingFilterButton.setTitle("별점", for: .normal)
        }
    }
    
    @objc private func handleApplyFilterNotification(_ note: Notification) {
        guard let info = note.userInfo, let filter = info["filter"] as? String else { return }
        switch filter {
        case "pinned":
            updateFilterButtons(selectedFilter: .pinned)
            ratingFilterSubject.onNext(.all)
            dateFilterSubject.onNext(.all)
            // Simulate user selecting pinned filter
            pinnedFilterButton.sendActions(for: .touchUpInside)
        default:
            // default to all
            updateFilterButtons(selectedFilter: .all)
            ratingFilterSubject.onNext(.all)
            dateFilterSubject.onNext(.all)
            allFilterButton.sendActions(for: .touchUpInside)
        }
    }
    
    private func showActionSheet(
        for viewModel: RecordCardViewModel,
        deleteSubject: PublishSubject<NSManagedObjectID>,
        pinSubject: PublishSubject<NSManagedObjectID>,
        editSubject: PublishSubject<NSManagedObjectID>
    ) {
        guard let objectID = viewModel.objectID else { return }
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let pinTitle = viewModel.isPin ? "핀 해제" : "핀 고정"
        let pinAction = UIAlertAction(title: pinTitle, style: .default) { _ in
            pinSubject.onNext(objectID)
        }
        
        let editAction = UIAlertAction(title: "수정", style: .default) { _ in
            editSubject.onNext(objectID)
        }
        
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation(for: objectID, deleteSubject: deleteSubject)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        actionSheet.addAction(pinAction)
        actionSheet.addAction(editAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func showDeleteConfirmation(
        for objectID: NSManagedObjectID,
        deleteSubject: PublishSubject<NSManagedObjectID>
    ) {
        let alert = UIAlertController(
            title: "기록 삭제",
            message: "이 기록을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { _ in
            deleteSubject.onNext(objectID)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func showMemoDetail(for viewModel: RecordCardViewModel) {
        let memoVC = MemoDetailViewController(viewModel: viewModel)
        memoVC.modalPresentationStyle = .pageSheet
        
        if let sheet = memoVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(memoVC, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "오류",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func handleMemoTap(for viewModel: RecordCardViewModel) {
        let currentMemo = viewModel.memo
        if (currentMemo?.isEmpty ?? true) {
            // 메모가 없으면 바로 편집기로 이동
            presentMemoEditor(for: viewModel, initialText: nil)
        } else {
            // 메모가 있으면 보기/편집 선택
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let viewAction = UIAlertAction(title: "메모 보기", style: .default) { [weak self] _ in
                self?.showMemoDetail(for: viewModel)
            }
            let editAction = UIAlertAction(title: "메모 편집", style: .default) { [weak self] _ in
                self?.presentMemoEditor(for: viewModel, initialText: currentMemo)
            }
            let cancel = UIAlertAction(title: "취소", style: .cancel)
            sheet.addAction(viewAction)
            sheet.addAction(editAction)
            sheet.addAction(cancel)
            // iPad popover anchor
            if let pop = sheet.popoverPresentationController {
                pop.sourceView = self.weatherFilterButton
                pop.sourceRect = self.weatherFilterButton.bounds
            }
            present(sheet, animated: true)
        }
    }

    private func presentMemoEditor(for viewModel: RecordCardViewModel, initialText: String?) {
        let editor = CreateMemoViewController()
        editor.initialText = initialText
        editor.onSave = { [weak self] text in
            guard let self = self else { return }
            guard let objectID = viewModel.objectID else {
                self.showErrorAlert(message: "선택된 기록을 찾을 수 없습니다.")
                return
            }
            self.updateMemoOnly(objectID: objectID, newMemo: text)
        }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func updateMemoOnly(objectID: NSManagedObjectID, newMemo: String) {
        surfRecordUseCase.fetchSurfRecord(by: objectID)
            .flatMap { [weak self] recordOpt -> Single<Void> in
                guard let self = self else { return .just(()) }
                guard let record = recordOpt else { return Single.error(RepositoryError.invalidObjectID) }
                let updated = SurfRecordData(
                    beachID: record.beachID,
                    id: record.id,
                    surfDate: record.surfDate,
                    startTime: record.startTime,
                    endTime: record.endTime,
                    rating: record.rating,
                    memo: newMemo,
                    isPin: record.isPin,
                    charts: record.charts
                )
                return self.surfRecordUseCase.updateSurfRecord(updated)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                // Broadcast global change so all views reload
                NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                // 목록 갱신
                if let relay = self?.selectedBeachIDRelay { relay.accept(relay.value) }
                let alert = UIAlertController(title: "메모 저장", message: "메모가 저장되었습니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self?.present(alert, animated: true)
            }, onFailure: { [weak self] error in
                self?.showErrorAlert(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateLocationButtonTitle(for beachID: Int) {
        if let beach = SurfBeach(rawValue: beachID) {
            locationButton.setTitle("\(beach.region.displayName) \(beach.displayName) 해변", for: .normal)
        } else {
            locationButton.setTitle("전체 해변", for: .normal)
        }
    }
    
    // MARK: - Actions
    @objc private func locationButtonTapped() {
        showLocationSelector()
    }
    
    @objc private func sortButtonTapped() {
        showSortMenu()
    }
    
    @objc private func ratingButtonTapped() {
        showRatingFilter()
    }
    
    @objc private func dateFilterButtonTapped() {
        showDatePresetMenu()
    }
    
    @objc private func createMemoButtonTapped() {
        showCreateMemoSheet()
    }
    
    @objc private func handleSelectedBeachChanged(_ note: Notification) {
        guard let idStr = note.userInfo?["beachID"] as? String, let id = Int(idStr) else { return }
        selectedBeachIDRelay.accept(id)
        updateLocationButtonTitle(for: id)
    }
    
    private func showCreateMemoSheet() {
        let createVC = CreateMemoViewController()
        createVC.onSave = { [weak self] text in
            guard let self = self else { return }
            guard let beachID = self.selectedBeachIDRelay.value else {
                self.showErrorAlert(message: "해변을 먼저 선택해주세요.")
                return
            }
            let now = Date()
            let end = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now

            self.surfRecordUseCase.saveSurfRecord(
                surfDate: now,
                startTime: now,
                endTime: end,
                beachID: beachID,
                rating: Int16(0),
                memo: text,
                isPin: false,
                charts: []
            )
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    // Broadcast global change so all views reload
                    NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                    // 저장 후 목록 새로고침: 같은 beachID를 다시 방출
                    if let relay = self?.selectedBeachIDRelay { relay.accept(relay.value) }
                    let alert = UIAlertController(title: "메모 저장", message: "메모가 저장되었습니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self?.present(alert, animated: true)
                },
                onFailure: { [weak self] error in
                    self?.showErrorAlert(message: error.localizedDescription)
                }
            )
            .disposed(by: self.disposeBag)
        }

        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
    
    private func showLocationSelector() {
        let alertController = UIAlertController(
            title: "장소 선택",
            message: nil,
            preferredStyle: .actionSheet
        )

        // '전체' 옵션 추가
        let allAction = UIAlertAction(title: "전체", style: .default) { [weak self] _ in
            self?.locationButton.setTitle("전체 해변", for: .normal)
            self?.selectedBeachIDRelay.accept(nil)
        }
        alertController.addAction(allAction)

        SurfBeach.allCases.forEach { beach in
            let action = UIAlertAction(title: beach.displayName, style: .default) { [weak self] _ in
                self?.locationButton.setTitle("\(beach.region.displayName) \(beach.displayName) 해변", for: .normal)
                self?.selectedBeachIDRelay.accept(beach.rawValue)
            }
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 팝오버 앵커 지정
        if let pop = alertController.popoverPresentationController {
            pop.sourceView = locationButton
            pop.sourceRect = locationButton.bounds
        }

        present(alertController, animated: true)
    }
    
    private func showSortMenu() {
        let alertController = UIAlertController(
            title: "정렬",
            message: "정렬 방식을 선택하세요",
            preferredStyle: .actionSheet
        )
        
        let sortOptions: [(String, SortType)] = [
            ("최신순", .latest),
            ("과거순", .oldest),
            ("높은 별점순", .highRating),
            ("낮은 별점순", .lowRating)
        ]
        
        sortOptions.forEach { title, _ in
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.sortButton.setTitle(title, for: .normal)
            }
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func showRatingFilter() {
        let alertController = UIAlertController(
            title: "별점 필터",
            message: nil,
            preferredStyle: .actionSheet
        )

        for rating in (1...5).reversed() {
            let action = UIAlertAction(title: "\(rating)점", style: .default) { [weak self] _ in
                self?.ratingFilterButton.setTitle("\(rating)점", for: .normal)
                self?.ratingFilterSubject.onNext(.rating(rating))
            }
            alertController.addAction(action)
        }

        let allAction = UIAlertAction(title: "전체", style: .default) { [weak self] _ in
            self?.ratingFilterButton.setTitle("별점", for: .normal)
            self?.ratingFilterSubject.onNext(.all)
        }
        alertController.addAction(allAction)

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func showDatePresetMenu() {
        let alertController = UIAlertController(
            title: "날짜 프리셋",
            message: nil,
            preferredStyle: .actionSheet
        )

        let presets: [(String, DatePreset)] = [
            ("오늘", .today),
            ("최근 7일", .last7Days),
            ("이번 달", .thisMonth),
            ("지난 달", .lastMonth)
        ]

        presets.forEach { title, preset in
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.weatherFilterButton.setTitle(title, for: .normal)
                self?.dateFilterSubject.onNext(.datePreset(preset))
            }
            alertController.addAction(action)
        }

        // 사용자 지정 항목 (Popover로 표시)
        let customAction = UIAlertAction(title: "사용자 지정…", style: .default) { [weak self, weak alertController] _ in
            guard let self = self else { return }
            let pickerVC = DateRangePickerViewController()
            pickerVC.initialStart = self.customStartDate ?? Date()
            pickerVC.initialEnd = self.customEndDate ?? Date()
            pickerVC.onApply = { [weak self] start, end in
                guard let self = self else { return }
                self.customStartDate = start
                self.customEndDate = end
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy.MM.dd"
                let title = "\(fmt.string(from: start)) - \(fmt.string(from: end))"
                self.weatherFilterButton.setTitle(title, for: .normal)
                self.dateFilterSubject.onNext(.dateRange(start: start, end: end))
            }

            let nav = UINavigationController(rootViewController: pickerVC)
            nav.modalPresentationStyle = .popover
            nav.preferredContentSize = CGSize(width: 360, height: 420)
            if let pop = nav.popoverPresentationController {
                pop.sourceView = self.weatherFilterButton
                pop.sourceRect = self.weatherFilterButton.bounds
                pop.permittedArrowDirections = [.up, .down]
                pop.delegate = self
            }

            // 먼저 액션시트를 닫고, 다음 런루프에서 팝오버 표시
            alertController?.dismiss(animated: true)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let presented = self.presentedViewController, presented is UIAlertController {
                    presented.dismiss(animated: false)
                }
                self.present(nav, animated: true)
            }
        }
        alertController.addAction(customAction)

        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 팝오버 앵커 지정 (액션시트)
        if let pop = alertController.popoverPresentationController {
            pop.sourceView = weatherFilterButton
            pop.sourceRect = weatherFilterButton.bounds
        }

        present(alertController, animated: true)
    }
    
    @MainActor deinit {
        NotificationCenter.default.removeObserver(self, name: .recordHistoryApplyFilterRequested, object: nil)
        NotificationCenter.default.removeObserver(self, name: .selectedBeachIDDidChange, object: nil)
    }
}

extension RecordHistoryViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - FilterButton
final class FilterButton: UIButton {
    
    private let hasDropdown: Bool
    
    init(title: String, hasDropdown: Bool = false) {
        self.hasDropdown = hasDropdown
        super.init(frame: .zero)
        setupButton(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton(title: String) {
        setTitle(title, for: .normal)
        setTitleColor(.label, for: .normal)
        setTitleColor(.white, for: .selected)
        titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        
        backgroundColor = .white
        layer.cornerRadius = 18
        layer.borderWidth = 0.75
        layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        if hasDropdown {
            setImage(UIImage(systemName: "chevron.down"), for: .normal)
            semanticContentAttribute = .forceRightToLeft
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            tintColor = .lableBlack
        }
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .surfBlue : .white
            tintColor = isSelected ? .white : .label
            layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.black.withAlphaComponent(0.1).cgColor
        }
    }
}

// MARK: - EmptyStateView
final class EmptyStateView: UIView {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "tray")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "아직 기록이 없습니다"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(imageView)
        addSubview(label)
        
        imageView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.width.height.equalTo(60)
        }
        
        label.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension Notification.Name {
    static let recordHistoryApplyFilterRequested = Notification.Name("RecordHistoryApplyFilterRequested")
}
