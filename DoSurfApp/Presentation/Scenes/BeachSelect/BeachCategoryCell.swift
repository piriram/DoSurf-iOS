//
//  BeachCategoryCell.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//
import UIKit
import SnapKit
// MARK: - LocationCell
final class BeachCategoryCell: UITableViewCell {
    static let identifier = "BeachCategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black.withAlphaComponent(0.5)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(20)
        }
    }
    
    func configure(with location: LocationDTO, isSelected: Bool) {
        titleLabel.text = location.displayText
        titleLabel.textColor = isSelected ? .surfBlue : .black.withAlphaComponent(0.5)
        titleLabel.font = isSelected ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 16)
    }
}
