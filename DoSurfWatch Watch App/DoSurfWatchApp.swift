import SwiftUI
import ClockKit

@main
struct DoSurfWatch_Watch_AppApp: App {
    @StateObject private var manager = SurfWorkoutManager()
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .environmentObject(connectivity)
                .task {
                    await connectivity.activate()
                    await manager.requestPermissions()
                }
        }
    }
}
