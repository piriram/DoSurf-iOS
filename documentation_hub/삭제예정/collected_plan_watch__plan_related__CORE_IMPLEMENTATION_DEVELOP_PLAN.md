# DoSurf Core Implementation & Development Plan

> 작성일: 2026-03-06
> 목적: 4개 핵심 구현 주제의 현황 분석 → Codex 즉시 실행 가능한 구현 계획
> 기준 브랜치: `Feat/watch-new`
> 수치 표기: `[추정]` = 측정 전 예상, `[측정]` = 실제 확인값

---

## 목차

1. [현황 요약 매핑](#1-현황-요약-매핑)
2. [누락/불완전 항목 목록 (P0/P1/P2)](#2-누락불완전-항목-목록)
3. [주제 1: 차트 캐싱 성능](#3-주제-1-차트-캐싱-성능)
4. [주제 2: Live Activities + Dynamic Island](#4-주제-2-live-activities--dynamic-island)
5. [주제 3: Watch-iPhone 양방향 동기화](#5-주제-3-watch-iphone-양방향-동기화)
6. [주제 4: 목업 데이터 전략](#6-주제-4-목업-데이터-전략)
7. [고도화 제안 (Beyond MVP)](#7-고도화-제안)

---

## 1. 현황 요약 매핑

| 주제 | 요구 | 현재 구현 | 완성도 |
|------|------|-----------|--------|
| **1. 차트 캐싱** | LRU 캐시 + prefetch + stale-while-revalidate | NSCache(LRU) + prefetch ±3 + 부분 SWR | 75% |
| **2. Live Activities** | ActivityKit + Dynamic Island 세션 모니터링 | 완전 구현 (타이머 기반 업데이트) | 85% |
| **3. Watch 동기화** | lastModifiedAt/deviceID/isDeleted + 충돌 규칙 + 증분/배치/재시도 | 완전 구현 (메모리 큐, 배치 8개, 재시도 3회) | 80% |
| **4. 목업 전략** | 프로토콜 추상화 + 단일 전환 스위치 | 프로토콜 추상화 완료, 전환 스위치 부재 | 70% |

### 핵심 현황 정리

**기존 구현 파일 (변경 대상)**

```
DoSurfApp/
├── Domain/
│   ├── Service/
│   │   ├── ChartCacheManager.swift          [측정: 92줄] ← 주제 1
│   │   └── SurfingActivityManager.swift     [측정: 226줄] ← 주제 2
│   ├── UseCase/
│   │   ├── CachedFetchBeachDataUseCase.swift [측정: 86줄] ← 주제 1
│   │   ├── MockFetchBeachDataUseCase.swift   [측정: 78줄] ← 주제 4
│   │   └── FetchBeachDataUseCase.swift      [측정: 56줄] ← 주제 4
│   ├── Service/
│   │   └── SurfRecordSyncService.swift      [측정: 146줄] ← 주제 3
│   └── Protocol/
│       └── FirestoreProtocol.swift          [측정: 8줄] ← 주제 4
├── Infra/
│   ├── iPhoneWatchConnectivity.swift        [측정: 330줄] ← 주제 3
│   └── WatchDataSyncCoordinator.swift       [측정: 28줄] ← 주제 3
└── App/
    └── DIContainer.swift                    [측정: 100줄] ← 주제 4

DoSurfWatch Watch App/
├── WatchConnectivityManager.swift           [측정: 112줄] ← 주제 3
└── WatchDataStructures.swift                [측정: 118줄] ← 주제 3

DoSurfWidgetExtension/
└── SurfingLiveActivity.swift                [측정: 195줄] ← 주제 2
```

---

## 2. 누락/불완전 항목 목록

### P0 (즉시 구현 필수 - 기능 안정성)

| ID | 항목 | 주제 | 이유 |
|----|------|------|------|
| P0-1 | Watch pending 세션 **디스크 영속화** | 3 | 앱 재시작 시 미전송 데이터 유실 |
| P0-2 | **중앙화된 Mock 전환 스위치** | 4 | 목업/실제 전환이 DIContainer 코드 수정 필요 |
| P0-3 | SWR(stale-while-revalidate) **오류 상태 처리** | 1 | 원격 실패 시 stale 데이터 명시 없음 |

### P1 (이번 스프린트 내 구현 권장)

| ID | 항목 | 주제 | 이유 |
|----|------|------|------|
| P1-1 | 차트 캐시 **디스크 2차 레이어** | 1 | 앱 재시작 시 캐시 cold start 발생 |
| P1-2 | 캐시 TTL **네트워크 상태 동적 조정** | 1 | 오프라인 시 만료 캐시도 사용 불가 |
| P1-3 | Live Activity **Push-to-Start / Remote Update** | 2 | 백그라운드에서 타이머 제한 (iOS 16+) |
| P1-4 | Watch 동기화 **네트워크 복구 자동 재시도** | 3 | 현재 수동 flushPending만 가능 |
| P1-5 | **MockSurfRecordRepository** 구현 | 4 | CoreData 목업 없어 세션 기록 테스트 불가 |

### P2 (개선/고도화)

| ID | 항목 | 주제 | 이유 |
|----|------|------|------|
| P2-1 | Prefetch **우선순위 큐** (인기 해변 가중치) | 1 | 현재 단순 ±3 인접 전략 |
| P2-2 | Dynamic Island **실시간 심박수 반영** | 2 | 현재 정적 업데이트 (타이머 60초) |
| P2-3 | **CRDT 기반 충돌 해결** 고도화 | 3 | 현재 lastModifiedAt 단순 비교 |
| P2-4 | Mock 데이터 **시나리오 기반 주입** | 4 | 고정 해변만 지원, 엣지 케이스 불가 |
| P2-5 | 캐시 **히트율 메트릭** 수집 | 1 | 성능 측정 불가 |

---

## 3. 주제 1: 차트 캐싱 성능

### 현재 구현 상세

```swift
// ChartCacheManager.swift - 현재 구현
private let cache = NSCache<NSString, CacheEntry>()  // LRU 자동
cache.countLimit = 10                                 // [측정] 10개 해변
private let staleSeconds: TimeInterval = 60 * 4      // [측정] 240초 TTL

// 부분 SWR: 캐시 먼저 emit 후 원격 필터링
return remoteObservable
    .filter { self.cacheManager.markIfUpdated(key, data: $0) }
    .startWith(cachedData.data)
```

### 누락 항목별 구현 전략

---

#### [P0-3] SWR 오류 상태 처리

**현황**: 원격 fetch 실패 시 stale 캐시 사용 여부 불명확, 에러 전파됨
**목표**: 네트워크 오류 시 stale 캐시 + 경고 배너 표시

**구현 전략**:
```swift
// CachedFetchBeachDataUseCase.swift 수정
func execute(...) -> Observable<BeachData> {
    let cached = cacheManager.get(cacheKey)

    return remoteObservable
        .catch { [weak self] error -> Observable<BeachData> in
            guard let cached = self?.cacheManager.get(cacheKey) else {
                return .error(error)
            }
            // stale 캐시 방출 + 에러 이벤트로 UI에 알림
            return .concat(
                .just(cached.data),
                .error(CacheError.staleDataUsed(age: cached.age))
            )
        }
        .startWith(cached?.data)
        .compactMap { $0 }
}
```

**영향 파일**:
- `DoSurfApp/Domain/UseCase/CachedFetchBeachDataUseCase.swift`
- `DoSurfApp/Presentation/ViewModel/ChartViewModel.swift` (에러 상태 처리)

**수용 기준**:
- [ ] 오프라인 상태에서 앱 실행 시 stale 캐시 데이터 표시됨
- [ ] UI에 "오프라인 / 마지막 업데이트: N분 전" 배너 노출
- [ ] 캐시 없는 오프라인 시 적절한 에러 메시지

**검증 절차**:
```
1. 네트워크 차단 (기기 비행기 모드)
2. 앱 실행 후 이전 캐시된 해변 탭
3. 데이터 표시 확인 + 오프라인 배너 확인
4. 캐시 없는 해변 탭 → 에러 메시지 확인
```

---

#### [P1-1] 디스크 2차 캐시 레이어

**현황**: NSCache(메모리)만 사용 → 앱 재시작 시 항상 cold start
**목표**: 메모리 미스 시 디스크에서 복구 (cold start [추정] 500ms → 50ms)

**구현 전략**:
```swift
// 신규 파일: DoSurfApp/Infra/Cache/DiskChartCache.swift
actor DiskChartCache {
    private let directory: URL
    private let maxSizeBytes = 50 * 1024 * 1024  // 50MB 상한
    private let ttl: TimeInterval = 60 * 60 * 6  // 6시간 (메모리 TTL보다 길게)

    func store(_ data: BeachData, key: String) async throws {
        let encoded = try JSONEncoder().encode(data)
        let fileURL = directory.appendingPathComponent("\(key).cache")
        try encoded.write(to: fileURL)
        try setMetadata(key: key, storedAt: Date())
    }

    func retrieve(key: String) async -> BeachData? {
        guard !isExpired(key: key) else { return nil }
        guard let data = try? Data(contentsOf: fileURL(for: key)) else { return nil }
        return try? JSONDecoder().decode(BeachData.self, from: data)
    }
}

// ChartCacheManager.swift에 레이어 통합
func get(_ key: String) -> CacheEntry? {
    // L1: 메모리
    if let entry = cache.object(forKey: key as NSString) { return entry }
    // L2: 디스크 (async 조회 후 L1에 warm-up)
    Task { await warmMemoryFromDisk(key) }
    return nil
}
```

**영향 파일**:
- `DoSurfApp/Infra/Cache/DiskChartCache.swift` (신규)
- `DoSurfApp/Domain/Service/ChartCacheManager.swift`
- `DoSurfApp/App/DIContainer.swift` (의존성 주입)

**수용 기준**:
- [ ] 앱 재시작 후 이전에 조회한 해변 데이터 즉시 표시 (네트워크 없어도)
- [ ] 디스크 캐시 크기 50MB 초과 시 LRU 정책으로 자동 정리
- [ ] 6시간 이상 된 디스크 캐시는 무효화 후 원격 fetch

**검증 절차**:
```
1. 해변 3개 탭 (캐시 생성)
2. 앱 완전 종료
3. 네트워크 차단
4. 앱 재시작 → 동일 해변 3개 즉시 표시 확인
5. XCTest: DiskChartCacheTests 통과
```

---

#### [P1-2] 동적 TTL (네트워크 상태 연동)

**현황**: TTL 고정 240초 → 오프라인 시 유효 데이터도 만료 처리
**목표**: 오프라인 시 TTL 무한대, Wi-Fi 시 240초, 셀룰러 시 480초

**구현 전략**:
```swift
// ChartCacheManager.swift 수정
import Network

private let monitor = NWPathMonitor()
private var currentTTL: TimeInterval {
    switch monitor.currentPath.status {
    case .satisfied where monitor.currentPath.usesInterfaceType(.wifi):
        return 60 * 4        // 240초 (Wi-Fi)
    case .satisfied:
        return 60 * 8        // 480초 (셀룰러) [추정]
    case .unsatisfied, .requiresConnection:
        return .infinity     // 오프라인: 만료 없음
    default:
        return 60 * 4
    }
}
```

**영향 파일**:
- `DoSurfApp/Domain/Service/ChartCacheManager.swift`

**수용 기준**:
- [ ] 오프라인 전환 시 캐시 만료되지 않음
- [ ] Wi-Fi 복구 시 TTL 정상 적용
- [ ] NWPathMonitor 정리 (deinit에서 cancel())

---

#### [P2-1] Prefetch 우선순위 큐

**현황**: ±3 인접 해변 단순 prefetch
**목표**: 사용자 조회 빈도 기반 가중치 prefetch

**구현 전략**:
```swift
// 신규: DoSurfApp/Domain/Service/PrefetchPriorityQueue.swift
actor PrefetchPriorityQueue {
    private var viewCounts: [String: Int] = [:]  // beachId → 조회수

    // 조회 시 카운트 증가
    func recordView(beachId: String) { viewCounts[beachId, default: 0] += 1 }

    // 상위 N개 반환 (우선순위 prefetch 대상)
    func topBeaches(limit: Int) -> [String] {
        viewCounts.sorted { $0.value > $1.value }
            .prefix(limit).map { $0.key }
    }
}
```

**영향 파일**:
- `DoSurfApp/Domain/Service/PrefetchPriorityQueue.swift` (신규)
- `DoSurfApp/Domain/Service/ChartCacheManager.swift`

---

## 4. 주제 2: Live Activities + Dynamic Island

### 현재 구현 상세

```swift
// SurfingActivityManager.swift - 타이머 기반 업데이트
private func scheduleUpdate(after seconds: TimeInterval) {
    Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
        Task { await self?.updateActivity() }
    }
}
// 동적 간격: 초기 60초 → 5분 → 10분
```

```swift
// SurfingActivityAttributes.swift
struct ContentState: Codable, Hashable {
    var startTime: Date
    var elapsedMinutes: Int      // [측정] 존재
    var statusMessage: String    // [측정] 존재
    var beachName: String        // [측정] 존재
    var rideCount: Int           // [측정] 존재
    var averageHeartRate: Double // [측정] 존재
}
```

### 누락 항목별 구현 전략

---

#### [P1-3] Push-to-Start / Remote Update 통합

**현황**: 타이머 기반만 → 백그라운드 제한(iOS) 시 업데이트 지연
**목표**: APNs를 통한 Live Activity 원격 업데이트

**구현 전략**:
```swift
// SurfingActivityManager.swift 수정
func startActivity(...) async throws -> Activity<SurfingActivityAttributes> {
    let activity = try Activity.request(
        attributes: attributes,
        contentState: initialState,
        pushType: .token  // Push 토큰 활성화
    )

    // Push 토큰 구독 (iOS 17+)
    if #available(iOS 17.2, *) {
        for await tokenData in activity.pushTokenUpdates {
            let token = tokenData.map { String(format: "%02x", $0) }.joined()
            await uploadPushToken(token, activityId: activity.id)
        }
    }
    return activity
}

// 서버 → APNs 페이로드 예시 (참고용)
// {
//   "aps": {
//     "timestamp": 1234567890,
//     "event": "update",
//     "content-state": {
//       "elapsedMinutes": 45,
//       "rideCount": 7,
//       "averageHeartRate": 142.0
//     }
//   }
// }
```

**영향 파일**:
- `DoSurfApp/Domain/Service/SurfingActivityManager.swift`
- 백엔드: Firebase Functions 또는 서버 (별도 작업)

**수용 기준**:
- [ ] 백그라운드 상태에서 Live Activity 수치 업데이트됨
- [ ] Push 토큰이 서버에 정상 전달됨
- [ ] 세션 종료 시 Live Activity 즉시 종료됨

**검증 절차**:
```
1. 세션 시작 → Live Activity 활성화
2. 앱 백그라운드 전환
3. 서버에서 APNs 전송 (또는 시뮬레이터 push 명령)
4. 잠금화면/Dynamic Island 업데이트 확인
```

> **주의**: Push 기반 업데이트는 서버 사이드 작업 필요.
> MVP 우선순위: 타이머 유지 + 토큰 등록만 구현.

---

#### [P2-2] 실시간 심박수 반영

**현황**: averageHeartRate를 60초 간격으로 업데이트
**목표**: HealthKit 심박수 스트림 → Live Activity 15초 반영

**구현 전략**:
```swift
// 신규: DoSurfApp/Domain/Service/HeartRateStreamService.swift
import HealthKit

final class HeartRateStreamService {
    private let healthStore = HKHealthStore()

    func startStreaming() -> AsyncStream<Double> {
        AsyncStream { continuation in
            let query = HKAnchoredObjectQuery(type: heartRateType, ...) { _, samples, _, _, _ in
                guard let bpm = (samples?.last as? HKQuantitySample)?
                    .quantity.doubleValue(for: .count().unitDivided(by: .minute())) else { return }
                continuation.yield(bpm)
            }
            query.updateHandler = { ... }
            healthStore.execute(query)
        }
    }
}
```

**영향 파일**:
- `DoSurfApp/Domain/Service/HeartRateStreamService.swift` (신규)
- `DoSurfApp/Domain/Service/SurfingActivityManager.swift`
- `Info.plist`: `NSHealthShareUsageDescription` 추가 필요

---

## 5. 주제 3: Watch-iPhone 양방향 동기화

### 현재 구현 상세

```swift
// SurfRecordSyncService.swift - 충돌 해결 (현재 완전 구현)
private func shouldApply(_ payload: WatchSessionPayload) -> Single<Bool> {
    // 1. 스키마 버전 < 최소 지원 → 거부
    // 2. lastModifiedAt 최신 → 수락
    // 3. isDeleted 우선 (삭제 우선 정책)
    // 4. deviceId 사전식 정렬 (결정적)
}

// WatchConnectivityManager.swift - 배치/재시도
private let maxBatchCount = 8           // [측정]
private let maxRetryCount = 3           // [측정]
// 지수 백오프: 0.5초 → 1초 → 2초    [측정]
```

### 누락 항목별 구현 전략

---

#### [P0-1] Pending 세션 디스크 영속화

**현황**: `pendingSessions: [WatchSurfSessionData]` 메모리 배열
→ Watch 앱 크래시/종료 시 미전송 세션 유실

**목표**: UserDefaults 또는 파일 시스템 영속화

**구현 전략**:
```swift
// WatchConnectivityManager.swift 수정
// actor로 thread-safe 보장

actor PendingSessionStore {
    private let storageKey = "dosurf.pending_sessions"

    func save(_ sessions: [WatchSurfSessionData]) {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    func load() -> [WatchSurfSessionData] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let sessions = try? JSONDecoder().decode([WatchSurfSessionData].self, from: data)
        else { return [] }
        return sessions
    }

    func remove(ids: Set<String>) {
        var sessions = load()
        sessions.removeAll { ids.contains($0.localId) }
        save(sessions)
    }
}

// WatchConnectivityManager에서 사용
private var pendingStore = PendingSessionStore()

func addPending(_ session: WatchSurfSessionData) async {
    pendingSessions.append(session)
    await pendingStore.save(pendingSessions)  // 즉시 영속화
}

// 앱 시작 시 복구
init() {
    Task { pendingSessions = await pendingStore.load() }
}
```

**영향 파일**:
- `DoSurfWatch Watch App/WatchConnectivityManager.swift`
- `DoSurfWatch Watch App/PendingSessionStore.swift` (신규)

**수용 기준**:
- [ ] 세션 기록 → Watch 앱 강제 종료 → 재시작 → 자동 전송 성공
- [ ] 전송 완료 세션은 영속화 저장소에서 즉시 제거
- [ ] UserDefaults 최대 1MB 이내 (세션 50개 [추정] 기준 충분)

**검증 절차**:
```
1. Watch에서 서핑 세션 기록
2. iPhone 연결 끊기
3. Watch 앱 강제 종료 (크라운 길게 누름 → 스와이프)
4. Watch 앱 재시작
5. iPhone 연결 복구
6. iPhone 앱에서 세션 데이터 확인
```

---

#### [P1-4] 네트워크 복구 자동 재시도

**현황**: `flushPending()` 수동 호출 필요 (세션 시작/종료 시에만 트리거)
**목표**: WCSession reachability 변경 → 자동 flush

**구현 전략**:
```swift
// WatchConnectivityManager.swift 수정
extension WatchConnectivityManager: WCSessionDelegate {

    // reachability 변경 감지 (기존 delegate)
    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task {
            // 연결 복구 시 자동 flush
            try? await flushPending()
        }
    }

    // iPhone 활성화 완료 시 (앱 포어그라운드 복귀 포함)
    func sessionWatchStateDidChange(_ session: WCSession) {
        if session.isPaired && session.isWatchAppInstalled {
            Task { try? await flushPending() }
        }
    }
}
```

**영향 파일**:
- `DoSurfWatch Watch App/WatchConnectivityManager.swift`

**수용 기준**:
- [ ] Watch와 iPhone 재연결 시 pending 세션 자동 전송
- [ ] 중복 전송 없음 (localId 기반 중복 제거)

---

#### [P2-3] CRDT 기반 충돌 해결 고도화

**현황**: lastModifiedAt 단순 비교 → 동시 편집 시 한쪽 유실
**목표**: 세션 필드별 개별 충돌 해결 (LWW-Element-Set 방식)

**구현 전략**:
```swift
// 신규: DoSurfApp/Domain/Model/CRDTSurfRecord.swift
struct CRDTSurfRecord {
    // 각 필드에 (값, 타임스탬프, 디바이스ID) 튜플
    struct LWWField<T: Codable> {
        var value: T
        var timestamp: Date
        var deviceId: String
    }

    var duration: LWWField<TimeInterval>
    var rideCount: LWWField<Int>
    var note: LWWField<String?>

    // 병합: 각 필드 독립 LWW
    func merged(with other: CRDTSurfRecord) -> CRDTSurfRecord {
        return CRDTSurfRecord(
            duration: duration.timestamp >= other.duration.timestamp ? duration : other.duration,
            rideCount: rideCount.timestamp >= other.rideCount.timestamp ? rideCount : other.rideCount,
            note: note.timestamp >= other.note.timestamp ? note : other.note
        )
    }
}
```

> **주의**: 기존 CoreData 스키마 마이그레이션 필요. P2 단계에서 검토.

---

## 6. 주제 4: 목업 데이터 전략

### 현재 구현 상세

```swift
// 프로토콜 추상화 현황 (완전 구현)
protocol FetchBeachDataUseCase { ... }        // [측정] 존재
protocol FirestoreProtocol { ... }           // [측정] 존재 (8줄)
protocol NoteRepositoryProtocol { ... }      // [측정] 존재

// 구현체
MockFetchBeachDataUseCase   // [측정] 78줄, 존재
DefaultFetchBeachDataUseCase // 실제
CachedFetchBeachDataUseCase  // 캐시 래퍼

// DIContainer - 전환점
func makeFetchBeachDataUseCase() -> FetchBeachDataUseCase {
    // 코드 수정 없이 전환 불가능 (환경변수/플래그 없음)
}
```

### 누락 항목별 구현 전략

---

#### [P0-2] 중앙화된 Mock 전환 스위치

**현황**: 목업 사용 시 `DIContainer.swift` 코드 직접 수정 필요
**목표**: 빌드 스킴 또는 환경 변수로 전환

**구현 전략**:
```swift
// 신규: DoSurfApp/App/AppEnvironment.swift
enum AppEnvironment {
    case production
    case mock
    case mockWithDelay(seconds: Double)  // 로딩 UX 테스트용

    static var current: AppEnvironment {
        #if DEBUG
        // 1순위: 런치 인수 (Xcode 스킴에서 설정)
        if CommandLine.arguments.contains("-UseMockData") {
            return .mock
        }
        if CommandLine.arguments.contains("-UseMockWithDelay") {
            return .mockWithDelay(seconds: 1.5)
        }
        // 2순위: 환경 변수
        if ProcessInfo.processInfo.environment["USE_MOCK_DATA"] == "1" {
            return .mock
        }
        #endif
        return .production
    }

    var isMock: Bool {
        switch self {
        case .production: return false
        default: return true
        }
    }
}

// DIContainer.swift 수정
func makeFetchBeachDataUseCase() -> FetchBeachDataUseCase {
    switch AppEnvironment.current {
    case .mock, .mockWithDelay:
        return MockFetchBeachDataUseCase()
    case .production:
        return CachedFetchBeachDataUseCase(
            remote: DefaultFetchBeachDataUseCase(repository: makeBeachRepository()),
            fallback: MockFetchBeachDataUseCase()
        )
    }
}
```

**Xcode 스킴 설정 (문서화)**:
```
Product → Scheme → Edit Scheme → Run → Arguments → Arguments Passed On Launch:
  -UseMockData
```

**영향 파일**:
- `DoSurfApp/App/AppEnvironment.swift` (신규)
- `DoSurfApp/App/DIContainer.swift`

**수용 기준**:
- [ ] `-UseMockData` 런치 인수로 코드 수정 없이 전환
- [ ] 프로덕션 빌드에서 mock 경로 접근 불가 (`#if DEBUG` 보호)
- [ ] AppEnvironment 단위 테스트 통과

**검증 절차**:
```
1. Xcode 스킴에 -UseMockData 추가
2. 앱 실행 → 해변 차트 탭
3. 콘솔: "[AppEnvironment] Using mock data" 로그 확인
4. 실제 API 호출 없음 확인 (Network Inspector)
```

---

#### [P1-5] MockSurfRecordRepository

**현황**: 실제 CoreData만 사용 → 세션 기록 관련 UI 테스트 불가
**목표**: 인메모리 목업 저장소로 CoreData 대체

**구현 전략**:
```swift
// 신규: DoSurfApp/Domain/Repository/MockSurfRecordRepository.swift
final class MockSurfRecordRepository: NoteRepositoryProtocol {
    // actor 미사용 (단순 메모리, 테스트용)
    private var records: [String: SurfRecordData] = [:]

    // 초기 시드 데이터
    static func withSeedData() -> MockSurfRecordRepository {
        let repo = MockSurfRecordRepository()
        let seeds = SeedDataFactory.makeSurfRecords(count: 5)
        seeds.forEach { repo.records[$0.recordId] = $0 }
        return repo
    }

    func saveSurfRecord(_ record: SurfRecordData) -> Single<Void> {
        records[record.recordId] = record
        return .just(())
    }

    func fetchAllSurfRecords() -> Single<[SurfRecordData]> {
        .just(Array(records.values).sorted { $0.createdAt > $1.createdAt })
    }

    func fetchSurfRecord(byRecordId recordId: String) -> Single<SurfRecordData?> {
        .just(records[recordId])
    }

    func updateSurfRecord(_ record: SurfRecordData) -> Single<Void> {
        records[record.recordId] = record
        return .just(())
    }
}
```

**영향 파일**:
- `DoSurfApp/Domain/Repository/MockSurfRecordRepository.swift` (신규)
- `DoSurfApp/App/DIContainer.swift`
- `DoSurfApp/App/AppEnvironment.swift`

**수용 기준**:
- [ ] 목업 모드에서 기록 목록 화면 정상 동작
- [ ] 세션 저장/조회/삭제 동작 확인
- [ ] CoreData 파일 생성 없음

---

#### [P2-4] 시나리오 기반 Mock 주입

**현황**: 고정 해변 ID (강릉/포항/제주/부산)만 목업 지원
**목표**: 엣지 케이스 시나리오 주입 가능

**구현 전략**:
```swift
// MockFetchBeachDataUseCase.swift 확장
enum MockScenario {
    case normal           // 기본 정상 데이터
    case noData           // 데이터 없음
    case networkError     // 네트워크 오류
    case slowNetwork(delay: TimeInterval)  // 느린 로딩
    case staleData(age: TimeInterval)      // 오래된 데이터
}

final class MockFetchBeachDataUseCase: FetchBeachDataUseCase {
    var scenario: MockScenario = .normal

    func execute(...) -> Observable<BeachData> {
        switch scenario {
        case .normal:           return .just(makeMockData(...))
        case .noData:           return .just(BeachData.empty)
        case .networkError:     return .error(URLError(.notConnectedToInternet))
        case .slowNetwork(let delay):
            return .just(makeMockData(...)).delay(.seconds(delay), scheduler: MainScheduler.instance)
        case .staleData(let age):
            return .just(makeMockData(ageOffset: -age))
        }
    }
}
```

**영향 파일**:
- `DoSurfApp/Domain/UseCase/MockFetchBeachDataUseCase.swift`

---

## 7. 고도화 제안 (Beyond MVP)

단순 보완을 넘어 경쟁력 있는 기능으로 발전 가능한 제안

### 7-1. 오프라인 퍼스트 아키텍처 (주제 1 + 3 통합)

**개념**: 차트 캐시(L1 메모리 + L2 디스크)와 Watch 동기화 큐를 통합한 단일 `OfflineDataManager`

```
사용자 요청
    ↓
OfflineDataManager
    ├── L1 메모리 캐시 (즉시 응답)
    ├── L2 디스크 캐시 (cold start 복구)
    ├── 원격 fetch (백그라운드)
    └── Watch 동기화 큐 (연결 복구 시 자동 flush)
```

**효과**: 네트워크 없이도 완전한 앱 경험 [추정: offline 사용성 80% 달성]

---

### 7-2. Live Activity ↔ Watch 동기화 연동 (주제 2 + 3 통합)

**개념**: Watch에서 라이딩 이벤트 발생 → iPhone Live Activity 즉시 업데이트

```
Watch 라이딩 감지
    → WCSession.sendMessage (즉시)
    → iPhone SurfingActivityManager.updateActivity()
    → Dynamic Island 실시간 갱신
```

**현재 갭**: Watch → iPhone 메시지와 Live Activity 업데이트가 분리되어 있음
**구현 비용**: [추정] 2-3일 (WatchConnectivity + ActivityManager 연결)

---

### 7-3. SwiftData 마이그레이션 (주제 3 + 4 고도화)

**현황**: CoreData (SurfRecordRepository.swift 447줄의 보일러플레이트)
**목표**: SwiftData로 마이그레이션 → 코드 [추정] 40% 감소

```swift
// 현재 CoreData
@NSManaged var durationSeconds: Double
// 변환 코드 수십 줄...

// SwiftData (미래)
@Model final class SurfRecord {
    var durationSeconds: Double
    var createdAt: Date
    // 자동 영속화, Codable 불필요
}
```

**주의**: iOS 17.0+ 필요. 현재 배포 타겟 확인 후 결정.

---

### 7-4. 캐시 히트율 메트릭 (주제 1 고도화)

**목표**: 개발 빌드에서 캐시 효율 측정

```swift
// ChartCacheManager.swift 추가
#if DEBUG
struct CacheMetrics {
    var hits: Int = 0
    var misses: Int = 0
    var hitRate: Double { Double(hits) / Double(hits + misses) }
}
private(set) var metrics = CacheMetrics()
#endif
```

**활용**: Xcode Console에서 `[Cache] Hit rate: 78%` 로그로 TTL/크기 튜닝

---

## 구현 순서 권장

```
Sprint 1 (안정성)
  P0-1 → Watch pending 영속화
  P0-2 → Mock 전환 스위치
  P0-3 → SWR 오류 처리

Sprint 2 (완성도)
  P1-1 → 디스크 캐시
  P1-4 → 자동 재시도
  P1-5 → MockSurfRecordRepository

Sprint 3 (고도화)
  P1-2 → 동적 TTL
  P1-3 → Push-to-Start
  P2-1 ~ P2-5
```

---

*최종 검토: 2026-03-06 | 다음 업데이트: Sprint 1 완료 후*
