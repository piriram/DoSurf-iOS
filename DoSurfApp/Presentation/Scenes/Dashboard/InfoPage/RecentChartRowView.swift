//
//  RecentChartRowView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/4/25.
//
import UIKit
import SnapKit
import RxSwift
// MARK: - ChartColumnRatio
enum ChartColumnRatio {
    private static let rawTime: CGFloat = 0.3
    private static let rawWind: CGFloat = 0.55
    private static let rawWave: CGFloat = 0.54
    private static let rawTemperature: CGFloat = 0.32
    private static let rawRating: CGFloat = 0.42
    
    private static let total: CGFloat = rawTime + rawWind + rawWave + rawTemperature + rawRating
    private static let contentFraction: CGFloat = 0.90
    
    static let time: CGFloat = (rawTime / total) * contentFraction
    static let wind: CGFloat = (rawWind / total) * contentFraction
    static let wave: CGFloat = (rawWave / total) * contentFraction
    static let temperature: CGFloat = (rawTemperature / total) * contentFraction
    static let rating: CGFloat = (rawRating / total) * contentFraction
}

final class RecentChartRowView: UIView {
    
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
    
    private let timeColumn = UIView()
    private let windColumn = UIView()
    private let waveColumn = UIView()
    private let tempColumn = UIView()
    private let ratingColumn = UIView()
    
    private lazy var columnStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [
            timeColumn, windColumn, waveColumn, tempColumn, ratingColumn
        ])
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.spacing = 0
        return sv
    }()
    
    private let surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()
    private var configureBag = DisposeBag()
    
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
        
        timeColumn.addSubview(timeStack)
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
            make.centerY.equalToSuperview()
        }
        
        timeColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.time)
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
        
        timeStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().priority(.high)
            make.trailing.lessThanOrEqualToSuperview().priority(.high)
            make.width.lessThanOrEqualToSuperview()
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
            make.height.equalTo(29)
        }
    }
    
    func configure(with chart: Chart) {
        configureBag = DisposeBag()
        
        let dateString = chart.time.toFormattedString(format: "M/d")
        let timeString = chart.time.toFormattedString(format: "HH시")
        dateLabel.text = dateString
        hourLabel.text = timeString
        
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
        
        print("🔧 ChartRowView: Configuration completed - \(dateString) \(timeString), Wind: \(chart.windSpeed)m/s, Wave: \(chart.waveHeight)m")
    }
}

// MARK: - ChartTableHeaderView
final class ChartTableHeaderView: UIView {
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "시간"
        label.font = .systemFont(ofSize: ChartFont.thirteen, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let windLabel: UILabel = {
        let label = UILabel()
        label.text = "바람"
        label.font = .systemFont(ofSize: ChartFont.thirteen, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let waveLabel: UILabel = {
        let label = UILabel()
        label.text = "파도"
        label.font = .systemFont(ofSize: ChartFont.thirteen, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.text = "수온"
        label.font = .systemFont(ofSize: ChartFont.thirteen, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "평가"
        label.font = .systemFont(ofSize: ChartFont.thirteen, weight: ChartFont.semibold)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    private let timeColumn = UIView()
    private let windColumn = UIView()
    private let waveColumn = UIView()
    private let tempColumn = UIView()
    private let ratingColumn = UIView()
    
    private lazy var columnStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [
            timeColumn, windColumn, waveColumn, tempColumn, ratingColumn
        ])
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.spacing = 0
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
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        
        timeColumn.addSubview(timeLabel)
        windColumn.addSubview(windLabel)
        waveColumn.addSubview(waveLabel)
        tempColumn.addSubview(temperatureLabel)
        ratingColumn.addSubview(ratingLabel)
        
        addSubview(columnStackView)
    }
    
    private func configureLayout() {
        columnStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        timeColumn.snp.makeConstraints { make in
            make.width.equalTo(columnStackView.snp.width).multipliedBy(ChartColumnRatio.time)
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
        
        timeLabel.snp.makeConstraints { make in
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

