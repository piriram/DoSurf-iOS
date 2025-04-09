//
//  StatCardView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/2/25.
//

import UIKit
import SnapKit
// MARK: - StatCardView (선호하는 차트 통계 카드)
final class StatCardView: UIView {
    
    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)
        view.layer.cornerRadius = 20
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
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
        imageView.image = UIImage(systemName: "arrow.up.right")
        imageView.tintColor = .white.withAlphaComponent(0.6)
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
        
        iconBackgroundView.addSubview(iconImageView)
        addSubview(iconBackgroundView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(subValueLabel)
        addSubview(arrowImageView)
    }
    
    private func configureLayout() {
        iconBackgroundView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.width.height.equalTo(40)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(8)
            make.centerY.equalTo(iconBackgroundView)
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
            make.trailing.bottom.equalToSuperview().inset(12)
            make.width.height.equalTo(20)
        }
    }
    
    func configure(with data: DashboardCardData) {
        iconImageView.image = UIImage(systemName: data.icon)
        titleLabel.text = data.title
        valueLabel.text = data.value
        subValueLabel.text = data.subtitle ?? ""
        subValueLabel.isHidden = (data.subtitle?.isEmpty ?? true)
        iconBackgroundView.backgroundColor = data.color
    }
}
