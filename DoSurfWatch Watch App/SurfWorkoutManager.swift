import Foundation
import Combine
import HealthKit
import CoreLocation
import WatchKit

final class SurfWorkoutManager: NSObject, ObservableObject {
    // MARK: - Published state
    @Published private(set) var isRunning = false
    @Published private(set) var sessionEnded = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var distance: Double = 0
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var activeCalories: Double = 0
    @Published private(set) var strokeCount: Int = 0
    @Published private(set) var waveCount: Int = 0
    @Published private(set) var currentSpeed: Double = 0
    @Published private(set) var maxSpeed: Double = 0
    @Published private(set) var averageSpeed: Double = 0
    @Published private(set) var currentSessionRecordId = UUID().uuidString
    @Published private(set) var isInSession = false

    // MARK: - HK + Location
    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // MARK: - Internal states
    private var timer: Timer?
    private var startDate: Date?
    private var lastLocation: CLLocation?
    private var heartRates: [Double] = []
    private var speedSamples: [Double] = []
    private var lastWaveDetect = Date()

    private var isSimulator: Bool {
#if targetEnvironment(simulator)
        true
#else
        false
#endif
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

        if !isSimulator {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Permissions
    func requestPermissions() async {
        let shareTypes: Set = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
        ]
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
        } catch {
            print("❌ Health authorization error: \(error.localizedDescription)")
        }
    }

    // MARK: - Session Control
    func start() {
        guard !isRunning else {
            print("⚠️ Session already running")
            return
        }

        cleanupForNewSession()
        resetLiveMetrics()
        currentSessionRecordId = UUID().uuidString
        sendLifecyclePayload(state: .started)

        let config = HKWorkoutConfiguration()
        config.activityType = .surfingSports
        config.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                        workoutConfiguration: config)

            session.delegate = self
            builder.delegate = self

            workoutSession = session
            workoutBuilder = builder
            startDate = Date()
            isInSession = true

            session.startActivity(with: startDate!)
            builder.beginCollection(withStart: startDate!) { [weak self] success, error in
                DispatchQueue.main.async {
                    if let error {
                        print("⚠️ beginCollection error: \(error.localizedDescription)")
                    }
                    self?.isRunning = success
                    if success {
                        self?.startSessionTicker()
                        if self?.isSimulator == true {
                            print("ℹ️ simulator fallback: metrics simulation active")
                        }
                    }
                }
            }

            locationManager.startUpdatingLocation()
            print("🏄‍♂️ Surf session started")
        } catch {
            print("❌ Failed to start HK session: \(error.localizedDescription)")
        }
    }

    func end() {
        guard isInSession, let session = workoutSession else {
            print("⚠️ No active workout session")
            return
        }

        isInSession = false
        session.end()
        stopSessionTicker()
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Private: transport
    private func sendLifecyclePayload(state: WatchSessionLifecycleState) {
        let now = Date()
        let summary = buildPayload(state: state, endTime: now)
        WatchConnectivityManager.shared.enqueuePayload(summary)
    }

    private func buildPayload(state: WatchSessionLifecycleState, endTime: Date) -> WatchSurfSessionData {
        let maxHR = heartRates.max() ?? heartRate
        let avgHR = heartRates.isEmpty ? heartRate : (heartRates.reduce(0, +) / Double(heartRates.count))

        let deviceId = WatchLocalDeviceIdentity.stableId

        return WatchSurfSessionData(
            payloadVersion: 1,
            sessionId: currentSessionRecordId,
            distanceMeters: distance,
            durationSeconds: elapsed,
            startTime: startDate ?? endTime,
            endTime: endTime,
            waveCount: waveCount,
            maxHeartRate: maxHR,
            avgHeartRate: avgHR,
            activeCalories: activeCalories,
            strokeCount: strokeCount,
            deviceId: deviceId,
            state: state
        )
    }

    private func cleanupForNewSession() {
        stopSessionTicker()
        heartRates.removeAll()
        speedSamples.removeAll()
        lastLocation = nil
        sessionEnded = false
    }

    private func resetLiveMetrics() {
        elapsed = 0
        distance = 0
        heartRate = 0
        activeCalories = 0
        strokeCount = 0
        waveCount = 0
        currentSpeed = 0
        maxSpeed = 0
        averageSpeed = 0
    }

    private func startSessionTicker() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopSessionTicker() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let startDate = startDate else { return }
        elapsed = Date().timeIntervalSince(startDate)

        if isSimulator {
            simulateMetrics()
        }

        if elapsed >= 3,
           isRunning,
           Date().timeIntervalSince(lastWaveDetect) > 7,
           Double.random(in: 0...1) < 0.12 {
            waveCount += 1
            lastWaveDetect = Date()
        }
    }

    private func simulateMetrics() {
        let riding = Int(elapsed) % 20 < 12
        let newSpeed = riding ? Double.random(in: 2.0...6.0) : Double.random(in: 0.8...2.5)
        distance += newSpeed
        currentSpeed = newSpeed
        maxSpeed = max(maxSpeed, currentSpeed)

        if !speedSamples.isEmpty {
            let moving = speedSamples.filter { $0 > 0.5 }
            if !moving.isEmpty {
                averageSpeed = moving.reduce(0, +) / Double(moving.count)
            }
        }
        speedSamples.append(newSpeed)
        if speedSamples.count > 300 { speedSamples.removeFirst() }

        let newHr = Double.random(in: riding ? 130...170 : 110...145)
        heartRate = newHr
        heartRates.append(newHr)
        if heartRates.count > 1200 { heartRates.removeFirst() }

        activeCalories += Double.random(in: riding ? 0.3...0.6 : 0.1...0.3)
        if !riding && Double.random(in: 0...1) < 0.3 {
            strokeCount += 1
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension SurfWorkoutManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRunning, let last = lastLocation, let new = locations.last else {
            lastLocation = locations.last
            return
        }

        let dt = max(new.timestamp.timeIntervalSince(last.timestamp), 0)
        let delta = new.distance(from: last)
        distance += delta

        if dt > 0 {
            currentSpeed = delta / dt
            maxSpeed = max(maxSpeed, currentSpeed)
            speedSamples.append(currentSpeed)
            if speedSamples.count > 300 { speedSamples.removeFirst() }

            let moving = speedSamples.filter { $0 > 0.5 }
            if !moving.isEmpty {
                averageSpeed = moving.reduce(0, +) / Double(moving.count)
            }
        }

        lastLocation = new
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
            print("⚠️ Location denied: using non-GPS fallback")
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
                self.sendLifecyclePayload(state: .started)
            case .ended:
                self.isRunning = false
                self.sessionEnded = true
                self.stopSessionTicker()
                self.locationManager.stopUpdatingLocation()
                self.workoutBuilder?.endCollection(withEnd: Date()) { [weak self] _, _ in
                    self?.workoutBuilder?.finishWorkout { _, _ in
                        self?.sendLifecyclePayload(state: .completed)
                        self?.cleanupAfterSession()
                    }
                }
            default:
                break
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error.localizedDescription)")
        isRunning = false
        isInSession = false
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                       didGenerate event: HKWorkoutEvent) {
        sendLifecyclePayload(state: .inProgress)
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension SurfWorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let startDate = startDate else { return }

        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: nil,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: [.discreteMostRecent]
            ) { [weak self] _, result, _ in
                guard let result,
                      let quantity = result.sumQuantity() ?? result.mostRecentQuantity() else {
                    return
                }

                DispatchQueue.main.async {
                    switch quantityType.identifier {
                    case HKQuantityTypeIdentifier.heartRate.rawValue:
                        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                        self?.heartRate = bpm
                        self?.heartRates.append(bpm)
                    case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                        self?.activeCalories = quantity.doubleValue(for: HKUnit.kilocalorie())
                    case HKQuantityTypeIdentifier.distanceSwimming.rawValue:
                        self?.distance = quantity.doubleValue(for: HKUnit.meter())
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

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        sendLifecyclePayload(state: .inProgress)
    }

    private func cleanupAfterSession() {
        workoutSession = nil
        workoutBuilder = nil
        speedSamples.removeAll()
        heartRates.removeAll()
        isInSession = false
    }
}
