//
//  UserDefaultsSurfingStorageService.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//

import Foundation

// MARK: - Protocol
protocol SurfingStorageService {
    func saveSurfingState(_ isActive: Bool)
    func loadSurfingState() -> Bool
    func saveSurfingStartTime(_ date: Date)
    func getSurfingStartTime() -> Date?
    func saveSurfingEndTime(_ date: Date)
    func getSurfingEndTime() -> Date?
    func calculateSurfingDuration() -> TimeInterval?
    func clearSurfingData()
}

// MARK: - Implementation
final class UserDefaultsSurfingStorageService: SurfingStorageService {
    
    // MARK: - Keys
    private struct Keys {
        static let surfingStartTime = "surfingStartTime"
        static let surfingEndTime = "surfingEndTime"
        static let isSurfingActive = "isSurfingActive"
    }
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public Methods
    
    /// 서핑 활성화 상태 저장
    func saveSurfingState(_ isActive: Bool) {
        userDefaults.set(isActive, forKey: Keys.isSurfingActive)
        userDefaults.synchronize()
        
        print("💾 서핑 상태 저장: \(isActive ? "활성" : "비활성")")
    }
    
    /// 저장된 서핑 상태 로드
    func loadSurfingState() -> Bool {
        let isActive = userDefaults.bool(forKey: Keys.isSurfingActive)
        print("📂 서핑 상태 로드: \(isActive ? "활성" : "비활성")")
        return isActive
    }
    
    /// 서핑 시작 시간 저장
    func saveSurfingStartTime(_ date: Date) {
        userDefaults.set(date, forKey: Keys.surfingStartTime)
        userDefaults.synchronize()
        
        print("🏄‍♂️ 서핑 시작 시간 저장: \(date)")
    }
    
    /// 저장된 서핑 시작 시간 가져오기
    func getSurfingStartTime() -> Date? {
        return userDefaults.object(forKey: Keys.surfingStartTime) as? Date
    }
    
    /// 서핑 종료 시간 저장
    func saveSurfingEndTime(_ date: Date) {
        userDefaults.set(date, forKey: Keys.surfingEndTime)
        userDefaults.synchronize()
        
        print("🏁 서핑 종료 시간 저장: \(date)")
        
        // 서핑 시간 계산 및 출력 (디버깅용)
        if let duration = calculateSurfingDuration() {
            let hours = Int(duration) / 3600
            let minutes = Int(duration) % 3600 / 60
            let seconds = Int(duration) % 60
            print("⏱️ 총 서핑 시간: \(hours)시간 \(minutes)분 \(seconds)초")
        }
    }
    
    /// 저장된 서핑 종료 시간 가져오기
    func getSurfingEndTime() -> Date? {
        return userDefaults.object(forKey: Keys.surfingEndTime) as? Date
    }
    
    /// 서핑 시간 계산 (초 단위)
    func calculateSurfingDuration() -> TimeInterval? {
        guard let startTime = getSurfingStartTime(),
              let endTime = getSurfingEndTime() else {
            return nil
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// UserDefaults에서 서핑 데이터 삭제
    func clearSurfingData() {
        userDefaults.removeObject(forKey: Keys.surfingStartTime)
        userDefaults.removeObject(forKey: Keys.surfingEndTime)
        userDefaults.removeObject(forKey: Keys.isSurfingActive)
        userDefaults.synchronize()
        
        print("🗑️ 서핑 데이터 삭제 완료")
    }
}

// MARK: - Mock for Testing
#if DEBUG
final class MockSurfingStorageService: SurfingStorageService {
    var savedState: Bool = false
    var savedStartTime: Date?
    var savedEndTime: Date?
    
    func saveSurfingState(_ isActive: Bool) {
        savedState = isActive
    }
    
    func loadSurfingState() -> Bool {
        return savedState
    }
    
    func saveSurfingStartTime(_ date: Date) {
        savedStartTime = date
    }
    
    func getSurfingStartTime() -> Date? {
        return savedStartTime
    }
    
    func saveSurfingEndTime(_ date: Date) {
        savedEndTime = date
    }
    
    func getSurfingEndTime() -> Date? {
        return savedEndTime
    }
    
    func calculateSurfingDuration() -> TimeInterval? {
        guard let start = savedStartTime, let end = savedEndTime else {
            return nil
        }
        return end.timeIntervalSince(start)
    }
    
    func clearSurfingData() {
        savedState = false
        savedStartTime = nil
        savedEndTime = nil
    }
}
#endif
