//
//  ButtonTabBarController+.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/30/25.
//

import UIKit

// MARK: - UINavigationControllerDelegate
extension ButtonTabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let shouldHideBottomBar = viewController.hidesBottomBarWhenPushed
        
        UIView.animate(withDuration: animated ? 0.3 : 0.0, delay: 0, options: [.curveEaseInOut]) {
            self.bottomBar.alpha = shouldHideBottomBar ? 0 : 1
            self.centerButton.alpha = shouldHideBottomBar ? 0 : 1
            
            // 완전히 숨길 때는 터치도 차단
            self.bottomBar.isUserInteractionEnabled = !shouldHideBottomBar
            self.centerButton.isUserInteractionEnabled = !shouldHideBottomBar
        }
    }
}






