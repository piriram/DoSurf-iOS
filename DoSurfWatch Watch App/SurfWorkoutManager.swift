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
import CoreMotion         // 가속도계, 자이로스코프 등
import WatchConnectivity

final class SurfWorkoutManager: NSObject, ObservableObject {
    // MARK: - HK & Location & Motion
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter() // 고도계
    
    // MARK: - Published states
    @Published var elapsed: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var isRunning: Bool = false
    @Published var sessionEnded: Bool = false
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var strokeCount: Int = 0 // 패들링 횟수 추적
    @Published var currentSpeed: Double = 0 // 현재 속도 (m/s)
    @Published var maxSpeed: Double = 0 // 최고 속도 (m/s)
    @Published var averageSpeed: Double = 0 // 평균 속도 (m/s)
    @Published var waveCount: Int = 0 // 파도 횟수
    @Published var currentAltitude: Double = 0 // 현재 고도
    @Published var isAutoDetecting: Bool = false // 자동 감지 상태
    
    // MARK: - Internal states
    private var startDate = Date()
    private var lastLocation: CLLocation?
    private var timer: Timer?
    var startTime: Date?
    private var isSessionActive = false  // 세션 상태 추적
    private var _heartRateHistory: [Double] = [] // 심박수 기록용
    
    // 속도 및 파도 감지용 데이터
    private var speedHistory: [Double] = [] // 속도 기록
    private var altitudeHistory: [Double] = [] // 고도 기록
    private var accelerationHistory: [CMAcceleration] = [] // 가속도 기록
    private var lastWaveDetectionTime: Date = Date() // 마지막 파도 감지 시간
    
    // 자동 감지 관련
    private var motionBuffer: [CMDeviceMotion] = [] // 모션 데이터 버퍼
    private var isInWater: Bool = false // 물 위에 있는지 여부
    private var surfingStartThreshold: Double = 2.0 // 서핑 시작 임계값 (m/s)
    private var surfingEndThreshold: TimeInterval = 60.0 // 서핑 종료 임계값 (초)
    
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
        
        // CoreMotion 설정
        setupMotionManager()
        
        // 시뮬레이터에서는 위치 권한이 없어도 정상 작동하도록 설정
        if !isSimulator {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // 자동 감지 시작
        startAutoDetection()
    }
    
    // MARK: - Motion & Auto Detection Setup
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // 10Hz
        motionManager.accelerometerUpdateInterval = 0.1
    }
    
    private func startAutoDetection() {
        guard !isSimulator else {
            print("ℹ️ Auto detection disabled in simulator")
            return
        }
        
        isAutoDetecting = true
        
        // 위치 업데이트 시작
        locationManager.startUpdatingLocation()
        
        // 고도 업데이트 시작
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { [weak self] data, error in
                guard let data = data else { return }
                self?.processAltitudeData(data)
            }
        }
        
        // 모션 업데이트 시작
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, error in
                guard let motion = motion else { return }
                self?.processMotionData(motion)
            }
        }
        
        print("✅ Auto detection started")
    }
    
    private func stopAutoDetection() {
        isAutoDetecting = false
        motionManager.stopDeviceMotionUpdates()
        altimeter.stopRelativeAltitudeUpdates()
        print("🛑 Auto detection stopped")
    }
    
    // MARK: - Data Processing
    private func processAltitudeData(_ data: CMAltitudeData) {
        let altitude = data.relativeAltitude.doubleValue
        currentAltitude = altitude
        
        // 고도 기록 저장 (최근 30초 분량만 유지)
        altitudeHistory.append(altitude)
        if altitudeHistory.count > 300 { // 10Hz * 30초
            altitudeHistory.removeFirst()
        }
        
        // 파도 감지 (고도 변화 기반)
        detectWaveFromAltitude()
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let acceleration = motion.userAcceleration
        
        // 가속도 기록 저장
        accelerationHistory.append(acceleration)
        if accelerationHistory.count > 100 { // 최근 10초 분량만 유지
            accelerationHistory.removeFirst()
        }
        
        // 모션 버퍼 관리
        motionBuffer.append(motion)
        if motionBuffer.count > 50 { // 최근 5초 분량
            motionBuffer.removeFirst()
        }
        
        // 서핑 활동 감지
        detectSurfingActivity(motion)
        
        // 패들링 감지
        detectPaddling(acceleration)
    }
    
    private func detectWaveFromAltitude() {
        guard altitudeHistory.count >= 20 else { return } // 최소 2초 데이터 필요
        
        let recent = Array(altitudeHistory.suffix(20))
        let max = recent.max() ?? 0
        let min = recent.min() ?? 0
        let altitudeChange = max - min
        
        // 1미터 이상의 고도 변화가 있고, 마지막 파도 감지로부터 5초 이상 지났으면
        if altitudeChange > 1.0 && Date().timeIntervalSince(lastWaveDetectionTime) > 5.0 {
            waveCount += 1
            lastWaveDetectionTime = Date()
            print("🌊 Wave detected! Count: \(waveCount)")
        }
    }
    
    private func detectSurfingActivity(_ motion: CMDeviceMotion) {
        let totalAcceleration = sqrt(
            pow(motion.userAcceleration.x, 2) +
            pow(motion.userAcceleration.y, 2) +
            pow(motion.userAcceleration.z, 2)
        )
        
        // 높은 가속도가 지속되면 서핑 중으로 판단
        let highAccelerationThreshold = 2.0 // 2G
        
        if totalAcceleration > highAccelerationThreshold {
            if !isInWater && !isRunning {
                // 자동으로 세션 시작
                print("🏄‍♂️ Auto-detected surfing activity!")
                DispatchQueue.main.async {
                    self.start()
                }
            }
            isInWater = true
        }
        
        // 낮은 활동량이 지속되면 세션 종료 고려
        if totalAcceleration < 0.5 && isRunning {
            // 1분간 낮은 활동량이 지속되면 자동 종료 (실제로는 더 복잡한 로직 필요)
            // 여기서는 간단한 구현만
        }
    }
    
    private func detectPaddling(_ acceleration: CMAcceleration) {
        // 팔 움직임 패턴을 통한 패들링 감지
        let armMovement = abs(acceleration.x) + abs(acceleration.y)
        
        // 일정 강도 이상의 팔 움직임이 감지되면 패들링으로 간주
        if armMovement > 1.5 && Date().timeIntervalSince(lastWaveDetectionTime) > 2.0 {
            strokeCount += 1
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
        
        // 이전 세션 정리 및 메트릭 초기화
        cleanupSession()
        resetMetrics()
        
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
            lastWaveDetectionTime = startDate
            
            session.startActivity(with: startDate)
            builder.beginCollection(withStart: startDate) { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.isRunning = success
                    if let error = error { print("⚠️ beginCollection error:", error) }
                    
                    // 시뮬레이터에서는 타이머로 가상 데이터 생성
                    if self?.isSimulator == true && success {
                        self?.startSimulatorTimer()
                    }
                }
            }
            
            print("🏄‍♂️ Surf session started!")
            
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
        
        // 자동 감지는 계속 유지하되, 세션 관련 데이터만 정리
        
        DispatchQueue.main.async {
            self.isRunning = false
            // 세션 종료 시에는 메트릭을 초기화하지 않음 (결과 표시를 위해)
            // 대신 새 세션 시작할 때 초기화
        }
    }
    
    private func resetMetrics() {
        DispatchQueue.main.async {
            self.elapsed = 0
            self.distance = 0
            self.heartRate = 0
            self.activeCalories = 0
            self.strokeCount = 0
            self.currentSpeed = 0
            self.maxSpeed = 0
            self.averageSpeed = 0
            self.waveCount = 0
            self.currentAltitude = 0
        }
        
        // 기록들도 초기화
        speedHistory.removeAll()
        altitudeHistory.removeAll()
        accelerationHistory.removeAll()
        motionBuffer.removeAll()
        _heartRateHistory.removeAll()
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
                    self.currentSpeed = ridingSpeed
                    
                    // 최고 속도 업데이트
                    if self.currentSpeed > self.maxSpeed {
                        self.maxSpeed = self.currentSpeed
                    }
                    
                    let currentHR = Double.random(in: 140...170)
                    self.heartRate = currentHR
                    self._heartRateHistory.append(currentHR)
                    self.activeCalories += Double.random(in: 0.3...0.5)
                    
                    // 고도 시뮬레이션 (파도 타기)
                    self.currentAltitude = Double.random(in: -2.0...3.0)
                    
                    // 파도 감지 시뮬레이션 (20% 확률)
                    if Double.random(in: 0...1) < 0.2 {
                        self.waveCount += 1
                    }
                    
                } else {
                    // 패들링: 느린 속도, 중간 심박수, 스트로크 카운트 증가
                    let paddlingSpeed = Double.random(in: 1.0...3.0) // 초당 1-3미터
                    self.distance += paddlingSpeed
                    self.currentSpeed = paddlingSpeed
                    
                    let currentHR = Double.random(in: 120...140)
                    self.heartRate = currentHR
                    self._heartRateHistory.append(currentHR)
                    self.activeCalories += Double.random(in: 0.2...0.3)
                    
                    // 고도 시뮬레이션 (수평)
                    self.currentAltitude = Double.random(in: -0.5...0.5)
                    
                    // 패들링할 때마다 스트로크 카운트 증가 (30% 확률)
                    if Double.random(in: 0...1) < 0.3 {
                        self.strokeCount += 1
                    }
                }
                
                // 평균 속도 계산
                self.speedHistory.append(self.currentSpeed)
                if self.speedHistory.count > 300 {
                    self.speedHistory.removeFirst()
                }
                let movingSpeeds = self.speedHistory.filter { $0 > 0.5 }
                if !movingSpeeds.isEmpty {
                    self.averageSpeed = movingSpeeds.reduce(0, +) / Double(movingSpeeds.count)
                }
            }
        }
    }
    
    private func sendSummaryToPhone() {
        let summary: [String: Any] = [
            "distance": distance,
            "duration": elapsed,
            "waveCount": waveCount,
            "maxSpeed": maxSpeed,
            "averageSpeed": averageSpeed,
            "maxHeartRate": _heartRateHistory.max() ?? heartRate,
            "avgHeartRate": _heartRateHistory.isEmpty ? heartRate : _heartRateHistory.reduce(0, +) / Double(_heartRateHistory.count),
            "activeCalories": activeCalories,
            "strokeCount": strokeCount,
            "maxAltitude": altitudeHistory.max() ?? currentAltitude,
            "minAltitude": altitudeHistory.min() ?? currentAltitude
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
        
        // 현재 고도 업데이트
        currentAltitude = new.altitude
        
        if let last = lastLocation {
            let distanceIncrement = new.distance(from: last)
            let timeIncrement = new.timestamp.timeIntervalSince(last.timestamp)
            
            // 거리 누적
            distance += distanceIncrement
            
            // 현재 속도 계산 (m/s)
            if timeIncrement > 0 {
                currentSpeed = distanceIncrement / timeIncrement
                
                // 최고 속도 업데이트
                if currentSpeed > maxSpeed {
                    maxSpeed = currentSpeed
                }
                
                // 속도 기록 저장
                speedHistory.append(currentSpeed)
                if speedHistory.count > 300 { // 최근 5분간의 데이터만 유지
                    speedHistory.removeFirst()
                }
                
                // 평균 속도 계산 (이동한 거리만 고려)
                let movingSpeedHistory = speedHistory.filter { $0 > 0.5 } // 0.5m/s 이상만 고려
                if !movingSpeedHistory.isEmpty {
                    averageSpeed = movingSpeedHistory.reduce(0, +) / Double(movingSpeedHistory.count)
                }
            }
        }
        
        lastLocation = new
        
        // 시뮬레이터가 아닐 때만 실시간 업데이트
        if !isSimulator {
            elapsed = Date().timeIntervalSince(startDate)
        }
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
                    if let error = error { print("⚠️ endCollection error:", error) }
                    if let finishError = finishError { print("⚠️ finishWorkout error:", finishError) }
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
