//
//  BeachChooseViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//
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
    private let storageService: SurfingRecordService = UserDefaultsManager()
    private let lastRegionsIndexKey = "BeachSelectViewController.lastCategoryIndex"
    private var didEmitInitialCategorySelection = false
    private var hasSetInitialSelection = false
    
    private let viewDidLoadSubject = PublishSubject<Void>()
    private let initialRegionSelection = PublishSubject<IndexPath>()
    private let initialBeachSelection = PublishSubject<IndexPath>()
    
    var onBeachSelected: ((BeachDTO) -> Void)?
    
    private lazy var regionDataSource = createRegionDataSource()
    private lazy var beachDataSource = createBeachDataSource()
    
    private var selectedBeachId: String?
    private var selectedBeach: BeachDTO?
    private var currentBeaches: [CategoryDTO] = []
    private var currentRegions: [BeachDTO] = []
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    
    private let regionTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(RegionSelectCell.self, forCellReuseIdentifier: RegionSelectCell.identifier)
        return tv
    }()
    
    private let beachTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = true
        tv.register(BeachSelectCell.self, forCellReuseIdentifier: BeachSelectCell.identifier)
        return tv
    }()
    
    private let confirmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("선택 완료", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.bold)
        b.backgroundColor = .backgroundGray
        b.setTitleColor(.white, for: .normal)
        b.isEnabled = false
        return b
    }()
    
    init(viewModel: BeachSelectViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
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
        let categorySelection = Observable.merge(
            regionTableView.rx.itemSelected.asObservable(),
            initialRegionSelection.asObservable()
        )
        
        let locationSelection = Observable.merge(
            beachTableView.rx.itemSelected.asObservable(),
            initialBeachSelection.asObservable()
        )
        
        let input = BeachSelectViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            categorySelected: categorySelection,
            locationSelected: locationSelection,
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.categories
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (categories: [CategoryDTO]) in
                self?.applyRegions(categories)
            })
            .disposed(by: disposeBag)
        
        output.locations
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (locations: [BeachDTO]) in
                guard let self = self else { return }
                self.applyBeaches(locations)
                
                if !self.hasSetInitialSelection,
                   let initialBeach = self.viewModel.initialSelectedBeach,
                   locations.contains(where: { $0.id == initialBeach.id }) {
                    self.selectedBeachId = initialBeach.id
                    self.selectedBeach = initialBeach
                    self.hasSetInitialSelection = true
                    DispatchQueue.main.async {
                        self.beachTableView.reloadData()
                    }
                } else if self.hasSetInitialSelection {
                    self.selectedBeachId = nil
                    self.selectedBeach = nil
                }
            })
            .disposed(by: disposeBag)
        
        output.selectedCategory
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (index: Int) in
                let indexPath = IndexPath(row: index, section: 0)
                self?.regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                UserDefaults.standard.set(index, forKey: self?.lastRegionsIndexKey ?? "BeachSelectViewController.lastCategoryIndex")
            })
            .disposed(by: disposeBag)
        
        output.canConfirm
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (canConfirm: Bool) in
                self?.confirmButton.isEnabled = canConfirm
                self?.confirmButton.backgroundColor = canConfirm ? .surfBlue : .backgroundGray
            })
            .disposed(by: disposeBag)
        
        output.dismiss
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (selectedLocations: [BeachDTO]) in
                guard let self = self else { return }
                if let selectedBeach = selectedLocations.first {
                    self.onBeachSelected?(selectedBeach)
                    self.storageService.createSelectedBeachID(selectedBeach.id)
                }
                
                let tabBar = self.tabBarController?.tabBar
                tabBar?.isUserInteractionEnabled = false
                self.navigationController?.popViewController(animated: true)
                
                if let coordinator = self.navigationController?.transitionCoordinator {
                    coordinator.animate(alongsideTransition: nil) { _ in
                        tabBar?.isUserInteractionEnabled = true
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        tabBar?.isUserInteractionEnabled = true
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // 사용자가 직접 카테고리를 탭한 경우
        regionTableView.rx.itemSelected
            .skip(1) // 초기 자동 선택 제외
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.hasSetInitialSelection = true
            })
            .disposed(by: disposeBag)
        
        beachTableView.rx.itemSelected
            .asObservable()
            .withLatestFrom(output.locations) { (indexPath: IndexPath, locations: [BeachDTO]) -> BeachDTO? in
                guard indexPath.row < locations.count else { return nil }
                return locations[indexPath.row]
            }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (location: BeachDTO) in
                guard let self = self else { return }
                self.selectedBeachId = location.id
                self.selectedBeach = location
                self.beachTableView.reloadData()
                
                if let selectedIndexPath = self.beachTableView.indexPathForSelectedRow {
                    self.beachTableView.deselectRow(at: selectedIndexPath, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func configureNavigationBar() {
        navigationItem.title = "지역 선택"
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
    
    override func configureAction() {}
    
    private func createRegionDataSource() -> RegionDataSource {
        RegionDataSource(tableView: regionTableView) { [weak self] tableView, indexPath, _ in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RegionSelectCell.identifier, for: indexPath
            ) as? RegionSelectCell else {
                return UITableViewCell()
            }
            if let category = self?.currentBeaches[safe: indexPath.row] {
                cell.configure(with: category)
            }
            return cell
        }
    }
    
    private func createBeachDataSource() -> BeachDataSource {
        let ds = BeachDataSource(tableView: beachTableView) { [weak self] tableView, indexPath, _ in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: BeachSelectCell.identifier, for: indexPath
            ) as? BeachSelectCell else {
                return UITableViewCell()
            }
            if let location = self?.currentRegions[safe: indexPath.row] {
                let isSelected = (self?.selectedBeachId == location.id)
                cell.configure(with: location, isSelected: isSelected)
            }
            return cell
        }
        ds.defaultRowAnimation = .fade
        return ds
    }
    
    private func applyRegions(_ categories: [CategoryDTO]) {
        currentBeaches = categories
        var snapshot = RegionSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(categories.map { $0.id })
        regionDataSource.apply(snapshot, animatingDifferences: false)
        
        if !categories.isEmpty {
            let savedIndex = (UserDefaults.standard.object(forKey: lastRegionsIndexKey) as? Int) ?? 0
            let clampedIndex = max(0, min(savedIndex, categories.count - 1))
            let indexPath = IndexPath(row: clampedIndex, section: 0)
            regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            if !didEmitInitialCategorySelection {
                didEmitInitialCategorySelection = true
                initialRegionSelection.onNext(indexPath)
            }
        }
    }
    
    private func applyBeaches(_ locations: [BeachDTO]) {
        currentRegions = locations
        var snapshot = BeachSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(locations.map { $0.id })
        beachDataSource.apply(snapshot, animatingDifferences: true)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
