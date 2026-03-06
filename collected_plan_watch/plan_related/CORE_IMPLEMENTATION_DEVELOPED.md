# CORE Implementation Developed Report

- 작성일시: 2026-03-06
- 기준 작업: `CORE_IMPLEMENTATION_DEVELOP_PLAN.md` 기반 즉시 구현 런
- 기준: 과장 수치 없이 `[측정]`과 `[추정]` 구분

## 구현한 누락 항목

### 1) 지역별 차트 조회 성능 개선 (LRU / prefetch / SWR)
- `ChartCacheManager`에 L1 메모리(NSCache) + L2 디스크 캐시 레이어, 동적 TTL(Wi-Fi/Cellular/Offline), prefetch 우선순위(조회 빈도+거리), stale fallback notification이 적용된 상태를 유지/정합화.
- `CachedFetchBeachDataUseCase`에서 SWR 흐름을 보완:
  - 캐시 존재 시 `startWith(cached)`로 즉시 표시.
  - 원격 실패 시 캐시가 있으면 stale fallback notification 발생 후 UI 중단 없이 캐시 유지.
  - 캐시 없고 live 모드면 실제 에러 전파.

### 2) Live Activities + Dynamic Island 개선
- `SurfingActivityManager`에서 Activity push token / push-to-start token 관측 경로 유지.
- 앱 레벨에서 원격 업데이트 브릿지 추가:
  - `AppDelegate.didReceiveRemoteNotification`에서 `aps.content-state` 파싱 후 `SurfingActivityManager.applyRemoteUpdate` 호출.
  - 토큰 업데이트 notification을 구독해 로컬 저장(UserDefaults) 및 로그 기록.

### 3) Watch-iPhone 양방향 동기화 충돌 처리 보완
- **핵심 안정화**: iPhone ACK 타이밍을 저장 성공 기준으로 변경.
  - 기존: payload 수신 즉시 성공 응답.
  - 변경: `iPhoneWatchConnectivityDelegate` completion 기반으로 실제 적용 성공 시에만 success ACK 반환.
- watch pending 큐 제거 로직을 **개수 기반(removeFirst)** 에서 **세션 스냅샷 기반(removeConfirmed by sessionId+version)** 으로 변경.
  - 전송 중 동일 sessionId의 newer payload가 들어와도 신버전이 삭제되지 않도록 보호.
- 배치 전송 루프를 재구성해 pending이 남아 있으면 연속 배치 전송, 실패 시 지수 백오프 재시도.

### 4) 목업 데이터 전략 (전환 스위치/추상화 보완)
- `AppEnvironment` 중심 전환 스위치 유지/보강:
  - `-UseMockData`, `-UseMockDataWithDelay`, `DOSURF_USE_MOCK_DATA`.
- `MockFetchBeachDataUseCase`에 시나리오 주입 추가:
  - `normal`, `noData`, `networkError`, `slow:<sec>`, `stale:<sec>`.
  - `-MockBeachScenario <scenario>` 또는 `DOSURF_MOCK_BEACH_SCENARIO`로 코드 수정 없이 전환 가능.
- `DIContainer`가 mock scenario를 주입하며, mock 모드에서 `MockSurfRecordRepository`/`MockFetchBeachListUseCase`를 사용하도록 유지.

## 디벨롭한 항목

- 동기화 신뢰성 강화(ACK after apply + snapshot-safe dequeue)로 데이터 유실 가능성 축소.
- 원격 Live Activity 업데이트를 AppDelegate까지 연결해 백그라운드 갱신 경로 관측성 강화.
- 목업 시나리오를 런치 인수/환경변수로 표준화해 QA 재현성 개선.
- mock chart 생성 로직의 날씨 값을 랜덤에서 deterministic으로 변경해 캐시/비교 일관성 개선.

## 변경 파일 목록 + 핵심 diff 요약

### 수정 파일
- `DoSurfApp/Infra/iPhoneWatchConnectivity.swift`
  - delegate 시그니처를 completion 기반으로 확장.
  - replyHandler를 실제 적용 결과(success/failure, acceptedCount) 기반으로 반환.
- `DoSurfApp/Infra/WatchDataSyncCoordinator.swift`
  - sync 적용 결과를 completion으로 전달.
- `DoSurfApp/Infra/SurfDataReceiverViewController.swift`
  - 변경된 delegate 시그니처 반영.
- `DoSurfWatch Watch App/WatchConnectivityManager.swift`
  - pending 전송 루프/재시도 재구성.
  - ACK 결과 파싱(`success`, `acceptedCount`) 반영.
  - `removeFirst` 제거, session snapshot 기반 안전 삭제로 변경.
- `DoSurfApp/App/AppDelegate.swift`
  - Live Activity push token 저장/로그 observer 추가.
  - 원격 notification(`aps.content-state`) → `applyRemoteUpdate` 브릿지 추가.
- `DoSurfApp/Domain/UseCase/MockFetchBeachDataUseCase.swift`
  - `MockBeachScenario` 도입 및 시나리오 기반 응답/에러/지연/stale 동작 추가.
- `DoSurfApp/App/AppEnvironment.swift`
  - mock scenario 파싱(`-MockBeachScenario`, `DOSURF_MOCK_BEACH_SCENARIO`) 추가.
- `DoSurfApp/App/DIContainer.swift`
  - 환경 기반 scenario 주입 및 mock/live usecase 조합 정리.

### 작업 트리 내 함께 존재하는 관련 변경(본 런에서 정합성 확인)
- `DoSurfApp/Domain/Service/ChartCacheManager.swift`
- `DoSurfApp/Domain/UseCase/CachedFetchBeachDataUseCase.swift`
- `DoSurfApp/Domain/Service/SurfingActivityManager.swift`
- `DoSurfApp/Domain/Service/SurfRecordSyncService.swift`
- `DoSurfApp/Presentation/Scenes/Dashboard/DashboardViewController.swift`
- `DoSurfApp/Core/Extensions/Notifications+.swift`
- 신규 파일 존재: `MockSurfRecordRepository.swift`, `DelayedFetchBeachDataUseCase.swift`, `MockFetchBeachListUseCase.swift`

## 검증 결과 (빌드/테스트/수동점검)

### 빌드
- `[측정]` `xcodebuild -project DoSurfApp.xcodeproj -scheme 'DoSurfApp' -configuration Debug -destination 'generic/platform=iOS Simulator' build`
  - 결과: `BUILD SUCCEEDED`
  - 경고 1건: `CLKComplicationSupportedFamilies` deprecated (watch extension target 경고 동반 빌드)
- `[측정]` `xcodebuild -project DoSurfApp.xcodeproj -scheme 'DoSurfWatch Watch App' -configuration Debug -destination 'generic/platform=watchOS Simulator' build`
  - 결과: `BUILD SUCCEEDED`
  - 경고 1건: `CLKComplicationSupportedFamilies` deprecated (기존 ClockKit 관련 경고)

### 테스트
- `[측정]` `xcodebuild ... -scheme 'DoSurfApp' ... test`
  - 결과: 실패(exit code 66)
  - 사유: `Scheme DoSurfApp is not currently configured for the test action.`
  - 해석: 테스트 타깃/테스트 액션 미구성 상태

### 수동 점검
- `[미실행]` 실제 디바이스에서 APNs 기반 Live Activity 원격 갱신, Watch 재시작 후 pending 복구 시나리오는 본 런에서 수행하지 않음.

## 남은 리스크 / 후속 과제

1. iPhone 수신 delegate completion이 비정상 경로에서 호출 누락되면 watch 전송 타임아웃이 발생할 수 있으므로, completion watchdog(타임아웃 보호) 추가 권장.
2. Live Activity 원격 업데이트는 앱 측 브릿지까지만 반영되어 있으며, 서버(APNs) 토큰 업로드/전송 파이프라인은 별도 구현 필요.
3. 시나리오 기반 mock은 현재 해변 차트 중심이며, SurfRecord mock 시드/시나리오(삭제 충돌/버전 충돌 등) 확장은 추가 여지 있음.
4. 자동 테스트가 스킴에 연결되어 있지 않아 회귀 검증 자동화가 불가. 최소 smoke UI test 또는 unit test target 연결 권장.
