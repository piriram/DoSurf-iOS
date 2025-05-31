import Foundation

/// 기기(사용자) 시간대를 따르는 날짜/시간 유틸리티
/// - 프로토콜 없이 간단한 클래스로 제공
/// - 테스트 시엔 원하는 Calendar로 초기화 가능
final class TimeProvider {

    // 기본 싱글톤 (권장)
    static let shared = TimeProvider()

    private let _calendar: Calendar

    /// 기본은 기기 시간대/로케일을 따르는 Gregorian 달력
    init(calendar: Calendar? = nil) {
        if let calendar {
            self._calendar = calendar
        } else {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = .autoupdatingCurrent
            cal.locale = .autoupdatingCurrent
            self._calendar = cal
        }
    }

    /// 현재 달력 (기기 시간대 반영)
    var calendar: Calendar { _calendar }

    /// 오늘의 시작 (00:00:00)
    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// 오늘의 끝 (23:59:59) — UI에서 inclusive 경계가 필요할 때 편리
    func endOfDay(for date: Date) -> Date {
        let start = calendar.startOfDay(for: date)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return calendar.date(byAdding: .second, value: -1, to: tomorrow) ?? date
    }

    /// 날짜와 ‘시간만’ 가진 Date를 합쳐 하나의 Date로 생성
    func combine(_ date: Date, withTimeOf time: Date) -> Date {
        let d = calendar.dateComponents([.year, .month, .day], from: date)
        let t = calendar.dateComponents([.hour, .minute, .second], from: time)
        var comps = DateComponents()
        comps.year = d.year
        comps.month = d.month
        comps.day = d.day
        comps.hour = t.hour
        comps.minute = t.minute
        comps.second = t.second
        return calendar.date(from: comps) ?? date
    }

    /// 현재 시각 (필요 시 주입 없이 바로 사용)
    func now() -> Date { Date() }
}

