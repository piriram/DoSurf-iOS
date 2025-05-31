import UIKit
import RxSwift
import RxCocoa

// MARK: - Custom Button Style
enum CustomButtonStyle {
    case primary(title: String)
    case secondary(title: String)
    case capsule(title: String, tintColor: UIColor)
    case icon(image: UIImage?, tintColor: UIColor)
    
    var isCircular: Bool {
        if case .icon = self {
            return true
        }
        return false
    }
}

// MARK: - Custom Button
final class CustomButton: UIButton {
    
    // MARK: - Properties
    private let style: CustomButtonStyle
    private let disposeBag = DisposeBag()
    private var gradientLayer: CAGradientLayer?
    // MARK: - Initialization
    init(style: CustomButtonStyle) {
        self.style = style
        super.init(frame: .zero)
        setupButton()
        bindTouchAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
        if style.isCircular {
            makeCircular()
        }
    }
    
    // MARK: - Setup
    private func setupButton() {
        switch style {
        case .primary(let title):
            setupPrimaryStyle(title: title)
            
        case .secondary(let title):
            setupSecondaryStyle(title: title)
            
        case .capsule(let title, let tintColor):
            setupCapsuleStyle(title: title, tintColor: tintColor)
            
        case .icon(let image, let tintColor):
            setupIconStyle(image: image, tintColor: tintColor)
        }
    }
    
    private func setupPrimaryStyle(title: String) {
        // 그라데이션 레이어 생성
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.004, green: 0.290, blue: 0.780, alpha: 1.0).cgColor, // #004AC7 (0%)
            UIColor(red: 0.871, green: 0.875, blue: 0.957, alpha: 1.0).cgColor  // #DEDFE4 (100%)
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 2.5)
        gradient.frame = bounds
        gradient.cornerRadius = 77
        
        layer.insertSublayer(gradient, at: 0)
        self.gradientLayer = gradient
        
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 32, weight: .bold)
        layer.cornerRadius = 77
        
        // 그림자 효과
        layer.shadowColor = UIColor.surfBlue.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.3
    }
    
    private func setupSecondaryStyle(title: String) {
        backgroundColor = .systemBackground
        setTitle(title, for: .normal)
        setTitleColor(.label, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = 24
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.cgColor
        
        // 그림자 효과
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
    }
    
    private func setupCapsuleStyle(title: String, tintColor: UIColor) {
        backgroundColor = .backgroundGray
        setTitle(title, for: .normal)
        setTitleColor(tintColor, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = 24
    }
    
    private func setupIconStyle(image: UIImage?, tintColor: UIColor) {
        backgroundColor = .systemBackground
        
        let iconImage = image?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        )
        setImage(iconImage, for: .normal)
        self.tintColor = tintColor
        layer.cornerRadius = 34
        layer.borderWidth = 1
        layer.borderColor = tintColor.cgColor
        
        // 그림자 효과
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
    }
    
    // MARK: - Animation
    private func bindTouchAnimation() {
        rx.controlEvent(.touchDown)
            .subscribe(onNext: { [weak self] in
                self?.animatePress(pressed: true)
            })
            .disposed(by: disposeBag)
        
        rx.controlEvent([.touchUpInside, .touchUpOutside, .touchCancel])
            .subscribe(onNext: { [weak self] in
                self?.animatePress(pressed: false)
            })
            .disposed(by: disposeBag)
    }
    
    private func animatePress(pressed: Bool) {
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseInOut]
        ) {
            self.transform = pressed ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
        }
    }
}
