# Widget Extension Target 추가 - 단계별 가이드

## ⚠️ 라이브 액티비티 UI가 안 보이는 이유

Activity는 생성되지만 **Widget Extension Target**이 없으면 **UI가 표시되지 않습니다**.

## 🎯 해결: Widget Extension Target 추가

### 1단계: Target 추가

1. **Xcode** 열기
2. 메뉴: **File > New > Target...**
3. **iOS > Widget Extension** 선택
4. 다음 입력:
   ```
   Product Name: DoSurfWidgetExtension
   Team: (본인 팀 선택)
   Language: Swift

   ✅ Include Live Activity (반드시 체크!)
   ❌ Include Configuration Intent (체크 해제)
   ```
5. **Finish** 클릭
6. "Activate 'DoSurfWidgetExtension' scheme?" → **Activate** 클릭

### 2단계: 자동 생성 파일 삭제

Xcode가 자동으로 만든 파일들을 **삭제**하세요:

```
❌ DoSurfWidgetExtension/DoSurfWidgetExtensionLiveActivity.swift
❌ DoSurfWidgetExtension/DoSurfWidgetExtension.swift (있다면)
❌ DoSurfWidgetExtension/Assets.xcassets (있다면 그냥 두세요)
```

**삭제 방법**: 파일 우클릭 → Delete → Move to Trash

### 3단계: 우리가 만든 파일 Target에 추가

다음 2개 파일을 Widget Extension Target에 추가:

#### 파일 1: DoSurfWidgetExtensionBundle.swift
1. 프로젝트 네비게이터에서 파일 찾기: `DoSurfWidgetExtension/DoSurfWidgetExtensionBundle.swift`
2. 파일 선택
3. 우측 **File Inspector** (⌘+⌥+1)
4. **Target Membership** 섹션:
   ```
   ✅ DoSurfWidgetExtension (체크)
   ❌ DoSurfApp (체크 해제)
   ```

#### 파일 2: SurfingLiveActivity.swift
1. `DoSurfWidgetExtension/SurfingLiveActivity.swift` 선택
2. File Inspector → Target Membership:
   ```
   ✅ DoSurfWidgetExtension (체크)
   ❌ DoSurfApp (체크 해제)
   ```

### 4단계: SurfingActivityAttributes 공유 설정

**중요!** 이 파일은 양쪽 Target 모두 필요합니다.

1. `DoSurfApp/Domain/Model/SurfingActivityAttributes.swift` 선택
2. File Inspector → Target Membership:
   ```
   ✅ DoSurfApp (체크)
   ✅ DoSurfWidgetExtension (체크) ← 둘 다 체크!
   ```

### 5단계: 빌드 및 테스트

1. **Product > Clean Build Folder** (⌘+Shift+K)

2. **Scheme 전환**:
   - 상단 Scheme 선택 → **DoSurfWidgetExtension** 선택
   - 빌드 (⌘+B)
   - 에러 없이 성공해야 함

3. **메인 앱 Scheme**으로 다시 전환:
   - Scheme 선택 → **DoSurfApp** 선택

4. **앱 실행** (⌘+R)

5. 서핑 시작 후 **Xcode Console 확인**:
   ```
   🔵 [LiveActivity] 시작 시도...
   🔵 [LiveActivity] Activity.request 호출...
   ✅ [LiveActivity] 시작 성공!
   💡 Dynamic Island 또는 잠금 화면을 확인하세요
   ```

6. **실제 확인**:
   - iPhone: Dynamic Island 확인 (14 Pro 이상)
   - 또는: 잠금 화면에서 확인
   - 시뮬레이터: 잠금 화면만 표시됨

## 📸 스크린샷으로 확인하기

### Xcode TARGETS 섹션 예시:
```
DoSurfApp.xcodeproj
├── PROJECT
│   └── DoSurfApp
└── TARGETS
    ├── DoSurfApp                    ← 메인 앱
    └── DoSurfWidgetExtension        ← 이게 있어야 함! ⭐
```

## ❓ 여전히 안 되는 경우

### 체크리스트:
- [ ] DoSurfWidgetExtension Target이 TARGETS에 보이나요?
- [ ] DoSurfWidgetExtension Scheme으로 빌드가 성공하나요?
- [ ] SurfingActivityAttributes.swift가 양쪽 Target에 체크되었나요?
- [ ] Clean Build 후 다시 빌드했나요?
- [ ] iOS 16.2 이상인가요?

### 디버깅:
1. **Widget Extension 직접 실행**:
   - Scheme: DoSurfWidgetExtension
   - 실행 → 에러 확인

2. **Console 필터**:
   ```
   [LiveActivity]
   ```

3. **Target Membership 다시 확인**:
   - SurfingActivityAttributes.swift
   - DoSurfWidgetExtensionBundle.swift
   - SurfingLiveActivity.swift

## 🎉 성공하면

잠금 화면이나 Dynamic Island에 다음과 같이 표시됩니다:

```
🏄‍♂️ 서핑 중
13:00  •  15분 경과
```

## 추가 도움

- 스크린샷 공유하면 더 구체적으로 도와드릴 수 있습니다
- Xcode TARGETS 섹션 스크린샷
- 에러 메시지 전체
