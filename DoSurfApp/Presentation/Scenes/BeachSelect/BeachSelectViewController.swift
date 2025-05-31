import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Foundation

private typealias RegionDataSource = UITableViewDiffableDataSource<Int, String>
private typealias BeachDataSource = UITableViewDiffableDataSource<Int, String>
private typealias RegionSnapshot = NSDiffableDataSourceSnapshot<Int, String>
private typealias BeachSnapshot = NSDiffableDataSourceSnapshot<Int, String>

final class BeachSelectViewController: BaseViewController {
    
    private let viewModel: BeachSelectViewModel
    private let disposeBag = DisposeBag()
    
    private let viewDidLoadSubject = PublishSubject<Void>()
    
    var onBeachSelected: ((BeachDTO) -> Void)?
    var onAllBeachesSelected: (() -> Void)?
    var showAllButton: Bool = false
    
    private lazy var regionDataSource = createRegionDataSource()
    private lazy var beachDataSource = createBeachDataSource()
    
    private var currentCategories: [CategoryDTO] = []
    private var currentBeaches: [BeachDTO] = []
    private var selectedBeachId: String?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let regionTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(RegionSelectCell.self, forCellReuseIdentifier: RegionSelectCell.identifier)
        return tableView
    }()
    
    private let beachTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.register(BeachSelectCell.self, forCellReuseIdentifier: BeachSelectCell.identifier)
        return tableView
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택 완료", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.bold)
        button.backgroundColor = .backgroundGray
        button.setTitleColor(.white, for: .normal)
        button.isEnabled = false
        return button
    }()
    
    init(viewModel: BeachSelectViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.onNext(())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        confirmButton.applyCornerRadius(makeCircular: true)
    }
    
    override func configureUI() {
        view.backgroundColor = .backgroundWhite
        view.addSubview(containerView)
        containerView.addSubview(regionTableView)
        containerView.addSubview(beachTableView)
        view.addSubview(confirmButton)
    }
    
    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(confirmButton.snp.top).offset(-16)
        }
        
        regionTableView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.375)
        }
        
        beachTableView.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(regionTableView.snp.trailing)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(56)
        }
    }
    
    override func configureBind() {
        let input = BeachSelectViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            categorySelected: regionTableView.rx.itemSelected.asObservable(),
            locationSelected: beachTableView.rx.itemSelected.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.categories
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] categories in
                self?.applyCategories(categories)
            })
            .disposed(by: disposeBag)
        
        output.locations
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] beaches in
                self?.applyBeaches(beaches)
            })
            .disposed(by: disposeBag)
        
        output.selectedCategoryIndex
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] index in
                let indexPath = IndexPath(row: index, section: 0)
                self?.regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            })
            .disposed(by: disposeBag)
        
        output.selectedBeachId
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] beachId in
                self?.selectedBeachId = beachId
            })
            .disposed(by: disposeBag)
        
        output.shouldReloadBeachTable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.beachTableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        output.canConfirm
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] canConfirm in
                self?.updateConfirmButton(isEnabled: canConfirm)
            })
            .disposed(by: disposeBag)
        
        output.dismiss
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selectedBeach in
                self?.handleDismiss(with: selectedBeach)
            })
            .disposed(by: disposeBag)
        
        beachTableView.rx.itemSelected
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] indexPath in
                self?.beachTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    override func configureNavigationBar() {
        navigationItem.title = "지역 선택"
        
        if showAllButton {
            let allButton = UIBarButtonItem(
                title: "전체",
                style: .plain,
                target: self,
                action: #selector(allButtonTapped)
            )
            navigationItem.rightBarButtonItem = allButton
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .clear
        appearance.backgroundColor = .backgroundWhite
        appearance.titleTextAttributes = [.foregroundColor: UIColor.surfBlue]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.surfBlue]
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        if let navBar = navigationController?.navigationBar {
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.compactAppearance = appearance
            navBar.tintColor = .surfBlue
        }
    }
    
    @objc private func allButtonTapped() {
        onAllBeachesSelected?()
        
        let tabBar = tabBarController?.tabBar
        tabBar?.isUserInteractionEnabled = false
        navigationController?.popViewController(animated: true)
        
        if let coordinator = navigationController?.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                tabBar?.isUserInteractionEnabled = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                tabBar?.isUserInteractionEnabled = true
            }
        }
    }
    
    override func configureAction() {}
    
    // MARK: - Private Methods
    private func createRegionDataSource() -> RegionDataSource {
        RegionDataSource(tableView: regionTableView) { [weak self] tableView, indexPath, _ in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RegionSelectCell.identifier,
                for: indexPath
            ) as? RegionSelectCell else {
                return UITableViewCell()
            }
            
            if let category = self?.currentCategories[safe: indexPath.row] {
                cell.configure(with: category)
            }
            return cell
        }
    }
    
    private func createBeachDataSource() -> BeachDataSource {
        let dataSource = BeachDataSource(tableView: beachTableView) { [weak self] tableView, indexPath, _ in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: BeachSelectCell.identifier,
                for: indexPath
            ) as? BeachSelectCell else {
                return UITableViewCell()
            }
            
            if let beach = self?.currentBeaches[safe: indexPath.row] {
                let isSelected = (self?.selectedBeachId == beach.id)
                cell.configure(with: beach, isSelected: isSelected)
            }
            return cell
        }
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }
    
    private func applyCategories(_ categories: [CategoryDTO]) {
        currentCategories = categories
        var snapshot = RegionSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(categories.map { $0.id })
        regionDataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func applyBeaches(_ beaches: [BeachDTO]) {
        currentBeaches = beaches
        var snapshot = BeachSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(beaches.map { $0.id })
        beachDataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func updateConfirmButton(isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
        confirmButton.backgroundColor = isEnabled ? .surfBlue : .backgroundGray
    }
    
    private func handleDismiss(with selectedBeach: BeachDTO) {
        onBeachSelected?(selectedBeach)
        
        let tabBar = tabBarController?.tabBar
        tabBar?.isUserInteractionEnabled = false
        navigationController?.popViewController(animated: true)
        
        if let coordinator = navigationController?.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                tabBar?.isUserInteractionEnabled = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                tabBar?.isUserInteractionEnabled = true
            }
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
