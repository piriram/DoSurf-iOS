//
//  UIView+.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/15/25.
//

import UIKit

extension UIView {
    /// Sets layer.cornerRadius using either a fixed radius or a height-based multiplier.
    /// - Parameters:
    ///   - fixedRadius: If provided, uses this value directly.
    ///   - heightMultiplier: If provided (and fixedRadius is nil), uses bounds.height * multiplier.
    ///   - makeCircular: Convenience to make the view perfectly pill/circle (height/2). Overrides others if true.
    func applyCornerRadius(fixedRadius: CGFloat? = nil, heightMultiplier: CGFloat? = nil, makeCircular: Bool = false) {
        let targetRadius: CGFloat
        if makeCircular {
            targetRadius = bounds.height / 2
        } else if let fixed = fixedRadius {
            targetRadius = fixed
        } else if let multiplier = heightMultiplier {
            targetRadius = bounds.height * multiplier
        } else {
            return
        }
        if layer.cornerRadius != targetRadius {
            layer.cornerRadius = targetRadius
            layer.masksToBounds = true
        }
    }
}
