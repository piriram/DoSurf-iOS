import Foundation
import ActivityKit

/// 서핑 라이브 액티비티의 속성 정의
struct SurfingActivityAttributes: ActivityAttributes {
    /// 변경되지 않는 정적 데이터
    public struct ContentState: Codable, Hashable {
        /// 서핑 시작 시간
        var startTime: Date

        /// 현재까지 경과된 시간 (분)
        var elapsedMinutes: Int

        /// 서핑 상태 메시지
        var statusMessage: String

        /// 현재 해변 이름
        var beachName: String

        /// 라이딩 횟수
        var rideCount: Int

        /// 평균 심박수
        var averageHeartRate: Double
    }

    /// 라이브 액티비티 ID (고유 식별자)
    var activityId: String
}
