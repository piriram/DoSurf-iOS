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
            MainWatchView(manager: manager)
                .environmentObject(WatchConnectivityManager.shared)
        }
    }
}

struct MainWatchView: View {
    @ObservedObject var manager: SurfWorkoutManager
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showingSendResult = false
    @State private var sendResultMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // 상태 표시
            VStack(spacing: 8) {
                Text("Distance: \(Int(manager.distance)) m")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Time: \(formatTime(manager.elapsed))")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if manager.isRunning {
                    Text("🏄‍♂️ Surfing...")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if manager.distance > 0 || manager.elapsed > 0 {
                    Text("📊 Session Complete")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // 컨트롤 버튼들
            VStack(spacing: 12) {
                Button(manager.isRunning ? "End Session" : "Start Session") {
                    if manager.isRunning {
                        manager.end()
                    } else {
                        manager.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                // 수동 전송 버튼
                if !manager.isRunning && (manager.distance > 0 || manager.elapsed > 0) {
                    Button("Send to iPhone") {
                        sendDataToiPhone()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.blue)
                }
            }
            
            // 연결 상태 표시
            HStack {
                Circle()
                    .fill(connectivity.isReachable ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(connectivity.isReachable ? "iPhone Connected" : "iPhone Disconnected")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .alert("Send Result", isPresented: $showingSendResult) {
            Button("OK") { }
        } message: {
            Text(sendResultMessage)
        }
        .onChange(of: manager.sessionEnded) { sessionEnded in
            if sessionEnded {
                // 세션이 끝나면 자동으로 데이터 전송
                sendDataToiPhone()
                manager.sessionEnded = false // 플래그 리셋
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func sendDataToiPhone() {
        let surfData = WatchSurfSessionData(
            distance: manager.distance,
            duration: manager.elapsed,
            startTime: manager.startTime ?? Date(),
            endTime: Date()
        )
        
        Task {
            do {
                try await connectivity.sendSurfData(surfData)
                await MainActor.run {
                    sendResultMessage = "✅ Data sent successfully!\nDistance: \(Int(surfData.distance))m\nDuration: \(formatTime(surfData.duration))"
                    showingSendResult = true
                }
            } catch {
                await MainActor.run {
                    sendResultMessage = "❌ Failed to send data:\n\(error.localizedDescription)"
                    showingSendResult = true
                }
            }
        }
    }
}
