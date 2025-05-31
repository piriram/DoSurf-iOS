import Foundation

struct FirestoreChartDTO {
    let documentId: String
    let beachId: Int
    let region: String
    let beach: String
    let datetime: String
    let timestamp: Date
    let windSpeed: Double?
    let windDirection: Double?
    let waveHeight: Double?
    let wavePeriod: Double?
    let airTemperature: Double?
    let precipitationProbability: Double?
    let precipitationType: Int?
    let skyCondition: Int?
    let humidity: Double?
    let precipitation: Double?
    let snow: Double?
    let omWaveHeight: Double?
    let omWaveDirection: Double?
    let omSeaSurfaceTemperature: Double?
    let weatherCode: Int?
    
    func toDomain() -> Chart {
        let computedWeather: WeatherType
        if let code = weatherCode, let w = WeatherType(rawValue: code) {
            computedWeather = w
        } else {
            computedWeather = mapWeather(skyCondition: skyCondition, precipitationType: precipitationType)
        }
        return Chart(
            beachID: beachId,
            time: timestamp,
            windDirection: windDirection ?? 0.0,
            windSpeed: windSpeed ?? 0.0,
            waveDirection: omWaveDirection ?? 0.0,
            waveHeight: waveHeight ?? omWaveHeight ?? 0.0,
            wavePeriod: wavePeriod ?? Self.estimateWavePeriod(
                windSpeed: windSpeed,
                waveHeight: waveHeight,
                omWaveHeight: omWaveHeight
            ) ?? 0.0,
            waterTemperature: omSeaSurfaceTemperature ?? 0.0,
            weather: computedWeather,
            airTemperature: airTemperature ?? 0.0
        )
    }
    
    private static func estimateWavePeriod(
        windSpeed: Double?,
        waveHeight: Double?,
        omWaveHeight: Double?
    ) -> Double? {
        guard let u = windSpeed, u.isFinite, u > 0 else { return nil }
        // Pierson–Moskowitz fully developed sea approximation:
        // Tp ≈ 0.83 * U10 (seconds), clamp to a reasonable surf range
        let raw = 0.83 * u
        let clamped = max(2.0, min(18.0, raw))
        return clamped
    }
    
    private func mapWeather(skyCondition: Int?, precipitationType: Int?) -> WeatherType {
        let sky = skyCondition ?? 0
        let pty = precipitationType ?? 0
        return WeatherType.from(
            skyCondition: sky,
            precipitationType: pty,
            humidity: humidity,
            windSpeed: windSpeed,
            precipitationProbability: precipitationProbability
        )
    }
}
