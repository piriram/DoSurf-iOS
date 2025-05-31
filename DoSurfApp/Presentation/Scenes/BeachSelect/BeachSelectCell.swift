import UIKit
import SnapKit
// MARK: - LocationCell
final class BeachSelectCell: UITableViewCell {
    static let identifier = "BeachCategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: FontSize.fifteen)
        label.textColor = .grayText
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
            $0.verticalEdges.equalToSuperview().inset(20)
        }
    }
    
    func configure(with location: BeachDTO, isSelected: Bool) {
        titleLabel.text = location.displayText
        titleLabel.textColor = isSelected ? .surfBlue : .grayText
        titleLabel.font = isSelected ? .systemFont(ofSize: FontSize.body1, weight: FontSize.semibold) : .systemFont(ofSize: FontSize.body1, weight: FontSize.medium)
        
    }
}
