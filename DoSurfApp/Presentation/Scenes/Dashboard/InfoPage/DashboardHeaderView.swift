//
//  DashboardChartSectionView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/3/25.
//
import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class DashboardHeaderView: UIView {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - Outputs
    let beachSelectTapped = PublishSubject<Void>()
    let currentPage = BehaviorRelay<Int>(value: 0)
    
    // MARK: - UI Components
    private lazy var beachSelectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("해변 선택", for: .normal)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.tintColor = .white.withAlphaComponent(0.7)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        return button
    }()
    
    private lazy var locationHeaderView: UIView = {
        let view = UIView()
        view.addSubview(beachSelectButton)
        beachSelectButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        return view
    }()
    
    private lazy var statisticsHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.tag = 1001
        titleLabel.text = "선호하는 차트 통계"
        titleLabel.font = .systemFont(ofSize: 21, weight: .bold)
        titleLabel.textColor = .white
        
        let infoButton = UIButton(type: .system)
        infoButton.tag = 1002
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = .white
        
        let seeAllButton = UIButton(type: .system)
        seeAllButton.tag = 1003
        seeAllButton.setTitle("모두 보기", for: .normal)
        seeAllButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        seeAllButton.tintColor = .white
        seeAllButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        seeAllButton.semanticContentAttribute = .forceRightToLeft
        seeAllButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        seeAllButton.isHidden = true
        
        view.addSubview(titleLabel)
        view.addSubview(infoButton)
        view.addSubview(seeAllButton)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        seeAllButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        return view
    }()
    
    private lazy var dashboardPageView: DashboardPageView = {
        let pageView = DashboardPageView()
        return pageView
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .white.withAlphaComponent(0.4)
        pageControl.currentPageIndicatorTintColor = .white
        return pageControl
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureLayout()
        configureBind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    private func configureUI() {
        backgroundColor = .clear
        
        addSubview(locationHeaderView)
        addSubview(statisticsHeaderView)
        addSubview(dashboardPageView)
        addSubview(pageControl)
    }
    
    private func configureLayout() {
        locationHeaderView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(27)
        }
        
        statisticsHeaderView.snp.makeConstraints {
            $0.top.equalTo(locationHeaderView.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(30)
        }
        
        dashboardPageView.snp.makeConstraints {
            $0.top.equalTo(statisticsHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(pageControl.snp.top)
            $0.height.lessThanOrEqualTo(170)
        }
        
        pageControl.snp.makeConstraints {
  
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.lessThanOrEqualTo(44)
        }
    }
    
    private func configureBind() {
        // 해변 선택 버튼 탭
        beachSelectButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: beachSelectTapped)
            .disposed(by: disposeBag)
        
        // 페이지 변경 감지
        dashboardPageView.currentPage
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] page in
                guard let self = self else { return }
                self.pageControl.currentPage = page
                self.updateStatisticsHeader(for: page)
                self.currentPage.accept(page)
            })
            .disposed(by: disposeBag)
        
        // 페이지 컨트롤 터치
        pageControl.rx.controlEvent(.valueChanged)
            .throttle(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let targetPage = self.pageControl.currentPage
                self.dashboardPageView.scrollToPage(targetPage)
                self.updateStatisticsHeader(for: targetPage)
            })
            .disposed(by: disposeBag)
        
        // 초기 상태 설정
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pageControl.currentPage = 0
            self.updateStatisticsHeader(for: 0)
        }
        
        // "모두 보기" 버튼 탭 → 기록 차트 탭으로 이동
        if let seeAllButton = self.statisticsHeaderView.viewWithTag(1003) as? UIButton {
            seeAllButton.addTarget(self, action: #selector(self.handleSeeAllTapped), for: .touchUpInside)
        }
        
        // "정보(Info)" 버튼 탭 → InfoSheetViewController 표시
        if let infoButton = self.statisticsHeaderView.viewWithTag(1002) as? UIButton {
            infoButton.addTarget(self, action: #selector(self.handleInfoTapped), for: .touchUpInside)
        }
    }
    
    // MARK: - Public Methods
    func configurePages(_ pages: [UIView]) {
        dashboardPageView.configure(pages: pages)
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        updateStatisticsHeader(for: 0)
    }
    
    func updateBeachTitle(_ title: String) {
        beachSelectButton.setTitle(title, for: .normal)
    }
    
    func getPage(at index: Int) -> UIView? {
        return dashboardPageView.getPage(at: index)
    }
    
    // MARK: - Private Methods
    private func updateStatisticsHeader(for page: Int) {
        guard let titleLabel = statisticsHeaderView.viewWithTag(1001) as? UILabel,
              let infoButton = statisticsHeaderView.viewWithTag(1002) as? UIButton,
              let seeAllButton = statisticsHeaderView.viewWithTag(1003) as? UIButton else { return }
        
        switch page {
        case 0:
            titleLabel.text = "선호하는 차트 통계"
            infoButton.isHidden = false
            seeAllButton.isHidden = true
            
        case 1:
            titleLabel.text = "최근 기록 차트"
            infoButton.isHidden = true
            seeAllButton.isHidden = false
            
        case 2:
            titleLabel.text = "고정 차트"
            infoButton.isHidden = true
            seeAllButton.isHidden = false
            
        default:
            titleLabel.text = "선호하는 차트 통계"
            infoButton.isHidden = false
            seeAllButton.isHidden = true
        }
        
        UIView.transition(with: statisticsHeaderView, duration: 0.2, options: [.transitionCrossDissolve], animations: {
            self.statisticsHeaderView.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func handleSeeAllTapped() {
        // 1) 탭바에서 "기록 차트" 탭(tag == 2)으로 전환
        if let vc = findViewController(), let tbc = vc.tabBarController {
            if let vcs = tbc.viewControllers, let idx = vcs.firstIndex(where: { $0.tabBarItem.tag == 2 }) {
                tbc.selectedIndex = idx
            } else {
                tbc.selectedIndex = min(2, (tbc.viewControllers?.count ?? 1) - 1)
            }
        }
        // 2) 현재 페이지에 따라 필터 적용 요청 브로드캐스트 (1: 최근 기록 차트 → all, 2: 고정 차트 → pinned)
        let page = currentPage.value
        let filter = (page == 2) ? "pinned" : "all"
        NotificationCenter.default.post(name: .recordHistoryApplyFilterRequested, object: nil, userInfo: ["filter": filter])
    }
    
    @objc private func handleInfoTapped() {
        guard let vc = findViewController() else { return }
        let viewController = InfoSheetViewController()
        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.preferredCornerRadius = 20
        }
        vc.present(viewController, animated: true)
    }

    private func findViewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        while let responder = nextResponder {
            if let vc = responder as? UIViewController { return vc }
            nextResponder = responder.next
        }
        return nil
    }
}
