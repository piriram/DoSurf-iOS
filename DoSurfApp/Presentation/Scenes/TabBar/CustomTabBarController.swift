//
//  CustomTabBarController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/28/25.
//
import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - CustomTabBarController
class CustomTabBarController: BaseTabBarController {
    
    // MARK: - Properties
    private let customTabBar: CustomTabBar
    private let storageService: SurfingRecordService
    private let disposeBag = DisposeBag()
    
    // iOS 26+ 플로팅 버튼
    private var floatingCenterButton: FloatingCenterButton?
    
    // 기록 화면 표시 여부 추적
    let isRecordingScreenPresented = BehaviorRelay<Bool>(value: false)
    private weak var dashboardProvider: (UIViewController & DashboardChartProviding)?
    
    // 서핑 종료 오버레이
    private var surfEndOverlay: SurfEndOverlayView?
    
    // MARK: - Initialization
    init(storageService: SurfingRecordService = UserDefaultsService()) {
        self.storageService = storageService
        self.customTabBar = CustomTabBar(storageService: storageService)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.storageService = UserDefaultsService()
        self.customTabBar = CustomTabBar(storageService: self.storageService)
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func configureUI() {
        super.configureUI()
        setupCustomTabBar()
        setupViewControllers()
        setupFloatingButtonIfNeeded()
    }
    
    override func configureBind() {
        super.configureBind()
        bindCenterButton()
        setupTabBarDelegate()
    }
    
    // MARK: - Setup
    private func setupCustomTabBar() {
        setValue(customTabBar, forKey: "tabBar")
        delegate = self
    }
    
    private func setupFloatingButtonIfNeeded() {
        if #available(iOS 26.0, *) {
            // iOS 26+에서는 플로팅 버튼 사용
            customTabBar.hideCenterButton()
            
            let floatingButton = FloatingCenterButton(storageService: storageService)
            self.floatingCenterButton = floatingButton
            view.addSubview(floatingButton)
            
            floatingButton.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
                make.width.height.equalTo(67)
            }
            
            floatingButton.centerButtonTapped
                .subscribe(onNext: { [weak self] in
                    self?.handleCenterButtonTap()
                })
                .disposed(by: disposeBag)
            
            isRecordingScreenPresented
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] isSelected in
                    self?.floatingCenterButton?.updateButtonState(isSelected: isSelected)
                })
                .disposed(by: disposeBag)
        }
    }
    
    private func setupViewControllers() {
        // 파도차트
        let chartVC = createChartViewController()
        if let provider = chartVC as? (UIViewController & DashboardChartProviding) {
            self.dashboardProvider = provider
        }
        let chartNav = UINavigationController(rootViewController: chartVC)
        chartNav.tabBarItem = UITabBarItem(
            title: "파도차트",
            image: UIImage(named: AssetImage.chartSymbol),
            selectedImage: UIImage(named: AssetImage.chartSymbolFill)
        )
        chartNav.tabBarItem.tag = 0
        chartNav.delegate = self
        
        // 더미
        let dummyVC = UIViewController()
        dummyVC.tabBarItem = UITabBarItem(title: "", image: nil, tag: 1)
        dummyVC.tabBarItem.isEnabled = false
        
        // 기록차트
        let recordListVC = createRecordListViewController()
        let recordNav = UINavigationController(rootViewController: recordListVC)
        recordNav.tabBarItem = UITabBarItem(
            title: "기록 차트",
            image: UIImage(named: AssetImage.recordSymbol),
            selectedImage: UIImage(named: AssetImage.recordSymbolFill)
        )
        recordNav.tabBarItem.tag = 2
        recordNav.delegate = self
        
        viewControllers = [chartNav, dummyVC, recordNav]
        selectedIndex = 0
    }
    
    private func createChartViewController() -> UIViewController {
        DashboardViewController()
    }
    
    private func createRecordListViewController() -> UIViewController {
        let repository = SurfRecordRepository()
        let useCase = SurfRecordUseCase(repository: repository)
        let storage = UserDefaultsService()
        let viewModel = RecordHistoryViewModel(useCase: useCase, storageService: storage)
        let vc = RecordHistoryViewController(viewModel: viewModel)
        vc.title = "기록 차트"
        vc.navigationItem.leftBarButtonItem = nil
        return vc
    }
    
    private func setupTabBarDelegate() {
        rx.didSelect
            .filter { $0.tabBarItem.tag == 1 }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.selectedIndex = self.selectedIndex == 0 ? 0 : 2
            })
            .disposed(by: disposeBag)
        
        rx.didSelect
            .filter { $0.tabBarItem.tag == 2 }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let nav = self.viewControllers?.first(where: { $0.tabBarItem.tag == 2 }) as? UINavigationController,
                   let recordVC = nav.viewControllers.first as? RecordHistoryViewController {
                    recordVC.resetAllFilters()
                } else if let recordVC = (self.viewControllers?.first(where: { $0.tabBarItem.tag == 2 }) as? RecordHistoryViewController) {
                    recordVC.resetAllFilters()
                } else if let nav = self.selectedViewController as? UINavigationController,
                          let recordVC = nav.viewControllers.first as? RecordHistoryViewController {
                    recordVC.resetAllFilters()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Binding
    private func bindCenterButton() {
        let initialState = storageService.readSurfingState()
        isRecordingScreenPresented.accept(initialState)
        
        // iOS 26 미만에서만 탭바 센터 버튼 바인딩
        if #available(iOS 26.0, *) {
            // 플로팅 버튼은 setupFloatingButtonIfNeeded에서 바인딩됨
        } else {
            customTabBar.centerButtonTapped
                .subscribe(onNext: { [weak self] in
                    self?.handleCenterButtonTap()
                })
                .disposed(by: disposeBag)
            
            isRecordingScreenPresented
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] isSelected in
                    self?.customTabBar.updateCenterButtonState(isSelected: isSelected)
                })
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Actions
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
        
        surfEndOverlay = SurfEndOverlayView()
        guard let overlay = surfEndOverlay else { return }
        
        overlay.onSurfEnd = { [weak self] in
            self?.endSurfing()
        }
        overlay.onCancel = { [weak self] in
            self?.hideSurfEndOverlay()
        }
        
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        animateTabBarVisibility(hidden: true)
        overlay.show()
    }
    
    private func hideSurfEndOverlay(completion: (() -> Void)? = nil) {
        guard let overlay = surfEndOverlay else {
            animateTabBarVisibility(hidden: false)
            completion?()
            return
        }
        
        animateTabBarVisibility(hidden: false)
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
        
        let chartsToPass: [Chart] = {
            if let provider = dashboardProvider {
                return provider.allChartsSnapshot
            }
            return []
        }()
        
        let recordVC = SurfRecordViewController(
            startTime: startTime,
            endTime: endTime,
            charts: chartsToPass
        )
        recordVC.title = "파도 기록"
        recordVC.hidesBottomBarWhenPushed = true
        
        if #available(iOS 26.0, *) {
            // 네비게이션 push 시 플로팅 버튼이 보이지 않도록 미리 페이드 아웃
            self.floatingCenterButton?.alpha = 0
        }
        
        if let nav = selectedViewController as? UINavigationController {
            nav.pushViewController(recordVC, animated: true)
        } else if let nav = navigationController {
            nav.pushViewController(recordVC, animated: true)
        }
    }
    
    private func animateTabBarVisibility(hidden: Bool) {
        if #available(iOS 26.0, *) {
            // iOS 26+에서는 탭바를 이동시키지 않고 알파만 조절해 숨김/표시를 연출
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
                self.tabBar.alpha = hidden ? 0 : 1
                self.tabBar.transform = .identity // 이동 금지
                // 플로팅 버튼도 함께 페이드 처리
                self.floatingCenterButton?.alpha = hidden ? 0 : 1
            }
        } else {
            // iOS 26 미만에서는 기존 슬라이드 다운 애니메이션 유지
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.tabBar.alpha = hidden ? 0 : 1
                self.tabBar.transform = hidden
                    ? CGAffineTransform(translationX: 0, y: self.tabBar.frame.height)
                    : .identity
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension CustomTabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard #available(iOS 26.0, *) else { return }
        // hidesBottomBarWhenPushed가 true인 화면에서는 플로팅 버튼을 숨김
        let shouldHideFloating = viewController.hidesBottomBarWhenPushed
        UIView.animate(withDuration: animated ? 0.2 : 0.0, delay: 0, options: [.curveEaseInOut]) {
            self.floatingCenterButton?.alpha = shouldHideFloating ? 0 : 1
        }
    }
}

// MARK: - FloatingCenterButton (iOS 26+)
class FloatingCenterButton: UIView {
    private let button = UIButton()
    private let storageService: SurfingRecordService
    private let disposeBag = DisposeBag()
    let centerButtonTapped = PublishRelay<Void>()
    
    init(storageService: SurfingRecordService) {
        self.storageService = storageService
        super.init(frame: .zero)
        setupButton()
        loadSurfingState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupButtonDesign()
        bindButtonEvents()
    }
    
    private func setupButtonDesign() {
        button.layer.masksToBounds = false
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        
        let startWaveImage = UIImage(named: AssetImage.startWave)
        button.setImage(startWaveImage, for: .normal)
        button.setImage(startWaveImage, for: .selected)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .selected)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.imagePlacement = .top
            config.imagePadding = 6
            config.titleAlignment = .center
            config.contentInsets = .zero
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = .systemFont(ofSize: 10, weight: .medium)
                return out
            }
            button.configuration = config
            button.configurationUpdateHandler = { button in
                var updated = button.configuration
                updated?.title = button.isSelected ? "서핑중" : "기록하기"
                button.configuration = updated
            }
            button.setNeedsUpdateConfiguration()
        } else {
            button.setTitle("기록하기", for: .normal)
            button.setTitle("서핑중", for: .selected)
            button.contentHorizontalAlignment = .center
            button.contentVerticalAlignment = .center
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
            button.contentEdgeInsets = .zero
            button.imageEdgeInsets = UIEdgeInsets(top: -6, left: 0, bottom: 6, right: 0)
            button.titleEdgeInsets = UIEdgeInsets(top: 24, left: 0, bottom: -4, right: 0)
        }
    }
    
    private func bindButtonEvents() {
        button.rx.controlEvent(.touchDown)
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(pressed: true)
            })
            .disposed(by: disposeBag)
        
        button.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(pressed: false)
            })
            .disposed(by: disposeBag)
        
        button.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: centerButtonTapped)
            .disposed(by: disposeBag)
    }
    
    func updateButtonState(isSelected: Bool) {
        storageService.createSurfingState(isSelected)
        
        UIView.transition(with: button, duration: 0.2, options: .transitionCrossDissolve) {
            self.button.isSelected = isSelected
            if #available(iOS 15.0, *) {
                self.button.setNeedsUpdateConfiguration()
            }
            
            if isSelected {
                self.button.backgroundColor = UIColor.surfBlue.withAlphaComponent(0.8)
                self.button.layer.shadowColor = UIColor.surfBlue.withAlphaComponent(0.6).cgColor
                self.button.layer.shadowOpacity = 0.4
            } else {
                self.button.backgroundColor = .surfBlue
                self.button.layer.shadowColor = UIColor.surfBlue.cgColor
                self.button.layer.shadowOpacity = 0.25
            }
        }
        
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
    }
    
    private func loadSurfingState() {
        updateButtonState(isSelected: storageService.readSurfingState())
    }
    
    private func animateButtonPress(pressed: Bool) {
        let isSurfing = storageService.readSurfingState()
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            self.button.transform = pressed
                ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                : .identity
            self.button.layer.shadowOpacity = pressed ? 0.1 : (isSurfing ? 0.4 : 0.25)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let side = min(button.bounds.width, button.bounds.height)
        button.layer.cornerRadius = side / 2
        if #available(iOS 13.0, *) {
            button.layer.cornerCurve = .continuous
        }
    }
}

// MARK: - CustomTabBar
class CustomTabBar: UITabBar {
    private let centerButton = UIButton()
    private let storageService: SurfingRecordService
    private let disposeBag = DisposeBag()
    let centerButtonTapped = PublishRelay<Void>()
    
    init(storageService: SurfingRecordService) {
        self.storageService = storageService
        super.init(frame: .zero)
        setupCenterButton()
        loadSurfingState()
    }
    
    required init?(coder: NSCoder) {
        self.storageService = UserDefaultsService()
        super.init(coder: coder)
        setupCenterButton()
        loadSurfingState()
    }
    
    func hideCenterButton() {
        centerButton.isHidden = true
    }
    
    private func setupCenterButton() {
        backgroundColor = .systemBackground
        tintColor = .surfBlue
        unselectedItemTintColor = .systemGray
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = .systemGray4
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
            isTranslucent = false
        }
        
        setupCenterButtonDesign()
        setupCenterButtonConstraints()
        bindCenterButtonEvents()
    }
    
    private func setupCenterButtonDesign() {
        centerButton.layer.masksToBounds = false
        centerButton.imageView?.contentMode = .scaleAspectFit
        centerButton.tintColor = .white
        
        let startWaveImage = UIImage(named: AssetImage.startWave)
        centerButton.setImage(startWaveImage, for: .normal)
        centerButton.setImage(startWaveImage, for: .selected)
        centerButton.setTitleColor(.white, for: .normal)
        centerButton.setTitleColor(.white, for: .selected)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.imagePlacement = .top
            config.imagePadding = 6
            config.titleAlignment = .center
            config.contentInsets = .zero
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = .systemFont(ofSize: 10, weight: .medium)
                return out
            }
            centerButton.configuration = config
            centerButton.configurationUpdateHandler = { button in
                var updated = button.configuration
                updated?.title = button.isSelected ? "서핑중" : "기록하기"
                button.configuration = updated
            }
            centerButton.setNeedsUpdateConfiguration()
        } else {
            centerButton.setTitle("기록하기", for: .normal)
            centerButton.setTitle("서핑중", for: .selected)
            centerButton.contentHorizontalAlignment = .center
            centerButton.contentVerticalAlignment = .center
            centerButton.titleLabel?.textAlignment = .center
            centerButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
            centerButton.contentEdgeInsets = .zero
            centerButton.imageEdgeInsets = UIEdgeInsets(top: -6, left: 0, bottom: 6, right: 0)
            centerButton.titleEdgeInsets = UIEdgeInsets(top: 24, left: 0, bottom: -4, right: 0)
        }
    }
    
    private func setupCenterButtonConstraints() {
        addSubview(centerButton)
        centerButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(snp.top).offset(10)
            make.width.height.equalTo(67)
        }
    }
    
    private func bindCenterButtonEvents() {
        centerButton.rx.controlEvent(.touchDown)
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(pressed: true)
            })
            .disposed(by: disposeBag)
        
        centerButton.rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .subscribe(onNext: { [weak self] in
                self?.animateButtonPress(pressed: false)
            })
            .disposed(by: disposeBag)
        
        centerButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: centerButtonTapped)
            .disposed(by: disposeBag)
    }
    
    func updateCenterButtonState(isSelected: Bool) {
        storageService.createSurfingState(isSelected)
        
        UIView.transition(with: centerButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.centerButton.isSelected = isSelected
            if #available(iOS 15.0, *) {
                self.centerButton.setNeedsUpdateConfiguration()
            }
            
            if isSelected {
                self.centerButton.backgroundColor = UIColor.surfBlue.withAlphaComponent(0.8)
                self.centerButton.layer.shadowColor = UIColor.surfBlue.withAlphaComponent(0.6).cgColor
                self.centerButton.layer.shadowOpacity = 0.4
            } else {
                self.centerButton.backgroundColor = .surfBlue
                self.centerButton.layer.shadowColor = UIColor.surfBlue.cgColor
                self.centerButton.layer.shadowOpacity = 0.25
            }
        }
        
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        centerButton.layer.shadowRadius = 12
    }
    
    var surfingState: Bool {
        storageService.readSurfingState()
    }
    
    private func loadSurfingState() {
        updateCenterButtonUI(isSelected: storageService.readSurfingState())
    }
    
    private func updateCenterButtonUI(isSelected: Bool) {
        updateCenterButtonState(isSelected: isSelected)
    }
    
    private func animateButtonPress(pressed: Bool) {
        let isSurfing = storageService.readSurfingState()
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            self.centerButton.transform = pressed
                ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                : .identity
            self.centerButton.layer.shadowOpacity = pressed ? 0.1 : (isSurfing ? 0.4 : 0.25)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || alpha < 0.01 || window == nil {
            return nil
        }
        
        if let superBounds = superview?.bounds, frame.minY >= superBounds.height - 1 {
            return nil
        }
        
        let centerFrame = centerButton.frame.insetBy(dx: -10, dy: -10)
        if centerFrame.contains(point) {
            return centerButton
        }
        
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        arrangeTabBarItems()
        
        let side = min(centerButton.bounds.width, centerButton.bounds.height)
        centerButton.layer.cornerRadius = side / 2
        if #available(iOS 13.0, *) {
            centerButton.layer.cornerCurve = .continuous
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var s = super.sizeThatFits(size)
        s.height += 20
        return s
    }
    
    private func arrangeTabBarItems() {
        guard let items = items, items.count >= 2 else { return }
        
        let totalWidth = frame.width
        let buttonWidth = totalWidth / 3
        var buttonIndex = 0
        
        for subview in subviews where String(describing: type(of: subview)) == "UITabBarButton" {
            let newFrame: CGRect
            if buttonIndex == 0 {
                newFrame = CGRect(
                    x: 0,
                    y: subview.frame.origin.y,
                    width: buttonWidth,
                    height: subview.frame.height
                )
            } else {
                newFrame = CGRect(
                    x: buttonWidth * 2,
                    y: subview.frame.origin.y,
                    width: buttonWidth,
                    height: subview.frame.height
                )
            }
            subview.frame = newFrame
            buttonIndex += 1
            if buttonIndex >= 2 { break }
        }
    }
}

