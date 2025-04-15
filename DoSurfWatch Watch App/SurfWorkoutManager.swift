//
//  SurfWorkoutManager.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/8/25.
//

import Foundation
import Combine            // ✅ ObservableObject, @Published
import HealthKit
import CoreLocation
import WatchConnectivity

final class SurfWorkoutManager: NSObject, ObservableObject {
    // MARK: - HK & Location
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let locationManager = CLLocationManager()

    // MARK: - Published states
    @Published var elapsed: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var isRunning: Bool = false

    // MARK: - Internal states
    private var startDate = Date()
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - Permissions (권한은 App 시작 시 한 번만 요청)
    func requestPermissions() async {
        do {
            let toShare: Set = [HKObjectType.workoutType()]
            let toRead: Set = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
            ]
            try await healthStore.requestAuthorization(toShare: toShare, read: toRead)
        } catch {
            print("❌ Health permission error:", error)
        }
    }

    // MARK: - Session Control
    func start() {
        // Location
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        let config = HKWorkoutConfiguration()
        config.activityType = .surfingSports
        config.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()

            // 데이터 소스 연결
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            // 델리게이트 지정
            session.delegate = self
            builder.delegate = self

            // 시작
            self.session = session
            self.builder = builder

            startDate = Date()
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.isRunning = success
                    if let error { print("⚠️ beginCollection error:", error) }
                }
            }
        } catch {
            print("❌ start error:", error)
        }
    }

    func end() {
        session?.end()
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Private
    private func sendSummaryToPhone() {
        let summary: [String: Any] = [
            "distance": distance,
            "duration": elapsed,
            "waveCount": 0
        ]
        guard WCSession.default.isReachable else {
            print("⚠️ iPhone not reachable")
            return
        }
        WCSession.default.sendMessage(summary, replyHandler: nil) { error in
            print("⚠️ send error:", error.localizedDescription)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension SurfWorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let new = locations.last else { return }
        if let last = lastLocation { distance += new.distance(from: last) }
        lastLocation = new
        elapsed = Date().timeIntervalSince(startDate)
    }
}

// MARK: - HKWorkoutSessionDelegate
extension SurfWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        if toState == .ended {
            // 수집 종료 → 피니시 → 요약 전송
            builder?.endCollection(withEnd: Date()) { [weak self] success, error in
                self?.builder?.finishWorkout { _, finishError in
                    if let error { print("⚠️ endCollection error:", error) }
                    if let finishError { print("⚠️ finishWorkout error:", finishError) }
                    self?.sendSummaryToPhone()
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ workoutSession failed:", error)
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension SurfWorkoutManager: HKLiveWorkoutBuilderDelegate {
    // 필수 (데이터 타입 수집 콜백)
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // 필요하면 심박/에너지/거리 등 처리
        // 여기서는 Location 기반 거리로 충분하므로 비워둬도 OK
    }

    // 필수 (이벤트 수집 콜백)
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 일시정지/재개 같은 이벤트가 들어올 수 있음
    }
}
