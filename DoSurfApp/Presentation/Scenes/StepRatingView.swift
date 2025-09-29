//
//  StepRatingView.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/29/25.
//

import UIKit
import SnapKit

final class StepRatingView: UIControl {
    private let stack = UIStackView()
    private var dots: [UIView] = []
    var value: Int = 0 { didSet { updateUI() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        (0..<5).forEach { _ in
            let dot = UIView()
            dot.layer.cornerRadius = 6
            dot.layer.borderWidth = 1
            dot.layer.borderColor = UIColor.systemBlue.cgColor
            dot.snp.makeConstraints { $0.size.equalTo(CGSize(width: 12, height: 12)) }
            dots.append(dot)
            stack.addArrangedSubview(dot)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        updateUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        let pt = gr.location(in: self)
        // 간단한 분할 계산
        let idx = Int((pt.x / bounds.width) * 5.0)
        value = min(max(idx + 1, 1), 5)
        sendActions(for: .valueChanged)
    }

    private func updateUI() {
        for (i, d) in dots.enumerated() {
            if i < value {
                d.backgroundColor = .systemBlue
            } else {
                d.backgroundColor = .clear
            }
        }
    }
}
