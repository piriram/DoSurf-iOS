//
//  RecordViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/28/25.
//

import UIKit

// MARK: - Record ViewController (예시)
class RecordViewController: UIViewController {
    // Called when the record screen is dismissed
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "기록하기"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }
}

