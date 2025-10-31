//
//  CategoryDTO.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import Foundation

// MARK: - DTOs
struct CategoryDTO: Sendable, Hashable {
    let region: BeachRegion
    
    var id: String { region.slug }
    var name: String { region.displayName }
    
    static func == (lhs: CategoryDTO, rhs: CategoryDTO) -> Bool {
        lhs.region == rhs.region
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(region)
    }
}
