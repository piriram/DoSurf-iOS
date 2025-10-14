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
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var strokeCount: Int = 0 // 패들링 횟수 추적
    
    // MARK: - Internal states
    private var startDate = Date()
    private var lastLocation: CLLocation?
    private var timer: Timer?
    var startTime: Date?
    private var isSessionActive = false  // 세션 상태 추적
    private var _heartRateHistory: [Double] = [] // 심박수 기록용
    
    // 심박수 기록에 접근할 수 있는 공개 프로퍼티
    var heartRateHistory: [Double] {
        return _heartRateHistory
    }
    
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
            let toShare: Set = [
                HKObjectType.workoutType(),
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
            ]
            let toRead: Set = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
                HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
                HKObjectType.workoutType()
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
        _heartRateHistory.removeAll() // 심박수 기록 초기화
        
        DispatchQueue.main.async {
            self.isRunning = false
            // 다른 메트릭들도 초기화
            self.heartRate = 0
            self.activeCalories = 0
            self.strokeCount = 0
        }
    }
    
    private func startSimulatorTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // 시간 업데이트
                self.elapsed = Date().timeIntervalSince(self.startDate)
                
                // 서핑은 주기적인 활동 - 웨이브 라이딩과 패들링이 번갈아 나타남
                let elapsedMinutes = self.elapsed / 60.0
                let isRiding = Int(elapsedMinutes * 6) % 2 == 0 // 10초마다 라이딩/패들링 전환
                
                if isRiding {
                    // 웨이브 라이딩: 빠른 속도, 높은 심박수
                    let ridingSpeed = Double.random(in: 8.0...15.0) // 초당 8-15미터
                    self.distance += ridingSpeed
                    let currentHR = Double.random(in: 140...170)
                    self.heartRate = currentHR
                    self._heartRateHistory.append(currentHR)
                    self.activeCalories += Double.random(in: 0.3...0.5)
                } else {
                    // 패들링: 느린 속도, 중간 심박수, 스트로크 카운트 증가
                    let paddlingSpeed = Double.random(in: 1.0...3.0) // 초당 1-3미터
                    self.distance += paddlingSpeed
                    let currentHR = Double.random(in: 120...140)
                    self.heartRate = currentHR
                    self._heartRateHistory.append(currentHR)
                    self.activeCalories += Double.random(in: 0.2...0.3)
                    
                    // 패들링할 때마다 스트로크 카운트 증가 (약 30% 확률)
                    if Double.random(in: 0...1) < 0.3 {
                        self.strokeCount += 1
                    }
                }
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
        
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            // 최신 데이터 가져오기
            let predicate = HKQuery.predicateForSamples(withStart: startTime, end: Date(), options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: quantityType,
                                        quantitySamplePredicate: predicate,
                                        options: [.mostRecent]) { [weak self] _, result, error in
                guard let result = result,
                      let quantity = result.mostRecentQuantity() else { return }
                
                DispatchQueue.main.async {
                    switch quantityType.identifier {
                    case HKQuantityTypeIdentifier.heartRate.rawValue:
                        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                        self?.heartRate = bpm
                        self?._heartRateHistory.append(bpm) // 기록 저장
                        
                    case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                        self?.activeCalories = quantity.doubleValue(for: HKUnit.kilocalorie())
                        
                    case HKQuantityTypeIdentifier.distanceSwimming.rawValue:
                        let meters = quantity.doubleValue(for: HKUnit.meter())
                        self?.distance = meters
                        
                    case HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue:
                        self?.strokeCount = Int(quantity.doubleValue(for: HKUnit.count()))
                        
                    default:
                        break
                    }
                }
            }
            
            healthStore.execute(query)
        }
    }

    // 필수 (이벤트 수집 콜백)
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // 일시정지/재개 같은 이벤트가 들어올 수 있음
    }
}
