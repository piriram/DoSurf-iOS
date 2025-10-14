//
//  MainWatchView.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/15/25.
//

import SwiftUI
struct MainWatchView: View {
    @ObservedObject var manager: SurfWorkoutManager
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showingSendResult = false
    @State private var sendResultMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // 상태 표시
            VStack(spacing: 8) {
                // 주요 메트릭들 (거리, 시간, 파도)
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("Distance")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(manager.distance)) m")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatTime(manager.elapsed))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Waves")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(manager.waveCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                    }
                }
                
                // 파도 감지 상태 표시
                if manager.isRunning && manager.waveCount > 0 {
                    Text("🌊 Last wave detected!")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                        .opacity(0.8)
                }
                
                // 추가 메트릭들
                VStack(spacing: 4) {
                    HStack(spacing: 16) {
                        if manager.currentSpeed > 0 {
                            HStack(spacing: 4) {
                                Text("⚡️")
                                Text("\(String(format: "%.1f", manager.currentSpeed)) m/s")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        if manager.heartRate > 0 {
                            HStack(spacing: 4) {
                                Text("❤️")
                                Text("\(Int(manager.heartRate)) BPM")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        if manager.activeCalories > 0 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                Text("\(Int(manager.activeCalories)) cal")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if manager.strokeCount > 0 {
                            HStack(spacing: 4) {
                                Text("🏊‍♂️")
                                Text("\(manager.strokeCount) strokes")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // 상태 메시지
                if manager.isRunning {
                    Text("🏄‍♂️ Surfing... Auto-detecting waves")
                        .font(.caption)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                } else if manager.distance > 0 || manager.elapsed > 0 {
                    VStack(spacing: 2) {
                        Text("📊 Session Complete")
                            .font(.caption)
                            .foregroundColor(.blue)
                        if manager.waveCount > 0 {
                            Text("Detected \(manager.waveCount) wave\(manager.waveCount == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                        }
                    }
                } else {
                    Text("🌊 Ready to surf - Wave detection enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
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
        // 심박수 통계 계산
        let maxHR = manager.heartRateHistory.max() ?? manager.heartRate
        let avgHR = manager.heartRateHistory.isEmpty ? manager.heartRate :
                   manager.heartRateHistory.reduce(0, +) / Double(manager.heartRateHistory.count)
        
        let surfData = WatchSurfSessionData(
            distance: manager.distance,
            duration: manager.elapsed,
            startTime: manager.startTime ?? Date(),
            endTime: Date(),
            waveCount: manager.waveCount, // 파도 횟수 추가
            maxHeartRate: maxHR,
            avgHeartRate: avgHR,
            activeCalories: manager.activeCalories,
            strokeCount: manager.strokeCount
        )
        
        Task {
            do {
                try await connectivity.sendSurfData(surfData)
                await MainActor.run {
                    sendResultMessage = """
                    ✅ Data sent successfully!
                    Distance: \(Int(surfData.distance))m
                    Duration: \(formatTime(surfData.duration))
                    Waves: \(surfData.waveCount) 🌊
                    Calories: \(Int(surfData.activeCalories))
                    Avg HR: \(Int(avgHR)) BPM
                    Max HR: \(Int(maxHR)) BPM
                    Strokes: \(surfData.strokeCount)
                    """
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
