//
//  ChartTableViewCell.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/27/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - Chart Table View Cell
class ChartTableViewCell: UITableViewCell {
    static let identifier = "ChartTableViewCell"
    
    // MARK: - UI Components
    private let timeLabel = UILabel()
    private let windIconImageView = UIImageView()
    private let windSpeedLabel = UILabel()
    private let windDirectionLabel = UILabel()
    private let waveIconImageView = UIImageView()
    private let waveHeightLabel = UILabel()
    private let waveSpeedLabel = UILabel()
    private let weatherIconImageView = UIImageView()
    private let airTemperatureLabel = UILabel()
    private let waterTemperatureLabel = UILabel()
    private let waterTemperatureImageView = UIImageView()
    
    private let containerStackView = UIStackView()
    private let windStackView = UIStackView()
    private let waveStackView = UIStackView()
    private let temperatureStackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset all values
        timeLabel.text = nil
        windSpeedLabel.text = nil
        windDirectionLabel.text = nil
        waveHeightLabel.text = nil
        waveSpeedLabel.text = nil
        airTemperatureLabel.text = nil
        waterTemperatureLabel.text = nil
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = UIColor.systemGray6
        selectionStyle = .none
        
        // Time Label
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = .label
        timeLabel.textAlignment = .center
        
        // Wind Components
        windIconImageView.image = UIImage(named: "windDirectionIcon")
        windIconImageView.tintColor = .systemBlue
        windIconImageView.contentMode = .scaleAspectFit
        
        windSpeedLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        windSpeedLabel.textColor = .label
        windSpeedLabel.adjustsFontSizeToFitWidth = true
        windSpeedLabel.minimumScaleFactor = 0.8
        
        windDirectionLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        windDirectionLabel.textColor = .secondaryLabel
        windDirectionLabel.adjustsFontSizeToFitWidth = true
        windDirectionLabel.minimumScaleFactor = 0.8
        
        // Wave Components
        waveIconImageView.image = UIImage(named: "swellDirectionIcon")
        waveIconImageView.tintColor = .systemCyan
        waveIconImageView.contentMode = .scaleAspectFit
        
        waveHeightLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        waveHeightLabel.textColor = .label
        waveHeightLabel.adjustsFontSizeToFitWidth = true
        waveHeightLabel.minimumScaleFactor = 0.8
        
        waveSpeedLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        waveSpeedLabel.textColor = .secondaryLabel
        waveSpeedLabel.adjustsFontSizeToFitWidth = true
        waveSpeedLabel.minimumScaleFactor = 0.8
        
        // Weather Icon
        weatherIconImageView.contentMode = .scaleAspectFit
        weatherIconImageView.tintColor = .systemOrange
        
        // Temperature Labels
        airTemperatureLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        airTemperatureLabel.textColor = .label
        airTemperatureLabel.adjustsFontSizeToFitWidth = true
        airTemperatureLabel.minimumScaleFactor = 0.8
        
        waterTemperatureLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        waterTemperatureLabel.textColor = .systemBlue
        waterTemperatureLabel.adjustsFontSizeToFitWidth = true
        waterTemperatureLabel.minimumScaleFactor = 0.8
        
        // Water Temperature Image
        waterTemperatureImageView.image = UIImage(named: "waterTemperature") ?? UIImage(systemName: "drop.fill")
        waterTemperatureImageView.contentMode = .scaleAspectFit
        waterTemperatureImageView.tintColor = .systemBlue
        
        // Stack Views
        setupStackViews()
    }
    
    private func setupStackViews() {
        // Wind Stack
        let windInfoStack = UIStackView(arrangedSubviews: [windSpeedLabel, windDirectionLabel])
        windInfoStack.axis = .vertical
        windInfoStack.alignment = .leading
        windInfoStack.spacing = 2
        
        windStackView.addArrangedSubview(windIconImageView)
        windStackView.addArrangedSubview(windInfoStack)
        windStackView.axis = .horizontal
        windStackView.alignment = .center
        windStackView.spacing = 4
        
        // Wave Stack
        let waveInfoStack = UIStackView(arrangedSubviews: [waveHeightLabel, waveSpeedLabel])
        waveInfoStack.axis = .vertical
        waveInfoStack.alignment = .leading
        waveInfoStack.spacing = 2
        
        waveStackView.addArrangedSubview(waveIconImageView)
        waveStackView.addArrangedSubview(waveInfoStack)
        waveStackView.axis = .horizontal
        waveStackView.alignment = .center
        waveStackView.spacing = 4
        
        // Temperature Stack
        let waterTempStack = UIStackView(arrangedSubviews: [waterTemperatureLabel, waterTemperatureImageView])
        waterTempStack.axis = .vertical
        waterTempStack.alignment = .center
        waterTempStack.spacing = 2
        temperatureStackView.addArrangedSubview(waterTempStack)
        temperatureStackView.addArrangedSubview(weatherIconImageView)
        temperatureStackView.addArrangedSubview(airTemperatureLabel)
        temperatureStackView.axis = .horizontal
        temperatureStackView.alignment = .center
        temperatureStackView.spacing = 4
        
        // Main Container Stack
        containerStackView.addArrangedSubview(timeLabel)
        containerStackView.addArrangedSubview(windStackView)
        containerStackView.addArrangedSubview(waveStackView)
        containerStackView.addArrangedSubview(temperatureStackView)
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fill
        containerStackView.alignment = .center
        containerStackView.spacing = 8
        
        contentView.addSubview(containerStackView)
    }
    
    private func setupConstraints() {
        windIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        waveIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        weatherIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
        
        waterTemperatureImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        // 시간 레이블의 너비를 고정 (가장 짧은 텍스트)
        timeLabel.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
        
        // 각 스택뷰의 최소 너비 설정과 우선순위 조정
        timeLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        
        windStackView.setContentHuggingPriority(UILayoutPriority(900), for: .horizontal)
        windStackView.setContentCompressionResistancePriority(UILayoutPriority(900), for: .horizontal)
        
        waveStackView.setContentHuggingPriority(UILayoutPriority(900), for: .horizontal)
        waveStackView.setContentCompressionResistancePriority(UILayoutPriority(900), for: .horizontal)
        
        temperatureStackView.setContentHuggingPriority(UILayoutPriority(900), for: .horizontal)
        temperatureStackView.setContentCompressionResistancePriority(UILayoutPriority(900), for: .horizontal)
        
        // 텍스트 레이블들의 압축 저항성을 높임 (잘리지 않도록)
        windSpeedLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        windDirectionLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        waveHeightLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        waveSpeedLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        airTemperatureLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        waterTemperatureLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)
        
        containerStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }
    
    // MARK: - Configure
    func configure(with chart: Chart) {
        // Time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH시"
        timeLabel.text = timeFormatter.string(from: chart.time)
        // Wind
        windSpeedLabel.text = String(format: "%.1fm/s", chart.windSpeed)
        windDirectionLabel.text = String(format: "%.0f°", chart.windDirection)
        
        // Update wind direction icon rotation
        let windRadians = chart.windDirection * .pi / 180
        windIconImageView.transform = CGAffineTransform(rotationAngle: windRadians)
        
        // Wave
        waveHeightLabel.text = String(format: "%.1fm", chart.waveHeight)
        waveSpeedLabel.text = String(format: "%.1fm/s", chart.waveSpeed)
        
        // Update wave direction icon rotation
        let waveRadians = chart.waveDirection * .pi / 180
        waveIconImageView.transform = CGAffineTransform(rotationAngle: waveRadians)
        
        // Weather
        weatherIconImageView.image = UIImage(named: chart.weather.iconName)
        
        // Temperature
        airTemperatureLabel.text = String(format: "%.0f°C", chart.airTemperature)
        waterTemperatureLabel.text = String(format: "%.0f°C", chart.waterTemperature)
    }
}

