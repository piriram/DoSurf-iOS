import SwiftUI

// MARK: - Main Content View with Tab Structure
struct ContentView: View {
    @ObservedObject var manager: SurfWorkoutManager
    @EnvironmentObject var connectivity: WatchConnectivityManager
    
    var body: some View {
        TabView {
            // 첫 번째 탭: 세션 제어
            MainWatchView(manager: manager)
                .tabItem {
                    Image(systemName: "play.circle")
                    Text("Control")
                }
            
            // 두 번째 탭: 실시간 메트릭
            RealTimeMetricsView(manager: manager)
                .tabItem {
                    Image(systemName: "gauge")
                    Text("Metrics")
                }
        }
    }
}
