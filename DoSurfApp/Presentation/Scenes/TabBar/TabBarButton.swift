import UIKit
import SnapKit
// MARK: - TabBarButton
final class TabBarButton: UIControl {
    
    enum ButtonType {
        case chart
        case record
        
        var title: String {
            switch self {
            case .chart: return "파도차트"
            case .record: return "기록 차트"
            }
        }
        
        var normalImage: UIImage? {
            switch self {
            case .chart: return UIImage(named: AssetImage.chartSymbol)
            case .record: return UIImage(named: AssetImage.recordSymbol)
            }
        }
        
        var selectedImage: UIImage? {
            switch self {
            case .chart: return UIImage(named: AssetImage.chartSymbolFill)
            case .record: return UIImage(named: AssetImage.recordSymbolFill)
            }
        }
    }
    
    private let type: ButtonType
    private let imageView = UIImageView()
    private let label = UILabel()
    private let stackView = UIStackView()
    
    private var isSelectedState = false
    
    init(type: ButtonType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Stack View
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.isUserInteractionEnabled = false
        
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        // Image View
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.image = type.normalImage
        stackView.addArrangedSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        // Label
        label.text = type.title
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .systemGray
        label.textAlignment = .center
        stackView.addArrangedSubview(label)
    }
    
    func setSelected(_ selected: Bool) {
        isSelectedState = selected
        
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            self.imageView.image = selected ? self.type.selectedImage : self.type.normalImage
            self.imageView.tintColor = selected ? .surfBlue : .systemGray
            self.label.textColor = selected ? .surfBlue : .systemGray
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.5 : 1.0
            }
        }
    }
}
