import Foundation

/// SurfRecordViewController의 생성 모드를 정의하는 열거형
enum SurfRecordMode {
    /// 새 기록 생성 모드
    /// - Parameters:
    ///   - startTime: 서핑 시작 시간 (옵셔널)
    ///   - endTime: 서핑 종료 시간 (옵셔널)
    ///   - charts: 해당 시간대 차트 데이터 (옵셔널)
    ///   - beach: 해변 정보 (차트 로딩용)
    case new(startTime: Date?, endTime: Date?, charts: [Chart]?, beach: BeachDTO?)

    /// 기존 기록 편집 모드
    /// - Parameter record: 편집할 기존 서핑 기록
    case edit(record: SurfRecordData)
}

// MARK: - Computed Properties
extension SurfRecordMode {
    /// 시작 시간 추출
    var startTime: Date? {
        switch self {
        case .new(let startTime, _, _, _):
            return startTime
        case .edit(let record):
            return record.startTime
        }
    }

    /// 종료 시간 추출
    var endTime: Date? {
        switch self {
        case .new(_, let endTime, _, _):
            return endTime
        case .edit(let record):
            return record.endTime
        }
    }

    /// 차트 데이터 추출
    var charts: [Chart]? {
        switch self {
        case .new(_, _, let charts, _):
            return charts
        case .edit(let record):
            return record.charts.map { chartData in
                Chart(
                    beachID: record.beachID,
                    time: chartData.time,
                    windDirection: chartData.windDirection,
                    windSpeed: chartData.windSpeed,
                    waveDirection: chartData.waveDirection,
                    waveHeight: chartData.waveHeight,
                    wavePeriod: chartData.wavePeriod,
                    waterTemperature: chartData.waterTemperature,
                    weather: WeatherType(rawValue: Int(chartData.weatherIconName) ?? 999) ?? .unknown,
                    airTemperature: chartData.airTemperature
                )
            }
        }
    }

    /// 해변 정보 추출
    var beach: BeachDTO? {
        switch self {
        case .new(_, _, _, let beach):
            return beach
        case .edit:
            return nil
        }
    }
    
    /// 편집 모드인지 확인
    var isEditMode: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
    
    /// 편집 중인 기록 추출
    var editingRecord: SurfRecordData? {
        if case .edit(let record) = self {
            return record
        }
        return nil
    }
    
    /// 네비게이션 타이틀
    var navigationTitle: String {
        switch self {
        case .new:
            return "서핑 기록"
        case .edit:
            return "기록 수정"
        }
    }
}
