# DoSurf 구현 기능 보고서

기준: `PRODUCT_SPECIFICATION.md` 및 현재 소스 구현 상태

---

## 1) 기획서 기준 구현된 기능

### 해양 예보 차트
- 해변별 시간대 예보 리스트 표시(파고/파주기, 풍향/풍속, 수온, 기온, 날씨) `DoSurfApp/Presentation/Scenes/Dashboard/ChartTableViewCell.swift`
- 대시보드에서 차트 리스트 제공 및 당일/시간별 그룹 표시 `DoSurfApp/Presentation/Scenes/Dashboard/BeachChartListView.swift`, `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift`
- 수동 새로고침(pull-to-refresh) `DoSurfApp/Presentation/Scenes/Dashboard/DashboardViewController.swift`
- 앱 재활성화 시 현재 시간대 근처로 자동 포커싱 `DoSurfApp/Presentation/Scenes/Dashboard/DashboardViewController.swift`

### 서핑 기록 관리
- 서핑 시작/종료 플로우(오버레이, 시작/종료 시각 저장) `DoSurfApp/Presentation/Scenes/TabBar/ButtonTabBarController.swift`, `DoSurfApp/Presentation/ViewModel/ButtonTabBarViewModel.swift`
- 기록 작성(날짜/시간, 별점, 메모, 차트 스냅샷 저장) `DoSurfApp/Presentation/Scenes/Note/NoteViewController.swift`, `DoSurfApp/Presentation/ViewModel/NoteViewModel.swift`
- 기록 수정/삭제 `DoSurfApp/Presentation/Scenes/RecordHistory/RecordHistoryVC+Presentation.swift`, `DoSurfApp/Domain/UseCase/SurfRecordUseCase.swift`
- 핀 고정 토글 `DoSurfApp/Presentation/ViewModel/RecordHistoryViewModel.swift`

### 기록 조회 및 필터
- 기록 리스트 + 기록별 차트 스냅샷 표시 `DoSurfApp/Presentation/Scenes/RecordHistory/RecordHisoryCell.swift`
- 필터: 전체/핀 고정, 해변 선택 `DoSurfApp/Presentation/Scenes/RecordHistory/RecordHistoryViewController.swift`, `DoSurfApp/Presentation/ViewModel/RecordHistoryViewModel.swift`
- 정렬: 최신/과거/평점 높은순/낮은순 `DoSurfApp/Presentation/ViewModel/RecordHistoryViewModel.swift`
- 상세 메모 보기 시트 `DoSurfApp/Presentation/Scenes/RecordHistory/MemoDetailViewController.swift`

### 통계 및 분석
- 카드 페이지 스와이프 구조 `DoSurfApp/Presentation/Scenes/Dashboard/PagenationView.swift`, `DoSurfApp/Presentation/Scenes/Dashboard/InfoPage/DashboardHeaderView.swift`
- 현재 해변 기반 파도/바람 카드 및 지역 평균 카드 `DoSurfApp/Presentation/ViewModel/DashboardViewModel.swift`
- 최근 기록 차트, 고정 차트 페이지 `DoSurfApp/Presentation/Scenes/Dashboard/InfoPage/ChartListPage.swift`

### 해변 선택
- 지역(카테고리)별 해변 목록/선택 `DoSurfApp/Presentation/Scenes/BeachSelect/BeachSelectViewController.swift`, `DoSurfApp/Presentation/ViewModel/BeachSelectViewModel.swift`
- 선택한 해변 유지(재실행 시 복원) `DoSurfApp/Infra/UserDefaultsManager.swift`

### 다국어 지원
- **구현 흔적 없음** (Localizable/리소스 미발견)

### 로드맵 v1.1 항목 중 구현됨
- Live Activity(잠금화면/다이내믹 아일랜드) `DoSurfApp/Domain/Service/SurfingActivityManager.swift`, `DoSurfWidgetExtension/SurfingLiveActivity.swift`
- watchOS 앱(서핑 세션, 심박수 등 운동 지표) `DoSurfWatch Watch App/MainWatchView.swift`, `DoSurfWatch Watch App/SurfWorkoutManager.swift`
- 위젯: Live Activity 전용 위젯으로 구현 `DoSurfWidgetExtension/SurfingLiveActivity.swift`

---

## 2) 기획서에 없는 추가 구현 기능

- 기록 바로하기(서핑 시작 없이 기록 화면 진입) `DoSurfApp/Presentation/Scenes/TabBar/ButtonTabBarController.swift`
- 메모 임시 저장/복원(자동 저장) `DoSurfApp/Presentation/ViewModel/NoteViewModel.swift`
- 기록 리스트에서 차트 스냅샷을 바로 확인(상세 진입 없이 노출) `DoSurfApp/Presentation/Scenes/RecordHistory/RecordHisoryCell.swift`
- Apple Watch ↔ iPhone 데이터 전송(WatchConnectivity) 및 수신 화면 `DoSurfApp/Infra/iPhoneWatchConnectivity.swift`, `DoSurfApp/Infra/SurfDataReceiverViewController.swift`, `DoSurfWatch Watch App/WatchConnectivityManager.swift`
- watchOS 컴플리케이션 제공 `DoSurfWatch Watch App/ComplicationController.swift`, `DoSurfWatch Watch App/ComplicationDataManager.swift`
- 서핑 중 상태 지속(앱 재시작 시 이어받기) `DoSurfApp/Infra/UserDefaultsManager.swift`, `DoSurfApp/Presentation/ViewModel/ButtonTabBarViewModel.swift`

---

## 참고: 부분 구현/연결 필요로 보이는 항목

- 기록 필터(날짜 프리셋/기간, 별점 선택) UI는 있으나 필터 적용 로직 연결 TODO `DoSurfApp/Presentation/Scenes/RecordHistory/RecordHistoryVC+Presentation.swift`
- 기록 리스트에서 메모 편집 시 저장 로직 TODO `DoSurfApp/Presentation/Scenes/RecordHistory/RecordHistoryVC+Presentation.swift`
