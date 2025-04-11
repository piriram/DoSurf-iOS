import UIKit
import SnapKit

final class RatingBadgeView: UIView {
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: FontSize.body2Size,weight: FontSize.medium)
        label.textColor = .darkGray
        label.numberOfLines = 1
        return label
    }()
    
    private let contentInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    /// Initialize with a badge background color.
    convenience init(badgeColor: UIColor) {
        self.init(frame: .zero)
        self.backgroundColor = badgeColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = backgroundColor
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(contentInsets.top)
            make.bottom.equalToSuperview().offset(-contentInsets.bottom)
            make.leading.equalToSuperview().offset(contentInsets.left)
            make.trailing.equalToSuperview().offset(-contentInsets.right)
        }
    }
    
    func configure(rating: Int, ratingText: String, starColor: UIColor = .systemBlue) {
        let prefix = "\(rating)점, "
        let baseFont = label.font ?? UIFont.systemFont(ofSize: FontSize.body2Size, weight: FontSize.medium)
        let mediumFont = UIFont.systemFont(ofSize: baseFont.pointSize, weight: .medium)
        
        let prefixAttributes: [NSAttributedString.Key: Any] = [
            .font: mediumFont,
            .foregroundColor: label.textColor as Any
        ]
        let suffixAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: label.textColor as Any
        ]
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: baseFont.pointSize, weight: .medium)
        let starImage = UIImage(systemName: "star.fill", withConfiguration: symbolConfig)?.withTintColor(starColor, renderingMode: .alwaysOriginal)
        
        let finalString = NSMutableAttributedString()
        
        if let starImage {
            let attachment = NSTextAttachment()
            attachment.image = starImage
            let attachmentString = NSAttributedString(attachment: attachment)
            finalString.append(attachmentString)
            finalString.append(NSAttributedString(string: " "))
        }
        
        finalString.append(NSAttributedString(string: prefix, attributes: prefixAttributes))
        finalString.append(NSAttributedString(string: ratingText, attributes: suffixAttributes))
        
        label.attributedText = finalString
    }
}
