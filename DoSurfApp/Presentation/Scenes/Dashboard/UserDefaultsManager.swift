//
//  UserDefaultsService.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/3/25.
//

import Foundation

// MARK: - Protocol
protocol SurfingRecordService {
    func createSurfingState(_ isActive: Bool)
    func readSurfingState() -> Bool
    func createSurfingStartTime(_ date: Date)
    func readSurfingStartTime() -> Date?
    func createSurfingEndTime(_ date: Date)
    func readSurfingEndTime() -> Date?
    func calculateSurfingDuration() -> TimeInterval?
    func deleteSurfingData()
    func createSelectedBeachID(_ id: String)
    func readSelectedBeachID() -> String?
}

// MARK: - Implementation
final class UserDefaultsManager: SurfingRecordService {
    
    // MARK: - Keys
    private struct Keys {
        static let surfingStartTime = "surfingStartTime"
        static let surfingEndTime = "surfingEndTime"
        static let isSurfingActive = "isSurfingActive"
        static let selectedBeachID = "selectedBeachID"
    }
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    // Q. 유저디폴트에 스탠다드말고 커스텀하는게 뭐가 있는지?
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public Methods
    
    /// 서핑 활성화 상태 저장
    func createSurfingState(_ isActive: Bool) {
        userDefaults.set(isActive, forKey: Keys.isSurfingActive)
    }
    
    /// 저장된 서핑 상태 로드
    func readSurfingState() -> Bool {
        let isActive = userDefaults.bool(forKey: Keys.isSurfingActive)
        return isActive
    }
    
    /// 서핑 시작 시간 저장
    func createSurfingStartTime(_ date: Date) {
        userDefaults.set(date, forKey: Keys.surfingStartTime)
    }
    
    /// 저장된 서핑 시작 시간 가져오기
    func readSurfingStartTime() -> Date? {
        return userDefaults.object(forKey: Keys.surfingStartTime) as? Date
    }
    
    /// 서핑 종료 시간 저장
    func createSurfingEndTime(_ date: Date) {
        userDefaults.set(date, forKey: Keys.surfingEndTime)
    }
    
    /// 저장된 서핑 종료 시간 가져오기
    func readSurfingEndTime() -> Date? {
        return userDefaults.object(forKey: Keys.surfingEndTime) as? Date
    }
    
    /// 서핑 시간 계산 (초 단위)
    func calculateSurfingDuration() -> TimeInterval? {
        guard let startTime = readSurfingStartTime(),
              let endTime = readSurfingEndTime() else {
            return nil
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// UserDefaults에서 서핑 데이터 삭제
    func deleteSurfingData() {
        userDefaults.removeObject(forKey: Keys.surfingStartTime)
        userDefaults.removeObject(forKey: Keys.surfingEndTime)
        userDefaults.removeObject(forKey: Keys.isSurfingActive)
    }
    
    func createSelectedBeachID(_ id: String) {
        userDefaults.set(id, forKey: Keys.selectedBeachID)
    }

    func readSelectedBeachID() -> String? {
        let id = userDefaults.string(forKey: Keys.selectedBeachID)
        return id
    }
}

