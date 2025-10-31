import UIKit
import SnapKit

final class DashboardGuideViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "내가 선호하는 차트 통계"
        label.font = .systemFont(ofSize: 21, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        button.accessibilityLabel = "닫기"
        return button
    }()
    
    private let sheetImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sheetImage"))
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        return iv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(sheetImageView)
        
        setupConstraints()
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
        }
        
        sheetImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(sheetImageView.snp.width).multipliedBy(572.0/593.0)  // 실제 이미지 비율 사용
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
