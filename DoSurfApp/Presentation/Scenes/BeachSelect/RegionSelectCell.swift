import UIKit
import SnapKit

import Foundation
// MARK: - CategoryCell
final class RegionSelectCell: UITableViewCell {
    static let identifier = "RegionCategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: FontSize.fifteen, weight: FontSize.semibold)
        label.textColor = .grayText
        label.adjustsFontSizeToFitWidth = false // keep consistent size across all rows
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
            $0.leading.equalToSuperview().inset(16)
            $0.trailing.equalToSuperview().inset(24)
            $0.top.bottom.equalToSuperview().inset(20)
        }
    }
    
    func configure(with category: CategoryDTO) {
        titleLabel.text = category.name
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        titleLabel.textColor = selected ? .surfBlue : .grayText
    }
}
