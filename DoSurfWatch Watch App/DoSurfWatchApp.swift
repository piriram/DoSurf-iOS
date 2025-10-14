//
//  DoSurfWatchApp.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/8/25.
//

import SwiftUI

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

