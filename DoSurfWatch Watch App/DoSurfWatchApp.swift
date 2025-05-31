import SwiftUI
import ClockKit

@main
struct DoSurfWatch_Watch_AppApp: App {
    @StateObject private var manager = SurfWorkoutManager()
    
    init() {
        // WatchConnectivity 초기화
        Task {
            await WatchConnectivityManager.shared.activate()
            try? await HealthAuth().requestPermissions()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .environmentObject(WatchConnectivityManager.shared)
        }
    }
}





