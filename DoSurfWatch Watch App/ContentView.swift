import SwiftUI

private enum WatchLaunchTab {
    static func initialIndex() -> Int {
        let prefix = "--watch-tab="
        guard let arg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(prefix) }) else {
            return 0
        }
        let value = String(arg.dropFirst(prefix.count)).lowercased()
        switch value {
        case "control", "제어": return 1
        case "records", "record", "기록": return 2
        default: return 0
        }
    }
}

// MARK: - Main Content View with Tab Structure
struct ContentView: View {
    @ObservedObject var manager: SurfWorkoutManager
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var selectedTab = WatchLaunchTab.initialIndex()

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchSessionOverviewView(manager: manager, connectivity: connectivity)
                .tabItem {
                    Image(systemName: "wave.3.forward")
                    Text("요약")
                }
                .tag(0)

            MainWatchView(manager: manager)
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("제어")
                }
                .tag(1)

            SyncedRecordsRootView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("기록")
                }
                .tag(2)
        }
    }
}

private struct WatchSessionOverviewView: View {
    @ObservedObject var manager: SurfWorkoutManager
    @ObservedObject var connectivity: WatchConnectivityManager

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    statusPill
                    Spacer(minLength: 0)
                    reachabilityPill
                }

                Text(formatTime(manager.elapsed))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    overviewCard(title: "라이딩", value: "\(manager.waveCount)회", symbol: "water.waves")
                    overviewCard(title: "심박", value: manager.heartRate > 0 ? "\(Int(manager.heartRate)) bpm" : "--", symbol: "heart.fill")
                }

                HStack(spacing: 8) {
                    overviewCard(title: "거리", value: "\(Int(manager.distance))m", symbol: "figure.surfing")
                    overviewCard(title: "칼로리", value: manager.activeCalories > 0 ? "\(Int(manager.activeCalories))" : "--", symbol: "flame.fill")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    private var statusPill: some View {
        Text(statusText)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.14), in: Capsule())
    }

    private var reachabilityPill: some View {
        Text(connectivity.isReachable ? "iPhone 연결" : "오프라인")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(connectivity.isReachable ? .green : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((connectivity.isReachable ? Color.green : Color.orange).opacity(0.12), in: Capsule())
    }

    private var statusText: String {
        if manager.isRunning { return "패들링 중" }
        if manager.elapsed > 0 { return "세션 종료" }
        return "준비됨"
    }

    private var statusColor: Color {
        if manager.isRunning { return .blue }
        if manager.elapsed > 0 { return .secondary }
        return .secondary
    }

    private func overviewCard(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }

    private func formatTime(_ value: TimeInterval) -> String {
        let min = Int(value) / 60
        let sec = Int(value) % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

#if DEBUG
private enum WatchPreviewData {
    static let runningManager = SurfWorkoutManager.preview(
        isRunning: true,
        elapsed: 25 * 60,
        distance: 1280,
        heartRate: 146,
        activeCalories: 182,
        waveCount: 2,
        strokeCount: 34
    )

    static let readyManager = SurfWorkoutManager.preview(
        isRunning: false,
        elapsed: 0,
        distance: 0,
        heartRate: 0,
        activeCalories: 0,
        waveCount: 0,
        strokeCount: 0
    )

    static let connectivity = WatchConnectivityManager()
}

#Preview("워치 · 요약 화면") {
    WatchSessionOverviewView(
        manager: WatchPreviewData.runningManager,
        connectivity: WatchPreviewData.connectivity
    )
}

#Preview("워치 · 제어 화면") {
    MainWatchView(manager: WatchPreviewData.runningManager)
        .environmentObject(WatchPreviewData.connectivity)
}

#Preview("워치 · 탭 전체") {
    ContentView(manager: WatchPreviewData.readyManager)
        .environmentObject(WatchPreviewData.connectivity)
}
#endif
