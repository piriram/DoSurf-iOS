import Foundation

enum DataSourceMode: Equatable {
    case live
    case mock
    case mockWithDelay(TimeInterval)

    var usesMockData: Bool {
        switch self {
        case .live:
            return false
        case .mock, .mockWithDelay:
            return true
        }
    }

    var delaySeconds: TimeInterval {
        switch self {
        case .mockWithDelay(let seconds):
            return max(0, seconds)
        case .live, .mock:
            return 0
        }
    }

    var description: String {
        switch self {
        case .live:
            return "live"
        case .mock:
            return "mock"
        case .mockWithDelay(let seconds):
            return "mockWithDelay(\(seconds)s)"
        }
    }
}

struct AppEnvironment {
    let dataSourceMode: DataSourceMode
    let mockBeachScenario: MockBeachScenario

    static let current = resolve()

    static func resolve(processInfo: ProcessInfo = .processInfo) -> AppEnvironment {
        #if DEBUG
        let arguments = processInfo.arguments
        let environment = processInfo.environment

        let scenario = resolveMockScenario(arguments: arguments, environment: environment)

        if let index = arguments.firstIndex(of: "-UseMockDataWithDelay") {
            let nextIndex = arguments.index(after: index)
            let delay = nextIndex < arguments.count ? (Double(arguments[nextIndex]) ?? 1.5) : 1.5
            return AppEnvironment(dataSourceMode: .mockWithDelay(delay), mockBeachScenario: scenario)
        }

        if arguments.contains("-UseMockData") {
            return AppEnvironment(dataSourceMode: .mock, mockBeachScenario: scenario)
        }

        if environment["DOSURF_USE_MOCK_DATA"] == "1" {
            return AppEnvironment(dataSourceMode: .mock, mockBeachScenario: scenario)
        }
        #endif

        return AppEnvironment(dataSourceMode: .live, mockBeachScenario: .normal)
    }

    #if DEBUG
    private static func resolveMockScenario(arguments: [String], environment: [String: String]) -> MockBeachScenario {
        if let value = valueAfter(flag: "-MockBeachScenario", in: arguments) {
            return MockBeachScenario.parse(value)
        }

        if let value = environment["DOSURF_MOCK_BEACH_SCENARIO"], !value.isEmpty {
            return MockBeachScenario.parse(value)
        }

        return .normal
    }

    private static func valueAfter(flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let nextIndex = arguments.index(after: index)
        guard nextIndex < arguments.count else { return nil }
        return arguments[nextIndex]
    }
    #endif
}
