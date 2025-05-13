//
//  CenterButton.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

import UIKit
import SnapKit

// MARK: - CenterButton
final class CenterButton: UIControl {
    
    private let button = UIButton()
    private var isRecordingState = false
    private var gradientLayer: CAGradientLayer?
    
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
        button.setImage(nil, for: .selected)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.surfBlue, for: .selected)
        
        var config = UIButton.Configuration.plain()
        config.imagePlacement = .top
        config.imagePadding = 6
        config.titleAlignment = .center
        config.contentInsets = .zero
        config.background.cornerRadius = 33.5
        config.background.backgroundColor = .surfBlue
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            var out = incoming
            if self?.isRecordingState == true {
                out.font = .systemFont(ofSize: 16, weight: .bold)
            } else {
                out.font = .systemFont(ofSize: 10, weight: .medium)
            }
            return out
        }
        button.configuration = config
        button.configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.title = button.isSelected ? "서핑중" : "기록하기"
            updated?.image = button.isSelected ? nil : UIImage(named: AssetImage.startWave)
            button.configuration = updated
        }
        button.setNeedsUpdateConfiguration()
        
        // iOS 16-25를 위한 cornerRadius 직접 설정
        button.layer.cornerRadius = 33.5
        
        // Shadow
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowColor = UIColor.surfBlue.cgColor
        layer.shadowOpacity = 0.25
    }
    
    func updateState(isRecording: Bool) {
        isRecordingState = isRecording
        button.isSelected = isRecording
        
        if isRecording {
            button.configuration?.background.backgroundColor = .clear
            button.setTitleColor(.surfBlue, for: .normal)
            button.tintColor = .surfBlue
            addRadialGradient()
        } else {
            button.setTitleColor(.white, for: .normal)
            button.tintColor = .white
            removeRadialGradient()
        }
        
        button.setNeedsUpdateConfiguration()
        
        // Shadow 업데이트
        layer.shadowColor = isRecording
        ? UIColor.surfBlue.withAlphaComponent(0.6).cgColor
        : UIColor.surfBlue.cgColor
        layer.shadowOpacity = isRecording ? 0.0 : 0.25
    }
    
    private func addRadialGradient() {
        removeRadialGradient()
        
        button.backgroundColor = .clear
        
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.colors = [
            UIColor.radialSkyBlue.cgColor,
            UIColor.white.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        let const = 1.5
        gradient.endPoint = CGPoint(x: const, y: const)
        gradient.frame = button.bounds
        gradient.cornerRadius = 33.5
        
        button.layer.insertSublayer(gradient, at: 0)
        self.gradientLayer = gradient
    }
    
    private func removeRadialGradient() {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        button.backgroundColor = .surfBlue
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
        gradientLayer?.frame = button.bounds
        gradientLayer?.cornerRadius = 33.5
    }
}
