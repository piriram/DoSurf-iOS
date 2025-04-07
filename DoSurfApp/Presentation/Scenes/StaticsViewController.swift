//
//  RecordViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/28/25.
//

import UIKit

// MARK: - Record ViewController (예시)
class StaticsViewController: BaseViewController {
    // Full-screen background image view
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "backgroundMain"))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
    }

    private func setupBackground() {
        // Add and pin to the view's edges (not the safe area) to cover the entire view
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        // Ensure the background stays behind any other subviews
        
        view.sendSubviewToBack(backgroundImageView)
    }
    
    override func configureNavigationBar() {
        navigationController?.isNavigationBarHidden = true
    }
}
