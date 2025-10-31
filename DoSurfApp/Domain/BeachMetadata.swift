//
//  BeachMetadata.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import Foundation

struct BeachMetadata {
    let id: String
    let name: String
    let region: String
    let status: String
    let lastUpdated: Date
    let totalForecasts: Int
    
    // beachID를 Int로 반환하는 계산 속성 추가
    var beachID: Int {
        return Int(id) ?? 0
    }
}
