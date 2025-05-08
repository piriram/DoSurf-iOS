import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CoreData
// TODO: actionsheet -> subview
// TODO: 수정 기능 되살리기
final class RecordHistoryViewController: BaseViewController {
    
    // MARK: - UI Components
    private let filterView = RecordFilterView()
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .backgroundWhite
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.register(RecordHistoryCell.self, forCellReuseIdentifier: RecordHistoryCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        return tableView
    }()
    private let emptyStateView = EmptyStateView()
    
    // MARK: - Dependencies
    private let viewModel: RecordHistoryViewModel
    //    private let surfRecordUseCase: SurfRecordUseCaseProtocol
    
    // MARK: - Rx
    private let disposeBag = DisposeBag()
    private let deleteRecordSubject = PublishSubject<NSManagedObjectID>()
    private let pinRecordSubject = PublishSubject<NSManagedObjectID>()
    private let editRecordSubject = PublishSubject<NSManagedObjectID>()
    private let sortSelectionSubject = PublishSubject<SortType>()
    private let locationSelectionSubject = PublishSubject<Int?>()
    
    // MARK: - Initializer
    init(viewModel: RecordHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - BaseViewController
    override func configureUI() {
        view.backgroundColor = .backgroundWhite
        navigationItem.title = ""
        
        view.addSubview(filterView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        emptyStateView.isHidden = true
        
        configureNavigationBarAppearance()
    }
    
    override func configureLayout() {
        filterView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(view)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(filterView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.width.equalTo(200)
        }
    }
    
    override func configureAction() {
        filterView.tapSort
            .subscribe(onNext: { [weak self] in
                self?.presentSortMenu()
            })
            .disposed(by: disposeBag)
        
        filterView.tapLocation
            .subscribe(onNext: { [weak self] in
                self?.presentLocationSelector()
            })
            .disposed(by: disposeBag)
        
        filterView.tapRating
            .subscribe(onNext: { [weak self] in
                self?.presentRatingFilter()
            })
            .disposed(by: disposeBag)
        
        filterView.tapDate
            .subscribe(onNext: { [weak self] in
                self?.presentDatePresetMenu()
            })
            .disposed(by: disposeBag)
    }
    
    override func configureBind() {
        let input = RecordHistoryViewModel.Input(
            viewDidLoad: Observable.just(()),
            filterSelection: createFilterSelectionObservable(),
            sortSelection: sortSelectionSubject.asObservable(),
            locationSelection: locationSelectionSubject.asObservable(),
            recordSelection: tableView.rx.modelSelected(RecordCardViewModel.self).asObservable(),
            deleteRecord: deleteRecordSubject.asObservable(),
            pinRecord: pinRecordSubject.asObservable(),
            editRecord: editRecordSubject.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        // Bind records to table view
        output.records
            .drive(tableView.rx.items(
                cellIdentifier: RecordHistoryCell.identifier,
                cellType: RecordHistoryCell.self
            )) { [weak self] _, viewModel, cell in
                guard let self = self else { return }
                cell.configure(with: viewModel)
                
                cell.onMoreButtonTap = { [weak self] in
                    self?.presentActionSheet(for: viewModel)
                }
                
                cell.onMemoButtonTap = { [weak self] in
                    self?.handleMemoTap(for: viewModel)
                }
                
                cell.onAddMemoButtonTap = { [weak self] in
                    self?.handleMemoTap(for: viewModel)
                }
            }
            .disposed(by: disposeBag)
        
        // Bind empty state
        output.isEmpty
            .drive(onNext: { [weak self] isEmpty in
                self?.emptyStateView.isHidden = !isEmpty
                self?.tableView.isHidden = isEmpty
            })
            .disposed(by: disposeBag)
        
        // Bind loading state (if needed)
        output.isLoading
            .drive()
            .disposed(by: disposeBag)
        
        // Handle errors
        output.error
            .emit(onNext: { [weak self] error in
                self?.presentErrorAlert(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        // Update filter view
        output.selectedFilter
            .drive(onNext: { [weak self] filter in
                self?.filterView.update(selectedFilter: filter)
                self?.scrollToTop()
            })
            .disposed(by: disposeBag)
        
        // Update location title
        output.selectedBeach
            .drive(onNext: { [weak self] beach in
                let title = beach?.displayName ?? "전체 해변"
                self?.filterView.setLocationTitle(title)
            })
            .disposed(by: disposeBag)
        
        // Update sort title
        output.selectedSort
            .drive(onNext: { [weak self] sortType in
                self?.filterView.setSortTitle(sortType.title)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func configureNavigationBarAppearance() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .backgroundWhite
        appearance.shadowColor = .clear
        
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.isTranslucent = false
    }
    
    private func createFilterSelectionObservable() -> Observable<RecordFilter> {
        return Observable.merge(
            filterView.tapAll.map { RecordFilter.all },
            filterView.tapPinned.map { RecordFilter.pinned }
        )
    }
    
    private func scrollToTop(_ animated: Bool = true) {
        let yOffset = -tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: animated)
    }
    
    // MARK: - Presentation Methods
    private func presentLocationSelector() {
        // ViewModel의 beaches를 받아와서 처리해야 함
        // 임시로 간단한 구현
        let alertController = UIAlertController(title: "장소 선택", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "전체", style: .default) { [weak self] _ in
            self?.locationSelectionSubject.onNext(nil)
            self?.scrollToTop()
        })
        
        // TODO: beaches를 output으로 받아서 동적으로 생성
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = filterView
            popoverController.sourceRect = CGRect(x: 20, y: 20, width: 1, height: 1)
        }
        
        present(alertController, animated: true)
    }
    
    private func presentSortMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let sortOptions: [SortType] = [.latest, .oldest, .highRating, .lowRating]
        sortOptions.forEach { sortType in
            alertController.addAction(UIAlertAction(title: sortType.title, style: .default) { [weak self] _ in
                self?.sortSelectionSubject.onNext(sortType)
                self?.scrollToTop()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentRatingFilter() {
        let alertController = UIAlertController(title: "별점 필터", message: nil, preferredStyle: .actionSheet)
        
        for rating in (1...5).reversed() {
            alertController.addAction(UIAlertAction(title: "\(rating)점", style: .default) { [weak self] _ in
                // TODO: ratingFilterSubject 연결
            })
        }
        
        alertController.addAction(UIAlertAction(title: "전체", style: .default) { [weak self] _ in
            // TODO: all filter 연결
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentDatePresetMenu() {
        let alertController = UIAlertController(title: "날짜 프리셋", message: nil, preferredStyle: .actionSheet)
        
        let presets: [(String, DatePreset)] = [
            ("오늘", .today),
            ("최근 7일", .last7Days),
            ("이번 달", .thisMonth),
            ("지난 달", .lastMonth)
        ]
        
        presets.forEach { title, preset in
            alertController.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                // TODO: datePresetSubject 연결
            })
        }
        
        alertController.addAction(UIAlertAction(title: "사용자 지정…", style: .default) { [weak self] _ in
            self?.presentDateRangePicker()
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentDateRangePicker() {
        let pickerViewController = DateRangePickerViewController()
        pickerViewController.initialStart = Date()
        pickerViewController.initialEnd = Date()
        
        pickerViewController.onApply = { [weak self] start, end in
            // TODO: dateRangeSubject 연결
        }
        
        let navigationController = UINavigationController(rootViewController: pickerViewController)
        navigationController.modalPresentationStyle = .popover
        navigationController.preferredContentSize = CGSize(width: 360, height: 420)
        
        if let popoverController = navigationController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: 88, width: 1, height: 1)
            popoverController.permittedArrowDirections = [.up, .down]
            popoverController.delegate = self
        }
        
        present(navigationController, animated: true)
    }
    
    private func presentActionSheet(for viewModel: RecordCardViewModel) {
        guard let objectID = viewModel.objectID else { return }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let pinTitle = viewModel.isPin ? "핀 해제" : "핀 고정"
        alertController.addAction(UIAlertAction(title: pinTitle, style: .default) { [weak self] _ in
            self?.pinRecordSubject.onNext(objectID)
        })
        
        alertController.addAction(UIAlertAction(title: "수정", style: .default) { [weak self] _ in
            self?.presentEditRecord(for: objectID)
        })
        
        alertController.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.presentDeleteConfirmation(for: objectID)
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentDeleteConfirmation(for objectID: NSManagedObjectID) {
        let alertController = UIAlertController(
            title: "기록 삭제",
            message: "이 기록을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteRecordSubject.onNext(objectID)
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentEditRecord(for objectID: NSManagedObjectID) {
        //        surfRecordUseCase.fetchSurfRecord(by: objectID)
        //            .observe(on: MainScheduler.instance)
        //            .subscribe(
        //                onSuccess: { [weak self] recordOption in
        //                    guard let self = self, let record = recordOption else {
        //                        self?.presentErrorAlert(message: "선택된 기록을 찾을 수 없습니다.")
        //                        return
        //                    }
        //
        //                    let editorViewController = DIContainer.shared.makeSurfRecordViewController(editing: record)
        //                    editorViewController.hidesBottomBarWhenPushed = true
        //
        //                    if let navigationController = self.navigationController {
        //                        navigationController.pushViewController(editorViewController, animated: true)
        //                    } else {
        //                        let navigationController = UINavigationController(rootViewController: editorViewController)
        //                        navigationController.modalPresentationStyle = .fullScreen
        //                        self.present(navigationController, animated: true)
        //                    }
        //                },
        //                onFailure: { [weak self] error in
        //                    self?.presentErrorAlert(message: error.localizedDescription)
        //                }
        //            )
        //            .disposed(by: disposeBag)
    }
    
    private func handleMemoTap(for viewModel: RecordCardViewModel) {
        let currentMemo = viewModel.memo
        
        if currentMemo?.isEmpty ?? true {
            presentMemoEditor(for: viewModel, initialText: nil)
        } else {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alertController.addAction(UIAlertAction(title: "메모 보기", style: .default) { [weak self] _ in
                self?.showMemoDetail(for: viewModel)
            })
            
            alertController.addAction(UIAlertAction(title: "메모 편집", style: .default) { [weak self] _ in
                self?.presentMemoEditor(for: viewModel, initialText: currentMemo)
            })
            
            alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
            present(alertController, animated: true)
        }
    }
    
    private func presentMemoEditor(for viewModel: RecordCardViewModel, initialText: String?) {
        let editorViewController = CreateMemoViewController()
        editorViewController.initialText = initialText
        
        editorViewController.onSave = { [weak self] text in
            guard let self = self, let objectID = viewModel.objectID else {
                self?.presentErrorAlert(message: "선택된 기록을 찾을 수 없습니다.")
                return
            }
            self.updateMemoOnly(objectID: objectID, newMemo: text)
        }
        
        let navigationController = UINavigationController(rootViewController: editorViewController)
        navigationController.modalPresentationStyle = .pageSheet
        
        if let sheetController = navigationController.sheetPresentationController {
            sheetController.detents = [.medium(), .large()]
            sheetController.prefersGrabberVisible = true
        }
        
        present(navigationController, animated: true)
    }
    
    private func updateMemoOnly(objectID: NSManagedObjectID, newMemo: String) {
        //        surfRecordUseCase.fetchSurfRecord(by: objectID)
        //            .flatMap { [weak self] recordOption -> Single<Void> in
        //                guard let self = self, let record = recordOption else {
        //                    return Single.error(RepositoryError.invalidObjectID)
        //                }
        //
        //                let updatedRecord = SurfRecordData(
        //                    beachID: record.beachID,
        //                    id: record.id,
        //                    surfDate: record.surfDate,
        //                    startTime: record.startTime,
        //                    endTime: record.endTime,
        //                    rating: record.rating,
        //                    memo: newMemo,
        //                    isPin: record.isPin,
        //                    charts: record.charts
        //                )
        //
        //                return self.surfRecordUseCase.updateSurfRecord(updatedRecord)
        //            }
        //            .observe(on: MainScheduler.instance)
        //            .subscribe(
        //                onSuccess: { [weak self] in
        //                    NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
        //
        //                    let alertController = UIAlertController(
        //                        title: "메모 저장",
        //                        message: "메모가 저장되었습니다.",
        //                        preferredStyle: .alert
        //                    )
        //                    alertController.addAction(UIAlertAction(title: "확인", style: .default))
        //                    self?.present(alertController, animated: true)
        //                },
        //                onFailure: { [weak self] error in
        //                    self?.presentErrorAlert(message: error.localizedDescription)
        //                }
        //            )
        //            .disposed(by: disposeBag)
    }
    
    private func showMemoDetail(for viewModel: RecordCardViewModel) {
        let memoViewController = MemoDetailViewController(viewModel: viewModel)
        memoViewController.modalPresentationStyle = .pageSheet
        
        if let sheetController = memoViewController.sheetPresentationController {
            sheetController.detents = [.medium(), .large()]
            sheetController.prefersGrabberVisible = true
        }
        
        present(memoViewController, animated: true)
    }
    
    private func presentErrorAlert(message: String) {
        let alertController = UIAlertController(
            title: "오류",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "확인", style: .default))
        present(alertController, animated: true)
    }
    public func resetAllFilters() {
        viewModel.resetToDefaults()
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension RecordHistoryViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }
}
