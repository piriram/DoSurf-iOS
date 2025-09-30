//
//  BeachRegion.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//

// Models/BeachSelectModels.swift
import Foundation


struct CategoryDTO: Sendable, Hashable {
    let region: BeachRegion

    var id: String { region.rawValue }
    var name: String { region.displayName }

    static func == (lhs: CategoryDTO, rhs: CategoryDTO) -> Bool {
        lhs.region == rhs.region
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(region)
    }
}

struct LocationDTO: Sendable, Hashable {
    let id: String
    let region: BeachRegion
    let place: String

    var displayText: String { place }
    var passText: String { "\(region.displayName) \(place)" }

    static func == (lhs: LocationDTO, rhs: LocationDTO) -> Bool {
        lhs.id == rhs.id // 고유 id 기준으로 동일성 판단
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
