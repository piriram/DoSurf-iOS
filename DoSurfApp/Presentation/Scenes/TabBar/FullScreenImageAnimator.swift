import UIKit

// MARK: - Full Screen Image Animator
final class FullScreenImageAnimator {
    
    /// 전체 화면에 이미지를 1초간 표시하고 사라지는 애니메이션
    /// - Parameters:
    ///   - image: 표시할 이미지
    ///   - on: 이미지를 표시할 뷰 (일반적으로 window 또는 view)
    ///   - duration: 이미지가 표시될 시간 (기본값: 1.0초)
    ///   - completion: 애니메이션 완료 후 실행될 클로저
    static func show(
        image: UIImage?,
        on view: UIView,
        duration: TimeInterval = 1.0,
        completion: (() -> Void)? = nil
    ) {
        guard let image = image else {
            completion?()
            return
        }
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0
        
        view.addSubview(imageView)
        imageView.frame = view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Fade In
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn]) {
            imageView.alpha = 1
        } completion: { _ in
            // Hold
            UIView.animate(withDuration: 0.2, delay: duration - 0.4, options: [.curveEaseOut]) {
                imageView.alpha = 0
            } completion: { _ in
                imageView.removeFromSuperview()
                completion?()
            }
        }
    }
    
    /// 애셋 이름으로 전체 화면 이미지 표시
    /// - Parameters:
    ///   - named: 애셋 이미지 이름
    ///   - on: 이미지를 표시할 뷰
    ///   - duration: 이미지가 표시될 시간
    ///   - completion: 애니메이션 완료 후 실행될 클로저
    static func show(
        named: String,
        on view: UIView,
        duration: TimeInterval = 1.0,
        completion: (() -> Void)? = nil
    ) {
        let image = UIImage(named: named)
        show(image: image, on: view, duration: duration, completion: completion)
    }
}
