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
        WatchTalker.shared.start()
        Task { try? await HealthAuth().requestPermissions() }
    }
    
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("Distance: \(Int(manager.distance)) m")
                Text("Time: \(Int(manager.elapsed)) s")
                Button(manager.isRunning ? "End" : "Start") {
                    manager.isRunning ? manager.end() : manager.start()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

