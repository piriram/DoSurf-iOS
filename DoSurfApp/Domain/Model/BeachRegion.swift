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
