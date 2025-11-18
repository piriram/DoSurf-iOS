//
//  SurfingActivityManager.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 11/17/25.
//

import Foundation
import ActivityKit
import UIKit

/// 서핑 라이브 액티비티 관리자
@available(iOS 16.2, *)
final class SurfingActivityManager {
    static let shared = SurfingActivityManager()

    private var currentActivity: Activity<SurfingActivityAttributes>?
    private var updateTimer: Timer?

    private init() {}

    /// 라이브 액티비티를 시작합니다
    /// - Parameter startTime: 서핑 시작 시간
    func startActivity(startTime: Date) {
        print("🔵 [LiveActivity] 시작 시도...")
        print("🔵 [LiveActivity] iOS 버전: \(ProcessInfo.processInfo.operatingSystemVersionString)")

        // 기존 액티비티가 있다면 종료
        endActivity()

        let attributes = SurfingActivityAttributes(activityId: UUID().uuidString)
        let initialContentState = SurfingActivityAttributes.ContentState(
            startTime: startTime,
            elapsedMinutes: 0,
            statusMessage: "서핑 중! 🏄‍♂️"
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            // 1분마다 경과 시간 업데이트
            startUpdateTimer(startTime: startTime)

        } catch {
            print("❌ [LiveActivity] 시작 실패: \(error.localizedDescription)")
            print("   - Error: \(error)")

        }
    }

    /// 라이브 액티비티를 업데이트합니다
    /// - Parameters:
    ///   - startTime: 서핑 시작 시간
    ///   - elapsedMinutes: 경과 시간 (분)
    private func updateActivity(startTime: Date, elapsedMinutes: Int) {
        guard let activity = currentActivity else { return }

        let updatedContentState = SurfingActivityAttributes.ContentState(
            startTime: startTime,
            elapsedMinutes: elapsedMinutes,
            statusMessage: "서핑 중! 🏄‍♂️"
        )

        Task {
            await activity.update(
                .init(state: updatedContentState, staleDate: nil)
            )
            print("🔄 Live Activity 업데이트됨: \(elapsedMinutes)분 경과")
        }
    }

    /// 라이브 액티비티를 종료합니다
    /// - Parameter dismissalPolicy: 액티비티 해제 정책 (기본: 즉시)
    func endActivity(dismissalPolicy: ActivityUIDismissalPolicy = .immediate) {
        guard let activity = currentActivity else { return }

        stopUpdateTimer()

        Task {
            await activity.end(
                .init(
                    state: activity.content.state,
                    staleDate: nil
                ),
                dismissalPolicy: dismissalPolicy
            )
            print("✅ Live Activity 종료됨")
        }

        currentActivity = nil
    }

    // MARK: - Timer Management

    /// 경과 시간 업데이트 타이머 시작
    private func startUpdateTimer(startTime: Date) {
        stopUpdateTimer()

        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let elapsed = Int(Date().timeIntervalSince(startTime) / 60)
            self.updateActivity(startTime: startTime, elapsedMinutes: elapsed)
        }

        // 즉시 한 번 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            let elapsed = Int(Date().timeIntervalSince(startTime) / 60)
            self.updateActivity(startTime: startTime, elapsedMinutes: elapsed)
        }
    }

    /// 경과 시간 업데이트 타이머 중지
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
