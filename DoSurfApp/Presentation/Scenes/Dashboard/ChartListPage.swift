//
//  ChartListPage.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/2/25.
//

import UIKit
import SnapKit
// MARK: - Page 2 & 3: 차트 리스트 페이지
final class ChartListPage: UIView {
    
    // MARK: - Properties
    private let showsHeader: Bool
    private let headerView: ChartListHeaderView
    private let tableContainerView = UIView()
    
    // MARK: - Initialization
    init(title: String, showsHeader: Bool = true) {
        self.showsHeader = showsHeader
        self.headerView = ChartListHeaderView(title: title)
        super.init(frame: .zero)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        layer.cornerRadius = 20
        clipsToBounds = true
        
        if showsHeader {
            addSubview(headerView)
        }
        addSubview(tableContainerView)
    }
    
    private func configureLayout() {
        if showsHeader {
            headerView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(52)
            }
            tableContainerView.snp.makeConstraints { make in
                make.top.equalTo(headerView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            tableContainerView.snp.makeConstraints { make in
                make.top.leading.trailing.bottom.equalToSuperview()
            }
        }
    }
    
    // MARK: - Public Methods
    func configure(with charts: [Chart]) {
        // 기존 차트 뷰 제거
        tableContainerView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        
        // 차트가 없는 경우 처리
        guard !charts.isEmpty else {
            let emptyLabel = UILabel()
            emptyLabel.text = "차트 데이터가 없습니다"
            emptyLabel.textColor = .white.withAlphaComponent(0.7)
            emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
            emptyLabel.textAlignment = .center
            
            tableContainerView.addSubview(emptyLabel)
            emptyLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            return
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.distribution = .fillEqually
        
        // 최대 3개의 차트 표시
        charts.prefix(3).enumerated().forEach { index, chart in
            let rowView = ChartRowView()
            rowView.tag = index
            rowView.configure(with: chart)
            stackView.addArrangedSubview(rowView)
        }
        
        tableContainerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }
}
// MARK: - ChartListHeaderView
final class ChartListHeaderView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("모두 보기", for: .normal)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .white.withAlphaComponent(0.8)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        return button
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        addSubview(titleLabel)
        addSubview(moreButton)
    }
    
    private func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
}
// MARK: - ChartRowView
final class ChartRowView: UIView {
    
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
        addSubview(ratingLabel)
    }
    
    private func configureLayout() {
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
        
        ratingLabel.snp.makeConstraints { make in
            make.leading.equalTo(temperatureLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
    
    func configure(with chart: Chart) {
        // Chart 데이터로 각 라벨 설정
        // 실제 데이터 구조에 맞게 수정 필요
        timeLabel.text = "7/20\n03시"
        windLabel.text = "3.3m/s"
        waveLabel.text = "0.2m\n3.3s"
        temperatureLabel.text = "28°C"
        ratingLabel.text = "⭐️ 5점"
    }
}
