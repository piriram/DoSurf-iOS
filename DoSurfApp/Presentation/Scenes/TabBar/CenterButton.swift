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
        }
    }
}
