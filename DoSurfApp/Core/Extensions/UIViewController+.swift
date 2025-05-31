import UIKit

extension UIViewController {
    
    // MARK: - Action Sheet
    func showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [(title: String, style: UIAlertAction.Style, handler: (() -> Void)?)],
        includeCancel: Bool = true
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        actions.forEach { action in
            alertController.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler?()
            })
        }
        
        if includeCancel {
            alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - Confirmation Alert
    func showConfirmationAlert(
        title: String,
        message: String,
        confirmTitle: String = "확인",
        confirmStyle: UIAlertAction.Style = .default,
        onConfirm: @escaping () -> Void
    ) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
            onConfirm()
        })
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alertController, animated: true)
    }
    
    // MARK: - Error Alert
    func showErrorAlert(message: String) {
        let alertController = UIAlertController(
            title: "오류",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "확인", style: .default))
        present(alertController, animated: true)
    }
}
