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
        VStack(spacing: 12) {
            Text(manager.isRunning ? "세션 진행 중" : "세션 제어")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(manager.isRunning ? "세션 종료" : "세션 시작") {
                if manager.isRunning {
                    manager.end()
                } else {
                    manager.start()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(manager.isRunning ? "라이딩 +1" : "라이딩 추가(세션 시작 후)") {
                manager.incrementWaveCount()
            }
            .buttonStyle(.bordered)
            .disabled(!manager.isRunning)

            if !manager.isRunning && (manager.elapsed > 0 || manager.distance > 0) {
                Button("iPhone으로 전송") {
                    sendDataToiPhone()
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(connectivity.isReachable ? .green : .orange)
                        .frame(width: 7, height: 7)
                    Text(connectivity.isReachable ? "iPhone 연결됨" : "iPhone 오프라인")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if connectivity.pendingCount > 0 {
                    Text("전송 대기 \(connectivity.pendingCount)건")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if connectivity.mirroredRecordCount > 0 {
                    Text("동기화 완료 \(connectivity.mirroredRecordCount)건")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
        .padding(.bottom, 8)
        .alert("전송 결과", isPresented: $showingSendResult) {
            Button("확인") {}
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
                        Text("동기화된 기록이 없어요")
                            .font(.headline)
                        Text("iPhone 동기화 후 기록이 여기에 표시됩니다.")
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
            .navigationTitle("기록")
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
                Text("라이딩 \(record.waveCount)회")
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
                        LabeledContent("해변", value: WatchBeachCatalog.name(for: record))
                        LabeledContent("날짜", value: record.startTime.formatted(date: .abbreviated, time: .omitted))
                        LabeledContent("시간", value: record.durationLabel)
                        LabeledContent("거리", value: "\(Int(record.distanceMeters))m")
                        LabeledContent("라이딩", value: "\(record.waveCount)회")
                    }

                    Section {
                        LabeledContent("평균 심박", value: record.avgHeartRate > 0 ? "\(Int(record.avgHeartRate)) bpm" : "-")
                        LabeledContent("최대 심박", value: record.maxHeartRate > 0 ? "\(Int(record.maxHeartRate)) bpm" : "-")
                        LabeledContent("칼로리", value: record.activeCalories > 0 ? "\(Int(record.activeCalories)) kcal" : "-")
                        LabeledContent("스트로크", value: record.strokeCount > 0 ? "\(record.strokeCount)" : "-")
                    }

                    if record.hasChartSummary {
                        Section {
                            LabeledContent("평균 파고", value: record.avgWaveHeightText)
                            LabeledContent("최대 파고", value: record.maxWaveHeightText)
                            LabeledContent("파도 주기", value: record.avgWavePeriodText)
                            LabeledContent("수온", value: record.avgWaterTemperatureText)
                            LabeledContent("풍속", value: record.avgWindSpeedText)
                        }
                    }

                    Section {
                        Toggle("상단 고정", isOn: $isPinned)

                        Stepper(value: $rating, in: 0...5) {
                            Text("평점 \(rating)/5")
                        }

                        TextField("메모", text: $memo)
                    }

                    Section {
                        Button("변경사항 저장") {
                            connectivity.saveMirroredRecordEdits(
                                sessionId: sessionId,
                                rating: rating,
                                memo: memo,
                                isPinned: isPinned
                            )
                        }

                        Button("기록 삭제", role: .destructive) {
                            connectivity.deleteMirroredRecord(sessionId: sessionId)
                            dismiss()
                        }
                    }

                    if connectivity.pendingCount > 0 {
                        Section {
                            Text("동기화 대기: \(connectivity.pendingCount)건")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }

                    Section {
                        LabeledContent("최종 수정", value: record.lastModifiedAt.formatted(date: .omitted, time: .shortened))
                        LabeledContent("기록 ID", value: String(record.sessionId.prefix(8)))
                            .font(.caption2)
                    }
                }
                .navigationTitle("기록 편집")
                .onAppear {
                    rating = record.rating
                    memo = record.memo ?? ""
                    isPinned = record.isPinned
                }
            } else {
                VStack(spacing: 8) {
                    Text("기록을 불러올 수 없어요")
                        .font(.headline)
                    Text("삭제되었거나 아직 동기화되지 않았을 수 있어요.")
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
            return "\(hours)시간 \(minutes)분"
        }
        return "\(minutes)분"
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
