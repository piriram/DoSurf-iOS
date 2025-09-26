//
//  Beach.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation
// MARK: - Updated SurfRegion with correct Firebase mapping
enum SurfRegion: Int, CaseIterable, Codable {
    case yangyang = 1000
    case gyungbuk = 2000
    case jeju = 3000
    case unknown = 0
    
    var displayName: String {
        switch self {
        case .yangyang: return "양양"
        case .gyungbuk: return "포항/울산"
        case .jeju: return "제주"
        case .unknown: return "알수없음"
        }
    }
    
    // Firebase regions 경로 매핑
    var firebaseRegionName: String? {
        switch self {
        case .yangyang: return "gangreung"
        case .gyungbuk: return "pohang"
        case .jeju: return "jeju"
        case .unknown: return nil
        }
    }
    
    static func from(beachID: Int) -> SurfRegion? {
        let regionValue = (beachID / 1000) * 1000
        return SurfRegion(rawValue: regionValue)
    }
}

// MARK: - Updated SurfBeach with Firebase beach name mapping
enum SurfBeach: Int, CaseIterable, Codable {
    case jukdo = 1001
    case wolpo = 2001
    case jungmun = 3001
    
    var displayName: String {
        switch self {
        case .jukdo: return "죽도"
        case .wolpo: return "월포"
        case .jungmun: return "중문"
        }
    }
    
    // Firebase에서 사용되는 해변 이름
    var firebaseBeachName: String {
        switch self {
        case .jukdo: return "jukdo"
        case .wolpo: return "wolpo"
        case .jungmun: return "jungmun"
        }
    }
    
    var region: SurfRegion {
        return SurfRegion.from(beachID: self.rawValue) ?? .unknown
    }
    
    var coordinate: (latitude: Double, longitude: Double) {
        switch self {
        case .jukdo: return (38.0756, 128.6194)
        case .wolpo: return (36.1023, 129.3656)
        case .jungmun: return (33.2394, 126.4135)
        }
    }
    
    var stringID: String {
        return String(rawValue)
    }
    
    // 전체 Firebase 경로 생성
    var firebasePath: String? {
        guard let regionName = region.firebaseRegionName else { return nil }
        return "regions/\(regionName)/beaches/\(firebaseBeachName)/forecasts"
    }
}
