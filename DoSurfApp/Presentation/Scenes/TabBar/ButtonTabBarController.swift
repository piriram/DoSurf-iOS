//
//  CustomTabBarController.swift
//  DoSurfApp
//
//  Created by Assistant on 10/16/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - ButtonTabBarController
final class ButtonTabBarController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: ButtonTabBarViewModel
    private let storageService: SurfingRecordService
    private let disposeBag = DisposeBag()
    
    // Container
    private let containerView = UIView()
    
    // Bottom Bar
    let bottomBar = UIView()
    private let chartButton = TabBarButton(type: .chart)
    let centerButton = CenterButton()
    private let recordButton = TabBarButton(type: .record)
    
    // View Controllers
    private lazy var chartViewController: DashboardViewController = {
        let vc = DashboardViewController()
        vc.title = "파도차트"
        return vc
    }()
    
    private lazy var recordViewController: UIViewController = {
        let surfRecordUseCase = DIContainer.shared.makeSurfRecordUseCase()
        let fetchBeachListUseCase = DIContainer.shared.makeFetchBeachListUseCase()
        
        let viewModel = RecordHistoryViewModel(
            surfRecordUseCase: surfRecordUseCase,
            fetchBeachListUseCase: fetchBeachListUseCase,
            storageService: storageService
        )
        
        let vc = RecordHistoryViewController(viewModel: viewModel)
        vc.title = "기록 차트"
        return vc
    }()
    
    
    private var currentNavigationController: UINavigationController?
    
    // Overlay
    private var surfEndOverlay: SurfEndOverlayView?
    private var surfStartOverlay: SurfStartOverlayView?
    
    // MARK: - Initialization
    init(
        viewModel: ButtonTabBarViewModel,
        storageService: SurfingRecordService = UserDefaultsManager()
    ) {
        self.viewModel = viewModel
        self.storageService = storageService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ButtonTabBarViewModel(storageService: UserDefaultsManager())
        self.storageService = UserDefaultsManager()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInitialViewController()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Container (먼저 추가)
        view.addSubview(containerView)
        
        // Bottom Bar
        setupBottomBar()
        
        // Container 제약조건 - 전체 화면 사용 (push된 화면이 하단까지 사용)
        containerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom)
        }
        
        // Center Button을 가장 위로 (다른 뷰들이 덮지 않도록)
        view.bringSubviewToFront(bottomBar)
        view.bringSubviewToFront(centerButton)
    }
    
    private func setupBottomBar() {
        bottomBar.backgroundColor = .systemBackground
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: -1)
        bottomBar.layer.shadowRadius = 4
        bottomBar.layer.shadowOpacity = 0.05
        
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-60)
        }
        
        // Buttons
        bottomBar.addSubview(chartButton)
        bottomBar.addSubview(centerButton)
        bottomBar.addSubview(recordButton)
        
        chartButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(40)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(50)
        }
        
        centerButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(bottomBar.snp.top).offset(-20)
            make.width.height.equalTo(70)
        }
        
        recordButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(50)
        }
    }
    
    private func setupInitialViewController() {
        showViewController(chartViewController)
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        let input = ButtonTabBarViewModel.Input(
            centerButtonTapped: centerButton.rx.controlEvent(.touchUpInside)
                .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
                .asObservable(),
            chartButtonTapped: chartButton.rx.controlEvent(.touchUpInside)
                .asObservable(),
            recordButtonTapped: recordButton.rx.controlEvent(.touchUpInside)
                .asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        // Tab State
        output.currentTab
            .drive(onNext: { [weak self] tab in
                self?.handleTabChange(tab)
            })
            .disposed(by: disposeBag)
        
        // Surfing State
        output.isSurfing
            .drive(onNext: { [weak self] isSurfing in
                self?.centerButton.updateState(isRecording: isSurfing)
                let backgroundColor: UIColor = isSurfing ? .systemYellow : .systemBackground
                self?.view.backgroundColor = backgroundColor
                self?.containerView.backgroundColor = backgroundColor
            })
            .disposed(by: disposeBag)
        
        // Show Start Overlay
        output.shouldShowStartOverlay
            .drive(onNext: { [weak self] _ in
                self?.showSurfStartOverlay()
            })
            .disposed(by: disposeBag)
        
        // Show End Overlay
        output.shouldShowEndOverlay
            .drive(onNext: { [weak self] _ in
                self?.showSurfEndOverlay()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Tab Switching
    private func handleTabChange(_ tab: TabType) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let viewController: UIViewController
        switch tab {
        case .chart:
            viewController = chartViewController
            if let recordVC = recordViewController as? RecordHistoryViewController {
                recordVC.resetAllFilters()
            }
        case .record:
            viewController = recordViewController
            if let recordVC = viewController as? RecordHistoryViewController {
                recordVC.resetAllFilters()
            }
        }
        
        showViewController(viewController)
        updateButtonStates(selectedTab: tab)
    }
    
    private func showViewController(_ viewController: UIViewController) {
        // Remove current
        currentNavigationController?.view.removeFromSuperview()
        currentNavigationController?.removeFromParent()
        
        // Add new
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.delegate = self
        
        addChild(navigationController)
        containerView.addSubview(navigationController.view)
        navigationController.view.frame = containerView.bounds
        navigationController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationController.didMove(toParent: self)
        
        currentNavigationController = navigationController
    }
    
    private func updateButtonStates(selectedTab: TabType) {
        chartButton.setSelected(selectedTab == .chart)
        recordButton.setSelected(selectedTab == .record)
    }
    
    // MARK: - Center Button Actions
    
    private func showSurfEndOverlay() {
        guard surfEndOverlay == nil else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let overlay = SurfEndOverlayView()
        surfEndOverlay = overlay
        
        overlay.onSurfEnd = { [weak self] in
            self?.endSurfing()
        }
        overlay.onCancelSurfing = { [weak self] in
            self?.cancelSurfing()
        }
        overlay.onCancel = { [weak self] in
            self?.hideSurfEndOverlay()
        }
        
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        animateBottomBarVisibility(hidden: true)
        overlay.show()
    }
    
    private func hideSurfEndOverlay(completion: (() -> Void)? = nil) {
        guard let overlay = surfEndOverlay else {
            animateBottomBarVisibility(hidden: false)
            completion?()
            return
        }
        
        animateBottomBarVisibility(hidden: false)
        overlay.hide { [weak self] in
            overlay.removeFromSuperview()
            self?.surfEndOverlay = nil
            completion?()
        }
    }
    
    private func endSurfing() {
        viewModel.endSurfing()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        hideSurfEndOverlay { [weak self] in
            self?.pushToRecordWrite()
        }
    }
    
    private func cancelSurfing() {
        viewModel.cancelSurfing()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        
        hideSurfEndOverlay()
    }
    
    private func pushToRecordWrite() {
        let recordData = viewModel.getRecordData()
        let chartsToPass: [Chart] = chartViewController.chartsSnapshot()
        
        let recordVC = DIContainer.shared.makeSurfRecordViewController(
            startTime: recordData.startTime,
            endTime: recordData.endTime,
            charts: chartsToPass
        )
        recordVC.title = "파도 기록"
        recordVC.hidesBottomBarWhenPushed = true
        
        currentNavigationController?.pushViewController(recordVC, animated: true)
    }
    
    
    private func animateBottomBarVisibility(hidden: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
            self.bottomBar.alpha = hidden ? 0 : 1
        }
    }
    
    // MARK: - Surf Start Overlay
    private func showSurfStartOverlay() {
        guard surfStartOverlay == nil else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let overlay = SurfStartOverlayView()
        surfStartOverlay = overlay
        
        overlay.onSurfStart = { [weak self] in
            self?.handleSurfStart()
        }
        overlay.onRecordDirectly = { [weak self] in
            self?.handleRecordDirectly()
        }
        overlay.onCancel = { [weak self] in
            self?.hideSurfStartOverlay()
        }
        
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        animateBottomBarVisibility(hidden: true)
        overlay.show()
    }
    
    private func hideSurfStartOverlay(completion: (() -> Void)? = nil) {
        guard let overlay = surfStartOverlay else {
            animateBottomBarVisibility(hidden: false)
            completion?()
            return
        }
        
        animateBottomBarVisibility(hidden: false)
        overlay.hide { [weak self] in
            overlay.removeFromSuperview()
            self?.surfStartOverlay = nil
            completion?()
        }
    }
    
    private func handleSurfStart() {
        hideSurfStartOverlay { [weak self] in
            guard let self = self else { return }
            
            // 서핑 상태를 먼저 업데이트 (InteractionImage 전에)
            self.viewModel.startSurfing()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            // InteractionImage 애니메이션 표시
            FullScreenImageAnimator.show(named: "InteractionImage", on: self.view, duration: 2.0) {
                // 애니메이션 완료 (추가 작업 없음)
            }
        }
    }
    
    private func handleRecordDirectly() {
        hideSurfStartOverlay { [weak self] in
            guard let self = self else { return }
            
            // InteractionImage 없이 바로 기록 화면으로 이동
            self.pushToRecordWriteDirectly()
        }
    }
    
    private func pushToRecordWriteDirectly() {
        let chartsToPass: [Chart] = chartViewController.chartsSnapshot()
        
        let recordVC = DIContainer.shared.makeSurfRecordViewController(
            startTime: nil,
            endTime: nil,
            charts: chartsToPass
        )
        recordVC.title = "파도 기록"
        recordVC.hidesBottomBarWhenPushed = true
        
        currentNavigationController?.pushViewController(recordVC, animated: true)
    }
    
}

// MARK: - UINavigationControllerDelegate
extension ButtonTabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let shouldHideBottomBar = viewController.hidesBottomBarWhenPushed
        
        UIView.animate(withDuration: animated ? 0.3 : 0.0, delay: 0, options: [.curveEaseInOut]) {
            self.bottomBar.alpha = shouldHideBottomBar ? 0 : 1
            self.centerButton.alpha = shouldHideBottomBar ? 0 : 1
            
            // 완전히 숨길 때는 터치도 차단
            self.bottomBar.isUserInteractionEnabled = !shouldHideBottomBar
            self.centerButton.isUserInteractionEnabled = !shouldHideBottomBar
        }
    }
}
