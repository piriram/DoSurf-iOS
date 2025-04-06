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

nonisolated extension CategoryDTO: Hashable {}

struct LocationDTO: Sendable {
    let id: String
    let categoryId: String
    let region: String
    let place: String
    
    var displayText: String {
        return "\(region) \(place)"
    }
}

nonisolated extension LocationDTO: Hashable {}

// MARK: - ViewModel
final class BeachChooseViewModel {
    
    // MARK: - Input
    struct Input {
        let categorySelected: Observable<IndexPath>
        let locationSelected: Observable<IndexPath>
        let confirmButtonTapped: Observable<Void>
    }
    
    // MARK: - Output
    struct Output {
        let categories: Observable<[CategoryDTO]>
        let locations: Observable<[LocationDTO]>
        let selectedCategory: Observable<Int>
        let canConfirm: Observable<Bool>
        let dismiss: Observable<[LocationDTO]>
    }
    
    // MARK: - Properties
    private let categories = BehaviorRelay<[CategoryDTO]>(value: [])
    private let locations = BehaviorRelay<[LocationDTO]>(value: [])
    private let selectedCategoryIndex = BehaviorRelay<Int>(value: 0)
    private let selectedLocations = BehaviorRelay<Set<String>>(value: [])
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialize
    init() {
        setupMockData()
    }
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        
        // 카테고리 선택 처리
        input.categorySelected
            .map { $0.row }
            .bind(to: selectedCategoryIndex)
            .disposed(by: disposeBag)
        
        // 선택된 카테고리에 따른 지역 목록 필터링
        let filteredLocations = selectedCategoryIndex
            .withLatestFrom(categories) { index, categories in
                guard index < categories.count else { return "" }
                return categories[index].id
            }
            .map { [weak self] categoryId -> [LocationDTO] in
                guard let self = self else { return [] }
                return self.locations.value.filter { $0.categoryId == categoryId }
            }
            .asObservable()
        
        // 지역 선택 처리
        input.locationSelected
            .withLatestFrom(filteredLocations) { indexPath, locations -> LocationDTO? in
                guard indexPath.row < locations.count else { return nil }
                return locations[indexPath.row]
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] location in
                // 단일 선택: 선택한 항목만 유지
                self?.selectedLocations.accept([location.id])
            })
            .disposed(by: disposeBag)
        
        // 확인 버튼 활성화 여부
        let canConfirm = selectedLocations
            .map { !$0.isEmpty }
            .asObservable()
        
        // 확인 버튼 탭 처리
        let dismiss = input.confirmButtonTapped
            .withLatestFrom(Observable.combineLatest(locations, selectedLocations))
            .map { locations, selectedIds in
                locations.filter { selectedIds.contains($0.id) }
            }
        
        return Output(
            categories: categories.asObservable(),
            locations: filteredLocations,
            selectedCategory: selectedCategoryIndex.asObservable(),
            canConfirm: canConfirm,
            dismiss: dismiss
        )
    }
    
    // MARK: - Mock Data
    private func setupMockData() {
        let mockCategories = [
            CategoryDTO(id: "yangyang", name: "양양"),
            CategoryDTO(id: "jeju", name: "제주"),
            CategoryDTO(id: "busan", name: "부산"),
            CategoryDTO(id: "goseong", name: "고성/속초"),
            CategoryDTO(id: "incheon", name: "인천/충청/강원"),
            CategoryDTO(id: "pohang", name: "포항/울산"),
            CategoryDTO(id: "jinhae", name: "지해/남해")
        ]
        
        let mockLocations = [
            LocationDTO(id: "1", categoryId: "yangyang", region: "양양", place: "죽도서핑비치"),
            LocationDTO(id: "2", categoryId: "yangyang", region: "양양", place: "죽도해변 C"),
            LocationDTO(id: "3", categoryId: "yangyang", region: "양양", place: "인구해변"),
            LocationDTO(id: "4", categoryId: "yangyang", region: "양양", place: "기사문해변A"),
            LocationDTO(id: "5", categoryId: "yangyang", region: "양양", place: "기사문해변B"),
            LocationDTO(id: "6", categoryId: "yangyang", region: "양양", place: "기사문해변"),
            LocationDTO(id: "7", categoryId: "yangyang", region: "양양", place: "남애해변파워A"),
            LocationDTO(id: "8", categoryId: "yangyang", region: "양양", place: "플라자해변"),
            LocationDTO(id: "9", categoryId: "yangyang", region: "양양", place: "싱잉타워해변"),
            LocationDTO(id: "10", categoryId: "yangyang", region: "양양", place: "동산해변"),
            LocationDTO(id: "11", categoryId: "yangyang", region: "양양", place: "하조대해변"),
        ]
        
        categories.accept(mockCategories)
        locations.accept(mockLocations)
    }
}

// MARK: - ViewController
final class BeachChooseViewController: UIViewController {
    
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
        tableView.register(LocationCell.self, forCellReuseIdentifier: LocationCell.identifier)
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
    private let viewModel: BeachChooseViewModel
    private let disposeBag = DisposeBag()
    
    private typealias CategoryDataSource = UITableViewDiffableDataSource<Int, CategoryDTO>
    private typealias LocationDataSource = UITableViewDiffableDataSource<Int, LocationDTO>
    
    private lazy var categoryDataSource = createCategoryDataSource()
    private lazy var locationDataSource = createLocationDataSource()
    
    private var selectedLocationId: String? = nil
    
    // MARK: - Initialize
    init(viewModel: BeachChooseViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure navigation bar is visible when this screen appears
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if title == nil || title?.isEmpty == true {
            title = "해변 선택"
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(containerView)
        containerView.addSubview(categoryTableView)
        containerView.addSubview(locationTableView)
        view.addSubview(confirmButton)
        
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
    private func bind() {
        let input = BeachChooseViewModel.Input(
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
                withIdentifier: LocationCell.identifier,
                for: indexPath
            ) as? LocationCell else {
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

// MARK: - LocationCell
final class LocationCell: UITableViewCell {
    static let identifier = "LocationCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        return label
    }()
    
    private let checkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.isHidden = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkImageView)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(checkImageView.snp.leading).offset(-8)
            $0.top.bottom.equalToSuperview().inset(12)
        }
        
        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
    }
    
    func configure(with location: LocationDTO, isSelected: Bool) {
        titleLabel.text = location.displayText
        titleLabel.textColor = isSelected ? .systemBlue : .label
        titleLabel.font = isSelected ? .systemFont(ofSize: 15, weight: .semibold) : .systemFont(ofSize: 15)
        // 체크박스는 사용하지 않음
        checkImageView.isHidden = true
    }
}
