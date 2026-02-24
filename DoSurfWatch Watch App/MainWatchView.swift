import SwiftUI
import Foundation

private enum WatchSendDeviceIdentity {
    static let storageKey = "watch_device_id"

    static var stableId: String {
        if let saved = UserDefaults.standard.string(forKey: storageKey) {
            return saved
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: storageKey)
        return newId
    }
}

struct MainWatchView: View {
    @ObservedObject var manager: SurfWorkoutManager
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showingSendResult = false
    @State private var sendResultMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(Int(manager.distance)) m")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatTime(manager.elapsed))
                    .font(.title2)
                    .fontWeight(.semibold)

                if manager.heartRate > 0 {
                    Text("❤️ \(Int(manager.heartRate)) BPM")
                        .font(.caption)
                }

                if manager.waveCount > 0 {
                    Text("🌊 \(manager.waveCount) waves")
                        .font(.caption)
                }

                if manager.strokeCount > 0 {
                    Text("🏄‍♂️ \(manager.strokeCount) strokes")
                        .font(.caption)
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(connectivity.isReachable ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(connectivity.isReachable ? "iPhone Connected" : "iPhone Disconnected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if manager.isRunning {
                    Text("🏄‍♂️ Session Running")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if connectivity.pendingCount > 0 {
                    Text("📤 Sync Pending: \(connectivity.pendingCount)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if manager.sessionEnded || manager.elapsed > 0 {
                    Text("📊 Session Done")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

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

                if !manager.isRunning && (manager.elapsed > 0 || manager.distance > 0) {
                    Button("Send to iPhone") {
                        sendDataToiPhone()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .alert("Send Result", isPresented: $showingSendResult) {
            Button("OK") {}
        } message: {
            Text(sendResultMessage)
        }
        .onChange(of: manager.sessionEnded) { ended in
            if ended {
                sendDataToiPhone()
            }
        }
    }

    private func formatTime(_ value: TimeInterval) -> String {
        let min = Int(value) / 60
        let sec = Int(value) % 60
        return String(format: "%02d:%02d", min, sec)
    }

    private func sendDataToiPhone() {
        Task {
            do {
                WatchConnectivityManager.shared.enqueuePayloads([
                    WatchSurfSessionData(
                        payloadVersion: 1,
                        sessionId: manager.currentSessionRecordId,
                        distanceMeters: manager.distance,
                        durationSeconds: manager.elapsed,
                        startTime: Date().addingTimeInterval(-manager.elapsed),
                        endTime: Date(),
                        waveCount: manager.waveCount,
                        maxHeartRate: manager.heartRate,
                        avgHeartRate: manager.heartRate,
                        activeCalories: manager.activeCalories,
                        strokeCount: manager.strokeCount,
                        deviceId: WatchSendDeviceIdentity.stableId,
                        state: .completed,
                        isDeleted: false
                    )
                ])
                await MainActor.run {
                    sendResultMessage = "✅ iPhone 전송 요청 완료"
                    showingSendResult = true
                }
            }

            if connectivity.pendingCount > 0 {
                await MainActor.run {
                    sendResultMessage = "❗ 전송이 대기중입니다.\n현재 대기: \(connectivity.pendingCount)"
                    showingSendResult = true
                }
            }
        }
    }
}
