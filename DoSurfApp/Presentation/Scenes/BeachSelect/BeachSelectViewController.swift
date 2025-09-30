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

// MARK: - Diffable Aliases
private typealias CategoryDataSource = UITableViewDiffableDataSource<Int, String>
private typealias LocationDataSource = UITableViewDiffableDataSource<Int, String>
private typealias CategorySnapshot = NSDiffableDataSourceSnapshot<Int, String>
private typealias LocationSnapshot = NSDiffableDataSourceSnapshot<Int, String>

// MARK: - BeachSelectViewController
final class BeachSelectViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: BeachSelectViewModel
    private let disposeBag = DisposeBag()

    var onBeachSelected: ((String) -> Void)?

    private lazy var categoryDataSource = createCategoryDataSource()
    private lazy var locationDataSource = createLocationDataSource()

    private var selectedLocationId: String?
    private var currentCategories: [CategoryDTO] = []
    private var currentLocations: [LocationDTO] = []

    // MARK: - UI
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
        tv.register(RegionCategoryCell.self, forCellReuseIdentifier: RegionCategoryCell.identifier)
        return tv
    }()

    private let beachTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = true
        tv.register(BeachCategoryCell.self, forCellReuseIdentifier: BeachCategoryCell.identifier)
        return tv
    }()

    private let confirmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("선택 완료", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.backgroundColor = .backgroundGray
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 26
        b.isEnabled = false
        return b
    }()

    // MARK: - Init
    init(viewModel: BeachSelectViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Base Overrides
    override func configureUI() {
        view.backgroundColor = .backgroundWhite
        navigationItem.title = "지역 선택"

        view.addSubview(containerView)
        containerView.addSubview(regionTableView)
        containerView.addSubview(beachTableView)
        view.addSubview(confirmButton)
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-16)
        }

        regionTableView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.375)
        }

        beachTableView.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(regionTableView.snp.trailing)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.height.equalTo(56)
        }
    }

    override func configureBind() {
        let input = BeachSelectViewModel.Input(
            categorySelected: regionTableView.rx.itemSelected.asObservable(),
            locationSelected: beachTableView.rx.itemSelected.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 카테고리 목록
        output.categories
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] categories in
                self?.applyCategories(categories)
            })
            .disposed(by: disposeBag)

        // 위치(비치) 목록
        output.locations
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] locations in
                self?.applyLocations(locations)
            })
            .disposed(by: disposeBag)

        // 선택된 카테고리 인덱스
        output.selectedCategory
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] index in
                let indexPath = IndexPath(row: index, section: 0)
                self?.regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            })
            .disposed(by: disposeBag)

        // 확인 버튼 활성/비활성
        output.canConfirm
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] canConfirm in
                self?.confirmButton.isEnabled = canConfirm
                self?.confirmButton.backgroundColor = canConfirm ? .surfBlue : .backgroundGray
            })
            .disposed(by: disposeBag)

        // 닫기(확정)
        output.dismiss
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selectedLocations in
                guard let self = self else { return }
                if let selectedBeachId = selectedLocations.first?.id {
                    self.onBeachSelected?(selectedBeachId)
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

        // 비치 선택 → 하이라이트/선택 상태 갱신
        beachTableView.rx.itemSelected
            .withLatestFrom(output.locations) { indexPath, locations -> (IndexPath, LocationDTO)? in
                guard indexPath.row < locations.count else { return nil }
                return (indexPath, locations[indexPath.row])
            }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] indexPath, location in
                guard let self = self else { return }
                self.selectedLocationId = location.id
                self.beachTableView.reloadData()
                self.beachTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Diffable DataSources
    private func createCategoryDataSource() -> CategoryDataSource {
        CategoryDataSource(tableView: regionTableView) { [weak self] tableView, indexPath, _ in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RegionCategoryCell.identifier, for: indexPath
            ) as? RegionCategoryCell else {
                return UITableViewCell()
            }
            if let category = self?.currentCategories[safe: indexPath.row] {
                cell.configure(with: category)
            }
            return cell
        }
    }

    private func createLocationDataSource() -> LocationDataSource {
        LocationDataSource(tableView: beachTableView) { [weak self] tableView, indexPath, _ in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: BeachCategoryCell.identifier, for: indexPath
            ) as? BeachCategoryCell else {
                return UITableViewCell()
            }
            if let location = self?.currentLocations[safe: indexPath.row] {
                let isSelected = (self?.selectedLocationId == location.id)
                cell.configure(with: location, isSelected: isSelected)
            }
            return cell
        }
    }

    // MARK: - Snapshot Apply
    private func applyCategories(_ categories: [CategoryDTO]) {
        currentCategories = categories
        var snapshot = CategorySnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(categories.map { $0.id })
        categoryDataSource.apply(snapshot, animatingDifferences: false)

        if !categories.isEmpty {
            let indexPath = IndexPath(row: 0, section: 0)
            regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }

    private func applyLocations(_ locations: [LocationDTO]) {
        currentLocations = locations
        var snapshot = LocationSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(locations.map { $0.id })
        locationDataSource.apply(snapshot, animatingDifferences: true)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
