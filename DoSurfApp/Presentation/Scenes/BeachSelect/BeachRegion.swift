//
//  BeachRegion.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import Foundation

// MARK: - BeachRegion (지역 정보)
struct BeachRegion: Sendable, Hashable, Codable {
    let slug: String          // "gangreung", "pohang", "jeju", "busan"
    let displayName: String   // "강릉", "포항", "제주", "부산"
    let order: Int            // 정렬 순서
    
    static func == (lhs: BeachRegion, rhs: BeachRegion) -> Bool {
        lhs.slug == rhs.slug
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(slug)
    }
}

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

struct BeachDTO: Sendable, Hashable {
    let id: String           // "1001", "2001", "3001", "4001"
    let region: BeachRegion
    let regionName: String   // "강릉", "포항", "제주", "부산" - 백엔드에서 가져옴
    let place: String        // "죽도", "월포", "중문", "송정"
    
    var displayText: String { place }
    var passText: String { "\(regionName) \(place)" }
    var displayName: String { "\(regionName) \(place)해변" }
    
    static func == (lhs: BeachDTO, rhs: BeachDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
