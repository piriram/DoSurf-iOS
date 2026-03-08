import SwiftUI
import Foundation

private enum WatchBeachCatalog {
    static func name(for record: WatchSurfSessionData) -> String {
        if let beachName = record.beachName, !beachName.isEmpty {
            return beachName
        }
        guard record.beachID != 0 else { return "해변 미지정" }
        return "해변 #\(record.beachID)"
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
                } else if connectivity.mirroredRecordCount > 0 {
                    Text("🗂 Synced Records: \(connectivity.mirroredRecordCount)")
                        .font(.caption2)
                        .foregroundColor(.blue)
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
                        deviceId: WatchLocalDeviceIdentity.stableId,
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

struct SyncedRecordsRootView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            List {
                if connectivity.syncedRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No Synced Records")
                            .font(.headline)
                        Text("iPhone records will appear here after sync.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                } else {
                    ForEach(connectivity.syncedRecords, id: \.sessionId) { record in
                        NavigationLink {
                            SyncedRecordDetailView(sessionId: record.sessionId)
                        } label: {
                            SyncedRecordRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("Records")
        }
    }
}

private struct SyncedRecordRow: View {
    let record: WatchSurfSessionData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(WatchBeachCatalog.name(for: record))
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if record.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.yellow)
                }
            }

            Text(record.startTime.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Text("\(Int(record.distanceMeters))m")
                Text("\(record.waveCount) waves")
                Text(record.durationLabel)
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            if let memo = record.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
    }
}

private struct SyncedRecordDetailView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss

    let sessionId: String

    @State private var rating = 0
    @State private var memo = ""
    @State private var isPinned = false

    private var record: WatchSurfSessionData? {
        connectivity.syncedRecords.first(where: { $0.sessionId == sessionId })
    }

    var body: some View {
        Group {
            if let record {
                Form {
                    Section {
                        LabeledContent("Beach", value: WatchBeachCatalog.name(for: record))
                        LabeledContent("Date", value: record.startTime.formatted(date: .abbreviated, time: .omitted))
                        LabeledContent("Duration", value: record.durationLabel)
                        LabeledContent("Distance", value: "\(Int(record.distanceMeters))m")
                        LabeledContent("Waves", value: "\(record.waveCount)")
                    }

                    Section {
                        LabeledContent("Avg HR", value: record.avgHeartRate > 0 ? "\(Int(record.avgHeartRate)) bpm" : "-")
                        LabeledContent("Max HR", value: record.maxHeartRate > 0 ? "\(Int(record.maxHeartRate)) bpm" : "-")
                        LabeledContent("Calories", value: record.activeCalories > 0 ? "\(Int(record.activeCalories)) kcal" : "-")
                        LabeledContent("Strokes", value: record.strokeCount > 0 ? "\(record.strokeCount)" : "-")
                    }

                    if record.hasChartSummary {
                        Section {
                            LabeledContent("Avg Wave", value: record.avgWaveHeightText)
                            LabeledContent("Max Wave", value: record.maxWaveHeightText)
                            LabeledContent("Wave Period", value: record.avgWavePeriodText)
                            LabeledContent("Water Temp", value: record.avgWaterTemperatureText)
                            LabeledContent("Wind", value: record.avgWindSpeedText)
                        }
                    }

                    Section {
                        Toggle("Pinned", isOn: $isPinned)

                        Stepper(value: $rating, in: 0...5) {
                            Text("Rating \(rating)/5")
                        }

                        TextField("Memo", text: $memo)
                    }

                    Section {
                        Button("Save Changes") {
                            connectivity.saveMirroredRecordEdits(
                                sessionId: sessionId,
                                rating: rating,
                                memo: memo,
                                isPinned: isPinned
                            )
                        }

                        Button("Delete Record", role: .destructive) {
                            connectivity.deleteMirroredRecord(sessionId: sessionId)
                            dismiss()
                        }
                    }

                    if connectivity.pendingCount > 0 {
                        Section {
                            Text("Sync pending: \(connectivity.pendingCount)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }

                    Section {
                        LabeledContent("Last Updated", value: record.lastModifiedAt.formatted(date: .omitted, time: .shortened))
                        LabeledContent("Record ID", value: String(record.sessionId.prefix(8)))
                            .font(.caption2)
                    }
                }
                .navigationTitle("Edit Record")
                .onAppear {
                    rating = record.rating
                    memo = record.memo ?? ""
                    isPinned = record.isPinned
                }
            } else {
                VStack(spacing: 8) {
                    Text("Record Unavailable")
                        .font(.headline)
                    Text("It may have been deleted or not synced yet.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

private extension WatchSurfSessionData {
    var hasChartSummary: Bool {
        avgWaveHeight != nil || maxWaveHeight != nil || avgWavePeriod != nil || avgWaterTemperature != nil || avgWindSpeed != nil
    }

    var durationLabel: String {
        let totalSeconds = max(Int(durationSeconds.rounded()), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var avgWaveHeightText: String {
        guard let avgWaveHeight else { return "-" }
        return String(format: "%.1fm", avgWaveHeight)
    }

    var maxWaveHeightText: String {
        guard let maxWaveHeight else { return "-" }
        return String(format: "%.1fm", maxWaveHeight)
    }

    var avgWavePeriodText: String {
        guard let avgWavePeriod else { return "-" }
        return String(format: "%.1fs", avgWavePeriod)
    }

    var avgWaterTemperatureText: String {
        guard let avgWaterTemperature else { return "-" }
        return String(format: "%.1f°C", avgWaterTemperature)
    }

    var avgWindSpeedText: String {
        guard let avgWindSpeed else { return "-" }
        return String(format: "%.1fm/s", avgWindSpeed)
    }
}
