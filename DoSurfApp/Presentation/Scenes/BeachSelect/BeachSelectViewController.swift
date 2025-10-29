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

/*
 이 화면은 두 개의 테이블뷰(지역 / 비치)를 가지고 있으며,
 DiffableDataSource + Snapshot 방식을 사용해 데이터 바인딩 및 UI 업데이트를 수행한다.
 RxSwift 바인딩을 통해 선택 이벤트를 ViewModel에 전달하여 상태 관리 및 비즈니스 로직을 분리한다.
 */

// MARK: - Diffable Aliases
// 섹션 타입은 단순 Int로 관리하여 한 섹션만 존재함을 명시
// 아이템 타입은 String (id)로 간단한 키만 사용하여 DiffableDataSource 효율적으로 관리
private typealias RegionDataSource = UITableViewDiffableDataSource<Int, String> // 지역 카테고리용 데이터소스
private typealias BeachDataSource = UITableViewDiffableDataSource<Int, String> // 비치 위치용 데이터소스
private typealias RegionSnapshot = NSDiffableDataSourceSnapshot<Int, String>    // 지역 스냅샷 타입
private typealias BeachSnapshot = NSDiffableDataSourceSnapshot<Int, String>    // 비치 스냅샷 타입

// MARK: - BeachSelectViewController
// 지역/비치 선택 및 마지막 선택 복원 기능을 담당하는 뷰컨트롤러
final class BeachSelectViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel: BeachSelectViewModel // 주입받는 ViewModel
    private let disposeBag = DisposeBag()
    private let storageService: SurfingRecordService = UserDefaultsManager() // 마지막 선택된 비치 id 저장/읽기
    
    // Persist last selected category index
    private let lastRegionsIndexKey = "BeachSelectViewController.lastCategoryIndex" // UserDefaults 키 (마지막 카테고리 인덱스)
    private var didEmitInitialCategorySelection = false // 초기 선택 이벤트 중복 방지 플래그
    
    // Subjects to emit initial selections programmatically
    private let viewDidLoadSubject = PublishSubject<Void>() // viewDidLoad 트리거용
    private let initialRegionSelection = PublishSubject<IndexPath>() // 초기 카테고리 선택 (프로그램적) + 사용자 선택 병합용
    private let initialBeachSelection = PublishSubject<IndexPath>() // 초기 위치 선택 (프로그램적) + 사용자 선택 병합용
    
    var onBeachSelected: ((BeachDTO) -> Void)? // 선택 완료시 콜백
    
    private lazy var regionDataSource = createRegionDataSource()
    private lazy var beachDataSource = createBeachDataSource()
    
    private var selectedBeachId: String? // 현재 선택된 위치 id (하이라이트 용)
    private var selectedBeach: BeachDTO? // 현재 선택된 위치 객체
    private var currentBeaches: [CategoryDTO] = [] // 현재 카테고리 배열 (DiffableDataSource 셀 구성용 백업)
    private var currentRegions: [BeachDTO] = [] // 현재 위치 배열 (DiffableDataSource 셀 구성용 백업)
    
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
        tv.register(RegionSelectCell.self, forCellReuseIdentifier: RegionSelectCell.identifier)
        return tv
    }() // 좌측 지역 테이블뷰 (카테고리 리스트)
    
    private let beachTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = true
        tv.register(BeachSelectCell.self, forCellReuseIdentifier: BeachSelectCell.identifier)
        return tv
    }() // 우측 비치 테이블뷰 (비치 리스트)
    
    private let confirmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("선택 완료", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.bold)
        b.backgroundColor = .backgroundGray
        b.setTitleColor(.white, for: .normal)
        b.isEnabled = false
        return b
    }() // 선택 완료 버튼 (둥글게 처리)
    
    // MARK: - Init
    init(viewModel: BeachSelectViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.onNext(())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 네비게이션 바 보이기
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // confirmButton을 둥글게 처리하는 헬퍼 호출
        confirmButton.applyCornerRadius(makeCircular: true)
    }
    
    // MARK: - Base Overrides
    override func configureUI() {
        view.backgroundColor = .backgroundWhite
        
        view.addSubview(containerView)
        containerView.addSubview(regionTableView)
        containerView.addSubview(beachTableView)
        view.addSubview(confirmButton)
    }
    
    override func configureLayout() {
        // 좌우 테이블뷰 비율 37.5% / 62.5% 분할 레이아웃
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
        /*
         초기 선택 주입 (initialCategorySelection, initialLocationSelection)과
         사용자 테이블뷰 선택 이벤트를 Observable.merge로 합쳐서
         ViewModel에 통합 입력으로 전달하기 위함.
         */
        let categorySelection = Observable.merge(
            regionTableView.rx.itemSelected.asObservable(),
            initialRegionSelection.asObservable()
        )
        
        let locationSelection = Observable.merge(
            beachTableView.rx.itemSelected.asObservable(),
            initialBeachSelection.asObservable()
        )
        
        // ViewModel Input 생성 및 transform 호출
        let input = BeachSelectViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            categorySelected: categorySelection,
            locationSelected: locationSelection,
            confirmButtonTapped: confirmButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        // 카테고리 목록 바인딩 - applyCategories 호출하며 초기 선택 복원 트리거
        output.categories
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (categories: [CategoryDTO]) in
                self?.applyRegions(categories)
            })
            .disposed(by: disposeBag)
        
        // 위치(비치) 목록 바인딩 - applyLocations 호출 후 저장된 비치 선택 복원 시도
        output.locations
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (locations: [BeachDTO]) in
                guard let self = self else { return }
                self.applyBeaches(locations)
                
                // 저장소에서 현재 카테고리 내 저장된 비치 선택 id 복원 시도
                if let savedID = self.storageService.readSelectedBeachID(),
                   let index = locations.firstIndex(where: { $0.id == savedID }) {
                    self.selectedBeachId = savedID
                    self.selectedBeach = locations[index]
                    self.beachTableView.reloadData()
                    
                    let indexPath = IndexPath(row: index, section: 0)
                    // ViewModel 상태 업데이트를 위해 프로그래밍 방식 선택 이벤트 전달
                    self.initialBeachSelection.onNext(indexPath)
                    // UX 향상을 위해 선택된 행으로 스크롤
                    self.beachTableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                } else {
                    // 저장된 선택이 없거나 현재 카테고리에 없으면 선택 상태 초기화
                    self.selectedBeachId = nil
                    self.selectedBeach = nil
                }
            })
            .disposed(by: disposeBag)
        
        // 선택된 카테고리 인덱스 바인딩 - 행 선택 표시 및 UserDefaults에 저장
        output.selectedCategory
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (index: Int) in
                let indexPath = IndexPath(row: index, section: 0)
                self?.regionTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                // 마지막 선택된 카테고리 인덱스 저장 (UserDefaults)
                UserDefaults.standard.set(index, forKey: self?.lastRegionsIndexKey ?? "BeachSelectViewController.lastCategoryIndex")
            })
            .disposed(by: disposeBag)
        
        // 확인 버튼 활성/비활성 토글 및 색상 변경
        output.canConfirm
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (canConfirm: Bool) in
                self?.confirmButton.isEnabled = canConfirm
                self?.confirmButton.backgroundColor = canConfirm ? .surfBlue : .backgroundGray
            })
            .disposed(by: disposeBag)
        
        // 선택 완료 후 처리 - 저장, 탭바 인터랙션 비활성화 후 pop, 완료시 인터랙션 복원
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
        
        // 비치 선택 시 내부 선택 상태 갱신 및 하이라이트 업데이트, 선택 해제 시각적 효과 제공
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
                
                // 선택 해제 (시각적 피드백)
                if let selectedIndexPath = self.beachTableView.indexPathForSelectedRow {
                    self.beachTableView.deselectRow(at: selectedIndexPath, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func configureNavigationBar() {
        // 네비게이션 바 appearance 설정 (배경색 및 타이틀 색상 surfBlue)
        navigationItem.title = "지역 선택"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowColor = .clear
        appearance.backgroundColor = .backgroundWhite
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.surfBlue
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.surfBlue
        ]
        
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
    
    override func configureAction() {
        
    }
    // MARK: - Diffable DataSources
    /// 지역 카테고리용 DiffableDataSource 생성
    /// cellProvider는 indexPath를 통해 현재 카테고리 배열에서 모델 가져와 셀 구성
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
    
    /// 비치 위치용 DiffableDataSource 생성
    /// 현재 선택된 위치 id와 비교하여 셀의 선택/하이라이트 상태 설정
    /// defaultRowAnimation은 fade로 설정하여 변경시 부드러운 애니메이션 적용
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
    
    // MARK: - Snapshot Apply
    /// 카테고리 배열 업데이트 및 스냅샷 적용
    /// 1) 현재 배열 갱신 2) 스냅샷에 섹션과 아이템 추가 3) 애니메이션 없이 적용
    /// 4) UserDefaults에서 마지막 선택된 인덱스 복원 및 범위 클램프 5) 해당 행 선택 표시
    /// 6) 초기 선택 이벤트는 한 번만 ViewModel에 전달
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
    
    /// 위치(비치) 배열 업데이트 및 스냅샷 적용
    /// 1) 배열 갱신 2) 섹션과 아이템 추가 3) 애니메이션과 함께 적용
    private func applyBeaches(_ locations: [BeachDTO]) {
        currentRegions = locations
        var snapshot = BeachSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(locations.map { $0.id })
        beachDataSource.apply(snapshot, animatingDifferences: true)
    }
}

private extension Array {
    /// 안전한 인덱스 접근 헬퍼
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
