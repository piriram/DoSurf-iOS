import UIKit

// MARK: - FilterButton
final class FilterButton: UIButton {
    
    private let hasDropdown: Bool
    
    init(title: String, hasDropdown: Bool = false) {
        self.hasDropdown = hasDropdown
        super.init(frame: .zero)
        setupButton(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton(title: String) {
        setTitle(title, for: .normal)
        setTitleColor(.label, for: .normal)
        setTitleColor(.white, for: .selected)
        titleLabel?.font = .systemFont(ofSize: FontSize.body2Size, weight: .medium)
        
        backgroundColor = .white
        layer.cornerRadius = 14
        layer.borderWidth = 0.75
        layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        contentEdgeInsets = UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)
        
        if hasDropdown {
            setImage(UIImage(systemName: "chevron.down"), for: .normal)
            semanticContentAttribute = .forceRightToLeft
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            tintColor = .lableBlack
        }
        
        sizeToFit()
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: 28)
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .surfBlue : .white
            tintColor = isSelected ? .white : .label
            layer.borderColor = isSelected ? UIColor.clear.cgColor : UIColor.black.withAlphaComponent(0.1).cgColor
        }
    }
}
