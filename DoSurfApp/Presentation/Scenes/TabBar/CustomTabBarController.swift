//
//  CustomTabBarController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/28/25.
//
import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - CustomTabBarController
class CustomTabBarController: BaseTabBarController {
    
    // MARK: - Properties
    private let customTabBar: CustomTabBar
    private let storageService: SurfingStorageService
    private let disposeBag = DisposeBag()
    
    // 기록 화면 표시 여부 추적
    let isRecordingScreenPresented = BehaviorRelay<Bool>(value: false)
    
    // 서핑 종료 오버레이
    private var surfEndOverlay: SurfEndOverlayView?
    
    // MARK: - Initialization
    init(storageService: SurfingStorageService = UserDefaultsSurfingStorageService()) {
        self.storageService = storageService
        self.customTabBar = CustomTabBar(storageService: storageService)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.storageService = UserDefaultsSurfingStorageService()
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
    
    private func setupViewControllers() {
        // 파도차트 ViewController
        let chartVC = createChartViewController()
        let chartNav = UINavigationController(rootViewController: chartVC)
        chartNav.tabBarItem = UITabBarItem(
            title: "파도차트",
            image: UIImage(named: "chartSymbol"),
            selectedImage: UIImage(named: "chartSymbol.fill")
        )
        chartNav.tabBarItem.tag = 0
        
        // 더미 ViewController (중앙 버튼 공간)
        let dummyVC = UIViewController()
        dummyVC.tabBarItem = UITabBarItem(title: "", image: nil, tag: 1)
        dummyVC.tabBarItem.isEnabled = false
        
        // 기록차트 ViewController
        let recordListVC = createRecordListViewController()
        let recordNav = UINavigationController(rootViewController: recordListVC)
        recordNav.tabBarItem = UITabBarItem(
            title: "기록 차트",
            image: UIImage(named: "recordSymbol"),
            selectedImage: UIImage(named: "recordSymbol.fill")
        )
        recordNav.tabBarItem.tag = 2
        
        viewControllers = [chartNav, dummyVC, recordNav]
        selectedIndex = 0
    }
    
    private func createChartViewController() -> UIViewController {
        return DashboardViewController()
    }
    
    private func createRecordListViewController() -> UIViewController {
        let vc = StaticsViewController()
        vc.title = "기록 차트"
        vc.navigationItem.leftBarButtonItem = nil
        return vc
    }
    
    private func setupTabBarDelegate() {
        // 중앙 탭(더미) 선택 방지
        rx.didSelect
            .filter { $0.tabBarItem.tag == 1 }
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.selectedIndex = self.selectedIndex == 0 ? 0 : 2
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Binding
    private func bindCenterButton() {
        // 저장된 서핑 상태로 초기화
        let initialState = storageService.loadSurfingState()
        isRecordingScreenPresented.accept(initialState)
        
        // 중앙 버튼 탭 이벤트
        customTabBar.centerButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.handleCenterButtonTap()
            })
            .disposed(by: disposeBag)
        
        // 기록 화면 상태에 따른 버튼 외형 변경
        isRecordingScreenPresented
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isPresented in
                self?.customTabBar.updateCenterButtonState(isSelected: isPresented)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    private func handleCenterButtonTap() {
        if storageService.loadSurfingState() {
            // 서핑 중이면 종료 오버레이 표시
            showSurfEndOverlay()
        } else {
            // 서핑 시작
            startSurfing()
        }
    }
    
    private func startSurfing() {
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 서핑 시작 시간 저장
        storageService.saveSurfingStartTime(Date())
        storageService.saveSurfingState(true)
        
        // 상태 업데이트
        isRecordingScreenPresented.accept(true)
    }
    
    private func showSurfEndOverlay() {
        // 이미 오버레이가 표시중이면 무시
        guard surfEndOverlay == nil else { return }
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 오버레이 생성
        surfEndOverlay = SurfEndOverlayView()
        guard let overlay = surfEndOverlay else { return }
        
        // 오버레이 이벤트 바인딩
        overlay.onSurfEnd = { [weak self] in
            self?.endSurfing()
        }
        
        overlay.onCancel = { [weak self] in
            self?.hideSurfEndOverlay()
        }
        
        // 메인 뷰에 추가
        view.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 탭바 숨기기
        animateTabBarVisibility(hidden: true)
        
        // 오버레이 애니메이션 표시
        overlay.show()
    }
    
    private func hideSurfEndOverlay(completion: (() -> Void)? = nil) {
        // 탭바 보이기
        if surfEndOverlay == nil {
            animateTabBarVisibility(hidden: false)
            completion?()
            return
        }
        
        guard let overlay = surfEndOverlay else { return }
        
        // 탭바 보이기
        animateTabBarVisibility(hidden: false)
        
        // 오버레이 애니메이션 숨기기
        overlay.hide { [weak self] in
            overlay.removeFromSuperview()
            self?.surfEndOverlay = nil
            completion?()
        }
    }
    
    private func endSurfing() {
        // 서핑 종료 시간 저장
        storageService.saveSurfingEndTime(Date())
        storageService.saveSurfingState(false)
        
        // 상태 업데이트
        isRecordingScreenPresented.accept(false)
        
        // 성공 햅틱
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        // 오버레이 숨기기 완료 후 기록 작성 화면으로 이동
        hideSurfEndOverlay { [weak self] in
            self?.pushToRecordWrite()
        }
    }
    
    private func pushToRecordWrite() {
        // 저장된 서핑 시작/종료 시간 가져오기
        let startTime = storageService.getSurfingStartTime()
        let endTime = storageService.getSurfingEndTime()
        
        // 서핑 시간을 전달하여 SurfRecordViewController 생성
        let recordVC = SurfRecordViewController(startTime: startTime, endTime: endTime)
        recordVC.title = "파도 기록"
        recordVC.hidesBottomBarWhenPushed = true
        
        if let nav = selectedViewController as? UINavigationController {
            nav.pushViewController(recordVC, animated: true)
        } else if let nav = navigationController {
            nav.pushViewController(recordVC, animated: true)
        }
    }
    
    private func animateTabBarVisibility(hidden: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.tabBar.alpha = hidden ? 0 : 1
            self.tabBar.transform = hidden ?
            CGAffineTransform(translationX: 0, y: self.tabBar.frame.height) : .identity
        }
    }
}

// MARK: - CustomTabBar
class CustomTabBar: UITabBar {
    
    // MARK: - Properties
    private let centerButton = UIButton()
    private let storageService: SurfingStorageService
    private let disposeBag = DisposeBag()
    
    // 중앙 버튼 클릭 이벤트
    let centerButtonTapped = PublishRelay<Void>()
    
    // MARK: - Initialization
    init(storageService: SurfingStorageService) {
        self.storageService = storageService
        super.init(frame: .zero)
        setupCenterButton()
        loadSurfingState()
    }
    
    required init?(coder: NSCoder) {
        self.storageService = UserDefaultsSurfingStorageService()
        super.init(coder: coder)
        setupCenterButton()
        loadSurfingState()
    }
    
    // MARK: - Setup
    private func setupCenterButton() {
        // 탭바 스타일링
        backgroundColor = .systemBackground
        tintColor = .surfBlue
        unselectedItemTintColor = .systemGray
        
        // iOS 15+ 대응
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
        
        setupCenterButtonStates()
        
        // 텍스트 라벨
        centerButton.setTitle("기록하기", for: .normal)
        centerButton.setTitle("서핑중", for: .selected)
        
        // 이미지와 텍스트 배치
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.imagePlacement = .top
            config.imagePadding = 6
            config.titleAlignment = .center
            config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 10, weight: .medium)
                return outgoing
            }
            centerButton.configuration = config
            
            // Update title based on selection state when using configuration (iOS 15+)
            centerButton.configurationUpdateHandler = { button in
                var updated = button.configuration
                updated?.title = button.isSelected ? "서핑중" : "기록하기"
                button.configuration = updated
            }
            // Ensure initial configuration reflects current selection
            centerButton.setNeedsUpdateConfiguration()
        } else {
            centerButton.contentHorizontalAlignment = .center
            centerButton.contentVerticalAlignment = .center
            centerButton.titleLabel?.textAlignment = .center
            centerButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
            centerButton.contentEdgeInsets = .zero
            centerButton.imageEdgeInsets = UIEdgeInsets(top: -6, left: 0, bottom: 6, right: 0)
            centerButton.titleEdgeInsets = UIEdgeInsets(top: 24, left: 0, bottom: -4, right: 0)
        }
    }
    
    private func setupCenterButtonStates() {
        let startWaveImage = UIImage(named: "startWave")
        centerButton.setImage(startWaveImage, for: .normal)
        centerButton.setTitleColor(.white, for: .normal)
        centerButton.setImage(startWaveImage, for: .selected)
        centerButton.setTitleColor(.white, for: .selected)
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
        // 버튼 터치 효과
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
        
        // 메인 터치 이벤트
        centerButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: centerButtonTapped)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Public Methods
    
    /// 중앙 버튼 상태 업데이트
    func updateCenterButtonState(isSelected: Bool) {
        storageService.saveSurfingState(isSelected)
        updateCenterButtonUI(isSelected: isSelected)
    }
    
    /// 서핑 상태 확인
    var surfingState: Bool {
        return storageService.loadSurfingState()
    }
    
    // MARK: - Private Methods
    
    /// 앱 실행 시 저장된 서핑 상태 로드
    private func loadSurfingState() {
        let savedSurfingState = storageService.loadSurfingState()
        updateCenterButtonUI(isSelected: savedSurfingState)
    }
    
    /// UI만 업데이트 (시간 저장 없이)
    private func updateCenterButtonUI(isSelected: Bool) {
        UIView.transition(with: centerButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.centerButton.isSelected = isSelected
            
            if #available(iOS 15.0, *) {
                self.centerButton.setNeedsUpdateConfiguration()
            }
            
            if isSelected {
                // 선택된 상태: 밝은 파란색
                self.centerButton.backgroundColor = UIColor.surfBlue.withAlphaComponent(0.8)
                self.centerButton.layer.shadowColor = UIColor.surfBlue.withAlphaComponent(0.6).cgColor
                self.centerButton.layer.shadowOpacity = 0.4
            } else {
                // 기본 상태: 진한 파란색
                self.centerButton.backgroundColor = UIColor.surfBlue
                self.centerButton.layer.shadowColor = UIColor.surfBlue.cgColor
                self.centerButton.layer.shadowOpacity = 0.25
            }
        }
        
        // 그림자 애니메이션
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        centerButton.layer.shadowRadius = 12
    }
    
    private func animateButtonPress(pressed: Bool) {
        let isSurfing = storageService.loadSurfingState()
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            self.centerButton.transform = pressed ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            self.centerButton.layer.shadowOpacity = pressed ? 0.1 : (isSurfing ? 0.4 : 0.25)
        }
    }
    
    // MARK: - Layout
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 탭바가 보이지 않거나 비활성 상태면 터치 무시
        if isHidden || alpha < 0.01 || window == nil {
            return nil
        }
        
        // 탭바가 화면 아래로 내려가 있는(숨겨진) 상태면 터치 무시
        if let superBounds = superview?.bounds, frame.minY >= superBounds.height - 1 {
            return nil
        }
        
        // 중앙 버튼 터치 영역 확장
        let centerButtonFrame = centerButton.frame.insetBy(dx: -10, dy: -10)
        if centerButtonFrame.contains(point) {
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
        
        for subview in subviews {
            if String(describing: type(of: subview)) == "UITabBarButton" {
                let newFrame: CGRect
                
                if buttonIndex == 0 {
                    // 첫 번째 버튼 (왼쪽)
                    newFrame = CGRect(x: 0, y: subview.frame.origin.y,
                                      width: buttonWidth, height: subview.frame.height)
                } else {
                    // 두 번째 버튼 (오른쪽)
                    newFrame = CGRect(x: buttonWidth * 2, y: subview.frame.origin.y,
                                      width: buttonWidth, height: subview.frame.height)
                }
                
                subview.frame = newFrame
                buttonIndex += 1
                
                if buttonIndex >= 2 { break }
            }
        }
    }
}

