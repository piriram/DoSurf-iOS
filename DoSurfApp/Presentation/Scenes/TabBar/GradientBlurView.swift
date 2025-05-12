//
//  GradientBlurView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

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
        // 블러에 그라데이션 마스크 적용
        let blurGradientLayer = CAGradientLayer()
        blurGradientLayer.frame = blurEffectView.bounds
        blurGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.cgColor
        ]
        blurGradientLayer.locations = [
            NSNumber(value: gradientStartLocation),
            NSNumber(value: gradientEndLocation)
        ]
        blurGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        blurGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        blurEffectView.layer.mask = blurGradientLayer
        
        // dimView에도 같은 그라데이션 마스크 적용
        let dimGradientLayer = CAGradientLayer()
        dimGradientLayer.frame = dimView.bounds
        dimGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.cgColor
        ]
        dimGradientLayer.locations = [
            NSNumber(value: gradientStartLocation),
            NSNumber(value: gradientEndLocation)
        ]
        dimGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        dimGradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        dimView.layer.mask = dimGradientLayer
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
