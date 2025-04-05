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
    private let waveIconImageView = UIImageView()
    private let waveHeightLabel = UILabel()
    private let waveSpeedLabel = UILabel()
    private let weatherIconImageView = UIImageView()
    private let airTemperatureLabel = UILabel()
    private let waterTemperatureLabel = UILabel()
    private let waterTemperatureImageView = UIImageView()
    
    private let containerStackView = UIStackView()
    private let timeStackView = UIStackView()
    private let windStackView = UIStackView()
    private let waveStackView = UIStackView()
    private let weatherStackView = UIStackView()
    private let waterTemperatureStackView = UIStackView()
    
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
        timeLabel.text = nil
        windSpeedLabel.text = nil
        waveHeightLabel.text = nil
        waveSpeedLabel.text = nil
        airTemperatureLabel.text = nil
        waterTemperatureLabel.text = nil
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .none
        
        // Time Label - Typography 적용
        timeLabel.applyTypography(.body2Medium, color: UIColor(white: 1, alpha: 0.7))
        timeLabel.textAlignment = .center
        
        // Wind Components
        windIconImageView.image = UIImage(named: "windDirectionIcon")
        windIconImageView.contentMode = .scaleAspectFit
        
        // Wind Speed Label - Typography 적용
        windSpeedLabel.applyTypography(.body1Medium, color: .label)
        windSpeedLabel.adjustsFontSizeToFitWidth = true
        windSpeedLabel.minimumScaleFactor = 0.8
        
        // Wave Components
        waveIconImageView.image = UIImage(named: "swellDirectionIcon")
        waveIconImageView.tintColor = .systemCyan
        waveIconImageView.contentMode = .scaleAspectFit
        
        // Wave Height Label - Typography 적용
//        waveHeightLabel.applyTypography(.body1Medium, color: .label)
        waveHeightLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        waveHeightLabel.adjustsFontSizeToFitWidth = true
        waveHeightLabel.minimumScaleFactor = 0.8
        
        // Wave Speed Label - Typography 적용 (더 작은 텍스트용)
        waveSpeedLabel.applyTypography(.captionMedium, color: .label)
        waveSpeedLabel.adjustsFontSizeToFitWidth = true
        waveSpeedLabel.minimumScaleFactor = 0.7
        
        // Weather Icon
        weatherIconImageView.contentMode = .scaleAspectFit
        weatherIconImageView.tintColor = .systemOrange
        
        // Air Temperature Label - Typography 적용
        airTemperatureLabel.applyTypography(.body1Medium, color: .label)
        airTemperatureLabel.adjustsFontSizeToFitWidth = true
        airTemperatureLabel.minimumScaleFactor = 0.8
        
        // Water Temperature Label - Typography 적용
        waterTemperatureLabel.applyTypography(.body1Medium, color: .label)
        waterTemperatureLabel.adjustsFontSizeToFitWidth = true
        waterTemperatureLabel.minimumScaleFactor = 0.8
        
        // Water Temperature Image
        waterTemperatureImageView.image = UIImage(named: "waterTemperature") ?? UIImage(systemName: "drop.fill")
        waterTemperatureImageView.contentMode = .scaleAspectFit
        
        // Stack Views
        setupStackViews()
    }
    
    private func setupStackViews() {
        // Time Stack
        timeStackView.addArrangedSubview(timeLabel)
        timeStackView.axis = .vertical
        timeStackView.alignment = .center
        timeStackView.spacing = 2
        
        // Wind Stack
        let windInfoStack = UIStackView(arrangedSubviews: [windSpeedLabel])
        windInfoStack.axis = .vertical
        windInfoStack.alignment = .leading
        windInfoStack.spacing = 2
        
        windStackView.addArrangedSubview(windIconImageView)
        windStackView.addArrangedSubview(windInfoStack)
        windStackView.axis = .horizontal
        windStackView.alignment = .center
        windStackView.spacing = 7
        
        // Wave Stack
        let waveInfoStack = UIStackView(arrangedSubviews: [waveHeightLabel, waveSpeedLabel])
        waveInfoStack.axis = .vertical
        waveInfoStack.alignment = .center
        waveInfoStack.spacing = 2
        
        waveStackView.addArrangedSubview(waveIconImageView)
        waveStackView.addArrangedSubview(waveInfoStack)
        waveStackView.axis = .horizontal
        waveStackView.alignment = .center
        waveStackView.spacing = 7
        
        // Weather Stack (날씨 아이콘과 기온)
        let weatherInfoStack = UIStackView(arrangedSubviews: [airTemperatureLabel])
        weatherInfoStack.axis = .vertical
        weatherInfoStack.alignment = .center
        weatherInfoStack.spacing = 2
        
        weatherStackView.addArrangedSubview(weatherIconImageView)
        weatherStackView.addArrangedSubview(weatherInfoStack)
        weatherStackView.axis = .horizontal
        weatherStackView.alignment = .center
        weatherStackView.spacing = 1
        
        // Water Temperature Stack
        let waterTempInfoStack = UIStackView(arrangedSubviews: [waterTemperatureLabel])
        waterTempInfoStack.axis = .vertical
        waterTempInfoStack.alignment = .center
        waterTempInfoStack.spacing = 2
        
        
        waterTemperatureStackView.addArrangedSubview(waterTempInfoStack)
        waterTemperatureStackView.addArrangedSubview(waterTemperatureImageView)
        waterTemperatureStackView.axis = .vertical
        waterTemperatureStackView.alignment = .center
        waterTemperatureStackView.spacing = 1
        
        // Main Container Stack
        containerStackView.addArrangedSubview(timeStackView)
        containerStackView.addArrangedSubview(windStackView)
        containerStackView.addArrangedSubview(waveStackView)
        containerStackView.addArrangedSubview(waterTemperatureStackView)
        containerStackView.addArrangedSubview(weatherStackView)
        containerStackView.axis = .horizontal
        containerStackView.distribution = .equalSpacing
        containerStackView.alignment = .center
        containerStackView.spacing = 6
        
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
            make.width.equalTo(waterTemperatureLabel.snp.width)
        }
        
        // 각 스택뷰의 최소 너비 설정
        timeStackView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(30)
        }
        
        windStackView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(60)
        }
        
        waveStackView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(60)
        }
        
        weatherStackView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(40)
        }
        
        waterTemperatureStackView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(60)
        }
        
        containerStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(4)
            make.height.greaterThanOrEqualTo(30) // 최소 높이 보장
        }
    }
    
    // MARK: - Configure
    func configure(with chart: Chart) {
        // Time - setTextWithTypography 사용하여 완전한 스타일링 적용
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH시"
        timeLabel.setTextWithTypography(timeFormatter.string(from: chart.time), style: .body2Medium, color: UIColor(white: 0, alpha: 0.7))
        
        // Wind - setTextWithTypography 사용
        windSpeedLabel.setTextWithTypography(String(format: "%.1fm/s", chart.windSpeed), style: .body1Medium)
        
        // Update wind direction icon rotation
        let windRadians = chart.windDirection * .pi / 180
        windIconImageView.transform = CGAffineTransform(rotationAngle: windRadians)
        
        // Wave - setTextWithTypography 사용
        waveHeightLabel.setTextWithTypography(String(format: "%.1fm", chart.waveHeight), style: .body1Medium)
        waveSpeedLabel.setTextWithTypography(String(format: "%.1fs", chart.wavePeriod), style: .captionMedium, color: .secondaryLabel)
        
        // Update wave direction icon rotation
        let waveRadians = chart.waveDirection * .pi / 180
        waveIconImageView.transform = CGAffineTransform(rotationAngle: waveRadians)
        
        // Weather
        weatherIconImageView.image = UIImage(named: chart.weather.iconName)
        
        // Temperature - setTextWithTypography 사용
        airTemperatureLabel.setTextWithTypography(String(format: "%.0f°C", chart.airTemperature), style: .body1Medium)
        waterTemperatureLabel.setTextWithTypography(String(format: "%.0f°C", chart.waterTemperature), style: .body1Medium, color: .label)
    }
}

