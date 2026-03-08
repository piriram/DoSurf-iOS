import ActivityKit
import WidgetKit
import SwiftUI

private enum SurfingLiveActivityURL {
    static let session = URL(string: "dosurf://live-activity/session")!
}

@available(iOS 16.2, *)
struct SurfingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SurfingActivityAttributes.self) { context in
            LockScreenSymbolHeroView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.surfing")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DoSurf")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.blue)
                            Text(context.state.beachName.isEmpty ? "해변 미지정" : context.state.beachName)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.startTime, style: .timer)
                            .font(.system(size: 16, weight: .bold))
                            .monospacedDigit()
                            .foregroundColor(.blue)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue, in: Capsule())
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        pill("라이딩", "\(context.state.rideCount)회")
                        pill("심박", "\(Int(context.state.averageHeartRate)) bpm")
                        Spacer(minLength: 4)
                        Text(context.state.statusMessage)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 2)
                }
            } compactLeading: {
                Image(systemName: "figure.surfing")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.blue, in: Circle())
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.blue)
            } minimal: {
                Image(systemName: "figure.surfing")
                    .foregroundColor(.blue)
            }
            .widgetURL(SurfingLiveActivityURL.session)
        }
    }

    private func pill(_ title: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.12), in: Capsule())
    }
}

@available(iOS 16.2, *)
private struct LockScreenSymbolHeroView: View {
    let context: ActivityViewContext<SurfingActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            SymbolHero(size: 54)

            VStack(alignment: .leading, spacing: 6) {
                Text("서핑 진행 중")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Text(context.state.beachName.isEmpty ? "해변 미지정" : context.state.beachName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    metricPill("라이딩", "\(context.state.rideCount)회")
                    metricPill("심박", "\(Int(context.state.averageHeartRate)) bpm")
                }
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.blue)
                Text("elapsed")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.16), lineWidth: 1)
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .widgetURL(SurfingLiveActivityURL.session)
    }

    private func metricPill(_ title: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.blue)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1), in: Capsule())
    }
}

@available(iOS 16.2, *)
private struct SymbolHero: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.35), Color.cyan.opacity(0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: "figure.surfing")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundColor(.blue)
        }
    }
}
