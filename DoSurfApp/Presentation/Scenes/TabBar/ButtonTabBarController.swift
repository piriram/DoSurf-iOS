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
    
    // State
    private let currentTab = BehaviorRelay<TabType>(value: .chart)
    private let isRecordingScreenPresented = BehaviorRelay<Bool>(value: false)
    
    // Overlay
    private var surfEndOverlay: SurfEndOverlayView?
    
    // MARK: - Initialization
    init(storageService: SurfingRecordService = UserDefaultsManager()) {
        self.storageService = storageService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.storageService = UserDefaultsManager()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInitialViewController()
        bindActions()
        loadSurfingState()
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
    private func bindActions() {
        // Chart Button
        chartButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.switchToTab(.chart)
            })
            .disposed(by: disposeBag)
        
        // Center Button
        centerButton.rx.controlEvent(.touchUpInside)
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.handleCenterButtonTap()
            })
            .disposed(by: disposeBag)
        
        // Record Button
        recordButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                self?.switchToTab(.record)
            })
            .disposed(by: disposeBag)
        
        // Tab State
        currentTab
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] tab in
                self?.updateButtonStates(selectedTab: tab)
            })
            .disposed(by: disposeBag)
        
        // Recording State
        isRecordingScreenPresented
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isRecording in
                self?.centerButton.updateState(isRecording: isRecording)
                let backgroundColor: UIColor = isRecording ? .systemYellow : .systemBackground
                self?.view.backgroundColor = backgroundColor
                self?.containerView.backgroundColor = backgroundColor
            })
            .disposed(by: disposeBag)
    }
    
    private func loadSurfingState() {
        let isRecording = storageService.readSurfingState()
        isRecordingScreenPresented.accept(isRecording)
    }
    
    // MARK: - Tab Switching
    private func switchToTab(_ tab: TabType) {
        guard currentTab.value != tab else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentTab.accept(tab)
        
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
    private func handleCenterButtonTap() {
        if storageService.readSurfingState() {
            showSurfEndOverlay()
        } else {
            startSurfing()
        }
    }
    
    private func startSurfing() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        storageService.createSurfingStartTime(Date())
        storageService.createSurfingState(true)
        isRecordingScreenPresented.accept(true)
    }
    
    private func showSurfEndOverlay() {
        guard surfEndOverlay == nil else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let overlay = SurfEndOverlayView()
        surfEndOverlay = overlay
        
        overlay.onSurfEnd = { [weak self] in
            self?.endSurfing()
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
        storageService.createSurfingEndTime(Date())
        storageService.createSurfingState(false)
        isRecordingScreenPresented.accept(false)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        hideSurfEndOverlay { [weak self] in
            self?.pushToRecordWrite()
        }
    }
    
    private func pushToRecordWrite() {
        let startTime = storageService.readSurfingStartTime()
        let endTime = storageService.readSurfingEndTime()
        let chartsToPass: [Chart] = chartViewController.chartsSnapshot()
        
        let recordVC = DIContainer.shared.makeSurfRecordViewController(
            startTime: startTime,
            endTime: endTime,
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
