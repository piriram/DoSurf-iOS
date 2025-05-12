//
//  OverlayViewProtocol.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 11/4/25.
//

import UIKit

// MARK: - Overlay Button Configuration
struct OverlayButtonConfiguration {
    let style: CustomButtonStyle
    let width: CGFloat
    let height: CGFloat
    
    static func primary(title: String, size: CGFloat = 154) -> OverlayButtonConfiguration {
        return OverlayButtonConfiguration(
            style: .primary(title: title),
            width: size,
            height: size
        )
    }
    
    static func capsuled(title: String, tintColor: UIColor, width: CGFloat = 130, height: CGFloat = 44) -> OverlayButtonConfiguration {
        return OverlayButtonConfiguration(
            style: .capsule(title: title, tintColor: tintColor),
            width: width,
            height: height
        )
    }
    
    static func icon(image: UIImage?, tintColor: UIColor, size: CGFloat = 68) -> OverlayButtonConfiguration {
        return OverlayButtonConfiguration(
            style: .icon(image: image, tintColor: tintColor),
            width: size,
            height: size
        )
    }
}

// MARK: - Overlay View Protocol
protocol OverlayViewProtocol: UIView {
    /// 오버레이 표시
    func show()
    
    /// 오버레이 숨기기
    func hide(completion: @escaping () -> Void)
}
