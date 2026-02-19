import Foundation
import RxSwift

final class MockFetchBeachDataUseCase: FetchBeachDataUseCase {
    func execute(beachId: String, region: String, daysBack: Int) -> Observable<BeachData> {
        .just(makeMockData(beachId: beachId, region: region, daysBack: daysBack))
    }

    private func makeMockData(beachId: String, region: String, daysBack: Int) -> BeachData {
        let now = Date()
        let step: TimeInterval = 3 * 60 * 60
        let total = max(1, daysBack * 8)
        let start = Calendar.current.date(byAdding: .hour, value: -(daysBack * 24), to: now) ?? now

        let beachName = beachName(for: beachId)
        let regionName = regionName(for: region)

        let charts: [Chart] = (0..<total).compactMap { index in
            let chartTime = Calendar.current.date(byAdding: .second, value: Int(step * Double(index)), to: start) ?? now
            let windBase = Double(4 + (index % 9))
            let waveBase = Double(0.6 + Double(index % 7) * 0.2)
            let weather = WeatherType.allCases.randomElement() ?? .clear

            return Chart(
                beachID: Int(beachId) ?? 0,
                time: chartTime,
                windDirection: Double(index * 11 % 360),
                windSpeed: windBase,
                waveDirection: Double(index * 17 % 360),
                waveHeight: waveBase,
                wavePeriod: 6 + Double(index % 5),
                waterTemperature: 18.0 + Double(index % 4),
                weather: weather,
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
