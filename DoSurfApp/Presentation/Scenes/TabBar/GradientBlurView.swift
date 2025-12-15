import UIKit
import SnapKit

// MARK: - Gradient Blur View
final class GradientBlurView: UIView {
    private let blurEffectView: UIVisualEffectView
    private let dimView = UIView()

    private let blurStyle: UIBlurEffect.Style
    private let dimAlpha: CGFloat
    private let gradientStartLocation: CGFloat
    private let gradientEndLocation: CGFloat

    private weak var referenceView: UIView?
    
    /// 그라데이션 블러 뷰 초기화
    /// - Parameters:
    ///   - blurStyle: 블러 스타일 (기본값: .systemThickMaterial)
    ///   - dimAlpha: 어둡게 처리할 투명도 (기본값: 0.2, 0.0~1.0)
    ///   - gradientStartLocation: 그라데이션 시작 위치 (기본값: 0.0, 완전 투명)
    ///   - gradientEndLocation: 그라데이션 끝 위치 (기본값: 1.0, 완전 불투명)
    init(
        blurStyle: UIBlurEffect.Style = .systemThickMaterial,
        dimAlpha: CGFloat = 0.2,
        gradientStartLocation: CGFloat = 0.0,
        gradientEndLocation: CGFloat = 1.0
    ) {
        self.blurStyle = blurStyle
        self.dimAlpha = dimAlpha
        self.gradientStartLocation = gradientStartLocation
        self.gradientEndLocation = gradientEndLocation
        self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        self.blurStyle = .systemThickMaterial
        self.dimAlpha = 0.2
        self.gradientStartLocation = 0.0
        self.gradientEndLocation = 1.0
        self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 블러 이펙트 뷰
        addSubview(blurEffectView)
        
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 어두운 오버레이 뷰
        dimView.backgroundColor = UIColor.black.withAlphaComponent(dimAlpha)
        addSubview(dimView)
        
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradientMask()
    }
    
    private func applyGradientMask() {
        guard let window = window else { return }

        let opaqueBottom = UIColor(red: 0xFB/255.0, green: 0xFB/255.0, blue: 0xFB/255.0, alpha: 1.0).cgColor
        let semiTransparentTop = UIColor(white: 1.0, alpha: 0.5).cgColor
        let fullyTransparent = UIColor(white: 1.0, alpha: 0.0).cgColor

        let viewFrameInWindow = convert(bounds, to: window)
        let viewTop = viewFrameInWindow.minY
        let viewHeight = bounds.height

        // 그라디언트 좌표 계산
        let gradientStartY: CGFloat
        let gradientEndY: CGFloat

        if let refView = referenceView, let refWindow = refView.window {
            // 참조 뷰가 있으면 그 영역을 기준으로 그라디언트 설정
            let refFrameInWindow = refView.convert(refView.bounds, to: refWindow)
            gradientStartY = refFrameInWindow.minY // chartContainerView 상단
            gradientEndY = refFrameInWindow.maxY   // chartContainerView 하단
        } else {
            // 참조 뷰가 없으면 화면 전체를 기준으로 설정
            gradientStartY = 0.0
            gradientEndY = window.bounds.height
        }

        // 뷰의 로컬 좌표계로 변환
        let localStartY = (gradientStartY - viewTop) / viewHeight
        let localEndY = (gradientEndY - viewTop) / viewHeight

        // 블러에 그라데이션 마스크 적용
        // chartContainerView 위쪽: 완전 투명
        // chartContainerView 상단: 반투명 시작
        // chartContainerView 하단: 불투명 끝
        // chartContainerView 아래쪽: 완전 투명
        let blurGradientLayer = CAGradientLayer()
        blurGradientLayer.frame = blurEffectView.bounds
        blurGradientLayer.colors = [
            fullyTransparent,      // chartContainerView 위쪽
            semiTransparentTop,    // chartContainerView 상단
            opaqueBottom,          // chartContainerView 하단
            fullyTransparent       // chartContainerView 아래쪽
        ]
        blurGradientLayer.locations = [
            NSNumber(value: max(0.0, localStartY - 0.01)),  // chartContainerView 바로 위
            NSNumber(value: max(0.0, localStartY)),         // chartContainerView 상단
            NSNumber(value: min(1.0, localEndY)),           // chartContainerView 하단
            NSNumber(value: min(1.0, localEndY + 0.01))     // chartContainerView 바로 아래
        ]
        blurGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        blurGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        blurEffectView.layer.mask = blurGradientLayer

        // dimView에도 같은 그라데이션 마스크 적용
        let dimGradientLayer = CAGradientLayer()
        dimGradientLayer.frame = dimView.bounds
        dimGradientLayer.colors = [
            fullyTransparent,      // chartContainerView 위쪽
            semiTransparentTop,    // chartContainerView 상단
            opaqueBottom,          // chartContainerView 하단
            fullyTransparent       // chartContainerView 아래쪽
        ]
        dimGradientLayer.locations = [
            NSNumber(value: max(0.0, localStartY - 0.01)),
            NSNumber(value: max(0.0, localStartY)),
            NSNumber(value: min(1.0, localEndY)),
            NSNumber(value: min(1.0, localEndY + 0.01))
        ]
        dimGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        dimGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        dimView.layer.mask = dimGradientLayer
    }

    /// 그라디언트 참조 뷰 설정
    /// - Parameter view: 그라디언트 영역의 기준이 되는 뷰
    func setReferenceView(_ view: UIView) {
        self.referenceView = view
        setNeedsLayout()
    }

    /// 그라데이션 방향 설정
    /// - Parameters:
    ///   - startPoint: 시작 지점 (기본값: CGPoint(x: 0.5, y: 0.0) - 위)
    ///   - endPoint: 끝 지점 (기본값: CGPoint(x: 0.5, y: 1.0) - 아래)
    func setGradientDirection(startPoint: CGPoint, endPoint: CGPoint) {
        guard let blurMask = blurEffectView.layer.mask as? CAGradientLayer,
              let dimMask = dimView.layer.mask as? CAGradientLayer else {
            return
        }
        
        blurMask.startPoint = startPoint
        blurMask.endPoint = endPoint
        
        dimMask.startPoint = startPoint
        dimMask.endPoint = endPoint
    }
}
