# 두섭이 (DoSurf)

<p align="center">
  <img src="docs/app_icon.png" width="120" height="120">
</p>

<p align="center">
  <strong>초보 서퍼를 위한 해양 날씨 데이터 간소화 앱</strong>
</p>

<p align="center">
  <a href="https://apps.apple.com/kr/app/두섭이/id6753593506">
    <img src="docs/download_appstore.svg" height="40">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.0+-blue.svg">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg">
  <img src="https://img.shields.io/badge/License-MIT-green.svg">
</p>

---

## 📱 스크린샷

<p align="center">
  <img src="docs/screenshot_1_dashboard.png" width="200">
  <img src="docs/screenshot_2_chart.png" width="200">
  <img src="docs/screenshot_3_record.png" width="200">
  <img src="docs/screenshot_4_history.png" width="200">
</p>

> 왼쪽부터: 대시보드, 해양 차트, 기록하기, 기록 조회

---

## 1. 프로젝트 개요

### 📋 기본 정보
- **앱 이름**: 두섭이 (DoSurf)
- **개발 기간**: 2024.06 ~ 2024.11 (약 6개월)
- **개발 인원**: 1인 (기획/디자인/개발/배포)
- **플랫폼**: iOS 16.0+
- **App Store**: [다운로드 링크](https://apps.apple.com/kr/app/두섭이/id6753593506)

### 🎯 개발 동기
초보 서퍼로서 WindFinder, Surfline 같은 해양 날씨 앱의 복잡한 차트를 읽기 어려웠고, "어떤 조건에서 서핑이 좋았는지" 기억하기 힘든 문제를 겪었습니다. **복잡한 해양 데이터를 간소화하고, 개인 기록을 기반으로 최적의 서핑 조건을 찾을 수 있는 앱**을 만들고자 했습니다.

---

## 2. 주요 기능

### 🌊 1. 실시간 해양 차트 대시보드
- 파고, 풍속/풍향, 수온, 기온, 날씨 등 **서핑에 필요한 모든 정보를 한 화면에 통합**
- Firebase Firestore를 통한 **실시간 데이터 동기화** (6시간마다 자동 갱신)
- 지역별 평균 통계 제공 (해당 지역 전체 해변의 평균 조건 표시)
- 날짜별로 차트를 그룹화하여 과거 데이터 조회 가능

### 📝 2. 서핑 세션 기록 및 관리
- 서핑 시작/종료 시간, 평가(1~5점), 메모를 한 곳에 기록
- **기록 시점의 해양 차트 데이터를 자동으로 연동**하여 "어떤 조건에서 서핑했는지" 저장
- CoreData를 활용한 오프라인 기록 관리
- 기록 수정/삭제 기능 제공

### 📊 3. 통계 기반 선호 조건 분석
- **"선호 조건" 카드**: 평점 높은 세션의 패턴을 분석하여 나만의 최적 조건 제시
- 최근 10개 세션의 차트 데이터를 시각화
- 중요한 세션을 "고정"하여 빠르게 참고 가능
- Lazy Loading으로 빠른 초기 로딩 + 점진적 데이터 보강

### 🔍 4. 스마트 필터링 및 히스토리 조회
- **날짜 범위** (프리셋: 오늘/이번주/이번달/전체), **해변**, **평점**으로 다차원 필터링
- 최신순, 평점순, 오래된순 정렬
- 핀 고정/해제, 삭제 기능
- 빈 상태(Empty State) UI로 UX 개선

### ⏱️ 5. Live Activities (iOS 16.2+)
- **잠금 화면 + Dynamic Island에서 실시간 서핑 타이머 표시**
- 앱을 열지 않고도 경과 시간 확인 가능
- 60초마다 자동 업데이트로 배터리 효율 고려

---

## 3. 기술 스택

### 🔧 Language & Framework

| 기술 | 선택 이유 |
|------|----------|
| **Swift 5.0** | 타입 안전성과 현대적인 문법으로 안정적이고 유지보수 가능한 코드 작성 |
| **UIKit** | 복잡한 커스텀 UI와 세밀한 성능 제어가 필요한 차트/통계 화면 구현에 적합 |
| **SnapKit** | 프로그래매틱 Auto Layout을 간결하고 가독성 높게 작성하기 위해 선택 |

### 📚 Architecture & Reactive

| 기술 | 선택 이유 |
|------|----------|
| **MVVM + Clean Architecture** | View-ViewModel-UseCase-Repository로 관심사 분리, 테스트 가능한 구조 구축 |
| **Input-Output Pattern** | ViewModel의 데이터 흐름을 명확하게 단방향으로 관리하여 예측 가능한 상태 관리 |
| **RxSwift / RxCocoa** | Firebase 실시간 업데이트, 사용자 입력, UI 업데이트를 선언적으로 연결하여 복잡한 비동기 로직 간소화 |

### 💾 Database & Network

| 기술 | 선택 이유 |
|------|----------|
| **CoreData** | 오프라인에서도 서핑 기록을 빠르게 저장/조회하기 위한 로컬 영구 저장소 |
| **Firebase Firestore** | 실시간 Snapshot Listener로 해양 차트 데이터를 자동 동기화, 서버리스로 백엔드 관리 부담 제거 |
| **Python Cloud Functions** | 6시간마다 해양 API 호출 및 데이터 가공을 서버에서 자동 실행 (앱 백그라운드 제약 해결) |

### 🎨 Others

| 기술 | 선택 이유 |
|------|----------|
| **ActivityKit (iOS 16.2+)** | 최신 iOS 기능인 Live Activities로 차별화된 UX 제공 (잠금 화면 타이머) |
| **Dependency Injection (DIContainer)** | Mock 객체 주입으로 단위 테스트 가능한 환경 구축, 결합도 낮춤 |

---

## 4. 아키텍처 및 설계

### 🏗️ 전체 구조도 (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │ViewController│ ◀─────▶ │  ViewModel   │                  │
│  │   (UIKit)    │         │(Input-Output)│                  │
│  └──────────────┘         └──────────────┘                  │
│         ▲                         │                          │
│         │                         ▼                          │
│         │                  ┌──────────────┐                  │
│         └──────────────────│   UseCase    │                  │
└────────────────────────────└──────────────┘──────────────────┘
                                     │
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │   Entities   │         │  Repository  │                  │
│  │(Beach, Chart)│         │  Protocols   │                  │
│  └──────────────┘         └──────────────┘                  │
└─────────────────────────────────────────────────────────────┘
                                     ▲
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │ Repositories │ ◀─────▶ │ Data Sources │                  │
│  │(Implement)   │         │Firebase/Core │                  │
│  └──────────────┘         │    Data      │                  │
│                           └──────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### 🔄 데이터 흐름 (RxSwift)

```
사용자 액션 (버튼 탭, 드롭다운 선택)
       │
       ▼
  ViewModel Input (Observable)
       │
       ▼
  UseCase (비즈니스 로직)
       │
       ▼
  Repository (인터페이스)
       │
       ▼
  Data Source (Firebase/CoreData)
       │
       ▼
  ViewModel Output (Driver)
       │
       ▼
  View 업데이트 (UI Binding)
```

**핵심 원칙**:
- **단방향 데이터 흐름**: Input → Transform → Output으로 명확한 흐름
- **의존성 역전**: Domain Layer는 Data Layer를 모르고, Protocol만 의존
- **메모리 안전**: `[weak self]` + `DisposeBag`으로 순환 참조 방지

### 🎨 사용한 디자인 패턴

| 패턴 | 적용 위치 | 목적 |
|------|----------|------|
| **MVVM** | Presentation Layer | View와 비즈니스 로직 분리, 테스트 가능한 ViewModel |
| **Repository Pattern** | Data Layer | 데이터 소스 추상화, Firebase ↔ CoreData 전환 가능 |
| **Dependency Injection** | 전 레이어 | Mock 객체 주입으로 단위 테스트 가능, 결합도 감소 |
| **Observer Pattern (Rx)** | Presentation-Domain | 데이터 변경 시 자동 UI 업데이트 |
| **Singleton (신중하게 사용)** | DIContainer, Managers | 전역 상태 관리 (FirebaseApp, CoreDataStack) |

---

## 5. 핵심 구현 내용

### 🔥 1. Live Activities - 잠금 화면 서핑 타이머

#### 🎯 왜 구현했는가?
서핑 중에는 휴대폰을 열기 어렵기 때문에, **잠금 화면에서 경과 시간을 확인할 수 있으면** 사용자 경험이 크게 향상됩니다. iOS 16.2의 Live Activities는 이를 위한 최적의 기능이었습니다.

#### 📝 코드 예시

```swift
// Domain/Service/SurfingActivityManager.swift

import ActivityKit
import Foundation

@available(iOS 16.2, *)
final class SurfingActivityManager {

    /// Live Activity 시작
    func startActivity(startTime: Date) -> String? {
        // 1. 권한 확인
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities가 비활성화되어 있습니다")
            return nil
        }

        // 2. ActivityKit Attributes 생성
        let attributes = SurfingActivityAttributes(beachName: "현재 해변")
        let contentState = SurfingActivityAttributes.ContentState(
            startTime: startTime,
            elapsedSeconds: 0
        )

        // 3. Activity 시작
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )

            // 4. 60초마다 업데이트 (배터리 효율 고려)
            startUpdating(activity: activity, startTime: startTime)

            return activity.id
        } catch {
            print("❌ Live Activity 시작 실패: \(error)")
            return nil
        }
    }

    /// 60초마다 경과 시간 업데이트
    private func startUpdating(activity: Activity<SurfingActivityAttributes>, startTime: Date) {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let elapsed = Int(Date().timeIntervalSince(startTime))
            let newState = SurfingActivityAttributes.ContentState(
                startTime: startTime,
                elapsedSeconds: elapsed
            )

            Task {
                await activity.update(using: .init(state: newState, staleDate: nil))
            }
        }
    }

    /// Live Activity 종료
    func endActivity(activityId: String) async {
        for activity in Activity<SurfingActivityAttributes>.activities {
            if activity.id == activityId {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}
```

#### ✅ 기존 방식 대비 개선점
- **이전**: 타이머 확인을 위해 앱을 켜야 함 → 서핑 중 불편
- **개선**: 잠금 화면 + Dynamic Island에서 실시간 확인 → **마찰 없는 UX**
- **기술적 장점**:
  - `staleDate` 관리로 오래된 데이터 표시 방지
  - 60초 간격 업데이트로 배터리 소모 최소화
  - `dismissalPolicy.immediate`로 세션 종료 시 즉시 제거

---

### 🧭 2. 원형 통계 평균 - 풍향/파향 계산

#### 🎯 왜 구현했는가?
풍향은 원형 데이터(359°와 1°는 거의 같음)이기 때문에, 단순 산술 평균(`(359 + 1) / 2 = 180°`)을 쓰면 **완전히 반대 방향이 나옵니다**. 정확한 통계를 위해 원형 평균(Circular Mean)을 구현했습니다.

#### 📝 코드 예시

```swift
// Domain/Model/BeachAverageCalculator.swift

/// 풍향/파향 평균 계산 (원형 통계)
private func averageDirectionDegrees(_ degrees: [Double]) -> Double? {
    guard !degrees.isEmpty else { return nil }

    // 1. 각도를 라디안으로 변환
    let radians = degrees.map { $0 * .pi / 180.0 }

    // 2. 단위 벡터의 합 계산
    //    각 각도를 (x, y) = (cos θ, sin θ) 벡터로 변환 후 합산
    let sumX = radians.reduce(0.0) { $0 + cos($1) }
    let sumY = radians.reduce(0.0) { $0 + sin($1) }

    // 3. 합이 0에 가까우면 방향이 사방팔방 → 평균 없음
    if abs(sumX) < 1e-6 && abs(sumY) < 1e-6 {
        return nil
    }

    // 4. atan2로 평균 각도 계산
    var averageAngle = atan2(sumY, sumX) * 180.0 / .pi

    // 5. 음수를 0~360 범위로 변환
    if averageAngle < 0 {
        averageAngle += 360.0
    }

    return averageAngle
}
```

#### ✅ 기존 방식 대비 개선점
- **이전 (산술 평균)**: `[359°, 1°, 3°]` → 평균 121° (완전히 틀림)
- **개선 (원형 평균)**: `[359°, 1°, 3°]` → 평균 1° (정확함)
- **실제 효과**: 지역별 평균 풍향이 실제 기상 패턴과 일치하여 **신뢰도 상승**

---

### ⚡ 3. RxSwift 동시성 제어 - 병렬 API 호출 최적화

#### 🎯 왜 구현했는가?
대시보드에서 지역 내 모든 해변(최대 10개)의 데이터를 가져올 때, **순차 호출하면 너무 느리고, 무제한 병렬 호출하면 네트워크 폭주**가 발생합니다. 적절한 동시성 제어가 필요했습니다.

#### 📝 코드 예시

```swift
// Presentation/Dashboard/DashboardViewModel.swift

func transform(input: Input) -> Output {

    // 지역 내 모든 해변 데이터를 병렬로 가져오기 (최대 10개 동시 실행)
    let lazyAvgCard = input.cardsLazyTrigger
        .withLatestFrom(Observable.combineLatest(currentBeach, regionAllBeaches))
        .flatMapLatest { [weak self] (current, allInRegion) -> Observable<[DashboardCardData]> in
            guard let self = self else { return .empty() }

            let targets = allInRegion.filter { $0.id != current.id }

            return Observable.from(targets)
                // ⭐ 핵심: 최대 10개 동시 실행, 네트워크 과부하 방지
                .flatMapConcurrent(maxConcurrent: 10) { beach -> Observable<BeachData?> in
                    self.fetchBeachDataUseCase
                        .execute(beachId: beach.id, region: beach.region.slug)
                        .map { Optional($0) }
                        .asObservable()
                        .catch { _ in .just(nil) }  // 에러 시 nil로 처리
                }
                .toArray()  // 모든 결과를 배열로 수집
                .asObservable()
                .observe(on: backgroundScheduler)  // 백그라운드 스레드에서 계산
                .map { datas -> [DashboardCardData] in
                    let validDatas = datas.compactMap { $0 }

                    // 지역 평균 계산 (파고, 풍속, 수온 등)
                    let avgWaveHeight = validDatas.map(\.waveHeight).average()
                    let avgWindSpeed = validDatas.map(\.windSpeed).average()
                    let avgWaterTemp = validDatas.map(\.waterTemp).average()

                    return [
                        DashboardCardData(
                            type: .regionAverage,
                            waveHeight: avgWaveHeight,
                            windSpeed: avgWindSpeed,
                            waterTemp: avgWaterTemp
                        )
                    ]
                }
                .observe(on: MainScheduler.instance)  // UI 업데이트는 메인 스레드
        }
        .asDriver(onErrorJustReturn: [])

    return Output(lazyAvgCard: lazyAvgCard)
}
```

#### ✅ 기존 방식 대비 개선점
- **이전 (순차 호출)**: 10개 API × 500ms = 5초 대기
- **개선 (병렬 10개)**: 최대 500ms만 대기 (약 **10배 빠름**)
- **네트워크 안전**: `maxConcurrent: 10`으로 서버 부하 제어
- **에러 견고성**: `catch`로 일부 API 실패해도 나머지 데이터 표시
- **스레드 최적화**:
  - 무거운 계산은 `backgroundScheduler`
  - UI 업데이트는 `MainScheduler.instance`
- **메모리 안전**: `[weak self]`로 ViewModel 해제 시 작업 취소

---

## 6. 트러블슈팅 및 개선 과정

### 🐛 1. CoreData 병렬 접근으로 인한 크래시

**문제 상황**
- 메인 스레드에서 CoreData 저장 작업을 하니 UI가 버벅임
- 백그라운드 스레드로 옮겼더니 `NSManagedObjectContext`의 스레드 안전성 위반으로 크래시 발생

**해결 방법**
```swift
// 각 스레드마다 전용 Context 생성
func saveSurfRecord(_ record: SurfRecordData) -> Single<Void> {
    return Single.create { [weak self] observer in
        guard let self = self else {
            observer(.failure(RepositoryError.unknown))
            return Disposables.create()
        }

        // ⭐ 백그라운드 전용 Context 생성
        let backgroundContext = self.coreDataStack.newBackgroundContext()

        backgroundContext.perform {
            // 이 블록 안에서는 안전하게 CoreData 작업
            let entity = SurfRecordEntity(context: backgroundContext)
            entity.id = record.id
            entity.rating = Int16(record.rating)

            do {
                try backgroundContext.save()
                DispatchQueue.main.async {
                    observer(.success(()))
                }
            } catch {
                observer(.failure(error))
            }
        }

        return Disposables.create()
    }
}
```

**배운 점**
- CoreData는 **Context마다 별도 스레드**를 사용해야 안전
- `perform` 블록 안에서만 해당 Context 접근
- 메인 Context는 읽기 전용, 백그라운드 Context는 쓰기 전용으로 역할 분리

---

### 🐛 2. Firebase Snapshot Listener 메모리 누수

**문제 상황**
- ViewModel이 해제되었는데도 Firebase Listener가 계속 실행됨
- 화면 전환 시 메모리 사용량이 계속 증가

**해결 방법**
```swift
class ChartViewModel {
    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let charts = input.beachSelected
            .flatMapLatest { [weak self] beach -> Observable<[Chart]> in
                guard let self = self else { return .empty() }

                // ⭐ RxSwift의 DisposeBag이 자동으로 Listener 해제
                return self.chartRepository.fetchCharts(beachID: beach.id)
            }
            .asDriver(onErrorJustReturn: [])

        return Output(charts: charts)
    }

    // ViewModel이 해제될 때 DisposeBag도 함께 해제 → Listener 자동 정리
    deinit {
        print("✅ ChartViewModel 해제됨")
    }
}
```

**배운 점**
- RxSwift의 `DisposeBag`은 자동 리소스 정리 도구
- `flatMapLatest`는 새 Observable 구독 시 이전 구독 자동 취소
- `[weak self]` 없으면 순환 참조 발생

---

### 🐛 3. 지역 평균 계산 시 UI 멈춤

**문제 상황**
- 10개 해변 데이터를 가져와서 평균 계산할 때 UI가 2~3초 멈춤
- 사용자가 "앱이 느리다"고 느낌

**해결 방법**
```swift
// ⭐ 1단계: 빠른 데이터(현재 해변)를 먼저 보여줌
let fastCard = currentBeachData
    .map { [$0.toDashboardCard()] }
    .asDriver(onErrorJustReturn: [])

// ⭐ 2단계: 느린 데이터(지역 평균)는 나중에 추가
let lazyAvgCard = input.cardsLazyTrigger
    .flatMapLatest { /* 병렬로 10개 해변 데이터 가져오기 */ }
    .observe(on: backgroundScheduler)  // 계산은 백그라운드에서
    .map { /* 평균 계산 */ }
    .observe(on: MainScheduler.instance)  // UI 업데이트는 메인에서
    .asDriver(onErrorJustReturn: [])

return Output(
    fastCard: fastCard,      // 즉시 표시
    lazyAvgCard: lazyAvgCard // 1~2초 후 추가
)
```

**배운 점**
- **Lazy Loading**: 필수 데이터 먼저 → 부가 데이터 나중에
- **백그라운드 스레드 활용**: 무거운 계산은 메인 스레드를 피해야 함
- **체감 속도 개선**: 실제 속도는 같아도 "빠르다"고 느끼게 만드는 것이 UX

---

## 7. 회고 및 개선 방향

### 💪 잘한 점
1. **실사용자 관점에서 출발**: 내가 겪은 문제를 해결하는 앱이라 기획이 명확했음
2. **Clean Architecture 적용**: 처음에는 어려웠지만, 기능 추가 시 기존 코드를 거의 안 건드려도 됨
3. **RxSwift 정복**: 복잡한 비동기 로직을 선언적으로 관리할 수 있게 됨
4. **성능 최적화 의식**: "왜 느린가?" → "어떻게 개선할까?" 사고 습관 형성

### 🤔 아쉬운 점
1. **단위 테스트 부재**: DI 구조는 만들었지만 실제 테스트 코드는 작성 안 함 → **다음 프로젝트에서 TDD 도입 목표**
2. **CI/CD 미구축**: 수동 배포로 인한 실수 여러 번 발생 → **Fastlane + GitHub Actions 도입 계획**
3. **디자인 시스템 일관성**: 초반에 색상/폰트를 enum으로 만들었지만, 중간에 하드코딩한 부분 있음

### 🚀 향후 개선 계획
1. **Unit Test 커버리지 70% 이상**
   - ViewModel, UseCase 우선 테스트 작성
   - Mock Repository로 네트워크 의존성 제거
2. **Fastlane으로 자동 배포**
   - 스크린샷 자동 생성
   - TestFlight 배포 자동화
3. **Widget 기능 추가**
   - 홈 화면에서 현재 파고/풍속 확인
   - WidgetKit으로 구현
4. **서핑 스팟 추천 알고리즘**
   - 사용자의 평점 패턴 학습
   - 오늘 날씨 기반 추천

---

## 8. 프로젝트 구조

```
DoSurf-iOS/
├── App/
│   ├── AppDelegate.swift           # Firebase 초기화
│   ├── SceneDelegate.swift
│   └── DIContainer.swift           # 의존성 주입 컨테이너
│
├── Presentation/
│   ├── Scenes/
│   │   ├── Dashboard/              # 대시보드 (메인 화면)
│   │   │   ├── DashboardViewController.swift
│   │   │   ├── DashboardViewModel.swift
│   │   │   └── Views/
│   │   ├── Chart/                  # 차트 목록
│   │   ├── Note/                   # 서핑 기록 작성/수정
│   │   ├── RecordHistory/          # 기록 조회 및 필터링
│   │   └── BeachSelect/            # 해변 선택
│   └── Common/
│       ├── Views/                  # 재사용 가능한 커스텀 뷰
│       └── Extensions/
│
├── Domain/
│   ├── Model/
│   │   ├── Beach.swift
│   │   ├── Chart.swift
│   │   └── SurfRecord.swift
│   ├── UseCase/
│   │   ├── FetchBeachDataUseCase.swift
│   │   ├── SaveSurfRecordUseCase.swift
│   │   └── FetchRecordHistoryUseCase.swift
│   ├── Repository/
│   │   ├── ChartRepository.swift   # Protocol
│   │   └── RecordRepository.swift  # Protocol
│   └── Service/
│       └── SurfingActivityManager.swift  # Live Activities
│
├── Data/
│   ├── Repository/
│   │   ├── DefaultChartRepository.swift       # Firebase 구현
│   │   └── DefaultRecordRepository.swift      # CoreData 구현
│   ├── Network/
│   │   ├── FirebaseService.swift
│   │   └── FirestoreProtocol.swift
│   └── Local/
│       ├── CoreDataManager.swift
│       └── DoSurf.xcdatamodeld     # CoreData 스키마
│
├── Resources/
│   ├── DesignSystem/
│   │   ├── Typography.swift
│   │   └── ColorSystem.swift
│   └── Assets.xcassets
│
└── README.md
```

---

## 9. 설치 및 실행

### 📦 요구사항
- Xcode 15.0+
- iOS 16.0+
- CocoaPods 또는 Swift Package Manager

### 🚀 실행 방법

```bash
# 1. 저장소 클론
git clone https://github.com/piriram/DoSurf-iOS.git
cd DoSurf-iOS

# 2. 의존성 설치 (SPM 사용 시 Xcode가 자동 설치)
# CocoaPods 사용 시:
# pod install

# 3. Xcode에서 프로젝트 열기
open DoSurf.xcodeproj

# 4. Firebase 설정
# - Firebase Console에서 GoogleService-Info.plist 다운로드
# - 프로젝트 루트에 추가

# 5. 빌드 및 실행 (⌘ + R)
```

---

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

## 📮 문의

- **Developer**: [@piriram](https://github.com/piriram)
- **Email**: piriram@example.com
- **App Store**: [두섭이 다운로드](https://apps.apple.com/kr/app/두섭이/id6753593506)

---

<p align="center">
  <strong>Made with ❤️ by a surfer, for surfers</strong>
</p>
