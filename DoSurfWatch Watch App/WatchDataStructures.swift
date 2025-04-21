//
//  WatchDataStructures.swift
//  DoSurfWatch Watch App
//
//  Watch 앱용 데이터 구조체들
//

import Foundation

// Watch 앱에서 사용할 서핑 세션 데이터
struct WatchSurfSessionData: Codable {
    let distance: Double
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date
    let waveCount: Int = 0
    
    var dictionary: [String: Any] {
        return [
            "distance": distance,
            "duration": duration,
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "waveCount": waveCount
        ]
    }
}