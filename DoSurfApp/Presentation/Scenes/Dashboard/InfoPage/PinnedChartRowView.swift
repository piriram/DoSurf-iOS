//
//  PinnedChartRowView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/4/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

// MARK: - PinnedChartRowView (고정 차트용)
final class PinnedChartRowView: UIView {
    
    private let pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: AssetImage.pinFill)
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        return imageView
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
        imageView.image = UIImage(named: AssetImage.ratingStarFill)
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
        
        addSubview(pinImageView)
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
        // PinnedChartTableHeaderView와 동일한 레이아웃
        pinImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        
        windLabel.snp.makeConstraints { make in
            make.leading.equalTo(pinImageView.snp.trailing).offset(24) // 44 - 20 = 24
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        waveLabel.snp.makeConstraints { make in
            make.leading.equalTo(windLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.leading.equalTo(waveLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        ratingStack.snp.makeConstraints { make in
            make.leading.equalTo(temperatureLabel.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        
        ratingImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
    
    func configure(with record: SurfRecordData) {
        print("📌 PinnedChartRowView: Configuring with record date: \(record.surfDate)")
        
        // 기본값 설정
        var avgWindSpeed: Double = 0
        var avgWaveHeight: Double = 0
        var avgWavePeriod: Double = 0
        var avgWaterTemperature: Double = 0
        
        // 해당 기록의 모든 차트 데이터에서 평균 계산
        if !record.charts.isEmpty {
            avgWindSpeed = record.charts.map { $0.windSpeed }.reduce(0, +) / Double(record.charts.count)
            avgWaveHeight = record.charts.map { $0.waveHeight }.reduce(0, +) / Double(record.charts.count)
            avgWavePeriod = record.charts.map { $0.wavePeriod }.reduce(0, +) / Double(record.charts.count)
            avgWaterTemperature = record.charts.map { $0.waterTemperature }.reduce(0, +) / Double(record.charts.count)
        }
        
        // 바람 속도
        windLabel.text = String(format: "%.1fm/s", avgWindSpeed)
        
        // 파도 높이와 주기
        waveLabel.text = String(format: "%.1fm\n%.1fs", avgWaveHeight, avgWavePeriod)
        
        // 수온
        temperatureLabel.text = String(format: "%.0f°C", avgWaterTemperature)
        
        // 평가 점수 (SurfRecord의 rating 사용)
        let rating = Int(record.rating)
        ratingLabel.text = "\(rating)점"
    }
}
// MARK: - PinnedChartTableHeaderView (고정 차트용 테이블 헤더)
final class PinnedChartTableHeaderView: UIView {
    
    private let pinnedLabel: UILabel = {
        let label = UILabel()
        label.text = "고정"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemYellow
        label.textAlignment = .center
        return label
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.text = "바람"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let waveLabel: UILabel = {
        let label = UILabel()
        label.text = "파도"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "수온"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "평가"
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
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
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        
        addSubview(pinnedLabel)
        addSubview(windLabel)
        addSubview(waveLabel)
        addSubview(temperatureLabel)
        addSubview(ratingLabel)
    }
    
    private func configureLayout() {
        // PinnedChartRowView와 동일한 레이아웃으로 정렬
        pinnedLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(44) // 핀 아이콘 + 텍스트 공간
        }
        
        windLabel.snp.makeConstraints { make in
            make.leading.equalTo(pinnedLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        waveLabel.snp.makeConstraints { make in
            make.leading.equalTo(windLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.leading.equalTo(waveLabel.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        
        ratingLabel.snp.makeConstraints { make in
            make.leading.equalTo(temperatureLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }
}
