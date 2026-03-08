import ActivityKit
import WidgetKit
import SwiftUI

private enum SurfingLiveActivityURL {
    static let session = URL(string: "dosurf://live-activity/session")!
}

/// 서핑 라이브 액티비티 위젯
@available(iOS 16.2, *)
struct SurfingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SurfingActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.surfing")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            Text("서핑")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(context.state.beachName.isEmpty ? "해변 미지정" : context.state.beachName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startTime, style: .timer)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text("\(context.state.elapsedMinutes)분")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                        Text("경과 | 라이딩 \(context.state.rideCount)회")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("평균 심박수")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(Int(context.state.averageHeartRate)) bpm")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                            .monospacedDigit()
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text(context.state.startTime, format: .dateTime.hour().minute())
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.secondary)

                        Spacer()

                        Text(context.state.statusMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact Leading
                HStack(spacing: 4) {
                    Image(systemName: "figure.surfing")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text(context.state.beachName.isEmpty ? "서핑" : context.state.beachName)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                }
            } compactTrailing: {
                // Compact Trailing
                HStack(spacing: 4) {
                    Text("\(context.state.elapsedMinutes)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .monospacedDigit()
                    Text("분")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            } minimal: {
                // Minimal
                Image(systemName: "figure.surfing")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
            .widgetURL(SurfingLiveActivityURL.session)
        }
    }
}

/// 잠금 화면 라이브 액티비티 뷰
@available(iOS 16.2, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<SurfingActivityAttributes>
    private var pulseScale: CGFloat {
        let wave = sin(Date().timeIntervalSince1970 * 2)
        return 0.9 + CGFloat((wave + 1) / 10)
    }

    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulseScale)

                Image(systemName: "figure.surfing")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text("서핑 중 🏄‍♂️")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text(context.state.beachName.isEmpty ? "해변 미지정" : context.state.beachName)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                        Text(context.state.startTime, format: .dateTime.hour().minute())
                            .font(.system(size: 13))
                    }

                    Text("•")
                        .font(.system(size: 11))

                    Text("경과 \(context.state.elapsedMinutes)분")
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Text("라이딩 \(context.state.rideCount)회")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    Text("평균 \(Int(context.state.averageHeartRate)) BPM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // 경과 시간 (크게)
            VStack(spacing: 2) {
                Text("\(context.state.elapsedMinutes)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .monospacedDigit()

                Text("분")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .widgetURL(SurfingLiveActivityURL.session)
    }
}
