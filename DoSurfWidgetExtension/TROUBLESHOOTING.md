# 라이브 액티비티 문제 해결 가이드

라이브 액티비티가 화면에 표시되지 않을 때 다음 단계를 확인하세요.

## 1단계: Widget Extension Target 추가 확인

### Xcode에서 확인하는 방법:

1. Xcode 프로젝트 열기
2. 프로젝트 네비게이터에서 최상위 프로젝트 파일 클릭
3. **TARGETS** 섹션에서 `DoSurfWidgetExtension` 확인
   - ✅ 있으면 → 2단계로
   - ❌ 없으면 → 아래 "Widget Extension Target 추가" 참조

### Widget Extension Target 추가:

1. **File > New > Target...** 선택
2. **Widget Extension** 선택
3. 다음 정보 입력:
   - Product Name: `DoSurfWidgetExtension`
   - Include Live Activity: ✅ **반드시 체크**
   - Include Configuration Intent: ❌ (선택사항)
4. **Finish** 클릭
5. 생성된 기본 파일들 삭제:
   - `DoSurfWidgetExtensionLiveActivity.swift` (자동 생성됨)
   - `DoSurfWidgetExtension.swift` (있다면)
6. 다음 파일들을 Widget Extension Target에 추가:
   - `DoSurfWidgetExtension/DoSurfWidgetExtensionBundle.swift`
   - `DoSurfWidgetExtension/SurfingLiveActivity.swift`

   **방법**: 파일 선택 > File Inspector > Target Membership에서 `DoSurfWidgetExtension` 체크

## 2단계: SurfingActivityAttributes.swift 공유 설정

**중요**: 이 파일은 메인 앱과 Widget Extension 양쪽에서 모두 사용해야 합니다.

1. Xcode에서 `DoSurfApp/Domain/Model/SurfingActivityAttributes.swift` 파일 선택
2. **File Inspector** (우측 패널)에서 **Target Membership** 확인:
   - ✅ DoSurfApp
   - ✅ DoSurfWidgetExtension
   - **양쪽 모두 체크되어야 함**

## 3단계: 빌드 및 테스트

1. **Product > Clean Build Folder** (⌘+Shift+K)
2. **Widget Extension Scheme** 선택
3. 빌드 및 실행
4. 메인 앱으로 돌아가서 서핑 시작

## 4단계: 기기/시뮬레이터 설정 확인

### 실제 기기 (권장):

**설정 > 화면 시간 > 항상 켜기 > Live Activities** 활성화

### 시뮬레이터:

- 시뮬레이터에서는 제한적으로 작동
- 잠금 화면에서만 표시될 수 있음
- Dynamic Island는 실제 iPhone 14 Pro 이상에서만 작동

## 5단계: 디버그 로그 확인

앱을 실행하고 서핑을 시작했을 때 다음 로그를 확인하세요:

### 정상적인 로그:
```
🔵 [LiveActivity] 시작 시도...
🔵 [LiveActivity] iOS 버전: ...
🔵 [LiveActivity] Activity.request 호출...
✅ [LiveActivity] 시작 성공!
   - Activity ID: ...
💡 Dynamic Island 또는 잠금 화면을 확인하세요
```

### 에러가 발생한 경우:

#### "not enabled" 에러
```
❌ [LiveActivity] 시작 실패: not enabled
```
**해결**: Widget Extension Target이 없거나 제대로 빌드되지 않음
- 1단계부터 다시 확인

#### "Live Activities가 비활성화" 메시지
```
❌ [LiveActivity] Live Activities가 비활성화되어 있습니다
💡 설정 > 화면 시간 > 항상 켜기 > Live Activities 활성화 필요
```
**해결**: 기기 설정에서 Live Activities 활성화

## 6단계: 여전히 안 되는 경우

### 체크리스트:

- [ ] iOS 버전이 16.2 이상인가요?
- [ ] Widget Extension Target이 Xcode에 추가되었나요?
- [ ] SurfingActivityAttributes.swift가 양쪽 Target에 포함되었나요?
- [ ] Info.plist에 `NSSupportsLiveActivities`가 있나요?
- [ ] Clean Build 후 다시 빌드했나요?
- [ ] 실제 기기에서 테스트했나요?

### 디버깅 팁:

1. **Xcode Console에서 로그 확인**:
   ```
   [LiveActivity]
   ```
   키워드로 필터링

2. **Widget Extension Scheme으로 직접 실행**:
   - Scheme 선택: DoSurfWidgetExtension
   - 실행하면 Widget Extension이 직접 디버깅됨

3. **Breakpoint 설정**:
   - `SurfingLiveActivity.swift`에 breakpoint 설정
   - Widget이 로드되는지 확인

## FAQ

### Q1: 시뮬레이터에서 Dynamic Island가 안 보여요
**A**: Dynamic Island는 iPhone 14 Pro 이상의 실제 기기에서만 작동합니다. 시뮬레이터에서는 잠금 화면 배너만 표시됩니다.

### Q2: 라이브 액티비티가 금방 사라져요
**A**: iOS는 최대 8시간까지만 라이브 액티비티를 유지합니다. 또한 사용자가 수동으로 닫을 수 있습니다.

### Q3: "Widget Extension not found" 에러
**A**: Widget Extension Target이 Xcode에 추가되지 않았습니다. 1단계를 다시 확인하세요.

### Q4: 실제 기기에서도 안 보여요
**A**:
1. 설정 > 화면 시간 > 항상 켜기 > Live Activities 활성화 확인
2. 잠금 화면 확인 (잠깐 화면을 끄고 다시 켜보세요)
3. 알림 센터 아래로 스와이프해서 확인

## 추가 리소스

- [Apple Documentation: ActivityKit](https://developer.apple.com/documentation/activitykit)
- [WWDC22: Live Activities](https://developer.apple.com/videos/play/wwdc2022/10184/)
- [Human Interface Guidelines: Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities)
