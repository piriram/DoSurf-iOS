//
//  RecordFilterView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//


// =============================================
// RecordFilterView.swift
// =============================================
import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol RecordFilterViewDelegate: AnyObject {
    func didTapLocation()
    func didChangeFilter(_ filter: RecordFilter)
    func didTapSort()
}

/// 상단 필터 전용 뷰 (위치/필터/정렬)
final class RecordFilterView: UIView {
    // MARK: - UI
    private let container = UIView()
    private let locationButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("전체 해변", for: .normal)
        b.setTitleColor(.black.withAlphaComponent(0.7), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.semibold)
        b.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        b.tintColor = .label
        b.semanticContentAttribute = .forceRightToLeft
        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        return b
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return sv
    }()
    private let stack = UIStackView()
    
    // Buttons
    private let allFilterButton = FilterButton(title: "전체")
    private let pinnedFilterButton = FilterButton(title: "핀 고정")
    private let dateFilterButton = FilterButton(title: "날짜 선택")
    private let ratingFilterButton = FilterButton(title: "별점", hasDropdown: true)
    private let sortButton = FilterButton(title: "최신순", hasDropdown: true)
    
    // MARK: - Outputs
    weak var delegate: RecordFilterViewDelegate?
    
    // Rx outputs (옵션: VC에서 합쳐 쓰기 좋게 노출)
    var tapAll: ControlEvent<Void> { allFilterButton.rx.tap }
    var tapPinned: ControlEvent<Void> { pinnedFilterButton.rx.tap }
    var tapDate: ControlEvent<Void> { dateFilterButton.rx.tap }
    var tapRating: ControlEvent<Void> { ratingFilterButton.rx.tap }
    var tapSort: ControlEvent<Void> { sortButton.rx.tap }
    var tapLocation: ControlEvent<Void> { locationButton.rx.tap }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Public API
    func setLocationTitle(_ title: String) {
        locationButton.setTitle(title, for: .normal)
    }
    
    func setSortTitle(_ title: String) {
        sortButton.setTitle(title, for: .normal)
    }
    
    func update(selectedFilter: RecordFilter) {
        allFilterButton.isSelected = (selectedFilter == .all)
        pinnedFilterButton.isSelected = (selectedFilter == .pinned)
        
        switch selectedFilter {
        case .datePreset(let preset):
            dateFilterButton.isSelected = true
            let title: String
            switch preset {
            case .today: title = "오늘"
            case .last7Days: title = "최근 7일"
            case .thisMonth: title = "이번 달"
            case .lastMonth: title = "지난 달"
            }
            dateFilterButton.setTitle(title, for: .normal)
            ratingFilterButton.isSelected = false
            ratingFilterButton.setTitle("별점", for: .normal)
        case .dateRange(let start, let end):
            dateFilterButton.isSelected = true
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy.MM.dd"
            dateFilterButton.setTitle("\(fmt.string(from: start)) - \(fmt.string(from: end))", for: .normal)
            ratingFilterButton.isSelected = false
            ratingFilterButton.setTitle("별점", for: .normal)
        case .rating(let r):
            ratingFilterButton.isSelected = true
            ratingFilterButton.setTitle("\(r)점", for: .normal)
            dateFilterButton.isSelected = false
            dateFilterButton.setTitle("날짜 선택", for: .normal)
        case .all, .pinned:
            dateFilterButton.isSelected = false
            dateFilterButton.setTitle("날짜 선택", for: .normal)
            ratingFilterButton.isSelected = false
            ratingFilterButton.setTitle("별점", for: .normal)
        }
    }
    
    func resetAll() {
        setSortTitle("최신순")
        update(selectedFilter: .all)
    }
    
    // MARK: - UI
    private func setupUI() {
        backgroundColor = .backgroundWhite
        addSubview(container)
        addSubview(scrollView)
        scrollView.addSubview(stack)
        
        container.addSubview(locationButton)
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .equalSpacing
        
        [allFilterButton, pinnedFilterButton, dateFilterButton, ratingFilterButton, sortButton].forEach { stack.addArrangedSubview($0) }
        
        // Layout
        container.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(32)
        }
        locationButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(container.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(28)
            make.bottom.equalToSuperview() // intrinsic height = header + 12 + 28
        }
        stack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        // Actions to delegate (optional; VC는 Rx로도 받을 수 있음)
        locationButton.addTarget(self, action: #selector(_didTapLocation), for: .touchUpInside)
        sortButton.addTarget(self, action: #selector(_didTapSort), for: .touchUpInside)
    }
    
    @objc private func _didTapLocation() { delegate?.didTapLocation() }
    @objc private func _didTapSort() { delegate?.didTapSort() }
}





// =============================================
// (옵션) ViewModel에 beach 이름까지 옮기고 싶다면 Output 확장 예시
//  * 실제 적용 시, FetchBeachListUseCase를 주입받아야 함.
//  * 아래는 참고용 스니펫이며, 현재 프로젝트 파일과 동기화해 적용하세요.
// =============================================
/*
 extension RecordHistoryViewModel {
 struct ExtendedOutput {
 let selectedBeachName: Driver<String>
 }
 }
 */
