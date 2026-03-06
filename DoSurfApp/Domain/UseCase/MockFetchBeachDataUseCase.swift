import Foundation
import RxSwift

enum MockBeachScenario: Equatable {
    case normal
    case noData
    case networkError
    case slowNetwork(TimeInterval)
    case staleData(TimeInterval)

    static func parse(_ rawValue: String) -> MockBeachScenario {
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalized == "normal" {
            return .normal
        }

        if normalized == "nodata" || normalized == "no_data" {
            return .noData
        }

        if normalized == "networkerror" || normalized == "network_error" {
            return .networkError
        }

        if normalized.hasPrefix("slow") {
            let seconds = extractSeconds(from: normalized, defaultValue: 1.5)
            return .slowNetwork(seconds)
        }

        if normalized.hasPrefix("stale") {
            let seconds = extractSeconds(from: normalized, defaultValue: 60 * 30)
            return .staleData(seconds)
        }

        return .normal
    }

    var description: String {
        switch self {
        case .normal:
            return "normal"
        case .noData:
            return "noData"
        case .networkError:
            return "networkError"
        case .slowNetwork(let seconds):
            return "slow(\(seconds)s)"
        case .staleData(let seconds):
            return "stale(\(seconds)s)"
        }
    }

    private static func extractSeconds(from normalized: String, defaultValue: TimeInterval) -> TimeInterval {
        guard let separator = normalized.firstIndex(of: ":") else {
            return defaultValue
        }

        let value = normalized[normalized.index(after: separator)...]
        return TimeInterval(value) ?? defaultValue
    }
}

enum MockFetchBeachDataError: LocalizedError {
    case simulatedNetworkFailure

    var errorDescription: String? {
        switch self {
        case .simulatedNetworkFailure:
            return "Mock scenario: simulated network failure"
        }
    }
}

final class MockFetchBeachDataUseCase: FetchBeachDataUseCase {
    private let scenario: MockBeachScenario
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .userInitiated)

    init(scenario: MockBeachScenario = .normal) {
        self.scenario = scenario
    }

    func execute(beachId: String, region: String, daysBack: Int) -> Observable<BeachData> {
        switch scenario {
        case .normal:
            return .just(makeMockData(beachId: beachId, region: region, daysBack: daysBack))
        case .noData:
            return .just(makeMockData(beachId: beachId, region: region, daysBack: daysBack, charts: []))
        case .networkError:
            return .error(MockFetchBeachDataError.simulatedNetworkFailure)
        case .slowNetwork(let delay):
            let normalizedDelay = max(0, delay)
            return .just(makeMockData(beachId: beachId, region: region, daysBack: daysBack))
                .delaySubscription(.milliseconds(Int(normalizedDelay * 1000)), scheduler: scheduler)
        case .staleData(let age):
            let now = Date().addingTimeInterval(-max(0, age))
            return .just(makeMockData(beachId: beachId, region: region, daysBack: daysBack, referenceDate: now))
        }
    }

    private func makeMockData(
        beachId: String,
        region: String,
        daysBack: Int,
        charts overrideCharts: [Chart]? = nil,
        referenceDate: Date = Date()
    ) -> BeachData {
        let now = referenceDate
        let step: TimeInterval = 3 * 60 * 60
        let total = max(1, daysBack * 8)
        let start = Calendar.current.date(byAdding: .hour, value: -(daysBack * 24), to: now) ?? now
        let beachIDValue = Int(beachId) ?? 0

        let beachName = beachName(for: beachId)
        let regionName = regionName(for: region)

        let charts: [Chart] = overrideCharts ?? (0..<total).compactMap { index in
            let chartTime = Calendar.current.date(byAdding: .second, value: Int(step * Double(index)), to: start) ?? now
            let windBase = Double(4 + (index % 9))
            let waveBase = 0.6 + (Double(index % 7) * 0.2)

            return Chart(
                beachID: beachIDValue,
                time: chartTime,
                windDirection: Double((index * 11) % 360),
                windSpeed: windBase,
                waveDirection: Double((index * 17) % 360),
                waveHeight: waveBase,
                wavePeriod: 6 + Double(index % 5),
                waterTemperature: 18.0 + Double(index % 4),
                weather: deterministicWeather(for: beachIDValue, index: index),
                airTemperature: 19.5 + Double(index % 3)
            )
        }

        let metadata = BeachMetadata(
            id: beachId,
            name: beachName,
            region: regionName,
            status: "mock-data",
            lastUpdated: now,
            totalForecasts: charts.count
        )

        return BeachData(
            metadata: metadata,
            charts: charts,
            lastUpdated: now
        )
    }

    private func deterministicWeather(for beachID: Int, index: Int) -> WeatherType {
        let weatherCases = WeatherType.allCases
        guard !weatherCases.isEmpty else { return .unknown }
        let rawIndex = abs(beachID + index) % weatherCases.count
        return weatherCases[rawIndex]
    }

    private func beachName(for beachId: String) -> String {
        [
            "1001": "죽도",
            "1002": "강촌",
            "1003": "안현",
            "1004": "도항",
            "2001": "간절곶",
            "2002": "청해",
            "3001": "협재",
            "3002": "중문",
            "3003": "함덕",
            "4001": "송도"
        ][beachId] ?? "알수없음"
    }

    private func regionName(for region: String) -> String {
        [
            "gangreung": "강릉",
            "pohang": "포항",
            "jeju": "제주",
            "busan": "부산"
        ][region] ?? region
    }
}
