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
final class ChartTableViewCell: UITableViewCell {
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
    
    // 스택 중첩 최소화: 상위 1개 + 섹션별 1개 수준으로 단순화
    private let containerStackView = UIStackView()
    private let timeStackView = UIStackView()
    private let windStackView = UIStackView()
    private let waveStackView = UIStackView()
    private let waterTemperatureStackView = UIStackView()
    private let weatherStackView = UIStackView()
    
    // 불필요한 재설정 방지용 캐시
    private var cachedWindRadians: CGFloat?
    private var cachedWaveRadians: CGFloat?
    private var cachedWeatherIconName: String?
    
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
        
        // 캐시는 그대로 두어 동일 값 재적용을 피함
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.isOpaque = true
        selectionStyle = .none
        
        // Time Label - Typography 적용
        timeLabel.applyTypography(.captionMedium, color: UIColor(white: 1, alpha: 0.7))
        timeLabel.textAlignment = .center
        
        // Wind Components
        windIconImageView.image = UIImage(named: AssetImage.windDirection)
        windIconImageView.contentMode = .scaleAspectFit
        
        // Wind Speed Label - Typography 적용
        windSpeedLabel.applyTypography(.body2Medium, color: .lableBlack)
        windSpeedLabel.adjustsFontSizeToFitWidth = true
        windSpeedLabel.minimumScaleFactor = 0.8
        
        // Wave Components
        waveIconImageView.image = UIImage(named: AssetImage.swellDirection)
        waveIconImageView.tintColor = .systemCyan
        waveIconImageView.contentMode = .scaleAspectFit
        
        // Wave Height / Speed - Typography 적용
        waveHeightLabel.applyTypography(.body2Medium, color: .lableBlack)
        waveHeightLabel.adjustsFontSizeToFitWidth = true
        waveHeightLabel.minimumScaleFactor = 0.8
        
        waveSpeedLabel.applyTypography(.body2Medium, color: .lableBlack)
        waveSpeedLabel.adjustsFontSizeToFitWidth = true
        waveSpeedLabel.minimumScaleFactor = 0.7
        
        // Weather
        weatherIconImageView.contentMode = .scaleAspectFit
        weatherIconImageView.tintColor = .systemOrange
        
        airTemperatureLabel.applyTypography(.body2Medium, color: .lableBlack)
        airTemperatureLabel.adjustsFontSizeToFitWidth = true
        airTemperatureLabel.minimumScaleFactor = 0.8
        airTemperatureLabel.textAlignment = .right
        
        // Water Temperature
        waterTemperatureLabel.applyTypography(.body2Medium, color: .lableBlack)
        waterTemperatureLabel.adjustsFontSizeToFitWidth = true
        waterTemperatureLabel.minimumScaleFactor = 0.8
        
        waterTemperatureImageView.image = UIImage(named: AssetImage.waterTemperature)
        waterTemperatureImageView.contentMode = .scaleAspectFit
        
        setupStackViews()
    }
    
    private func setupStackViews() {
        // 상위 컨테이너 (수평 1단)
        containerStackView.axis = .horizontal
        containerStackView.alignment = .center
        containerStackView.distribution = .equalSpacing
        containerStackView.spacing = 6
        contentView.addSubview(containerStackView)
        
        // 시간 (수직 1단)
        timeStackView.axis = .vertical
        timeStackView.alignment = .center
        timeStackView.spacing = 2
        timeStackView.addArrangedSubview(timeLabel)
        
        // 바람 (수평 1단)
        windStackView.axis = .horizontal
        windStackView.alignment = .center
        windStackView.spacing = 7
        windStackView.addArrangedSubview(windIconImageView)
        windStackView.addArrangedSubview(windSpeedLabel)
        
        // 파도 (수평 1단) - 세부 텍스트는 수직 1단
        let waveInfoStack = UIStackView(arrangedSubviews: [waveHeightLabel, waveSpeedLabel])
        waveInfoStack.axis = .vertical
        waveInfoStack.alignment = .center
        waveInfoStack.spacing = 2
        
        waveStackView.axis = .horizontal
        waveStackView.alignment = .center
        waveStackView.spacing = 7
        waveStackView.addArrangedSubview(waveIconImageView)
        waveStackView.addArrangedSubview(waveInfoStack)
        
        // 수온 (수직 1단)
        waterTemperatureStackView.axis = .vertical
        waterTemperatureStackView.alignment = .center
        waterTemperatureStackView.spacing = 1
        waterTemperatureStackView.addArrangedSubview(waterTemperatureLabel)
        waterTemperatureStackView.addArrangedSubview(waterTemperatureImageView)
        
        // 날씨 (수평 1단)
        weatherStackView.axis = .horizontal
        weatherStackView.alignment = .center
        weatherStackView.spacing = 4
        weatherStackView.distribution = .fill
        weatherStackView.addArrangedSubview(weatherIconImageView)
        weatherStackView.addArrangedSubview(airTemperatureLabel)
        
        // 컨테이너에 추가
        containerStackView.addArrangedSubview(timeStackView)
        containerStackView.addArrangedSubview(windStackView)
        containerStackView.addArrangedSubview(waveStackView)
        containerStackView.addArrangedSubview(waterTemperatureStackView)
        containerStackView.addArrangedSubview(weatherStackView)
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
        
        // 수온 이미지 너비 = 라벨 너비
        waterTemperatureImageView.snp.makeConstraints { make in
            make.width.equalTo(waterTemperatureLabel.snp.width)
        }
        
        // 최소 폭 제약 (자동 줄바꿈/압축을 줄여 스택 레이아웃 안정화)
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
            make.width.equalTo(60)
        }
        airTemperatureLabel.snp.makeConstraints { make in
            make.width.equalTo(36)
        }
        waterTemperatureStackView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(60)
        }
        
        containerStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(4)
            make.height.greaterThanOrEqualTo(30)
        }
    }
    
    // MARK: - Configure
    func configure(with chart: Chart) {
        // 포매팅 문자열은 경량 포맷 사용 (Formatter 객체 생성 없음)
        timeLabel.setTextWithTypography(chart.time.toFormattedString(format: "HH시"), style: .body2Medium, color: UIColor(white: 0, alpha: 0.7))
        windSpeedLabel.setTextWithTypography(String(format: "%.1fm/s", chart.windSpeed), style: .body1Medium)
        waveHeightLabel.setTextWithTypography(String(format: "%.1fm", chart.waveHeight), style: .body1Medium)
        waveSpeedLabel.setTextWithTypography(String(format: "%.1fs", chart.wavePeriod), style: .captionMedium, color: .secondaryLabel)
        airTemperatureLabel.setTextWithTypography(String(format: "%.0f°C", chart.airTemperature), style: .body1Medium)
        waterTemperatureLabel.setTextWithTypography(String(format: "%.0f°C", chart.waterTemperature), style: .body1Medium, color: .label)
        
        // 동일 각도/아이콘 중복 설정 방지
        let windRadians = chart.windDirection * .pi / 180
        if cachedWindRadians != windRadians {
            windIconImageView.transform = CGAffineTransform(rotationAngle: windRadians)
            cachedWindRadians = windRadians
        }
        
        let waveRadians = chart.waveDirection * .pi / 180
        if cachedWaveRadians != waveRadians {
            waveIconImageView.transform = CGAffineTransform(rotationAngle: waveRadians)
            cachedWaveRadians = waveRadians
        }
        
        if cachedWeatherIconName != chart.weather.iconName {
            weatherIconImageView.image = UIImage(named: chart.weather.iconName)
            cachedWeatherIconName = chart.weather.iconName
        }
    }
}
