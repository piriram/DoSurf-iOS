//
//  BaseViewController.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/24/25.
//

import UIKit

class BaseViewController:UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        configureUI()
        configureLayout()
        configureAction()
        configureBind()
        
    }
    func configureUI(){}
    func configureLayout(){}
    func configureAction(){}
    func configureBind(){}
    func configureNavigationBar(){
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""
    }
}

