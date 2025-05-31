import HealthKit

final class HealthAuth {
    private let store = HKHealthStore()
    
    func requestPermissions() async throws {
        let typesToShare: Set = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
        ]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!, // 서핑은 수영과 비슷한 거리 측정
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!, // 패들링 횟수 추적 가능
            HKObjectType.workoutType()
        ]
        try await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }
}

