import UIKit
import FirebaseCore
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var liveActivityTokenObserver: NSObjectProtocol?

    deinit {
        if let liveActivityTokenObserver {
            NotificationCenter.default.removeObserver(liveActivityTokenObserver)
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        // IQKeyboardManager 설정
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardManager.shared.keyboardDistance = 60

        observeLiveActivityTokens()
        launchDebugLiveActivityIfNeeded()

        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard #available(iOS 16.2, *) else {
            completionHandler(.noData)
            return
        }

        guard let state = parseLiveActivityState(from: userInfo) else {
            completionHandler(.noData)
            return
        }

        SurfingActivityManager.shared.applyRemoteUpdate(state)
        completionHandler(.newData)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    private func observeLiveActivityTokens() {
        liveActivityTokenObserver = NotificationCenter.default.addObserver(
            forName: .liveActivityPushTokenDidUpdate,
            object: nil,
            queue: .main
        ) { notification in
            let token = notification.userInfo?["token"] as? String ?? ""
            let tokenType = notification.userInfo?["tokenType"] as? String ?? "unknown"
            let activityId = notification.userInfo?["activityId"] as? String ?? ""

            guard !token.isEmpty else { return }

            let key = "liveActivity.pushToken.\(tokenType)"
            UserDefaults.standard.set(token, forKey: key)
            UserDefaults.standard.set(activityId, forKey: "liveActivity.lastActivityId")
            UserDefaults.standard.set(Date(), forKey: "liveActivity.tokenUpdatedAt")

            print("📡 [LiveActivity] token stored: type=\(tokenType), activity=\(activityId), length=\(token.count)")
        }
    }

    private func launchDebugLiveActivityIfNeeded() {
        #if DEBUG
        guard #available(iOS 16.2, *) else { return }
        guard ProcessInfo.processInfo.arguments.contains("--debug-live-activity") else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let startTime = Date().addingTimeInterval(-25 * 60)
            SurfingActivityManager.shared.startActivity(
                startTime: startTime,
                beachName: "포항 신항만해변",
                rideCount: 2,
                averageHeartRate: 146
            )
            SurfingActivityManager.shared.applyRemoteUpdate(
                SurfingActivityAttributes.ContentState(
                    startTime: startTime,
                    elapsedMinutes: 25,
                    statusMessage: "",
                    beachName: "포항 신항만해변",
                    rideCount: 2,
                    averageHeartRate: 146
                )
            )
            print("🧪 [LiveActivity] debug launch mock started")
        }
        #endif
    }

    @available(iOS 16.2, *)
    private func parseLiveActivityState(from userInfo: [AnyHashable: Any]) -> SurfingActivityAttributes.ContentState? {
        guard let aps = userInfo["aps"] as? [String: Any],
              let contentState = aps["content-state"] as? [String: Any] else {
            return nil
        }

        let elapsedMinutes = parseInt(contentState["elapsedMinutes"]) ?? 0
        let rideCount = parseInt(contentState["rideCount"]) ?? 0
        let averageHeartRate = parseDouble(contentState["averageHeartRate"]) ?? 0
        let beachName = (contentState["beachName"] as? String) ?? "서핑"
        let statusMessage = (contentState["statusMessage"] as? String) ?? "서핑 업데이트"

        let startTime = parseDate(contentState["startTime"])
            ?? Date().addingTimeInterval(-TimeInterval(max(0, elapsedMinutes) * 60))

        return SurfingActivityAttributes.ContentState(
            startTime: startTime,
            elapsedMinutes: max(0, elapsedMinutes),
            statusMessage: statusMessage,
            beachName: beachName,
            rideCount: max(0, rideCount),
            averageHeartRate: max(0, averageHeartRate)
        )
    }

    private func parseInt(_ value: Any?) -> Int? {
        switch value {
        case let number as NSNumber:
            return number.intValue
        case let value as Int:
            return value
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }

    private func parseDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let value as Double:
            return value
        case let value as Int:
            return Double(value)
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    private func parseDate(_ value: Any?) -> Date? {
        switch value {
        case let date as Date:
            return date
        case let timestamp as NSNumber:
            return Date(timeIntervalSince1970: timestamp.doubleValue)
        case let timestamp as Double:
            return Date(timeIntervalSince1970: timestamp)
        case let timestamp as Int:
            return Date(timeIntervalSince1970: TimeInterval(timestamp))
        case let value as String:
            if let timestamp = Double(value) {
                return Date(timeIntervalSince1970: timestamp)
            }
            return nil
        default:
            return nil
        }
    }
}
