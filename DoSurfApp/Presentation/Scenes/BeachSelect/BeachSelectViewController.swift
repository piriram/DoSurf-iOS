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
    
    // TODO: 이페이지에서 보이는 네임과 대시보드에서 보이는 네임 다르게 하기
    var displayText: String {
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
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let categoryTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .systemGray6
        tableView.separatorStyle = .none
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
        return tableView
    }()
    
    private let locationTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.register(BeachCategoryCell.self, forCellReuseIdentifier: BeachCategoryCell.identifier)
        return tableView
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("설명 받기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
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
    
    // MARK: - Setup
    override func configureUI() {
        view.addSubview(containerView)
        containerView.addSubview(categoryTableView)
        containerView.addSubview(locationTableView)
        view.addSubview(confirmButton)
    }
    
    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-16)
        }
        
        categoryTableView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.3)
        }
        
        locationTableView.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(categoryTableView.snp.trailing)
        }
        
        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.height.equalTo(52)
        }
    }
    
    // MARK: - Bind
    override func configureBind() {
        let input = BeachSelectViewModel.Input(
            categorySelected: categoryTableView.rx.itemSelected.asObservable(),
            locationSelected: locationTableView.rx.itemSelected.asObservable(),
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
                self?.categoryTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            })
            .disposed(by: disposeBag)
        
        // 확인 버튼 활성화
        output.canConfirm
            .subscribe(onNext: { [weak self] canConfirm in
                self?.confirmButton.isEnabled = canConfirm
                self?.confirmButton.backgroundColor = canConfirm ? .systemBlue : .systemGray5
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
        locationTableView.rx.itemSelected
            .withLatestFrom(output.locations) { indexPath, locations -> (IndexPath, LocationDTO)? in
                guard indexPath.row < locations.count else { return nil }
                return (indexPath, locations[indexPath.row])
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] indexPath, location in
                guard let self = self else { return }
                self.selectedLocationId = location.id
                self.locationTableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        // 지역 선택 해제 처리
        locationTableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.locationTableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - DataSource
    private func createCategoryDataSource() -> CategoryDataSource {
        return CategoryDataSource(tableView: categoryTableView) { tableView, indexPath, category in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: CategoryCell.identifier,
                for: indexPath
            ) as? CategoryCell else {
                return UITableViewCell()
            }
            cell.configure(with: category)
            return cell
        }
    }
    
    private func createLocationDataSource() -> LocationDataSource {
        return LocationDataSource(tableView: locationTableView) { [weak self] tableView, indexPath, location in
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
            categoryTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    private func applyLocations(_ locations: [LocationDTO]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, LocationDTO>()
        snapshot.appendSections([0])
        snapshot.appendItems(locations)
        locationDataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - CategoryCell
final class CategoryCell: UITableViewCell {
    static let identifier = "CategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            return view
        }()
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(12)
        }
    }
    
    func configure(with category: CategoryDTO) {
        titleLabel.text = category.name
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        titleLabel.textColor = selected ? .systemBlue : .label
        titleLabel.font = selected ? .systemFont(ofSize: 15, weight: .bold) : .systemFont(ofSize: 15, weight: .medium)
    }
}


