//
//  StatCardView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/2/25.
//

import UIKit
import SnapKit
// MARK: - StatCardView (선호하는 차트 통계 카드)
final class PreferredCardView: UIView {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .surfBlue
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let subValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.2)
        layer.cornerRadius = 20
        clipsToBounds = true
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(subValueLabel)
        addSubview(arrowImageView)
    }
    
    private func configureLayout() {
        iconImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.width.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(iconImageView)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(16)
        }
        
        subValueLabel.snp.makeConstraints { make in
            make.leading.equalTo(valueLabel.snp.trailing).offset(8)
            make.bottom.equalTo(valueLabel).offset(-4)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(16)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
    }
    
    func configure(with data: DashboardCardData) {
        iconImageView.image = UIImage(named: data.icon)
        titleLabel.text = data.title
        valueLabel.text = data.value
        subValueLabel.text = data.subtitle ?? ""

        let hasSubtitle = !(data.subtitle?.isEmpty ?? true)
        let isWave = data.type == .wave && hasSubtitle

        if isWave {
            subValueLabel.isHidden = false

            // Wave: place period below height
            valueLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().inset(12)
                make.bottom.equalTo(subValueLabel.snp.top).offset(-2)
            }
            subValueLabel.snp.remakeConstraints { make in
                make.leading.equalTo(valueLabel)
                make.bottom.equalToSuperview().inset(16)
            }
        } else {
            // Wind (or no subtitle): show only value at bottom-left
            subValueLabel.isHidden = true

            valueLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().inset(12)
                make.bottom.equalToSuperview().inset(16)
            }
            // Neutralize subValue constraints to avoid conflicts
            subValueLabel.snp.remakeConstraints { make in
                make.leading.equalTo(valueLabel)
                make.top.equalTo(valueLabel.snp.bottom)
                make.height.equalTo(0)
            }
        }
        
        // 카드 타입에 따라 방향 화살표 애셋 설정
        let arrowAssetName: String = {
            switch data.type {
            case .wind: return AssetImage.windDirection
            case .wave: return AssetImage.swellDirection
            }
        }()
        arrowImageView.image = UIImage(named: arrowAssetName)?.withRenderingMode(.alwaysOriginal)
        arrowImageView.tintColor = nil
        
        // 방향 화살표 회전 설정 (0° = 북/위쪽 기준, 시계방향 회전)
        if let deg = data.directionDegrees {
            arrowImageView.isHidden = false
            let radians = CGFloat(deg) * .pi / 180.0
            arrowImageView.transform = CGAffineTransform(rotationAngle: radians)
        } else {
            // 방향값이 없으면 숨김 처리
            arrowImageView.isHidden = true
            arrowImageView.transform = .identity
        }
    }
}

struct DashboardCardData {
    enum CardType {
        case wind
        case wave
    }
    
    let type: CardType
    let title: String
    let value: String
    let subtitle: String?
    let directionDegrees: Double?
    let icon: String
    let color: UIColor
    
    init(type: CardType, title: String, value: String, subtitle: String? = nil, directionDegrees: Double? = nil, icon: String, color: UIColor) {
        self.type = type
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.directionDegrees = directionDegrees
        self.icon = icon
        self.color = color
    }
}

