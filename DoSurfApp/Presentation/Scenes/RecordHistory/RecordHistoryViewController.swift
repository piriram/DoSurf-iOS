import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CoreData

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
    let viewModel: RecordHistoryViewModel

    // MARK: - Rx
    let disposeBag = DisposeBag()
    let deleteRecordSubject = PublishSubject<NSManagedObjectID>()
    let pinRecordSubject = PublishSubject<NSManagedObjectID>()
    let editRecordSubject = PublishSubject<NSManagedObjectID>()
    let sortSelectionSubject = PublishSubject<SortType>()
    let locationSelectionSubject = PublishSubject<Int?>()
    
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
        
        bindRecords(output: output)
        bindEmptyState(output: output)
        bindLoadingState(output: output)
        bindErrors(output: output)
        bindFilterUpdates(output: output)
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
    
    func scrollToTop(_ animated: Bool = true) {
        let yOffset = -tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: animated)
    }
    
    public func resetAllFilters() {
        viewModel.resetToDefaults()
    }
}

// MARK: - Binding Methods
private extension RecordHistoryViewController {
    
    func bindRecords(output: RecordHistoryViewModel.Output) {
        output.records
            .drive(tableView.rx.items(
                cellIdentifier: RecordHistoryCell.identifier,
                cellType: RecordHistoryCell.self
            )) { [weak self] _, viewModel, cell in
                self?.configureCell(cell, with: viewModel)
            }
            .disposed(by: disposeBag)
    }
    
    func configureCell(_ cell: RecordHistoryCell, with viewModel: RecordCardViewModel) {
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
    
    func bindEmptyState(output: RecordHistoryViewModel.Output) {
        output.isEmpty
            .drive(onNext: { [weak self] isEmpty in
                self?.emptyStateView.isHidden = !isEmpty
                self?.tableView.isHidden = isEmpty
            })
            .disposed(by: disposeBag)
    }
    
    func bindLoadingState(output: RecordHistoryViewModel.Output) {
        output.isLoading
            .drive()
            .disposed(by: disposeBag)
    }
    
    func bindErrors(output: RecordHistoryViewModel.Output) {
        output.error
            .emit(onNext: { [weak self] error in
                self?.showErrorAlert(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    func bindFilterUpdates(output: RecordHistoryViewModel.Output) {
        output.selectedFilter
            .drive(onNext: { [weak self] filter in
                self?.filterView.update(selectedFilter: filter)
                self?.scrollToTop()
            })
            .disposed(by: disposeBag)
        
        output.selectedBeach
            .drive(onNext: { [weak self] beach in
                let title = beach?.displayName ?? "전체 해변"
                self?.filterView.setLocationTitle(title)
            })
            .disposed(by: disposeBag)
        
        output.selectedSort
            .drive(onNext: { [weak self] sortType in
                self?.filterView.setSortTitle(sortType.title)
            })
            .disposed(by: disposeBag)
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
