//
//  SurfRecord.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation

//struct SurfRecord {
//    let id: String
//    let beachID: String
//    let startTime: Date
//    let endTime: Date
//    let charts: [Chart]
//    let score: SurfScore
//    let comment: String?
//    let isPin: Bool
//}

enum SurfScore: Int, CaseIterable, Codable {
    case terrible = 1
    case poor = 2
    case average = 3
    case good = 4
    case excellent = 5
    
    var displayName: String {
        switch self {
        case .terrible: return "최악"
        case .poor: return "나쁨"
        case .average: return "보통"
        case .good: return "좋음"
        case .excellent: return "최고"
        }
    }
    
    var emoji: String {
        switch self {
        case .terrible: return "😞"
        case .poor: return "😐"
        case .average: return "🙂"
        case .good: return "😊"
        case .excellent: return "🤩"
        }
    }
}
