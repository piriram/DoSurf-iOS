import Foundation
import ActivityKit
import UIKit

/// 서핑 라이브 액티비티 관리자
@available(iOS 16.2, *)
final class SurfingActivityManager {
    static let shared = SurfingActivityManager()

    private var currentActivity: Activity<SurfingActivityAttributes>?
    private var updateTimer: Timer?
    private var currentStartTime: Date?

    private var beachName: String = "서핑"
    private var rideCount: Int = 0
    private var averageHeartRate: Double = 0
    private var currentUpdateInterval: TimeInterval = 60

    private var activityPushTokenTask: Task<Void, Never>?
    private var pushToStartTokenTask: Task<Void, Never>?
    private var hasStartedPushToStartObservation = false

    private init() {}

    /// 라이브 액티비티를 시작합니다
    /// - Parameters:
    ///   - startTime: 서핑 시작 시간
    ///   - beachName: 표시할 해변 이름
    ///   - rideCount: 초기 라이딩 횟수
    ///   - averageHeartRate: 초기 평균 심박수
    func startActivity(
        startTime: Date,
        beachName: String = "서핑 중",
        rideCount: Int = 0,
        averageHeartRate: Double = 0
    ) {
        print("🔵 [LiveActivity] 시작 시도...")
        print("🔵 [LiveActivity] iOS 버전: \(ProcessInfo.processInfo.operatingSystemVersionString)")

#if !targetEnvironment(simulator)
        let authInfo = ActivityAuthorizationInfo()
        print("🔵 [LiveActivity] 권한 상태: \(authInfo.areActivitiesEnabled)")

        guard authInfo.areActivitiesEnabled else {
            print("❌ [LiveActivity] Live Activities가 비활성화되어 있습니다")
            print("💡 설정 > 화면 시간 > 항상 켜기 > Live Activities 활성화 필요")
            return
        }
#else
        print("🔵 [LiveActivity] 시뮬레이터에서 실행 중")
#endif

        endActivity()

        self.currentStartTime = startTime
        self.beachName = beachName
        self.rideCount = max(0, rideCount)
        self.averageHeartRate = max(0, averageHeartRate)
        self.currentUpdateInterval = intervalForElapsedMinutes(0)

        let attributes = SurfingActivityAttributes(activityId: UUID().uuidString)
        let initialContentState = SurfingActivityAttributes.ContentState(
            startTime: startTime,
            elapsedMinutes: 0,
            statusMessage: statusMessage(elapsedMinutes: 0),
            beachName: beachName,
            rideCount: rideCount,
            averageHeartRate: averageHeartRate
        )

        print("🔵 [LiveActivity] Activity.request 호출...")

        do {
            let (activity, supportsRemotePush) = try requestActivity(
                attributes: attributes,
                contentState: initialContentState
            )

            currentActivity = activity
            print("✅ [LiveActivity] 시작 성공!")
            print("   - Activity ID: \(activity.id)")
            print("   - 시작 시간: \(startTime)")
            print("💡 Dynamic Island 또는 잠금 화면을 확인하세요")

            if supportsRemotePush {
                print("✅ [LiveActivity] 원격 업데이트용 push token 모드 활성화")
            } else {
                print("ℹ️ [LiveActivity] 로컬 업데이트 모드로 시작됨")
                print("💡 원격 업데이트까지 쓰려면 App Target에 Push Notifications capability와 aps-environment entitlement가 필요합니다")
            }

#if targetEnvironment(simulator)
            print("⚠️ 시뮬레이터에서는 제한적으로 작동할 수 있습니다")
            print("💡 실제 기기에서 테스트하는 것을 권장합니다")
#endif

            startUpdateTimer(startTime: startTime)
            if supportsRemotePush {
                observeActivityPushTokens(activity)
                observePushToStartTokenIfNeeded()
            }

        } catch {
            print("❌ [LiveActivity] 시작 실패: \(error.localizedDescription)")
            print("   - Error: \(error)")

            if error.localizedDescription.contains("not enabled") {
                print("💡 해결 방법:")
                print("   1. Xcode에서 Widget Extension Target 추가 확인")
                print("   2. DoSurfWidgetExtension이 빌드되는지 확인")
                print("   3. Info.plist에 NSSupportsLiveActivities=true 확인")
            }

            print("   4. 실제 기기 설정 > 앱/Face ID 및 암호/Live Activities 허용 상태 확인")
            print("   5. 원격 업데이트를 쓸 경우 App Target의 Push Notifications capability와 aps-environment entitlement 확인")
        }
    }

    /// 라이브 액티비티 메트릭을 업데이트합니다
    func updateSummary(
        beachName: String? = nil,
        rideCount: Int? = nil,
        averageHeartRate: Double? = nil
    ) {
        if let beachName {
            self.beachName = beachName
        }
        if let rideCount {
            self.rideCount = max(0, rideCount)
        }
        if let averageHeartRate {
            self.averageHeartRate = max(0, averageHeartRate)
        }

        guard let startTime = currentStartTime else { return }
        let elapsed = Int(Date().timeIntervalSince(startTime) / 60)
        updateActivity(startTime: startTime, elapsedMinutes: elapsed)
    }

    /// 원격 업데이트(서버/APNs 수신 후) 내용을 액티비티에 반영합니다.
    func applyRemoteUpdate(_ state: SurfingActivityAttributes.ContentState) {
        guard let activity = currentActivity else { return }

        beachName = state.beachName
        rideCount = max(0, state.rideCount)
        averageHeartRate = max(0, state.averageHeartRate)
        currentStartTime = state.startTime

        Task {
            await activity.update(.init(state: state, staleDate: nil))
            print("📡 [LiveActivity] remote update applied")
        }
    }

    /// 라이브 액티비티를 종료합니다
    /// - Parameter dismissalPolicy: 액티비티 해제 정책 (기본: 즉시)
    func endActivity(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) {
        guard let activity = currentActivity else {
            stopUpdateTimer()
            cancelTokenTasks()
            return
        }

        stopUpdateTimer()
        cancelTokenTasks()

        Task {
            await activity.end(
                .init(
                    state: activity.content.state,
                    staleDate: nil
                ),
                dismissalPolicy: dismissalPolicy
            )
            print("✅ Live Activity 종료됨")
        }

        currentActivity = nil
        currentStartTime = nil
    }

    // MARK: - Timer Management

    /// 경과 시간 업데이트 타이머 시작
    private func startUpdateTimer(startTime: Date) {
        scheduleUpdateTimer(startTime: startTime, interval: currentUpdateInterval)
    }

    private func scheduleUpdateTimer(startTime: Date, interval: TimeInterval) {
        stopUpdateTimer()
        currentUpdateInterval = interval

        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.handleTimerTick(startTime: startTime)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.handleTimerTick(startTime: startTime)
        }
    }

    private func handleTimerTick(startTime: Date) {
        let elapsed = Int(Date().timeIntervalSince(startTime) / 60)
        let updatedInterval = intervalForElapsedMinutes(elapsed)

        if updatedInterval != currentUpdateInterval {
            scheduleUpdateTimer(startTime: startTime, interval: updatedInterval)
            return
        }

        updateActivity(startTime: startTime, elapsedMinutes: elapsed)
    }

    /// 경과 시간과 메트릭을 반영해 액티비티를 갱신합니다
    private func updateActivity(startTime: Date, elapsedMinutes: Int) {
        guard let activity = currentActivity else { return }

        let updatedContentState = SurfingActivityAttributes.ContentState(
            startTime: startTime,
            elapsedMinutes: max(0, elapsedMinutes),
            statusMessage: statusMessage(elapsedMinutes: elapsedMinutes),
            beachName: beachName,
            rideCount: rideCount,
            averageHeartRate: averageHeartRate
        )

        Task {
            await activity.update(
                .init(state: updatedContentState, staleDate: nil)
            )
            print("🔄 Live Activity 업데이트됨: \(elapsedMinutes)분 경과 / 라이딩 \(rideCount)회")
        }
    }

    private func requestActivity(
        attributes: SurfingActivityAttributes,
        contentState: SurfingActivityAttributes.ContentState
    ) throws -> (activity: Activity<SurfingActivityAttributes>, supportsRemotePush: Bool) {
        let content = ActivityContent(state: contentState, staleDate: nil)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: .token
            )
            return (activity, true)
        } catch {
            print("⚠️ [LiveActivity] push token 모드 시작 실패, 로컬 모드로 재시도합니다")
            print("   - Fallback reason: \(error)")

            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            return (activity, false)
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func intervalForElapsedMinutes(_ elapsedMinutes: Int) -> TimeInterval {
        if elapsedMinutes < 10 {
            return 60
        }

        if elapsedMinutes < 30 {
            return 5 * 60
        }

        return 10 * 60
    }

    private func statusMessage(elapsedMinutes: Int) -> String {
        if elapsedMinutes < 5 {
            return "서핑 준비 중"
        }

        if elapsedMinutes < 20 {
            return "서핑 중! 라이딩 \(rideCount)회"
        }

        return "서핑 지속 중"
    }

    private func observeActivityPushTokens(_ activity: Activity<SurfingActivityAttributes>) {
        activityPushTokenTask?.cancel()
        activityPushTokenTask = Task { [weak self] in
            guard let self else { return }

            for await tokenData in activity.pushTokenUpdates {
                let token = Self.hexString(from: tokenData)
                print("📡 [LiveActivity] push token updated (length=\(token.count))")
                NotificationCenter.default.post(
                    name: .liveActivityPushTokenDidUpdate,
                    object: nil,
                    userInfo: [
                        "activityId": activity.id,
                        "token": token,
                        "tokenType": "activity"
                    ]
                )
            }
        }
    }

    private func observePushToStartTokenIfNeeded() {
        guard #available(iOS 17.2, *) else { return }
        guard !hasStartedPushToStartObservation else { return }

        hasStartedPushToStartObservation = true
        pushToStartTokenTask?.cancel()

        pushToStartTokenTask = Task {
            for await tokenData in Activity<SurfingActivityAttributes>.pushToStartTokenUpdates {
                let token = Self.hexString(from: tokenData)
                print("📡 [LiveActivity] push-to-start token updated (length=\(token.count))")
                NotificationCenter.default.post(
                    name: .liveActivityPushTokenDidUpdate,
                    object: nil,
                    userInfo: [
                        "activityId": "",
                        "token": token,
                        "tokenType": "pushToStart"
                    ]
                )
            }
        }
    }

    private func cancelTokenTasks() {
        activityPushTokenTask?.cancel()
        activityPushTokenTask = nil
    }

    private static func hexString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
