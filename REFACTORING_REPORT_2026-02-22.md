# DoSurf-iOS 리팩토링 검토 보고서

작성일: 2026-02-22 (KST)
검토 브랜치: `성능최적화` (main 기반)

## 1) 검토 범위/방법

- 정적 코드 리뷰(실행/런타임 테스트 제외)
- 코드베이스 규모
  - Swift 파일: **109개**
  - 총 코드 라인: **14,031 LOC**
  - `print(` 사용: **105회**
  - `NotificationCenter.default` 사용: **10회**
  - `UserDefaults.standard` 직접 사용: **11회**
- Hotspot(파일 크기 상위)
  - `SurfWorkoutManager.swift` 615줄
  - `ButtonTabBarController.swift` 431줄
  - `NoteViewModel.swift` 412줄
  - `RecordHistoryViewModel.swift` 391줄
  - `DashboardViewModel.swift` 342줄

---

## 2) 핵심 결론 (우선순위)

### P0 (즉시 정리 권장: 기능 안정성)

1. **Watch ↔ iPhone 메시지 포맷 불일치 위험**
2. **Rx 구독 누수/수명관리 누락 (`disposed(by:)` 누락 1건)**

### P1 (단기 리팩토링 권장: 유지보수/성능)

3. **`SurfWorkoutManager` 단일 클래스 과대 책임(센서/운동세션/통계/전송 혼재)**
4. **`DashboardViewModel` 과대 `transform` + 중복 매핑 로직 + 사용되지 않는 상태/함수**
5. **`SurfRecordRepository` 문자열 기반 CoreData 접근 + 스키마 호환 임시 로직 누적**
6. **ViewModel 계층의 저장소/알림 직접 접근(UserDefaults/NotificationCenter) 결합도 높음**

### P2 (중기 정리 권장: 코드 건강도)

7. **Watch 연결 계층 중복(`WatchSessionManager` vs `iPhoneWatchConnectivity`) 및 디버그 화면 잔재**
8. **로깅/디버그 코드 과다 및 파일/네이밍 정리 필요**
9. **테스트 타깃 부재(리팩토링 안전망 부족)**

---

## 3) 상세 항목

## 3-1. Watch ↔ iPhone 메시지 포맷 불일치 (P0)

### 관찰
- Watch 전송 payload는 `distance`, `duration`, `waveCount`, `maxSpeed` 등 요약 필드 위주
  - 근거: `DoSurfWatch Watch App/SurfWorkoutManager.swift:430-440`
- iPhone 파싱은 `startTime`, `endTime` 필드를 필수로 요구
  - 근거: `DoSurfApp/Infra/iPhoneWatchConnectivity.swift:131-135`

### 위험
- 런타임에서 메시지 파싱 실패 가능성 큼(데이터 수신 실패/무응답)

### 권장 리팩토링
- 단일 DTO/스키마 정의(`SurfSessionSummaryDTO`)를 양쪽 타깃에서 공유
- 버전 필드(`schemaVersion`) 추가
- 필수/옵셔널 필드 분리 및 하위호환 파서 적용

---

## 3-2. Rx 구독 수명관리 누락 (P0)

### 관찰
- `recordButtonTapped` 바인딩에 `.disposed(by: disposeBag)` 누락
  - 근거: `DoSurfApp/Presentation/ViewModel/ButtonTabBarViewModel.swift:49-52`
- 반면 `chartButtonTapped`는 정상 dispose 처리
  - 근거: `...ButtonTabBarViewModel.swift:43-47`

### 위험
- 구독 수명 예측 어려움, 재바인딩 시 부작용/누수 가능성

### 권장 리팩토링
- 모든 `bind/subscribe` 체인에 dispose 일관 적용
- RxLint(또는 스크립트)로 누락 검사 자동화

---

## 3-3. `SurfWorkoutManager` 과대 책임 (P1)

### 관찰
- 한 클래스에서 아래를 모두 처리
  - HealthKit workout/session
  - 위치/고도/모션 센서
  - 파도/패들링/속도 계산
  - 시뮬레이터 데이터 생성
  - iPhone 메시지 전송
- 근거: `DoSurfWatch Watch App/SurfWorkoutManager.swift:8-607`

### 위험
- 변경 영향 범위가 넓어 회귀 발생 가능성 증가
- 테스트 작성/디버깅 난이도 상승

### 권장 리팩토링
- 모듈 분리
  1. `WorkoutSessionService` (HK 세션)
  2. `MotionAnalyzer` (파도/패들링/속도 계산)
  3. `WatchSyncService` (iPhone 전송)
  4. `SimulatorMetricsProvider` (시뮬레이터 전용)
- 상태는 `SurfWorkoutState` 단일 모델로 집약

---

## 3-4. `DashboardViewModel` 구조 단순화 필요 (P1)

### 관찰
- `transform` 내 비즈니스 로직/병렬 fetch/매핑/로그가 과밀
  - 근거: `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift:70-261`
- `recentRecordCharts`와 `pinnedCharts`에서 Chart 매핑 로직 중복
  - 근거: `...DashboardViewModel.swift:206-246`
- 사용되지 않는 상태/함수 존재
  - `knownBeaches` 선언만 존재: `45-56`
  - `avgCardsCacheByRegion` 저장만 하고 조회 없음: `37`, `187-191`
  - `fetchBeachDataDirectly` 미사용: `274-275`

### 위험
- 기능 추가 시 사이드이펙트 증가
- 성능 최적화 지점 추적 어려움

### 권장 리팩토링
- `DashboardCardsBuilder`, `RecordChartMapper` 유틸로 추출
- 미사용 상태/함수 제거
- `Output`을 기능별 파이프라인으로 분리

---

## 3-5. `SurfRecordRepository` 문자열 기반 CoreData 접근 (P1)

### 관찰
- `setValue(_:forKey:)`, `value(forKey:)` 중심 구현
  - 근거: `DoSurfApp/Domain/Repository/SurfRecordRepository.swift:41-69`, `297-330`
- `beachId`/`beachID` 동시 대응 임시 로직 누적
  - 근거: `...SurfRecordRepository.swift:281-293`
- 강제 캐스팅 1건
  - `as! NSManagedObject`: `239`

### 위험
- 런타임 오류 탐지 지연(컴파일 타임 안전성 낮음)
- 스키마 변경 시 영향 추적 어려움

### 권장 리팩토링
- NSManagedObject 서브클래스 기반 타입 안전 매핑으로 전환
- 마이그레이션 정책 명시(필드명 통일: `beachID` 등)
- 매퍼(`SurfRecordMapper`) 분리

---

## 3-6. ViewModel의 인프라 결합도 개선 (P1)

### 관찰
- `NoteViewModel`이 `UserDefaults`와 `NotificationCenter`를 직접 호출
  - 근거: `DoSurfApp/Presentation/ViewModel/NoteViewModel.swift:147,155,216-219,276-279`
- `RecordHistoryViewModel`도 Notification 기반 상태 동기화 의존
  - 근거: `...RecordHistoryViewModel.swift:98-110,227`

### 위험
- 테스트 어려움(모킹 포인트 부족)
- 화면 간 결합도 증가

### 권장 리팩토링
- `DraftMemoStore`, `RecordChangeNotifier` 프로토콜 도입
- ViewModel은 프로토콜 의존으로 전환

---

## 3-7. Watch 연결 계층 중복/디버그 잔재 (P2)

### 관찰
- `WatchSessionManager`가 사실상 미사용
  - 사용처 없음: `DoSurfApp/Infra/WatchConnectivity.swift`
- 별도 구현인 `iPhoneWatchConnectivity`와 역할 중복
  - `DoSurfApp/Infra/iPhoneWatchConnectivity.swift`
- `SurfDataReceiverViewController`는 디버그 성격 강하고 SceneDelegate에 주석 잔재
  - `DoSurfApp/App/SceneDelegate.swift:14`

### 권장 리팩토링
- Watch 통신 엔트리포인트 단일화
- 디버그 화면은 DEBUG 플래그/별도 타깃으로 격리

---

## 3-8. 로깅/디버그 코드 정리 (P2)

### 관찰
- `print(` 사용 105회(핵심 로직에도 혼재)
- 상위: `SurfWorkoutManager`(23), `SurfingActivityManager`(21), `iPhoneWatchConnectivity`(15)

### 권장 리팩토링
- `Logger`(os.log) 래퍼 도입
- 로그 레벨 분리(debug/info/error)
- 릴리즈 빌드 최소 로그 정책

---

## 3-9. 테스트 안전망 부재 (P2)

### 관찰
- 테스트 타깃/디렉토리 흔적 확인되지 않음

### 권장 리팩토링
- 최소 우선 테스트
  1. `NoteViewModel.filterCharts`
  2. `DashboardViewModel` 카드 계산
  3. Watch payload parser
  4. SurfRecordMapper(CoreData ↔ Domain)

---

## 4) 추천 실행 순서 (2스프린트)

### Sprint 1 (안정화)
1. Watch payload 스키마 통일(P0)
2. Rx dispose 누락 수정(P0)
3. Dashboard/Note의 직접 의존(UserDefaults/NotificationCenter) 인터페이스화(P1 일부)

### Sprint 2 (구조 개선)
4. SurfWorkoutManager 분리(P1)
5. SurfRecordRepository 타입 안전화 + 마이그레이션 정리(P1)
6. 중복/미사용 코드 제거 + 로깅 체계화(P2)
7. 핵심 유닛테스트 추가(P2)

---

## 5) 기대 효과

- **결함 감소**: 메시지 포맷 불일치/구독 수명 문제 제거
- **개발 속도 개선**: ViewModel/Repository 복잡도 완화
- **회귀 위험 감소**: 테스트 가능한 경계(프로토콜/매퍼/DTO) 확보
- **운영 안정성 향상**: 로그 체계화 및 CoreData 접근 안전성 강화

---

## 6) 한 줄 요약

지금 당장 중요한 건 **(1) Watch 메시지 스키마 통일**과 **(2) Rx dispose 누락 수정**이고,
그 다음으로 **SurfWorkoutManager 분해 + Repository 타입 안전화**를 진행하면 리팩토링 효율이 가장 높습니다.
