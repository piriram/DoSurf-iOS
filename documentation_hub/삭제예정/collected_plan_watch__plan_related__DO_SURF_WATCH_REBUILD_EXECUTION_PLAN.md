# 두섭이 WatchOS 재구현 실행 계획 (v1.1)

## 1. 수집한 기획/요구사항 원본
- `DoSurf-iOS/portfolio.md`
- `DoSurf-iOS/PRODUCT_SPECIFICATION_FINAL.md`
- `DoSurf-iOS/portfolio_doseub_core_implementations.md`
- `DoSurf-iOS/collected_plan_watch/plan_related/IMPLEMENTATION_REPORT.md`
- `DoSurf-iOS/collected_plan_watch/watch_related/PRODUCT_SPECIFICATION_FINAL.md`
- 기존 Watch 시나리오/샘플: `DoSurf-iOS/DoSurfWatch Watch App`

## 2. 핵심 연동 요구사항 (기획 ↔ WatchOS)
1. 기획 `Apple Watch 앱` 항목에서 세션 시작/종료와 지표(거리·시간·심박·칼로리·스트로크) 수집/표시가 필요.
2. `다국가 멀티 디바이스(Apple Watch)` 요구: 세션 완료 후 iPhone 동기화 및 수신 확인 화면 필요.
3. `Live Activity` 요구: 세션 시작/중간/종료 상태를 iPhone 잠금화면/알림군에 반영.
4. `서핑 기록 관리` 요구: 기록이 누락/중복/덮어쓰기 없이 정확히 한 건으로 반영되어야 함.

## 3. 핵심 구현 4개(필수)
- 1) Watch 세션 수집 코어
  - 상태 전이: `started → inProgress → completed/deleted`
  - 수집 데이터: `distanceMeters`, `durationSeconds`, `waveCount`, `heartRate`, `activeCalories`, `strokeCount`
  - 지표 산출 타임라인: 시작 시점/경과시간/세션 종료시간
- 2) WatchConnectivity 동기화 파이프라인
  - 세션 payload 배치 전송 (`payloads`)
  - 큐잉 + 재시도(backoff) + reachability 복구
  - reachability/activation 상태 UI 반영
- 3) 동기화 병합 정책
  - 스키마/버전 관리: `schemaVersion`, `payloadVersion`
  - 충돌 해결: `lastModifiedAt` 비교, 동률 시 `deviceId` tie-break, `isDeleted` 우선 반영
  - 멱등성: 동일 payload 중복 저장 방지
- 4) Live Activity 연동
  - 시작 시 시작, 진행 업데이트, 완료/삭제 시 종료 처리
  - iPhone이 화면 외부 상태에서도 세션 상태 확인 가능

## 4. Watch MVP (최소 실행 단위)
- Watch: 시작/종료 1회 플로우 완성
- Watch: 종료 시 자동 iPhone 전송
- iPhone: 배치 수신 + 파싱 + 로컬 저장
- 연결 불량 시 Watch측 pending 큐 보관 후 자동 복구
- 동기화 성공/실패 상태 가시화

## 5. Rebuild Scope (삭제 후 재구현)
### 삭제
- 기존 Watch session 수집/전송 코드 전부 교체
  - `DoSurfWatch Watch App/SurfWorkoutManager.swift`
  - `DoSurfWatch Watch App/WatchConnectivityManager.swift`
  - `DoSurfWatch Watch App/WatchDataStructures.swift`
  - `DoSurfWatch Watch App/MainWatchView.swift`
- 기존 iPhone 수신/병합 파이프라인 교체
  - `DoSurfApp/Infra/iPhoneWatchConnectivity.swift`
  - `DoSurfApp/Infra/WatchDataSyncCoordinator.swift`
  - `DoSurfApp/Domain/Service/SurfRecordSyncService.swift`
  - `DoSurfApp/Infra/SurfDataReceiverViewController.swift`

### 재구현 포인트
- 단일 payload 스키마 정의 → 배치 수신/파싱 동시 지원
- 연결 상태별 송수신 플로우 테스트 (실시간/비접속/복구)
- 완전 종료 시점(`completed`)에서만 영속 저장 보장
- 시작/진행 payload는 Live Activity 갱신 중심으로 처리

## 6. 수용 기준
- iPhone 연결이 끊겨도 Watch 보류 큐가 100% 보존
- 시작/종료 시 iPhone 레코드 1건 반영
- 동일 세션 중복 수신 시 중복 저장 0건
- 삭제 플래그 수신 시 해당 레코드 정상 삭제 반영
- `sessionId + lastModifiedAt` 기준 중복 억제 로그 확인

## 7. 다음 반영 우선순위
1. 빌드 전 `iPhoneWatchConnectivity` key 매핑 점검
2. `SurfRecordSyncService` 병합 경로별 단위 검증 (started/inProgress/completed/deleted)
3. WatchUI에서 전송 실패/보류 상태 가시성 보강
4. 연결 불안정 환경에서 재시도 횟수/간격 조절
