import Foundation

// MARK: - Weather Type Enum
enum WeatherType: Int, CaseIterable, Codable {
    case clear = 1
    case rain = 4
    case snow = 5
    case cloudy = 3
    case cloudLittleSun = 9
    case cloudMuchSun = 10
    case forg = 13
    case fog = 14
    case unknown = 999
    
    static func fromPtype(_ ptype: Double) -> WeatherType {
        switch ptype {
        case 0: return .clear
        case 1: return .rain
        case 2: return .snow
        case 3: return .cloudy
        default: return .clear
        }
    }
    
    var description: String {
        switch self {
        case .clear: return "맑음"
        case .rain: return "비"
        case .snow: return "눈"
        case .cloudy: return "구름많음"
        case .fog: return "안개"
        default: return "알수없음"
        }
    }
    var iconName: String {
        switch self {
        case .clear:
            return "sun"
        case .cloudLittleSun:
            return "cloudLittleSun"
        case .cloudMuchSun:
            return "cloudMuchSun"
        case .cloudy:
            return "cloudy"
        case .rain:
            return "rain"
        case .fog:
            return "forg"
        case .forg:
            return "forg"
        case .snow:
            return "snow"
        case .unknown:
            return "cloudLittleMoon"
        }
    }
}

// MARK: - WeatherType Enum Extension
extension WeatherType {
    
    static func from(
        skyCondition: Int,
        precipitationType: Int,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        precipitationProbability: Double? = nil
    ) -> WeatherType {
        if precipitationType != 0 {
            switch precipitationType {
            case 1:
                return .rain
            case 2:
                return .snow
            case 3:
                return .snow
            case 4:
                return .rain
            default:
                return .unknown
            }
        }
        
        let h = humidity ?? -1
        let w = windSpeed ?? Double.greatestFiniteMagnitude
        if h >= 95, w <= 2.0 {
            return .fog
        }
        
        switch skyCondition {
        case 1:
            return .clear
        case 3:
            let p = precipitationProbability ?? 0
            let isMuch = (p >= 30) || (humidity ?? 0 >= 85)
            return isMuch ? .cloudMuchSun : .cloudLittleSun
        case 4:
            return .cloudy
        default:
            return .unknown
        }
    }
    
    static func from(firestoreData data: [String: Any]) -> WeatherType {
        let skyCondition = data["sky_condition"] as? Int ?? 0
        let precipitationType = data["precipitation_type"] as? Int ?? 0
        
        return from(skyCondition: skyCondition, precipitationType: precipitationType)
    }
}
