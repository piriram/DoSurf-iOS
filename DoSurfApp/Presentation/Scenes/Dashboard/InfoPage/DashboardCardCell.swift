import UIKit
import SnapKit
// MARK: - Dashboard Card Cell
class DashboardCardCell: UICollectionViewCell {
    static let identifier = "DashboardCardCell"
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: FontSize.seventeen, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(valueLabel)
        cardView.addSubview(subtitleLabel)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(16)
        }
    }
    
    func configure(with data: DashboardCardData) {
        iconView.image = UIImage(systemName: data.icon)
        titleLabel.text = data.title
        valueLabel.text = data.value
        subtitleLabel.text = data.subtitle
        subtitleLabel.isHidden = data.subtitle == nil
    }
}
