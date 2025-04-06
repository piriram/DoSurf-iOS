//
//  RegionCategoryCell.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import UIKit
import SnapKit
// MARK: - LocationCell
final class BeachCategoryCell: UITableViewCell {
    static let identifier = "LocationCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        return label
    }()
    
    private let checkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.isHidden = true
        return imageView
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
        contentView.addSubview(checkImageView)
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalTo(checkImageView.snp.leading).offset(-8)
            $0.top.bottom.equalToSuperview().inset(12)
        }
        
        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
    }
    
    func configure(with location: LocationDTO, isSelected: Bool) {
        titleLabel.text = location.displayText
        titleLabel.textColor = isSelected ? .systemBlue : .label
        titleLabel.font = isSelected ? .systemFont(ofSize: 15, weight: .semibold) : .systemFont(ofSize: 15)
        // 체크박스는 사용하지 않음
        checkImageView.isHidden = true
    }
}
