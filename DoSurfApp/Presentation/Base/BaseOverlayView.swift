import UIKit
import RxSwift
import SnapKit

// MARK: - Base Overlay View
class BaseOverlayView: UIView, OverlayViewProtocol {
    
    // MARK: - Properties
    private let gradientBlurView = GradientBlurView(
        blurStyle: .systemUltraThinMaterial,
        dimAlpha: 0.0,
        gradientStartLocation: 0.0,
        gradientEndLocation: 1.0
    )

    let containerView = UIView()
    let disposeBag = DisposeBag()

    private let blurHeight: CGFloat = 497
    private let containerSize: CGFloat
    
    // MARK: - Buttons
    private(set) var mainButton: CustomButton?
    private(set) var secondaryButton: CustomButton?
    private(set) var cancelButton: CustomButton?
    
    // MARK: - Initialization
    init(containerSize: CGFloat = 400) {
        self.containerSize = containerSize
        super.init(frame: .zero)
        setupBaseUI()
    }
    
    required init?(coder: NSCoder) {
        self.containerSize = 400
        super.init(coder: coder)
        setupBaseUI()
    }
    
    // MARK: - Setup
    private func setupBaseUI() {
        // 그라데이션 블러 배경
        gradientBlurView.alpha = 0
        addSubview(gradientBlurView)

        gradientBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 컨테이너 뷰
        containerView.alpha = 0
        addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.height.equalTo(containerSize)
        }
    }
    
    // MARK: - Gradient Configuration
    func configureGradientReference(_ view: UIView) {
        gradientBlurView.setReferenceView(view)
    }

    // MARK: - Button Setup
    func setupButtons(
        main: OverlayButtonConfiguration,
        secondary: OverlayButtonConfiguration,
        cancel: OverlayButtonConfiguration,
        spacing: CGFloat = 24
    ) {
        // Main Button (상단)
        let mainBtn = CustomButton(style: main.style)
        self.mainButton = mainBtn
        containerView.addSubview(mainBtn)
        
        mainBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(200)
            make.width.equalTo(main.width)
            make.height.equalTo(main.height)
        }
        
        // Secondary Button (중간)
        let secondaryBtn = CustomButton(style: secondary.style)
        self.secondaryButton = secondaryBtn
        containerView.addSubview(secondaryBtn)
        
        secondaryBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(130)
            make.width.equalTo(secondary.width)
            make.height.equalTo(secondary.height)
        }
        
        // Cancel Button (하단)
        let cancelBtn = CustomButton(style: cancel.style)
        self.cancelButton = cancelBtn
        containerView.addSubview(cancelBtn)
        
        cancelBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(32)
            make.width.equalTo(cancel.width)
            make.height.equalTo(cancel.height)
        }
    }
    
    // MARK: - Animation
    func show() {
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
            self.gradientBlurView.alpha = 1
        }
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0.1,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.allowUserInteraction]
        ) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn]) {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.1, options: [.curveEaseIn]) {
            self.gradientBlurView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 백그라운드 터치 무시
    }
}
