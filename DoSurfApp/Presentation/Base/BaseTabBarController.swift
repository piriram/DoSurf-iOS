import UIKit

class BaseTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        configureUI()
        configureLayout()
        configureAction()
        configureBind()
    }
    
    // MARK: - Hook methods (override in subclasses)
    func configureUI() {}
    func configureLayout() {}
    func configureAction() {}
    func configureBind() {}
    
    func configureNavigationBar() {
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""
    }
}
