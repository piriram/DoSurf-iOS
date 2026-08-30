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
    
    /// 시트 전체를 불투명하게 덮는 배경.
    ///
    /// 지금까지 흰 배경으로 보이던 것은 `sheetImageView` 의 이미지였고, 이미지가
    /// 끝나는 지점부터 뒤의 대시보드가 비쳤다. 내용이 이미지 높이보다 길어지면
    /// 바로 드러난다.
    ///
    /// `.systemBackground` 로는 안 된다. iOS 26 시트는 반투명 재질을 쓰기 때문에
    /// 시맨틱 배경색이 그대로 비쳐 보인다. 불투명 값을 직접 지정해야 한다.
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
                : UIColor(white: 1, alpha: 1)
        }
        return view
    }()

    private let sheetImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "sheetImage"))
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        return iv
    }()

    /// 해양 예보는 Open-Meteo 무료 티어를 쓴다. CC BY 4.0이라 출처 표기가 의무다.
    /// 지우지 말 것 — 라이선스 조건이다.
    private let attributionLabel: UILabel = {
        let label = UILabel()
        label.text = "데이터 제공: Open-Meteo.com, 기상청"
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(backgroundView)   // 나머지보다 먼저 — 맨 뒤에 깔린다
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(sheetImageView)
        view.addSubview(attributionLabel)

        setupConstraints()
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

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

        attributionLabel.snp.makeConstraints { make in
            make.top.equalTo(sheetImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
