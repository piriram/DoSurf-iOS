//
//  SurfingLiveActivity.swift
//  DoSurfWidgetExtension
//
//  Created by Claude on 11/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

/// 서핑 라이브 액티비티 위젯
@available(iOS 16.1, *)
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
                    HStack(spacing: 4) {
                        Image(systemName: "figure.surfing")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        Text("서핑 중")
                            .font(.system(size: 14, weight: .semibold))
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
                        Text("경과")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact Leading
                Image(systemName: "figure.surfing")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact Trailing
                Text("\(context.state.elapsedMinutes)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .monospacedDigit()
            } minimal: {
                // Minimal
                Image(systemName: "figure.surfing")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
        }
    }
}

/// 잠금 화면 라이브 액티비티 뷰
@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<SurfingActivityAttributes>

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

                Image(systemName: "figure.surfing")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text("서핑 중 🏄‍♂️")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                        Text(context.state.startTime, format: .dateTime.hour().minute())
                            .font(.system(size: 13))
                    }

                    Text("•")
                        .font(.system(size: 11))

                    Text("\(context.state.elapsedMinutes)분 경과")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.secondary)
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
    }
}

// MARK: - Preview
@available(iOS 16.1, *)
struct SurfingLiveActivity_Previews: PreviewProvider {
    static let attributes = SurfingActivityAttributes(activityId: "preview")
    static let contentState = SurfingActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-900), // 15분 전
        elapsedMinutes: 15,
        statusMessage: "서핑 중! 🏄‍♂️"
    )

    static var previews: some View {
        Group {
            // Lock Screen
            attributes
                .previewContext(contentState, viewKind: .content)
                .previewDisplayName("잠금 화면")

            // Dynamic Island - Expanded
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island - 확장")

            // Dynamic Island - Compact
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Dynamic Island - 축소")
        }
    }
}
