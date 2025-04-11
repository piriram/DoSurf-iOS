//
//  RegionCategoryCell.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import UIKit
import SnapKit

import Foundation
// MARK: - CategoryCell
final class RegionCategoryCell: UITableViewCell {
    static let identifier = "RegionCategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: FontSize.subheading, weight: FontSize.semibold)
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
        backgroundColor = .clear
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = .backgroundSkyblue
            return view
        }()
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(20)
        }
    }
    
    func configure(with category: CategoryDTO) {
        titleLabel.text = category.name
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        titleLabel.textColor = selected ? .surfBlue : .black.withAlphaComponent(0.5)
    }
}
