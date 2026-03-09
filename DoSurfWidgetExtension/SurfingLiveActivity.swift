import ActivityKit
import WidgetKit
import SwiftUI

private enum SurfingLiveActivityURL {
    static let session = URL(string: "dosurf://live-activity/session")!
}

private extension SurfingActivityAttributes {
    static let preview = SurfingActivityAttributes(activityId: "preview-session")
}

private extension SurfingActivityAttributes.ContentState {
    static let preview = SurfingActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-25 * 60),
        elapsedMinutes: 25,
        statusMessage: "", 
        beachName: "포항 신항만해변",
        rideCount: 2,
        averageHeartRate: 146
    )
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
                            .padding(5)
                            .background(Color.blue.opacity(0.14), in: Circle())

                        VStack(alignment: .leading, spacing: 1) {
                            Text("DoSurf")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.blue)
                            Text(context.state.beachName.isEmpty ? "해변 미지정" : context.state.beachName)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.startTime, style: .timer)
                            .font(.system(size: 18, weight: .bold))
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
                    HStack(spacing: 6) {
                        expandedMetric(symbol: "clock", title: "시작", value: context.state.startTime.formatted(date: .omitted, time: .shortened))
                        expandedMetric(symbol: "water.waves", title: "라이딩", value: "\(context.state.rideCount)회")
                        expandedMetric(symbol: "heart.fill", title: "심박", value: "\(Int(context.state.averageHeartRate)) bpm")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                }
            } compactLeading: {
                Image(systemName: "water.waves")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color(red: 0/255, green: 74/255, blue: 199/255), in: Circle())
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.blue)
            } minimal: {
                Image(systemName: "water.waves")
                    .foregroundColor(Color(red: 0/255, green: 74/255, blue: 199/255))
            }
            .widgetURL(SurfingLiveActivityURL.session)
        }
    }

    private func expandedMetric(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(Color.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
        .frame(maxWidth: .infinity)
    }
}

@available(iOS 16.2, *)
private struct LockScreenSymbolHeroView: View {
    let context: ActivityViewContext<SurfingActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("서핑 진행 중")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                Spacer(minLength: 4)

                Text(context.state.statusMessage)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            HStack(spacing: 8) {
                statTile("시간", elapsedText(), emphasize: true)
                statTile("라이딩", "\(context.state.rideCount)회")
                statTile("심박", "\(Int(context.state.averageHeartRate)) bpm")
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Text(context.state.beachName.isEmpty ? "해변 미지정" : context.state.beachName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.16), lineWidth: 1)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .widgetURL(SurfingLiveActivityURL.session)
    }

    private func statTile(_ title: String, _ value: String, emphasize: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: emphasize ? 16 : 13, weight: .bold))
                .foregroundColor(.blue)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private func elapsedText() -> String {
        let total = max(0, context.state.elapsedMinutes)
        let hour = total / 60
        let minute = total % 60
        if hour > 0 { return String(format: "%d:%02d", hour, minute) }
        return "\(minute)m"
    }
}


@available(iOS 17.0, *)
#Preview("Live Activity · Lock Screen", as: .content, using: SurfingActivityAttributes.preview) {
    SurfingLiveActivity()
} contentStates: {
    SurfingActivityAttributes.ContentState.preview
}

@available(iOS 17.0, *)
#Preview("Live Activity · Dynamic Island (Expanded)", as: .dynamicIsland(.expanded), using: SurfingActivityAttributes.preview) {
    SurfingLiveActivity()
} contentStates: {
    SurfingActivityAttributes.ContentState.preview
}

@available(iOS 17.0, *)
#Preview("Live Activity · Dynamic Island (Compact)", as: .dynamicIsland(.compact), using: SurfingActivityAttributes.preview) {
    SurfingLiveActivity()
} contentStates: {
    SurfingActivityAttributes.ContentState.preview
}

@available(iOS 17.0, *)
#Preview("Live Activity · Dynamic Island (Minimal)", as: .dynamicIsland(.minimal), using: SurfingActivityAttributes.preview) {
    SurfingLiveActivity()
} contentStates: {
    SurfingActivityAttributes.ContentState.preview
}
