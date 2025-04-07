//
//  BeachRegion.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//
import Foundation

// MARK: - BeachRegion (지역 - Firebase 매핑용)
enum BeachRegion: String, CaseIterable, Sendable, Hashable, Codable {
    case gangreung = "gangreung"
    case pohang = "pohang"
    case jeju = "jeju"
    case busan = "busan"
    
    var displayName: String {
        switch self {
        case .gangreung: return "강릉"
        case .pohang: return "포항"
        case .jeju: return "제주"
        case .busan: return "부산"
        }
    }
}

// MARK: - SurfBeach (해변 - beachID 포함)
enum SurfBeach: Int, CaseIterable, Codable {
    case jukdo = 1001
    case wolpo = 2001
    case jungmun = 3001
    case songjeong = 4001
    
    var displayName: String {
        switch self {
        case .jukdo: return "죽도"
        case .wolpo: return "월포"
        case .jungmun: return "중문"
        case .songjeong: return "송정"
        }
    }
    
    var firebaseBeachID: String {
        return String(rawValue)
    }
    
    var region: BeachRegion {
        switch self {
        case .jukdo: return .gangreung
        case .wolpo: return .pohang
        case .jungmun: return .jeju
        case .songjeong: return .busan
        }
    }
    
    var coordinate: (latitude: Double, longitude: Double) {
        switch self {
        case .jukdo: return (38.0756, 128.6194)
        case .wolpo: return (36.1023, 129.3656)
        case .jungmun: return (33.2394, 126.4135)
        case .songjeong: return (35.1588, 129.1995)
        }
    }
    
    var stringID: String {
        return String(rawValue)
    }
    
    var firebaseBasePath: String {
        return "regions/\(region.rawValue)/\(firebaseBeachID)"
    }
    
    func firebasePath(for dateTime: String) -> String {
        return "\(firebaseBasePath)/\(dateTime)"
    }
}

// MARK: - DTOs
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
    let id: String           // "1001", "2001", "3001", "4001"
    let region: BeachRegion
    let place: String        // "죽도", "월포", "중문", "송정"
    
    var displayText: String { place }
    var passText: String { "\(region.displayName) \(place)" }
    
    var beach: SurfBeach? {
        guard let beachID = Int(id) else { return nil }
        return SurfBeach(rawValue: beachID)
    }
    
    static func == (lhs: LocationDTO, rhs: LocationDTO) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
