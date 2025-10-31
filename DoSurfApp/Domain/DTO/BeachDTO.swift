//
//  BeachDTO.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import Foundation

struct BeachDTO: Sendable, Hashable {
    let id: String           // "1001", "2001", "3001", "4001"
    let region: BeachRegion
    let regionName: String   // "강릉", "포항", "제주", "부산" - 백엔드에서 가져옴
    let place: String        // "죽도", "월포", "중문", "송정"
    
    var displayText: String { "\(place) 해변" }
    var displayName: String { "\(regionName) \(place)해변" }
    
    static func == (lhs: BeachDTO, rhs: BeachDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
