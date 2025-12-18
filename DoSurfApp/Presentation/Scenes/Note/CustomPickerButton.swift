import UIKit
import SnapKit

final class CustomPickerButton: UIButton {
    
    // MARK: - Properties
    private let label = UILabel()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        backgroundColor = .surfBlue
        
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .white
        label.textAlignment = .center
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 11, bottom: 6, right: 11))
        }
        
        // 높이가 설정되면 코너 반경 자동 업데이트
        snp.makeConstraints { make in
            make.height.equalTo(34)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    // MARK: - Public Methods
    func setText(_ text: String) {
        label.text = text
    }
}
