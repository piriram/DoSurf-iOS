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
    @Published var sessionEnded: Bool = false
    
    // MARK: - Internal states
    private var startDate = Date()
    private var lastLocation: CLLocation?
    private var timer: Timer?
    var startTime: Date?
    private var isSessionActive = false  // 세션 상태 추적
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 시뮬레이터에서는 위치 권한이 없어도 정상 작동하도록 설정
        if !isSimulator {
            locationManager.requestWhenInUseAuthorization()
        }
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
        // 이미 세션이 활성화된 경우 중복 실행 방지
        guard !isSessionActive else {
            print("⚠️ Session already active")
            return
        }
        
        // 이전 세션 정리
        cleanupSession()
        
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
            self.isSessionActive = true

            startDate = Date()
            startTime = startDate
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.isRunning = success
                    if let error { print("⚠️ beginCollection error:", error) }
                    
                    // 시뮬레이터에서는 타이머로 가상 데이터 생성
                    if self?.isSimulator == true && success {
                        self?.startSimulatorTimer()
                    }
                }
            }
        } catch {
            print("❌ start error:", error)
        }
    }

    func end() {
        // 이미 종료된 세션인지 확인
        guard isSessionActive, let session = self.session else {
            print("⚠️ No active session to end")
            return
        }
        
        // 중복 종료 방지
        isSessionActive = false
        
        session.end()
        locationManager.stopUpdatingLocation()
        
        // 시뮬레이터 타이머 정리
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private
    private func cleanupSession() {
        timer?.invalidate()
        timer = nil
        session = nil
        builder = nil
        isSessionActive = false
        
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }
    
    private func startSimulatorTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // 시간 업데이트
                self.elapsed = Date().timeIntervalSince(self.startDate)
                
                // 가상 거리 증가 (초당 약 1-3미터, 서핑 속도 시뮬레이션)
                let speedVariation = Double.random(in: 1.0...3.0)
                self.distance += speedVariation
            }
        }
    }
    
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
        // 시뮬레이터에서는 타이머가 처리하므로 실제 디바이스에서만 위치 기반 계산
        guard !isSimulator else { return }
        
        guard let new = locations.last else { return }
        if let last = lastLocation { 
            distance += new.distance(from: last) 
        }
        lastLocation = new
        elapsed = Date().timeIntervalSince(startDate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .locationUnknown:
                print("ℹ️ Location unknown (normal in simulator)")
            case .denied:
                print("⚠️ Location access denied - using simulator mode")
                // 시뮬레이터에서는 위치 거부되어도 계속 진행
            case .network:
                print("⚠️ Network error for location")
            default:
                print("⚠️ Location error: \(error.localizedDescription)")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted")
        case .denied, .restricted:
            print("⚠️ Location permission denied - using simulator mode")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension SurfWorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.isRunning = true
                self.isSessionActive = true
            case .ended:
                self.isRunning = false
                self.sessionEnded = true // SwiftUI에 세션 종료 알림
                // 세션 정리
                self.cleanupSession()
            default:
                break
            }
        }
        
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
