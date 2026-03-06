# DoSurf iOS 프로젝트 - 주니어 개발자 포트폴리오용 핵심 구현 사례 선정

---

## 📋 1단계: 후보 리스트 (12개)

### 후보 1: 지역 전체 해변 병렬 조회 및 원형 평균 계산

**카테고리**: A (복잡한 데이터 처리), E (메모리 & 성능 관리)

**구현 위치**:
- `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift` (136-195줄)

**기획서 연결**:
- **문제**: 초보자 친화 - 복잡한 기상 데이터를 시각적으로 단순화
- **핵심 기능**: 통계 및 분석 - 지역 평균 카드 제공

**기술 스택**: RxSwift (flatMapConcurrent, combineLatest), Single.zip, 비동기 병렬 처리

**복잡도**: ⭐️⭐️⭐️⭐️⭐️ (5/5)
- 10개 해변 데이터를 동시 조회하여 성능 최적화
- 방향(degree) 데이터의 원형 평균 계산 (sin/cos 삼각함수)
- 이동평균 옵션 지원 (최근 N시간)
- 실시간 캐싱 및 지연 로딩(lazy trigger)

**어필도**: ⭐️⭐️⭐️⭐️⭐️ (5/5)

**한 줄 요약**: flatMapConcurrent로 지역 내 10개 해변을 병렬 조회하고, 원형 평균(circular mean)으로 바람/파도 방향의 평균을 계산하여 사용자에게 단순화된 지역 조건 제공

---

### 후보 2: Firestore 데이터 검증 및 해양 물리 공식 적용

**카테고리**: A (복잡한 데이터 처리), D (에러 핸들링)

**구현 위치**:
- `DoSurfApp/Domain/Repository/FirestoreRepository.swift` (92-163줄, 262-309줄)
- `DoSurfApp/Domain/DTO/FirestoreChartDTO.swift`

**기획서 연결**:
- **문제**: 한국 특화 - 기상청 API 데이터의 불완전성 (NaN, -900 같은 이상값)
- **핵심 기능**: 해양 예보 차트 - 파도/바람/수온 데이터 제공

**기술 스택**: Firestore, RxSwift (Single), Pierson-Moskowitz 해양 물리 공식

**복잡도**: ⭐️⭐️⭐️⭐️ (4/5)
- NaN, -900 같은 이상값 필터링
- Pierson-Moskowitz 공식으로 파도 주기 추정 (`Tp ≈ 0.83 * U10`)
- 날씨 코드 계산 (습도, 풍속, 강수 확률 기반)
- 2-18초 범위 정규화

**어필도**: ⭐️⭐️⭐️⭐️ (4/5)

**한 줄 요약**: 기상청 API의 불완전한 데이터를 검증하고, 해양 물리 공식(Pierson-Moskowitz)으로 누락된 파도 주기를 추정하여 신뢰성 있는 서핑 조건 제공

---

### 후보 3: Apple Watch 서핑 세션 자동 감지 및 멀티 센서 통합

**카테고리**: B (iOS 플랫폼 특화), E (메모리 & 성능), F (프로덕트 사고력)

**구현 위치**:
- `DoSurfWatch Watch App/SurfWorkoutManager.swift` (전체 615줄)

**기획서 연결**:
- **문제**: 멀티 디바이스 - Apple Watch 연동
- **핵심 기능**: Apple Watch 앱 - 거리/시간/심박/칼로리/스트로크 수 표시

**기술 스택**: HealthKit, CoreLocation, CoreMotion, CMAltimeter, Combine

**복잡도**: ⭐️⭐️⭐️⭐️⭐️ (5/5)
- **HealthKit**: HKWorkoutSession으로 surfingSports 타입 추적
- **CoreLocation**: GPS로 거리 및 속도 계산
- **CoreMotion**: 가속도(2G+)로 서핑 활동 자동 감지
- **CMAltimeter**: 고도 변화(1m+)로 파도 감지
- **자동 시작/종료**: 모션 패턴 분석으로 서핑 세션 자동 감지
- **메모리 최적화**: 최근 30초 데이터만 버퍼링 (10Hz 업데이트)

**어필도**: ⭐️⭐️⭐️⭐️⭐️ (5/5)

**한 줄 요약**: HealthKit, CoreLocation, CoreMotion, CMAltimeter를 통합하여 서핑 세션을 자동 감지하고, 고도 변화로 파도 횟수를 카운팅하는 멀티 센서 시스템

---

### 후보 4: Live Activity 및 Dynamic Island 통합

**카테고리**: B (iOS 플랫폼 특화), F (프로덕트 사고력)

**구현 위치**:
- `DoSurfApp/Domain/Service/SurfingActivityManager.swift` (전체 148줄)
- `DoSurfWidgetExtension/SurfingLiveActivity.swift`

**기획서 연결**:
- **문제**: 사용자 경험 - 서핑 중 앱을 닫아도 경과 시간 추적
- **핵심 기능**: Live Activity - 잠금화면/다이내믹 아일랜드에 경과 시간 표시

**기술 스택**: ActivityKit (iOS 16.2+), Timer, async/await

**복잡도**: ⭐️⭐️⭐️ (3/5)
- iOS 16.2+ Live Activity API 통합
- ActivityAuthorizationInfo로 권한 확인
- 1분마다 경과 시간 자동 업데이트
- Dynamic Island 및 잠금 화면 동시 지원

**어필도**: ⭐️⭐️⭐️⭐️ (4/5)

**한 줄 요약**: iOS 16.2 Live Activity로 서핑 세션의 경과 시간을 Dynamic Island와 잠금화면에 실시간 표시하여 앱을 닫아도 추적 가능

---

### 후보 5: WatchConnectivity 양방향 통신 및 동기 응답

**카테고리**: B (iOS 플랫폼 특화), D (에러 핸들링)

**구현 위치**:
- `DoSurfApp/Infra/iPhoneWatchConnectivity.swift` (전체 164줄)
- `DoSurfWatch Watch App/WatchConnectivityManager.swift`

**기획서 연결**:
- **문제**: 멀티 디바이스 - Watch 데이터를 iPhone으로 전송
- **핵심 기능**: WatchConnectivity로 iPhone에 데이터 전송 및 수신 확인 화면 제공

**기술 스택**: WatchConnectivity, async/await, replyHandler, Codable

**복잡도**: ⭐️⭐️⭐️⭐️ (4/5)
- replyHandler로 동기식 응답 (성공/실패 확인)
- TimeInterval → Date 변환 및 검증
- isReachable 체크 및 에러 처리
- async/await로 completion handler 변환 (`withCheckedThrowingContinuation`)

**어필도**: ⭐️⭐️⭐️⭐️ (4/5)

**한 줄 요약**: WatchConnectivity로 Watch 서핑 세션 데이터를 iPhone에 전송하고, replyHandler로 동기식 응답을 받아 전송 성공/실패를 사용자에게 피드백

---

### 후보 6: 다중 필터링 및 정렬의 3-way combineLatest

**카테고리**: A (복잡한 데이터 처리), C (아키텍처 설계)

**구현 위치**:
- `DoSurfApp/Presentation/ViewModel/RecordHistoryViewModel.swift` (238-285줄, 288-381줄)

**기획서 연결**:
- **문제**: 기록 정리의 번거로움 (중급 서퍼 페인포인트)
- **핵심 기능**: 기록 조회 및 필터 - 필터/정렬 옵션 제공

**기술 스택**: RxSwift (combineLatest, withLatestFrom), DateComponents

**복잡도**: ⭐️⭐️⭐️⭐️ (4/5)
- 3-way combineLatest (기록 + 필터 + 정렬)
- 5가지 필터 타입: 전체, 핀 고정, 날짜 프리셋, 날짜 범위, 별점
- 4가지 정렬: 최신/과거/평점 높은순/낮은순
- 날짜 범위 계산 (오늘, 최근 7일, 이번 달, 지난 달)
- Pin 토글 후 즉시 재조회

**어필도**: ⭐️⭐️⭐️⭐️ (4/5)

**한 줄 요약**: RxSwift combineLatest로 기록/필터/정렬 3개 스트림을 결합하여, 사용자가 조건을 변경할 때마다 실시간으로 필터링된 기록 리스트 제공

---

### 후보 7: 메모 자동 임시 저장 및 복원

**카테고리**: F (프로덕트 사고력), E (메모리 관리)

**구현 위치**:
- `DoSurfApp/Presentation/ViewModel/NoteViewModel.swift` (49-58줄, 146-156줄, 209-221줄, 274-286줄)

**기획서 연결**:
- **문제**: 앱이 종료되어도 작성 중인 메모 보존
- **핵심 기능**: 추가 편의 기능 - 메모 자동 임시 저장/복원

**기술 스택**: UserDefaults, RxSwift, Key-value 저장소

**복잡도**: ⭐️⭐️ (2/5)
- memoChanged 이벤트마다 자동 저장
- 모드별 키 분리 (`temp_memo_new`, `temp_memo_edit_{id}`)
- 저장 성공 시 임시 메모 삭제
- viewDidLoad 시 자동 복원

**어필도**: ⭐️⭐️⭐️ (3/5)

**한 줄 요약**: 사용자가 메모를 입력할 때마다 UserDefaults에 자동 저장하고, 앱 재시작 후에도 작성 중이던 내용을 복원하여 데이터 손실 방지

---

### 후보 8: Input-Output 패턴의 MVVM 아키텍처

**카테고리**: C (아키텍처 설계), A (데이터 처리)

**구현 위치**:
- `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift` (12-30줄, 70-262줄)
- 모든 ViewModel에 동일 패턴 적용

**기획서 연결**:
- **문제**: 유지보수 가능한 코드 구조
- **가치**: 테스트 가능한 아키텍처

**기술 스택**: RxSwift, MVVM, Protocol-Oriented Programming

**복잡도**: ⭐️⭐️⭐️ (3/5)
- Input struct로 ViewController 이벤트 정의
- Output struct로 ViewModel 데이터 스트림 제공
- transform(_ input) 메서드로 단방향 데이터 흐름
- 모든 ViewModel에 일관된 패턴 적용

**어필도**: ⭐️⭐️⭐️⭐️ (4/5)

**한 줄 요약**: Input-Output 패턴으로 ViewModel의 역할을 명확히 분리하여, 단방향 데이터 흐름과 테스트 가능성을 확보한 MVVM 아키텍처

---

### 후보 9: FirebaseAPIError 한글 메시지 및 재시도 로직

**카테고리**: D (에러 핸들링), F (프로덕트 사고력)

**구현 위치**:
- `DoSurfApp/Domain/Model/FirebaseAPIError.swift` (전체 99줄)

**기획서 연결**:
- **문제**: 사용자에게 친화적인 에러 메시지 제공
- **핵심 기능**: API 실패 시 한글 메시지 및 재시도 가능 여부 판단

**기술 스택**: Firestore, LocalizedError, Equatable

**복잡도**: ⭐️⭐️⭐️ (3/5)
- FirestoreErrorCode를 13가지 커스텀 에러로 매핑
- 한글 errorDescription 제공
- `isRetryable` 플래그로 재시도 가능 여부 판단
- Equatable 구현으로 에러 비교 가능

**어필도**: ⭐️⭐️⭐️ (3/5)

**한 줄 요약**: Firestore 에러를 13가지 커스텀 타입으로 매핑하고, 한글 메시지와 재시도 가능 여부를 제공하여 사용자 친화적인 에러 핸들링

---

### 후보 10: flatMapLatest로 불필요한 API 요청 자동 취소

**카테고리**: E (메모리 & 성능 관리), A (데이터 처리)

**구현 위치**:
- `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift` (82-102줄)
- `DoSurfApp/Presentation/ViewModel/RecordHistoryViewModel.swift` (114-143줄)

**기획서 연결**:
- **문제**: 사용자가 해변을 빠르게 변경할 때 불필요한 요청 방지
- **가치**: 네트워크 비용 절감 및 성능 최적화

**기술 스택**: RxSwift (flatMapLatest, debounce)

**복잡도**: ⭐️⭐️⭐️ (3/5)
- flatMapLatest로 새로운 요청 시 이전 요청 자동 취소
- debounce(120ms)로 빠른 연속 입력 스로틀링
- subscribe(on: bg)로 백그라운드 스레드 처리
- observe(on: MainScheduler)로 UI 업데이트

**어필도**: ⭐️⭐️⭐️⭐️ (4/5)

**한 줄 요약**: flatMapLatest와 debounce를 결합하여 사용자가 해변을 빠르게 변경할 때 이전 API 요청을 자동 취소하고, 최신 요청만 처리하여 성능 최적화

---

### 후보 11: 앱 재활성화 시 현재 시간대로 자동 포커싱

**카테고리**: F (프로덕트 사고력), E (성능 관리)

**구현 위치**:
- `DoSurfApp/Presentation/Scenes/Dashboard/DashboardViewController.swift` (188-194줄)
- `DoSurfApp/Presentation/Scenes/Dashboard/BeachChartListView.swift`

**기획서 연결**:
- **문제**: 사용자가 앱을 다시 열었을 때 과거 차트가 보이면 불편
- **핵심 기능**: 앱 재활성화 시 현재 시간대 근처로 자동 포커싱

**기술 스택**: NotificationCenter, UIApplication.didBecomeActiveNotification, UITableView

**복잡도**: ⭐️⭐️ (2/5)
- didBecomeActiveNotification 구독
- 현재 시간과 가장 가까운 차트 찾기
- UITableView scrollToRow로 자동 스크롤

**어필도**: ⭐️⭐️⭐️ (3/5)

**한 줄 요약**: 앱이 백그라운드에서 돌아올 때 NotificationCenter로 감지하여, 차트 리스트를 현재 시간대로 자동 스크롤하여 사용자 편의성 향상

---

### 후보 12: DIContainer로 의존성 주입 및 테스트 용이성

**카테고리**: C (아키텍처 설계)

**구현 위치**:
- `DoSurfApp/App/DIContainer.swift` (전체 123줄)

**기획서 연결**:
- **가치**: 테스트 가능한 코드 구조
- **목적**: Repository, UseCase, ViewModel의 의존성 관리

**기술 스택**: Singleton 패턴, Factory 패턴, Protocol-Oriented Programming

**복잡도**: ⭐️⭐️⭐️ (3/5)
- Singleton으로 앱 전체에서 공유
- Factory 메서드로 객체 생성
- Protocol 기반으로 테스트 시 Mock 주입 가능
- 전체 객체 생명 주기 관리

**어필도**: ⭐️⭐️⭐️ (3/5)

**한 줄 요약**: DIContainer 싱글톤으로 모든 Repository, UseCase, ViewModel의 생성을 중앙 관리하여, 테스트 시 Mock 객체 주입이 가능한 구조

---

## ✅ 후보 리스트 요약 테이블

| 번호 | 제목 | 카테고리 | 복잡도 | 어필도 | 핵심 키워드 |
|------|------|---------|--------|--------|------------|
| 1 | 지역 전체 해변 병렬 조회 및 원형 평균 | A, E | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ | flatMapConcurrent, 원형 평균, 병렬 처리 |
| 2 | Firestore 데이터 검증 및 해양 물리 공식 | A, D | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | Pierson-Moskowitz, NaN 필터링 |
| 3 | Apple Watch 서핑 세션 자동 감지 | B, E, F | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ | HealthKit, CoreMotion, 멀티 센서 |
| 4 | Live Activity 및 Dynamic Island | B, F | ⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | iOS 16.2, ActivityKit |
| 5 | WatchConnectivity 양방향 통신 | B, D | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | replyHandler, async/await |
| 6 | 다중 필터링 및 정렬 | A, C | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | combineLatest, 복합 조건 |
| 7 | 메모 자동 임시 저장 | F, E | ⭐️⭐️ | ⭐️⭐️⭐️ | UserDefaults, 데이터 손실 방지 |
| 8 | Input-Output MVVM 패턴 | C, A | ⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | 아키텍처, 단방향 데이터 흐름 |
| 9 | FirebaseAPIError 에러 핸들링 | D, F | ⭐️⭐️⭐️ | ⭐️⭐️⭐️ | 한글 메시지, 재시도 로직 |
| 10 | flatMapLatest 요청 자동 취소 | E, A | ⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | 성능 최적화, debounce |
| 11 | 앱 재활성화 자동 포커싱 | F, E | ⭐️⭐️ | ⭐️⭐️⭐️ | UX 개선, NotificationCenter |
| 12 | DIContainer 의존성 주입 | C | ⭐️⭐️⭐️ | ⭐️⭐️⭐️ | Factory 패턴, 테스트 용이성 |

---

## 📝 다음 단계

위 12개 후보 중에서 다음 기준으로 **최종 6개**를 선정:

### 선정 기준
1. **카테고리 분산**: A~F를 골고루 커버
2. **스토리텔링**: 면접에서 5분 안에 설명 가능한 것
3. **차별화**: AI 코딩으로 안 나오는, 생각이 필요한 것
4. **기획 연결**: 프로젝트의 핵심 가치와 강하게 연결

### 카테고리별 분포 (현재 후보)
- **A (복잡한 데이터 처리)**: 1, 2, 6, 8, 10
- **B (iOS 플랫폼 특화)**: 3, 4, 5
- **C (아키텍처 설계)**: 6, 8, 12
- **D (에러 핸들링)**: 2, 5, 9
- **E (메모리 & 성능)**: 1, 3, 7, 10, 11
- **F (프로덕트 사고력)**: 3, 4, 7, 9, 11
