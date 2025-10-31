//
//  BaseViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/24/25.
//

import Foundation

protocol BaseViewModel{
    associatedtype Input
    associatedtype Output
    func transform(_ input: Input) -> Output
}
