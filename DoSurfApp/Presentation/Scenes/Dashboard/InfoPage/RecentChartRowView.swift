//
//  RecentChartRowView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/4/25.
//
import UIKit
import SnapKit
import RxSwift

final class RecentChartRowView: UIView {
    
    // MARK: - UI Components
    
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
    
    private let windDirectionImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "windDirectionIcon"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let waveDirectionImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "waveDirectionIcon"))
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
        let sv = UIStackView(arrangedSubviews: [waveDirectionImageView, waveLabel])
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
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
    
    // MARK: - Properties
    
    private let surfRecordUseCase: SurfRecordUseCaseProtocol = SurfRecordUseCase()
    private var configureBag = DisposeBag()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Configuration
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        
        ratingLabel.setContentHuggingPriority(.required, for: .horizontal)
        ratingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        ratingImageView.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    private func configureLayout() {
        let timeContainer = makeColumnContainer(with: timeLabel)
        let windContainer = makeColumnContainer(with: windStack)
        let waveContainer = makeColumnContainer(with: waveStack)
        let temperatureContainer = makeColumnContainer(with: temperatureLabel)
        let ratingContainer = makeColumnContainer(with: ratingStack)
        
        let mainStack = UIStackView(arrangedSubviews: [
            timeContainer,
            windContainer,
            waveContainer,
            temperatureContainer,
            ratingContainer
        ])
        mainStack.axis = .horizontal
        mainStack.distribution = .fill
        mainStack.spacing = 8
        
        addSubview(mainStack)
        
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8))
        }
        
        // 컬럼 비율 설정 (헤더와 동일하게 맞춰야 함)
        timeContainer.snp.makeConstraints { make in
            make.width.equalTo(mainStack).multipliedBy(0.15)
        }
        
        windContainer.snp.makeConstraints { make in
            make.width.equalTo(mainStack).multipliedBy(0.20)
        }
        
        waveContainer.snp.makeConstraints { make in
            make.width.equalTo(mainStack).multipliedBy(0.25)
        }
        
        temperatureContainer.snp.makeConstraints { make in
            make.width.equalTo(mainStack).multipliedBy(0.20)
        }
        
        ratingContainer.snp.makeConstraints { make in
            make.width.equalTo(mainStack).multipliedBy(0.20)
        }
        
        // 아이콘 크기 고정
        windDirectionImageView.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        
        waveDirectionImageView.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        
        ratingImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(29)
        }
    }
    
    private func makeColumnContainer(with content: UIView) -> UIView {
        let container = UIView()
        container.addSubview(content)
        content.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return container
    }
    
    // MARK: - Configuration
    
    func configure(with chart: Chart) {
        configureBag = DisposeBag()
        
        let dateString = chart.time.toFormattedString(format: "M/d")
        let timeString = chart.time.toFormattedString(format: "HH시")
        timeLabel.text = "\(dateString)\n\(timeString)"
        
        windLabel.text = String(format: "%.1fm/s", chart.windSpeed)
        waveLabel.text = String(format: "%.1fm\n%.1fs", chart.waveHeight, chart.wavePeriod)
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
