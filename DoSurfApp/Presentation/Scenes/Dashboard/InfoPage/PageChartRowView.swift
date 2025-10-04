//
//  RecentChartRowView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/4/25.
//

// MARK: - ChartColumnRatio
import UIKit
import SnapKit
import RxSwift
import RxCocoa

enum ChartRatio {
    static let first: CGFloat = 0.3
    static let second: CGFloat = 0.55
    static let third: CGFloat = 0.54
    static let fourth: CGFloat = 0.32
    static let fifth: CGFloat = 0.42
}

// MARK: - ChartColumnRatio
enum ChartColumnRatio {
    private static let rawFirst: CGFloat = ChartRatio.first
    private static let rawWind: CGFloat = ChartRatio.second
    private static let rawWave: CGFloat = ChartRatio.third
    private static let rawTemperature: CGFloat = ChartRatio.fourth
    private static let rawRating: CGFloat = ChartRatio.fifth
    
    private static let total: CGFloat = rawFirst + rawWind + rawWave + rawTemperature + rawRating
    private static let contentFraction: CGFloat = 0.90
    
    static let first: CGFloat = (rawFirst / total) * contentFraction
    static let wind: CGFloat = (rawWind / total) * contentFraction
    static let wave: CGFloat = (rawWave / total) * contentFraction
    static let temperature: CGFloat = (rawTemperature / total) * contentFraction
    static let rating: CGFloat = (rawRating / total) * contentFraction
}

// MARK: - ChartRowView
final class ChartRowView: UIView {
    
    private let isTimeMode: Bool
    
    // Time mode components
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.fourteen, weight: ChartFont.semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let hourLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.twelve, weight: ChartFont.medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var timeStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [dateLabel, hourLabel])
        sv.axis = .vertical
        sv.spacing = 0
        sv.alignment = .center
        return sv
    }()
    
    // Pin mode component
    private let pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "pin.fill")
        imageView.tintColor = .pinBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.fourteen, weight: ChartFont.medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let waveHeightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.fourteen, weight: ChartFont.medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let wavePeriodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.twelve, weight: ChartFont.medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var waveValueStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [waveHeightLabel, wavePeriodLabel])
        sv.axis = .vertical
        sv.spacing = 0
        sv.alignment = .center
        return sv
    }()
    
    private let windDirectionImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: AssetImage.windDirection))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let waveDirectionImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: AssetImage.swellDirection))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var windStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [windDirectionImageView, windLabel])
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
    }()
    
    private lazy var waveStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [waveDirectionImageView, waveValueStack])
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.fourteen, weight: ChartFont.medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.fourteen, weight: ChartFont.medium)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let ratingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: AssetImage.ratingStarFill)
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
    
    private let firstColumn = UIView()
    private let windColumn = UIView()
    private let waveColumn = UIView()
    private let tempColumn = UIView()
    private let ratingColumn = UIView()
    
    private lazy var columnStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [
            firstColumn, windColumn, waveColumn, tempColumn, ratingColumn
        ])
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.spacing = 0
        return sv
    }()
    
    private var columnCenterYConstraint: Constraint?
    private var columnTopConstraint: Constraint?
    
    private let surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()
    private var configureBag = DisposeBag()
    
    init(isTimeMode: Bool) {
        self.isTimeMode = isTimeMode
        super.init(frame: .zero)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        
        if isTimeMode {
            firstColumn.addSubview(timeStack)
        } else {
            firstColumn.addSubview(pinImageView)
        }
        
        windColumn.addSubview(windStack)
        waveColumn.addSubview(waveStack)
        tempColumn.addSubview(temperatureLabel)
        ratingColumn.addSubview(ratingStack)
        
        addSubview(columnStackView)
        
        ratingLabel.setContentHuggingPriority(.required, for: .horizontal)
        ratingImageView.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    private func configureLayout() {
        columnStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()  // 항상 중앙 정렬
        }
        
        firstColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.first)
        }
        
        windColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.wind)
        }
        
        waveColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.wave)
        }
        
        tempColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.temperature)
        }
        
        ratingColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.rating)
        }
        
        if isTimeMode {
            timeStack.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview().priority(.high)
                make.trailing.lessThanOrEqualToSuperview().priority(.high)
                make.width.lessThanOrEqualToSuperview()
            }
        } else {
            pinImageView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(23)
            }
        }
        
        windStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().priority(.high)
            make.trailing.lessThanOrEqualToSuperview().priority(.high)
            make.width.lessThanOrEqualToSuperview()
        }
        
        waveStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().priority(.high)
            make.trailing.lessThanOrEqualToSuperview().priority(.high)
            make.width.lessThanOrEqualToSuperview()
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().priority(.high)
            make.trailing.lessThanOrEqualToSuperview().priority(.high)
            make.width.lessThanOrEqualToSuperview()
        }
        
        ratingStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().priority(.high)
            make.trailing.lessThanOrEqualToSuperview().priority(.high)
            make.width.lessThanOrEqualToSuperview()
        }
        
        windDirectionImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        
        waveDirectionImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        
        ratingImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    
    func configure(with chart: Chart) {
        configureBag = DisposeBag()
        
        if isTimeMode {
            let dateString = chart.time.toFormattedString(format: "M/d")
            let timeString = chart.time.toFormattedString(format: "HH시")
            dateLabel.text = dateString
            hourLabel.text = timeString
        }
        
        windLabel.text = String(format: "%.1fm/s", chart.windSpeed)
        waveHeightLabel.text = String(format: "%.1fm", chart.waveHeight)
        wavePeriodLabel.text = String(format: "%.1fs", chart.wavePeriod)
        temperatureLabel.text = String(format: "%.0f°C", chart.waterTemperature)
        
        ratingLabel.text = "—점"
        surfRecordUseCase.fetchSurfRecords(for: chart.beachID)
            .map { records -> Int? in
                if let matched = records.first(where: { record in
                    record.charts.contains(where: { $0.time == chart.time })
                }) {
                    return Int(matched.rating)
                }
                return nil
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] rating in
                if let rating = rating {
                    self?.ratingLabel.text = "\(rating)점"
                } else {
                    self?.ratingLabel.text = "—점"
                }
            }, onFailure: { [weak self] _ in
                self?.ratingLabel.text = "—점"
            })
            .disposed(by: configureBag)
    }
    
    func configure(with record: SurfRecordData) {
        var avgWindSpeed: Double = 0
        var avgWaveHeight: Double = 0
        var avgWavePeriod: Double = 0
        var avgWaterTemperature: Double = 0
        
        if !record.charts.isEmpty {
            avgWindSpeed = record.charts.map { $0.windSpeed }.reduce(0, +) / Double(record.charts.count)
            avgWaveHeight = record.charts.map { $0.waveHeight }.reduce(0, +) / Double(record.charts.count)
            avgWavePeriod = record.charts.map { $0.wavePeriod }.reduce(0, +) / Double(record.charts.count)
            avgWaterTemperature = record.charts.map { $0.waterTemperature }.reduce(0, +) / Double(record.charts.count)
        }
        
        windLabel.text = String(format: "%.1fm/s", avgWindSpeed)
        waveHeightLabel.text = String(format: "%.1fm", avgWaveHeight)
        wavePeriodLabel.text = String(format: "%.1fs", avgWavePeriod)
        temperatureLabel.text = String(format: "%.0f°C", avgWaterTemperature)
        
        let rating = Int(record.rating)
        ratingLabel.text = "\(rating)점"
    }
}

// MARK: - ChartTableHeaderView
final class ChartTableHeaderView: UIView {
    
    private let isTimeMode: Bool
    
    private let firstLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: ChartFont.twelve, weight: ChartFont.semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.text = "바람"
        label.font = .systemFont(ofSize: ChartFont.twelve, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let waveLabel: UILabel = {
        let label = UILabel()
        label.text = "파도"
        label.font = .systemFont(ofSize: ChartFont.twelve, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "수온"
        label.font = .systemFont(ofSize: ChartFont.twelve, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "평가"
        label.font = .systemFont(ofSize: ChartFont.twelve, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let firstColumn = UIView()
    private let windColumn = UIView()
    private let waveColumn = UIView()
    private let tempColumn = UIView()
    private let ratingColumn = UIView()
    
    private lazy var columnStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [
            firstColumn, windColumn, waveColumn, tempColumn, ratingColumn
        ])
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.spacing = 0
        return sv
    }()
    
    private var headerCenterYConstraint: Constraint?
    private var headerTopConstraint: Constraint?
    private var headerBottomConstraint: Constraint?
    
    init(isTimeMode: Bool) {
        self.isTimeMode = isTimeMode
        super.init(frame: .zero)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        
        firstLabel.text = isTimeMode ? "시간" : "고정"
        firstLabel.textColor = .white.withAlphaComponent(0.8)
        
        firstColumn.addSubview(firstLabel)
        windColumn.addSubview(windLabel)
        waveColumn.addSubview(waveLabel)
        tempColumn.addSubview(temperatureLabel)
        ratingColumn.addSubview(ratingLabel)
        
        addSubview(columnStackView)
    }
    
    private func configureLayout() {
        columnStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()  // 항상 중앙 정렬
        }
        
        firstColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.first)
        }
        
        windColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.wind)
        }
        
        waveColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.wave)
        }
        
        tempColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.temperature)
        }
        
        ratingColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.rating)
        }
        
        firstLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        windLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        waveLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        temperatureLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        ratingLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

