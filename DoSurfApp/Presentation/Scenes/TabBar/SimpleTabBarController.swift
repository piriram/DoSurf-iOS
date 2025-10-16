//
//  SimpleTabBarController.swift
//  DoSurfApp
//
//  Created by Assistant on 10/16/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - SimpleTabBarController
final class SimpleTabBarController: UIViewController {
    
    // MARK: - Properties
    private let storageService: SurfingRecordService
    private let disposeBag = DisposeBag()
    
    // Container
    private let containerView = UIView()
    
    // Bottom Bar
    private let bottomBar = UIView()
    private let chartButton = TabBarButton(type: .chart)
    private let centerButton = CenterButton()
    private let recordButton = TabBarButton(type: .record)
    
    // View Controllers
    private lazy var chartViewController: UIViewController = {
        let vc = DashboardViewController()
        vc.title = "파도차트"
        return vc
    }()
    
    private lazy var recordViewController: UIViewController = {
        let repository = SurfRecordRepository()
        let useCase = SurfRecordUseCase(repository: repository)
        let viewModel = RecordHistoryViewModel(useCase: useCase, storageService: storageService)
        let vc = RecordHistoryViewController(viewModel: viewModel)
        vc.title = "기록 차트"
        return vc
    }()
    
    private var currentNavigationController: UINavigationController?
    private weak var dashboardProvider: (UIViewController & DashboardChartProviding)?
    
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-80)
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
            make.bottom.equalTo(bottomBar.snp.top).offset(20)
            make.width.height.equalTo(67)
        }
        
        recordButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(50)
        }
    }
    
    private func setupInitialViewController() {
        if let provider = chartViewController as? (UIViewController & DashboardChartProviding) {
            dashboardProvider = provider
        }
        
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
        
        currentNavigationController?.pushViewController(recordVC, animated: true)
    }
    
    private func animateBottomBarVisibility(hidden: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
            self.bottomBar.alpha = hidden ? 0 : 1
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension SimpleTabBarController: UINavigationControllerDelegate {
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

// MARK: - TabType
enum TabType {
    case chart
    case record
}

// MARK: - TabBarButton
final class TabBarButton: UIControl {
    
    enum ButtonType {
        case chart
        case record
        
        var title: String {
            switch self {
            case .chart: return "파도차트"
            case .record: return "기록 차트"
            }
        }
        
        var normalImage: UIImage? {
            switch self {
            case .chart: return UIImage(named: AssetImage.chartSymbol)
            case .record: return UIImage(named: AssetImage.recordSymbol)
            }
        }
        
        var selectedImage: UIImage? {
            switch self {
            case .chart: return UIImage(named: AssetImage.chartSymbolFill)
            case .record: return UIImage(named: AssetImage.recordSymbolFill)
            }
        }
    }
    
    private let type: ButtonType
    private let imageView = UIImageView()
    private let label = UILabel()
    private let stackView = UIStackView()
    
    private var isSelectedState = false
    
    init(type: ButtonType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Stack View
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.isUserInteractionEnabled = false
        
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        // Image View
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.image = type.normalImage
        stackView.addArrangedSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        // Label
        label.text = type.title
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .systemGray
        label.textAlignment = .center
        stackView.addArrangedSubview(label)
    }
    
    func setSelected(_ selected: Bool) {
        isSelectedState = selected
        
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = selected ? self.type.selectedImage : self.type.normalImage
            self.imageView.tintColor = selected ? .surfBlue : .systemGray
            self.label.textColor = selected ? .surfBlue : .systemGray
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.5 : 1.0
            }
        }
    }
}

// MARK: - CenterButton
final class CenterButton: UIControl {
    
    private let button = UIButton()
    private var isRecordingState = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(button)
        button.isUserInteractionEnabled = false
        button.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        button.backgroundColor = .surfBlue
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        button.clipsToBounds = true
        
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
            config.background.cornerRadius = 33.5
            config.background.backgroundColor = .surfBlue
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = .systemFont(ofSize: 10, weight: .medium)
                return out
            }
            button.configuration = config
            button.configurationUpdateHandler = { button in
                var updated = button.configuration
                updated?.title = button.isSelected ? "서핑중" : "기록하기"
                updated?.background.backgroundColor = button.isSelected
                    ? UIColor.surfBlue.withAlphaComponent(0.8)
                    : .surfBlue
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
            button.layer.cornerRadius = 33.5
        }
        
        // Shadow
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowColor = UIColor.surfBlue.cgColor
        layer.shadowOpacity = 0.25
    }
    
    func updateState(isRecording: Bool) {
        isRecordingState = isRecording
        button.isSelected = isRecording
        
        if #available(iOS 26.0, *) {
            // iOS 26: Configuration 업데이트
            button.setNeedsUpdateConfiguration()
        } else {
            // iOS 26 미만: backgroundColor 직접 변경
            UIView.transition(with: button, duration: 0.2, options: .transitionCrossDissolve) {
                if isRecording {
                    self.button.backgroundColor = UIColor.surfBlue.withAlphaComponent(0.8)
                } else {
                    self.button.backgroundColor = .surfBlue
                }
            }
        }
        
        // Shadow 업데이트
        layer.shadowColor = isRecording
            ? UIColor.surfBlue.withAlphaComponent(0.6).cgColor
            : UIColor.surfBlue.cgColor
        layer.shadowOpacity = isRecording ? 0.4 : 0.25
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
                self.button.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                    : .identity
                self.layer.shadowOpacity = self.isHighlighted ? 0.1 : (self.isRecordingState ? 0.4 : 0.25)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // iOS 26 미만에서는 layoutSubviews에서 cornerRadius 재계산
        if #unavailable(iOS 26.0) {
            let radius = min(button.bounds.width, button.bounds.height) / 2
            button.layer.cornerRadius = radius
            print("🔵 CenterButton cornerRadius: \(radius), bounds: \(button.bounds)")
        }
    }
}
