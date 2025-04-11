//
//  RecentChartRowView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/4/25.
//

import UIKit
import SnapKit

final class RecentChartRowView: UIView {
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let waveLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let ratingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "rating.star.fill") ?? UIImage(systemName: "star.fill")
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var ratingStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [ratingImageView, ratingLabel])
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
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
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        
        addSubview(timeLabel)
        addSubview(windLabel)
        addSubview(waveLabel)
        addSubview(temperatureLabel)
        addSubview(ratingStack)

        // Keep star and text snug; prevent label from stretching
        ratingLabel.setContentHuggingPriority(.required, for: .horizontal)
        ratingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        ratingImageView.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    private func configureLayout() {
        // ChartTableHeaderView와 동일한 레이아웃
        timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(50)
        }
        
        windLabel.snp.makeConstraints { make in
            make.leading.equalTo(timeLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        waveLabel.snp.makeConstraints { make in
            make.leading.equalTo(windLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.leading.equalTo(waveLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        ratingStack.snp.makeConstraints { make in
            make.leading.equalTo(temperatureLabel.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        ratingImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
    
    func configure(with chart: Chart) {
        
        let dateString = chart.time.toFormattedString(format: "M/d")
        let timeString = chart.time.toFormattedString(format: "HH시")
        timeLabel.text = "\(dateString)\n\(timeString)"
        
        // 바람 속도
        windLabel.text = String(format: "%.1fm/s", chart.windSpeed)
        
        // 파도 높이와 주기
        waveLabel.text = String(format: "%.1fm\n%.1fs", chart.waveHeight, chart.wavePeriod)
        
        // 수온
        temperatureLabel.text = String(format: "%.0f°C", chart.waterTemperature)
        
        // 평점 (예시로 랜덤 점수 표시, 실제로는 데이터에 따라 결정)
        let rating = Int.random(in: 1...5)
        ratingLabel.text = "\(rating)점"
        
        print("🔧 ChartRowView: Configuration completed - \(dateString) \(timeString), Wind: \(chart.windSpeed)m/s, Wave: \(chart.waveHeight)m")
    }
}
