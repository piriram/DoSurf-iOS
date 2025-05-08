//
//  SortType.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import Foundation

// MARK: - SortType
enum SortType {
    case latest
    case oldest
    case highRating
    case lowRating
    
    var title: String {
        switch self {
        case .latest: return "최신순"
        case .oldest: return "과거순"
        case .highRating: return "높은 별점순"
        case .lowRating: return "낮은 별점순"
        }
    }
}
