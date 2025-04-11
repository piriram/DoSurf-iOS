//
//  PreferredChartPage.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/2/25.
//

import UIKit
import RxSwift
import SnapKit
// MARK: - Page 1: 선호하는 차트 통계
final class PreferredPage: UIView {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let windCard = PreferredCardView()
    private let waveCard = PreferredCardView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    private func configureUI() {
        backgroundColor = .clear
        
        containerStackView.addArrangedSubview(windCard)
        containerStackView.addArrangedSubview(waveCard)
        
        addSubview(containerStackView)
    }
    
    private func configureLayout() {
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    func configure(with cards: [DashboardCardData]) {
        guard cards.count >= 2 else { return }
        windCard.configure(with: cards[0])
        waveCard.configure(with: cards[1])
    }
}
