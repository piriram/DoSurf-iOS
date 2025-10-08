//
//  HealthAuth.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/8/25.
//

import HealthKit

final class HealthAuth {
    private let store = HKHealthStore()
    
    func requestPermissions() async throws {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)! // 거리 대용
        ]
        try await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
}

