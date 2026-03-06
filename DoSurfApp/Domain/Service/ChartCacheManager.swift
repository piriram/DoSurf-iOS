import Foundation
import Network

struct CachedBeachData {
    let data: BeachData
    let cachedAt: Date
    let signature: String

    init(data: BeachData, cachedAt: Date = Date(), signature: String? = nil) {
        self.data = data
        self.cachedAt = cachedAt
        self.signature = signature ?? CachedBeachData.computeSignature(for: data)
    }

    var age: TimeInterval {
        Date().timeIntervalSince(cachedAt)
    }

    static func computeSignature(for data: BeachData) -> String {
        let points = data.charts.suffix(20).map {
            "\($0.time.timeIntervalSince1970)|\($0.windSpeed)|\($0.waveHeight)|\($0.wavePeriod)|\($0.weather.rawValue)"
        }
        return "\(data.charts.count)-\(data.lastUpdated.timeIntervalSince1970)-\(points.joined(separator: ","))"
    }
}

struct ChartCacheMetrics {
    let memoryHits: Int
    let memoryMisses: Int
    let diskHits: Int
    let staleFallbacks: Int
    let writes: Int
}

final class ChartCacheManager {
    private final class CacheEntry: NSObject {
        let value: CachedBeachData
        init(_ value: CachedBeachData) { self.value = value }
    }

    private struct MutableMetrics {
        var memoryHits = 0
        var memoryMisses = 0
        var diskHits = 0
        var staleFallbacks = 0
        var writes = 0
    }

    private struct DiskCacheRecord: Codable {
        let cachedAt: Date
        let signature: String
        let payload: BeachDataDiskDTO
    }

    private struct BeachDataDiskDTO: Codable {
        let metadata: BeachMetadataDiskDTO
        let charts: [ChartDiskDTO]
        let lastUpdated: Date

        init(_ value: BeachData) {
            metadata = BeachMetadataDiskDTO(value.metadata)
            charts = value.charts.map(ChartDiskDTO.init)
            lastUpdated = value.lastUpdated
        }

        func toDomain() -> BeachData {
            BeachData(
                metadata: metadata.toDomain(),
                charts: charts.map { $0.toDomain() },
                lastUpdated: lastUpdated
            )
        }
    }

    private struct BeachMetadataDiskDTO: Codable {
        let id: String
        let name: String
        let region: String
        let status: String
        let lastUpdated: Date
        let totalForecasts: Int

        init(_ value: BeachMetadata) {
            id = value.id
            name = value.name
            region = value.region
            status = value.status
            lastUpdated = value.lastUpdated
            totalForecasts = value.totalForecasts
        }

        func toDomain() -> BeachMetadata {
            BeachMetadata(
                id: id,
                name: name,
                region: region,
                status: status,
                lastUpdated: lastUpdated,
                totalForecasts: totalForecasts
            )
        }
    }

    private struct ChartDiskDTO: Codable {
        let beachID: Int
        let time: Date
        let windDirection: Double
        let windSpeed: Double
        let waveDirection: Double
        let waveHeight: Double
        let wavePeriod: Double
        let waterTemperature: Double
        let weatherRawValue: Int
        let airTemperature: Double

        init(_ value: Chart) {
            beachID = value.beachID
            time = value.time
            windDirection = value.windDirection
            windSpeed = value.windSpeed
            waveDirection = value.waveDirection
            waveHeight = value.waveHeight
            wavePeriod = value.wavePeriod
            waterTemperature = value.waterTemperature
            weatherRawValue = value.weather.rawValue
            airTemperature = value.airTemperature
        }

        func toDomain() -> Chart {
            Chart(
                beachID: beachID,
                time: time,
                windDirection: windDirection,
                windSpeed: windSpeed,
                waveDirection: waveDirection,
                waveHeight: waveHeight,
                wavePeriod: wavePeriod,
                waterTemperature: waterTemperature,
                weather: WeatherType(rawValue: weatherRawValue) ?? .unknown,
                airTemperature: airTemperature
            )
        }
    }

    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheQueue = DispatchQueue(label: "com.dosurf.chartcache", qos: .utility)

    private let staleSecondsWiFi: TimeInterval = 60 * 4
    private let staleSecondsCellular: TimeInterval = 60 * 8
    private let diskTTLSeconds: TimeInterval = 60 * 60 * 6
    private let maxDiskSizeBytes = 50 * 1024 * 1024

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.dosurf.chartcache.network", qos: .utility)
    private var networkStatus: NWPath.Status = .requiresConnection
    private var isOnWiFi = false

    private let fileManager = FileManager.default
    private let diskDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var metrics = MutableMetrics()
    private var accessFrequency: [String: Int] = [:]

    init() {
        cache.countLimit = 10

        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        diskDirectory = baseDirectory.appendingPathComponent("DoSurfChartCache", isDirectory: true)

        ensureDiskDirectory()
        startNetworkMonitor()
    }

    deinit {
        monitor.cancel()
    }

    func cacheKey(beachId: String, region: String, daysBack: Int) -> String {
        "\(region)|\(beachId)|\(daysBack)"
    }

    func noteAccess(beachId: String, region: String) {
        cacheQueue.async {
            let key = self.frequencyKey(region: region, beachId: beachId)
            self.accessFrequency[key, default: 0] += 1
        }
    }

    func read(key: String) -> CachedBeachData? {
        var cached: CachedBeachData?

        cacheQueue.sync {
            noteAccessLocked(cacheKey: key)

            if let value = cache.object(forKey: key as NSString)?.value {
                metrics.memoryHits += 1
                cached = value
                return
            }

            metrics.memoryMisses += 1
            guard let diskValue = readFromDiskLocked(key: key) else { return }
            metrics.diskHits += 1

            cache.setObject(CacheEntry(diskValue), forKey: key as NSString)
            cached = diskValue
        }

        return cached
    }

    func write(_ data: BeachData, for key: String) {
        let value = CachedBeachData(data: data)

        cacheQueue.async {
            self.metrics.writes += 1
            self.noteAccessLocked(cacheKey: key)
            self.cache.setObject(CacheEntry(value), forKey: key as NSString)
            self.writeToDiskLocked(value, key: key)
        }
    }

    func isStale(_ cached: CachedBeachData) -> Bool {
        var stale = false

        cacheQueue.sync {
            let ttl = currentStaleSecondsLocked()
            guard ttl.isFinite else {
                stale = false
                return
            }
            stale = Date().timeIntervalSince(cached.cachedAt) > ttl
        }

        return stale
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

        var results: [String] = []

        cacheQueue.sync {
            guard let candidates = groupedByRegion[region],
                  let currentIndex = candidates.firstIndex(of: currentBeachId) else {
                return
            }

            let neighbors = candidates.enumerated()
                .filter { $0.offset != currentIndex }
                .map { (beachId: $0.element, distance: abs($0.offset - currentIndex)) }

            let ordered = neighbors.sorted { lhs, rhs in
                let lhsFrequency = accessFrequency[frequencyKey(region: region, beachId: lhs.beachId), default: 0]
                let rhsFrequency = accessFrequency[frequencyKey(region: region, beachId: rhs.beachId), default: 0]

                if lhsFrequency != rhsFrequency {
                    return lhsFrequency > rhsFrequency
                }

                return lhs.distance < rhs.distance
            }

            results = Array(ordered.prefix(maxCount).map { $0.beachId })
        }

        return results
    }

    func notifyStaleFallback(key: String, age: TimeInterval, underlyingError: Error) {
        cacheQueue.async {
            self.metrics.staleFallbacks += 1
        }

        let keyParts = parseCacheKey(key)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .chartCacheServedStaleData,
                object: nil,
                userInfo: [
                    "cacheKey": key,
                    "region": keyParts?.region ?? "",
                    "beachId": keyParts?.beachId ?? "",
                    "age": age,
                    "reason": underlyingError.localizedDescription
                ]
            )
        }
    }

    func metricsSnapshot() -> ChartCacheMetrics {
        var snapshot: ChartCacheMetrics!

        cacheQueue.sync {
            snapshot = ChartCacheMetrics(
                memoryHits: metrics.memoryHits,
                memoryMisses: metrics.memoryMisses,
                diskHits: metrics.diskHits,
                staleFallbacks: metrics.staleFallbacks,
                writes: metrics.writes
            )
        }

        return snapshot
    }

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.cacheQueue.async {
                self?.networkStatus = path.status
                self?.isOnWiFi = path.usesInterfaceType(.wifi)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func currentStaleSecondsLocked() -> TimeInterval {
        guard networkStatus == .satisfied else {
            return .infinity
        }

        return isOnWiFi ? staleSecondsWiFi : staleSecondsCellular
    }

    private func ensureDiskDirectory() {
        do {
            try fileManager.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        } catch {
            print("⚠️ [ChartCache] failed to create cache directory: \(error.localizedDescription)")
        }
    }

    private func writeToDiskLocked(_ cached: CachedBeachData, key: String) {
        let record = DiskCacheRecord(
            cachedAt: cached.cachedAt,
            signature: cached.signature,
            payload: BeachDataDiskDTO(cached.data)
        )

        do {
            let data = try encoder.encode(record)
            let fileURL = cacheFileURL(for: key)
            try data.write(to: fileURL, options: [.atomic])
            try? fileManager.setAttributes([.modificationDate: cached.cachedAt], ofItemAtPath: fileURL.path)
            pruneDiskIfNeededLocked()
        } catch {
            print("⚠️ [ChartCache] failed to write disk cache: \(error.localizedDescription)")
        }
    }

    private func readFromDiskLocked(key: String) -> CachedBeachData? {
        let fileURL = cacheFileURL(for: key)
        guard let data = try? Data(contentsOf: fileURL),
              let record = try? decoder.decode(DiskCacheRecord.self, from: data) else {
            return nil
        }

        let diskAge = Date().timeIntervalSince(record.cachedAt)
        if diskAge > diskTTLSeconds {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        return CachedBeachData(
            data: record.payload.toDomain(),
            cachedAt: record.cachedAt,
            signature: record.signature
        )
    }

    private func pruneDiskIfNeededLocked() {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]

        guard let files = try? fileManager.contentsOfDirectory(
            at: diskDirectory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        var totalBytes = 0
        var fileInfos: [(url: URL, size: Int, modifiedAt: Date)] = []

        for file in files {
            guard let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true else {
                continue
            }
            let size = values.fileSize ?? 0
            let modifiedAt = values.contentModificationDate ?? .distantPast
            totalBytes += size
            fileInfos.append((url: file, size: size, modifiedAt: modifiedAt))
        }

        guard totalBytes > maxDiskSizeBytes else { return }

        let bytesToTrim = totalBytes - maxDiskSizeBytes
        var removedBytes = 0

        for candidate in fileInfos.sorted(by: { $0.modifiedAt < $1.modifiedAt }) {
            try? fileManager.removeItem(at: candidate.url)
            removedBytes += candidate.size
            if removedBytes >= bytesToTrim {
                break
            }
        }
    }

    private func cacheFileURL(for key: String) -> URL {
        diskDirectory.appendingPathComponent("\(safeFileName(for: key)).json", isDirectory: false)
    }

    private func safeFileName(for key: String) -> String {
        String(
            key.unicodeScalars.map { scalar in
                CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "_"
            }
        )
    }

    private func noteAccessLocked(cacheKey: String) {
        guard let parts = parseCacheKey(cacheKey) else { return }
        let key = frequencyKey(region: parts.region, beachId: parts.beachId)
        accessFrequency[key, default: 0] += 1
    }

    private func frequencyKey(region: String, beachId: String) -> String {
        "\(region)|\(beachId)"
    }

    private func parseCacheKey(_ key: String) -> (region: String, beachId: String)? {
        let parts = key.split(separator: "|")
        guard parts.count >= 2 else { return nil }
        return (String(parts[0]), String(parts[1]))
    }
}
