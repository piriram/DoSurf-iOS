import UIKit
import SnapKit

final class ColumnHeaderView: UIView {
    // MARK: - Public
    var titles: [String] {
        didSet { reloadLabels() }
    }

    // MARK: - UI
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        sv.spacing = 8
        return sv
    }()

    // MARK: - Init
    init(titles: [String] = ["시간", "바람", "파도", "수온", "날씨"]) {
        self.titles = titles
        super.init(frame: .zero)
        setupUI()
        reloadLabels()
    }

    required init?(coder: NSCoder) {
        self.titles = ["시간", "바람", "파도", "수온", "날씨"]
        super.init(coder: coder)
        setupUI()
        reloadLabels()
    }

    // MARK: - Private
    private func setupUI() {
        backgroundColor = .backgroundHeader.withAlphaComponent(0.5)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    private func reloadLabels() {
        // Remove existing arranged subviews
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // Add labels for current titles
        for text in titles {
            let label = UILabel()
            label.text = text
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            stackView.addArrangedSubview(label)
        }
    }
}
