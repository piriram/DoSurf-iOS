**후보 리스트 (12개)**

## 후보 1: 해양 예보 데이터 정제 파이프라인  
**카테고리**: A, D, F  
**구현 위치**: `DoSurfApp/Domain/Repository/FirestoreRepository.swift`, `DoSurfApp/Domain/UseCase/FetchBeachDataUseCase.swift`, `DoSurfApp/Domain/Model/FirebaseAPIError.swift`  
**기획서 연결**: 한국 해변 예보를 초보자 친화적으로 단순화  
**기술 스택**: RxSwift, Firestore  
**복잡도**: ⭐️⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️  
**한 줄 요약**: 원천 데이터 결측/이상치를 정제해 신뢰 가능한 차트 입력으로 변환  

## 후보 2: 지역 평균 카드 동시 수집/계산  
**카테고리**: A, C, E, F  
**구현 위치**: `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift`  
**기획서 연결**: 초보자에게 지역 평균 정보로 이해 쉬운 요약 제공  
**기술 스택**: RxSwift, MVVM  
**복잡도**: ⭐️⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️⭐️  
**한 줄 요약**: 다수 해변 데이터를 병렬 집계해 지역 평균 카드를 만든다  

## 후보 3: 앱 재활성화 시 현재 시간대 자동 포커싱  
**카테고리**: F, D  
**구현 위치**: `DoSurfApp/Presentation/Scenes/Dashboard/DashboardViewController.swift`  
**기획서 연결**: “현재 시간대 근처 자동 포커싱” 요구사항  
**기술 스택**: RxSwift, UIKit  
**복잡도**: ⭐️⭐️  
**어필도**: ⭐️⭐️⭐️  
**한 줄 요약**: 재진입 UX를 개선해 초보자도 바로 현재 예보를 확인  

## 후보 4: 메모 자동 임시 저장 + KST 3시간 슬롯 필터  
**카테고리**: A, F, C  
**구현 위치**: `DoSurfApp/Presentation/ViewModel/NoteViewModel.swift`  
**기획서 연결**: 메모 자동 저장/복원, 기록 스냅샷 저장  
**기술 스택**: RxSwift, MVVM, UserDefaults  
**복잡도**: ⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️  
**한 줄 요약**: 기록 입력 중 이탈에도 복원되고, 시간대 스냅샷을 정확히 맞춘다  

## 후보 5: 서핑 상태 지속 + Live Activity 재개  
**카테고리**: B, F, D  
**구현 위치**: `DoSurfApp/Presentation/ViewModel/ButtonTabBarViewModel.swift`, `DoSurfApp/Infra/UserDefaultsManager.swift`, `DoSurfApp/Domain/Service/SurfingActivityManager.swift`  
**기획서 연결**: 멀티 디바이스/라이브 액티비티, 서핑 중 상태 복원  
**기술 스택**: ActivityKit, RxSwift  
**복잡도**: ⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️  
**한 줄 요약**: 앱 재시작 후에도 서핑 세션과 Live Activity를 이어간다  

## 후보 6: Live Activity 타이머 기반 상태 업데이트  
**카테고리**: B, E  
**구현 위치**: `DoSurfApp/Domain/Service/SurfingActivityManager.swift`  
**기획서 연결**: 잠금화면/다이내믹 아일랜드 경과시간 표시  
**기술 스택**: ActivityKit, Timer  
**복잡도**: ⭐️⭐️  
**어필도**: ⭐️⭐️⭐️  
**한 줄 요약**: 1분 단위 업데이트로 서핑 경과시간을 실시간 제공  

## 후보 7: Watch Workout 자동 감지 + 다중 센서 지표  
**카테고리**: B, E, F  
**구현 위치**: `DoSurfWatch Watch App/SurfWorkoutManager.swift`  
**기획서 연결**: Apple Watch 세션 시작/종료, 거리/심박/칼로리  
**기술 스택**: HealthKit, CoreMotion, CoreLocation  
**복잡도**: ⭐️⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️  
**한 줄 요약**: 자동 감지 로직으로 워치의 서핑 트래킹 신뢰도를 높인다  

## 후보 8: iPhone ↔ Watch 데이터 전송 파이프라인  
**카테고리**: B, D, F  
**구현 위치**: `DoSurfWatch Watch App/WatchConnectivityManager.swift`, `DoSurfApp/Infra/iPhoneWatchConnectivity.swift`, `DoSurfApp/Infra/SurfDataReceiverViewController.swift`  
**기획서 연결**: 멀티 디바이스 경험, 데이터 전송 확인 화면  
**기술 스택**: WatchConnectivity  
**복잡도**: ⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️  
**한 줄 요약**: 워치 세션 요약을 iPhone으로 전달하고 수신 UX까지 완성  

## 후보 9: 기록 필터/정렬/핀 토글 + Rx 동기화  
**카테고리**: C, A, F, D  
**구현 위치**: `DoSurfApp/Presentation/ViewModel/RecordHistoryViewModel.swift`  
**기획서 연결**: 기록 조회/필터/정렬, 핀 고정  
**기술 스택**: RxSwift, CoreData, MVVM  
**복잡도**: ⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️  
**한 줄 요약**: 필터/정렬/핀 토글을 하나의 반응형 스트림으로 관리  

## 후보 10: 차트 셀 렌더링 캐시 최적화  
**카테고리**: E  
**구현 위치**: `DoSurfApp/Presentation/Scenes/Dashboard/ChartTableViewCell.swift`  
**기획서 연결**: 해양 예보 차트 리스트의 스크롤 성능  
**기술 스택**: UIKit, SnapKit  
**복잡도**: ⭐️⭐️  
**어필도**: ⭐️⭐️⭐️  
**한 줄 요약**: 동일 아이콘/회전 재적용을 줄여 스크롤 성능을 개선  

## 후보 11: 레거시 날씨 포맷 호환 처리  
**카테고리**: D, F  
**구현 위치**: `DoSurfApp/Presentation/ViewModel/RecordCardViewModel.swift`  
**기획서 연결**: 기록 스냅샷 정확도 유지  
**기술 스택**: CoreData  
**복잡도**: ⭐️⭐️  
**어필도**: ⭐️⭐️⭐️  
**한 줄 요약**: 저장 포맷 변경에도 기존 기록을 깨지지 않게 복원  

## 후보 12: 운영 장애 대응용 목업 전환 경로  
**카테고리**: D, F  
**구현 위치**: `DoSurfApp/Domain/Model/FirebaseAPIError.swift`, `DoSurfApp/Infra/SurfTest.swift`  
**기획서 연결**: 운영 장애 시 사용자 경험 유지  
**기술 스택**: UIKit  
**복잡도**: ⭐️⭐️⭐️  
**어필도**: ⭐️⭐️⭐️⭐️  
**한 줄 요약**: 장애 분류/메시지화와 목업 화면을 통해 서비스 지속성을 확보  

---

**최종 6개 선정**

1. 지역평균 카드  
구현 위치 `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift`  
기획서 연결  
* 초보자가 복잡한 해양 데이터를 한눈에 이해해야 한다는 문제를 해결  
* “초보자 친화”와 “한국 특화(지역 평균)” 가치와 직접 연결  
기술적 도전  
* 동일 지역 여러 해변(최대 10개 내외)을 동시에 조회하고 7일치 예보를 집계해야 했다  
* 단순 평균은 풍향/파향 같은 원형 데이터에서 왜곡이 발생  
* 응답 지연이 2~3초 이상 발생할 수 있어 UI 블로킹 위험이 있었다  
해결 접근  
* RxSwift `flatMapConcurrent`로 병렬 요청하고 `cardsLazyTrigger`로 지연 로딩  
* 평균 방향은 벡터 합(코사인/사인) 기반으로 계산해 왜곡 방지  
* 결과 캐시(`avgCardsCacheByRegion`)로 재진입 시 불필요한 재계산 방지  
차별화 포인트  
* 단순 API 호출이 아닌 “집계 로직 설계 + 방향 평균”까지 완성  
* A(데이터 처리)·C(아키텍처)·E(성능) 복합 역량 증명  
* AI 생성 코드로 잘 나오지 않는 “원형 데이터 평균” 판단이 핵심  
성과/학습  
* 정량 지표는 미집계, 체감 로딩 지연과 스크롤 끊김이 감소  
* 병렬 처리와 UI 지연 로딩의 균형을 학습  
* 다음엔 캐시 만료 정책과 지표 측정을 추가하고 싶다  
카테고리: A/C/E/F  
복잡도: ⭐️⭐️⭐️⭐️  
주니어 어필도: ⭐️⭐️⭐️⭐️⭐️  
면접 예상 질문 3개  
1. "이 기능을 구현하면서 가장 어려웠던 점은?"  
2. "왜 이 방식을 선택했나요?"  
3. "다시 구현한다면 어떻게 개선하겠습니까?"  

2. 예보정제  
구현 위치 `DoSurfApp/Domain/Repository/FirestoreRepository.swift`, `DoSurfApp/Domain/Model/FirebaseAPIError.swift`, `DoSurfApp/Infra/SurfTest.swift`  
기획서 연결  
* 한국 해변 예보의 신뢰도를 높여 초보자도 쉽게 판단하도록 한다  
* “한국 서퍼를 위한 데이터”와 “초보자 친화” 가치에 직접 연결  
기술적 도전  
* 원천 데이터에 -900 같은 이상치와 결측이 섞여 있어 그대로 노출하면 오판 위험  
* 날씨/파주기 정보가 없을 때도 의미 있는 값으로 보정해야 했다  
* 실제 운영에서는 화재/장애처럼 API가 `unavailable` 상태가 되는 경우가 있었다  
해결 접근  
* Firestore 응답을 DTO로 파싱 후 `computeWeatherCode`/`estimateWavePeriod`로 보정  
* 유효하지 않은 차트는 필터링해 초보자에게 “이상치”가 보이지 않게 처리  
* FirebaseAPIError로 장애 유형을 구분하고, 목업 전환 경로(`SurfTest`)를 준비  
차별화 포인트  
* 데이터 정제/보정은 도메인 이해 없이는 설계가 어렵다  
* A(데이터 처리)·D(에러 대응)·F(운영 경험) 역량을 동시에 보여줌  
* 운영 이슈까지 고려한 사고 과정이 AI 코드와 차별화  
성과/학습  
* 정량 지표는 미집계, 오표시/이상치 노출 리스크 감소  
* 에러를 “사용자 메시지+전환 시나리오”로 연결하는 법을 학습  
* 다음엔 캐시 기반 오프라인 fallback을 붙이고 싶다  
카테고리: A/D/F  
복잡도: ⭐️⭐️⭐️⭐️  
주니어 어필도: ⭐️⭐️⭐️⭐️  
면접 예상 질문 3개  
1. "이 기능을 구현하면서 가장 어려웠던 점은?"  
2. "왜 이 방식을 선택했나요?"  
3. "다시 구현한다면 어떻게 개선하겠습니까?"  

3. 서핑상태 복원  
구현 위치 `DoSurfApp/Presentation/ViewModel/ButtonTabBarViewModel.swift`, `DoSurfApp/Infra/UserDefaultsManager.swift`, `DoSurfApp/Domain/Service/SurfingActivityManager.swift`  
기획서 연결  
* “서핑 중 상태 지속”과 “Live Activity 자동 시작/종료” 요구사항 해결  
* 멀티 디바이스 경험(잠금화면/다이내믹 아일랜드)과 연결  
기술적 도전  
* 앱 재시작/백그라운드 복귀 시 서핑 상태가 끊기면 UX가 크게 저하됨  
* Live Activity 권한 비활성화/시뮬레이터 환경 등 예외가 많았다  
* 시작/종료 시간의 정확성을 유지해야 기록 신뢰도가 확보된다  
해결 접근  
* UserDefaults에 서핑 상태/시작시간을 저장하고 초기 로드 시 복원  
* iOS 16.2+에서 Live Activity를 재시작하며, 실패 시 안내 로그 처리  
* 종료/취소 분기별로 상태를 명확히 정리해 데이터 일관성 유지  
차별화 포인트  
* 상태 복원은 실사용 시점에서 효과가 큰 UX 개선  
* B(플랫폼)·F(프로덕트)·D(예외 처리) 역량을 동시에 보여줌  
* 단순 ActivityKit 연결을 넘어 “상태 복원”까지 포함  
성과/학습  
* 정량 지표는 미집계, 세션 이탈 시 사용자 불만 리스크 감소  
* 상태 복원은 작은 기능처럼 보여도 핵심 신뢰를 만든다는 걸 학습  
* 다음에는 앱 종료 시점에도 자동 종료 정책을 고민하고 싶다  
카테고리: B/D/F  
복잡도: ⭐️⭐️⭐️  
주니어 어필도: ⭐️⭐️⭐️⭐️  
면접 예상 질문 3개  
1. "이 기능을 구현하면서 가장 어려웠던 점은?"  
2. "왜 이 방식을 선택했나요?"  
3. "다시 구현한다면 어떻게 개선하겠습니까?"  

4. 워치세션 파이프  
구현 위치 `DoSurfWatch Watch App/SurfWorkoutManager.swift`, `DoSurfWatch Watch App/WatchConnectivityManager.swift`, `DoSurfApp/Infra/iPhoneWatchConnectivity.swift`  
기획서 연결  
* Apple Watch 앱의 서핑 세션 측정과 iPhone 연동  
* “멀티 디바이스” 핵심 가치와 직접 연결  
기술적 도전  
* 10Hz 모션/고도 데이터를 실시간 처리하면서 배터리/성능을 고려해야 했다  
* 서핑 시작/종료를 자동 감지하려면 잡음이 많은 센서 데이터를 해석해야 했다  
* 워치↔폰 전송 시 연결 불가/파싱 실패 같은 예외가 발생할 수 있다  
해결 접근  
* HealthKit/Location/Motion을 결합해 거리·심박·파도 카운트를 계산  
* 고도 변화 1m+, 5초 쿨다운 같은 규칙으로 파도 감지 로직을 구성  
* WatchConnectivity에서 파싱/응답을 분리해 실패 시 사용자 피드백 가능  
차별화 포인트  
* 단순 운동 기록이 아니라 “서핑에 맞는 자동 감지”를 직접 설계  
* B(플랫폼 특화)·E(성능)·F(제품 사고) 역량을 증명  
* 센서 융합과 예외 대응은 AI 코드로 나오기 어려운 부분  
성과/학습  
* 정량 지표는 미집계, 워치 단독 사용 시나리오의 완성도 향상  
* 센서 노이즈를 다룰 때 “완벽한 정확도”보다 “실사용 안정성”이 중요함을 학습  
* 다음에는 백그라운드 전송 및 배터리 최적화를 추가하고 싶다  
카테고리: B/E/F/D  
복잡도: ⭐️⭐️⭐️⭐️  
주니어 어필도: ⭐️⭐️⭐️⭐️  
면접 예상 질문 3개  
1. "이 기능을 구현하면서 가장 어려웠던 점은?"  
2. "왜 이 방식을 선택했나요?"  
3. "다시 구현한다면 어떻게 개선하겠습니까?"  

5. 메모자동 저장  
구현 위치 `DoSurfApp/Presentation/ViewModel/NoteViewModel.swift`  
기획서 연결  
* 메모 자동 임시 저장/복원, 차트 스냅샷 저장  
* “초보자 친화”와 “개인화 기록” 가치에 연결  
기술적 도전  
* 기록 작성 중 이탈/앱 종료가 잦아 메모 손실 위험이 컸다  
* 서핑 시간대에 맞는 차트 스냅샷을 정확히 골라야 했다  
* 사용자 입력 스트림이 복잡해 저장 타이밍을 잘못 잡으면 UX가 깨진다  
해결 접근  
* RxSwift로 메모 변경 스트림을 바로 UserDefaults에 임시 저장  
* KST 기준 3시간 슬롯 정렬로 차트 필터링 정확도 확보  
* 저장 성공 시 임시 키를 삭제해 중복 복원 문제를 제거  
차별화 포인트  
* 단순 CRUD가 아니라 “사용자 이탈 시 복원”까지 고려한 설계  
* A(데이터 처리)·F(프로덕트 사고)·C(MVVM) 역량 강조  
* 초보자에게 가장 치명적인 “작성 중 손실”을 예방  
성과/학습  
* 정량 지표는 미집계, 메모 손실 리스크가 체감 감소  
* 시간대 데이터 매칭에서 시간대/로케일 고려가 중요함을 학습  
* 다음엔 백그라운드 저장 타이밍을 더 정교하게 잡고 싶다  
카테고리: A/C/F  
복잡도: ⭐️⭐️⭐️  
주니어 어필도: ⭐️⭐️⭐️⭐️  
면접 예상 질문 3개  
1. "이 기능을 구현하면서 가장 어려웠던 점은?"  
2. "왜 이 방식을 선택했나요?"  
3. "다시 구현한다면 어떻게 개선하겠습니까?"  

6. 기록필터 엔진  
구현 위치 `DoSurfApp/Presentation/ViewModel/RecordHistoryViewModel.swift`  
기획서 연결  
* 기록 리스트의 필터/정렬/핀 고정 기능  
* “개인화 기록” 가치와 연결  
기술적 도전  
* 여러 필터/정렬 조합이 동시에 바뀌면 상태가 쉽게 꼬인다  
* CoreData에서 가져온 데이터와 UI 상태를 안정적으로 동기화해야 했다  
* 삭제/핀 토글 시 즉시 UI 반영이 필요했다  
해결 접근  
* RxSwift로 `records + filter + sort`를 결합한 단일 스트림 구성  
* NotificationCenter와 연동해 타 뷰의 변경을 즉시 반영  
* 핀 토글은 업데이트 후 재조회해 데이터 일관성을 유지  
차별화 포인트  
* 복잡한 상태를 한 스트림으로 정리해 안정적 UX를 제공  
* C(아키텍처)·D(예외 처리)·F(프로덕트) 역량을 보여줌  
* 필터/정렬은 주니어가 놓치기 쉬운 “상태 관리” 포인트  
성과/학습  
* 정량 지표는 미집계, UI 상태 꼬임 이슈가 줄어듦  
* 데이터 변경 이벤트의 단일화가 유지보수성을 높임을 학습  
* 다음엔 테스트 가능한 필터 엔진 단위 테스트를 추가하고 싶다  
카테고리: C/D/F  
복잡도: ⭐️⭐️⭐️  
주니어 어필도: ⭐️⭐️⭐️⭐️  
면접 예상 질문 3개  
1. "이 기능을 구현하면서 가장 어려웠던 점은?"  
2. "왜 이 방식을 선택했나요?"  
3. "다시 구현한다면 어떻게 개선하겠습니까?"  

---

최종 체크리스트  
* [x] 10~12개 후보 리스트가 별도 섹션으로 먼저 출력됨  
* [x] 각 구현의 "기술적 도전", "해결 접근"이 포트폴리오에 바로 쓸 수 있는 수준  
