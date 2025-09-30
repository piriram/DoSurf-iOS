
import Foundation

// MARK: - Domain Enums
enum BeachRegion: String, CaseIterable, Sendable, Hashable {
    case yangyang = "yangyang"
    case jeju = "jeju"
    case busan = "busan"
    case goseong = "goseong"
    case gangreung = "gangreung"
    case pohang = "pohang"
    case southsea = "southsea"
    
    var displayName: String {
        switch self {
        case .yangyang: return "양양"
        case .jeju: return "제주"
        case .busan: return "부산"
        case .goseong: return "고성/속초"
        case .gangreung: return "강릉/동해/삼척"
        case .pohang: return "포항/울산"
        case .southsea: return "서해/남해"
        }
    }
    
}
