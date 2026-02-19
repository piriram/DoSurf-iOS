import Foundation

struct CachedBeachData {
    let data: BeachData
    let cachedAt: Date
    let signature: String

    init(data: BeachData) {
        self.data = data
        self.cachedAt = Date()
        self.signature = CachedBeachData.computeSignature(for: data)
    }

    static func computeSignature(for data: BeachData) -> String {
        let points = data.charts.suffix(20).map {
            "\($0.time.timeIntervalSince1970)|\($0.windSpeed)|\($0.waveHeight)|\($0.wavePeriod)|\($0.weather.rawValue)"
        }
        return "\(data.charts.count)-\(data.lastUpdated.timeIntervalSince1970)-\(points.joined(separator: ","))"
    }
}

final class ChartCacheManager {
    private final class CacheEntry: NSObject {
        let value: CachedBeachData
        init(_ value: CachedBeachData) { self.value = value }
    }

    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheQueue = DispatchQueue(label: "com.dosurf.chartcache", qos: .utility)
    private let staleSeconds: TimeInterval = 60 * 4

    init() {
        cache.countLimit = 10
    }

    func cacheKey(beachId: String, region: String, daysBack: Int) -> String {
        "\(region)|\(beachId)|\(daysBack)"
    }

    func read(key: String) -> CachedBeachData? {
        var cached: CachedBeachData?
        cacheQueue.sync {
            cached = cache.object(forKey: key as NSString)?.value
        }
        return cached
    }

    func write(_ data: BeachData, for key: String) {
        let value = CachedBeachData(data: data)
        cacheQueue.async {
            self.cache.setObject(CacheEntry(value), forKey: key as NSString)
        }
    }

    func isStale(_ cached: CachedBeachData) -> Bool {
        Date().timeIntervalSince(cached.cachedAt) > staleSeconds
    }

    func markIfUpdated(_ key: String, data: BeachData) -> Bool {
        let newSignature = CachedBeachData.computeSignature(for: data)
        let cached = read(key: key)
        return cached?.signature != newSignature
    }

    func prefetchCandidates(for currentBeachId: String, region: String, maxCount: Int = 3) -> [String] {
        let groupedByRegion: [String: [String]] = [
            "gangreung": ["1001", "1002", "1003", "1004"],
            "pohang": ["2001", "2002"],
            "jeju": ["3001", "3002", "3003"],
            "busan": ["4001"]
        ]

        guard let candidates = groupedByRegion[region],
              let index = candidates.firstIndex(of: currentBeachId) else {
            return []
        }

        var results: [String] = []
        let previous = max(0, index - maxCount/2)
        let next = min(candidates.count - 1, index + maxCount/2)

        if index > previous {
            results.append(contentsOf: candidates[previous..<index])
        }
        if index < next {
            results.append(contentsOf: candidates[(index + 1)...next])
        }

        return Array(results.prefix(maxCount))
    }
}
