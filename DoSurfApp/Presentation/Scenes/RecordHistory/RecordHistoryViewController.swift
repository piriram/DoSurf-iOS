import UIKit
import RxSwift
import RxCocoa
import RxRelay
import SnapKit
import CoreData

// MARK: - RecordHistoryViewController
final class RecordHistoryViewController: BaseViewController {
    
    // MARK: - UI Components
    private let locationButton: UIButton = {
        let button = UIButton()
        button.setTitle(SurfBeach.songjeong.displayName, for: .normal)
        button.setTitleColor(.label, for: .normal)
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
    private let weatherFilterButton = FilterButton(title: "날씨 선택")
    private let ratingFilterButton = FilterButton(title: "별점", hasDropdown: true)
    private let sortButton = FilterButton(title: "최신순", hasDropdown: true)
    
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
    
    private let selectedBeachIDRelay = BehaviorRelay<Int>(value: SurfBeach.songjeong.rawValue)
    
    // MARK: - Initializer
    init(viewModel: RecordHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
         ratingFilterButton, sortButton].forEach {
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
            $0.height.equalTo(48)
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
                weatherFilterButton.rx.tap.map { RecordFilter.weather }
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
                    self?.showMemoDetail(for: viewModel)
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
        weatherFilterButton.isSelected = (selectedFilter == .weather)
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
    
    private func showLocationSelector() {
        let alertController = UIAlertController(
            title: "장소 선택",
            message: nil,
            preferredStyle: .actionSheet
        )
        SurfBeach.allCases.forEach { beach in
            let action = UIAlertAction(title: beach.displayName, style: .default) { [weak self] _ in
                self?.locationButton.setTitle(beach.displayName, for: .normal)
                self?.selectedBeachIDRelay.accept(beach.rawValue)
            }
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
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
            message: "별점을 선택하세요",
            preferredStyle: .actionSheet
        )
        
        for rating in (1...5).reversed() {
            let stars = String(repeating: "⭐", count: rating)
            let action = UIAlertAction(title: "\(stars) \(rating)점 이상", style: .default) { _ in
                // Handle rating filter
            }
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "전체", style: .default))
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
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
        
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        if hasDropdown {
            setImage(UIImage(systemName: "chevron.down"), for: .normal)
            semanticContentAttribute = .forceRightToLeft
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            tintColor = .label
        }
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .surfBlue : .secondarySystemBackground
            tintColor = isSelected ? .white : .label
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

