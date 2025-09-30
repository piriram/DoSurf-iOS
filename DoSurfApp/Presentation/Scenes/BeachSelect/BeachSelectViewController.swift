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

// MARK: - DTOs
struct CategoryDTO: Sendable {
    let id: String
    let name: String
}

struct LocationDTO: Sendable {
    let id: String
    let categoryId: String
    let region: String
    let place: String
    
    var displayText: String {
        return "\(place)"
    }
    
    var passText: String {
        return "\(region) \(place)"
    }
}

// MARK: - Nonisolated conformances for Diffable Data Source
nonisolated extension CategoryDTO: Hashable {}
nonisolated extension LocationDTO: Hashable {}

// MARK: - ViewController
final class BeachSelectViewController: BaseViewController {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let regionTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(RegionCategoryCell.self, forCellReuseIdentifier: RegionCategoryCell.identifier)
        return tableView
    }()
    
    private let beachTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(BeachCategoryCell.self, forCellReuseIdentifier: BeachCategoryCell.identifier)
        return tableView
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택 완료", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .backgroundGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 26
        return button
    }()
    
    // MARK: - Properties
    private let viewModel: BeachSelectViewModel
    private let disposeBag = DisposeBag()
    
    private typealias CategoryDataSource = UITableViewDiffableDataSource<Int, CategoryDTO>
    private typealias LocationDataSource = UITableViewDiffableDataSource<Int, LocationDTO>
    
    private lazy var categoryDataSource = createCategoryDataSource()
    private lazy var locationDataSource = createLocationDataSource()
    
    private var selectedLocationId: String? = nil
    
    // MARK: - Initialize
    init(viewModel: BeachSelectViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure the navigation bar is visible when this view appears
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Setup
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
    
    // MARK: - Bind
    override func configureBind() {
        let input = BeachSelectViewModel.Input(
            categorySelected: regionTableView.rx.itemSelected.asObservable(),
            locationSelected: beachTableView.rx.itemSelected.asObservable(),
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        // 카테고리 목록 바인딩
        output.categories
            .subscribe(onNext: { [weak self] categories in
                self?.applyCategories(categories)
            })
            .disposed(by: disposeBag)
        
        // 지역 목록 바인딩
        output.locations
            .subscribe(onNext: { [weak self] locations in
                self?.applyLocations(locations)
            })
            .disposed(by: disposeBag)
        
        // 선택된 카테고리 하이라이트
        output.selectedCategory
            .subscribe(onNext: { [weak self] index in
                let indexPath = IndexPath(row: index, section: 0)
                self?.regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            })
            .disposed(by: disposeBag)
        
        // 확인 버튼 활성화
        output.canConfirm
            .subscribe(onNext: { [weak self] canConfirm in
                self?.confirmButton.isEnabled = canConfirm
                self?.confirmButton.backgroundColor = canConfirm ? .surfBlue : .backgroundGray
            })
            .disposed(by: disposeBag)
        
        // 확인 버튼 탭 처리 (전환 동안 탭 바 터치 비활성화)
        output.dismiss
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selectedLocations in
                guard let self = self else { return }
                // 선택된 지역 정보 전달 등 필요한 작업
                print("Selected locations: \(selectedLocations)")
                
                // 전환 동안 탭 바 터치 비활성화
                let tabBar = self.tabBarController?.tabBar
                tabBar?.isUserInteractionEnabled = false
                
                self.navigationController?.popViewController(animated: true)
                
                if let coordinator = self.navigationController?.transitionCoordinator {
                    coordinator.animate(alongsideTransition: nil) { _ in
                        tabBar?.isUserInteractionEnabled = true
                    }
                } else {
                    // 전환 코디네이터가 없을 경우를 대비한 안전장치
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        tabBar?.isUserInteractionEnabled = true
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // 지역 단일 선택: 텍스트 파란색으로 표시
        beachTableView.rx.itemSelected
            .withLatestFrom(output.locations) { indexPath, locations -> (IndexPath, LocationDTO)? in
                guard indexPath.row < locations.count else { return nil }
                return (indexPath, locations[indexPath.row])
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] indexPath, location in
                guard let self = self else { return }
                self.selectedLocationId = location.id
                self.beachTableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        // 지역 선택 해제 처리
        beachTableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.beachTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - DataSource
    private func createCategoryDataSource() -> CategoryDataSource {
        return CategoryDataSource(tableView: regionTableView) { tableView, indexPath, category in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RegionCategoryCell.identifier,
                for: indexPath
            ) as? RegionCategoryCell else {
                return UITableViewCell()
            }
            cell.configure(with: category)
            return cell
        }
    }
    
    private func createLocationDataSource() -> LocationDataSource {
        return LocationDataSource(tableView: beachTableView) { [weak self] tableView, indexPath, location in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: BeachCategoryCell.identifier,
                for: indexPath
            ) as? BeachCategoryCell else {
                return UITableViewCell()
            }
            let isSelected = (self?.selectedLocationId == location.id)
            cell.configure(with: location, isSelected: isSelected)
            return cell
        }
    }
    
    private func applyCategories(_ categories: [CategoryDTO]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CategoryDTO>()
        snapshot.appendSections([0])
        snapshot.appendItems(categories)
        categoryDataSource.apply(snapshot, animatingDifferences: false)
        
        // 첫 번째 항목 자동 선택
        if !categories.isEmpty {
            let indexPath = IndexPath(row: 0, section: 0)
            regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    private func applyLocations(_ locations: [LocationDTO]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, LocationDTO>()
        snapshot.appendSections([0])
        snapshot.appendItems(locations)
        locationDataSource.apply(snapshot, animatingDifferences: true)
    }
}

