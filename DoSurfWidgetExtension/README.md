# DoSurf Widget Extension 설정 가이드

이 폴더에는 서핑 라이브 액티비티(Live Activity)를 위한 위젯 UI 코드가 포함되어 있습니다.

## Widget Extension Target 추가 방법

### 1. Xcode에서 Widget Extension Target 추가

1. Xcode에서 프로젝트를 엽니다
2. 프로젝트 네비게이터에서 프로젝트 파일 선택
3. 하단의 `+` 버튼 클릭 또는 `File > New > Target...` 선택
4. `Widget Extension` 선택
5. 다음 정보 입력:
   - **Product Name**: `DoSurfWidgetExtension`
   - **Include Live Activity**: ✅ 체크
   - **Finish** 클릭

### 2. 생성된 기본 파일 삭제 및 교체

Widget Extension Target이 생성되면 기본 파일들이 자동으로 생성됩니다. 다음 작업을 수행하세요:

1. 자동 생성된 파일들을 삭제:
   - `DoSurfWidgetExtensionLiveActivity.swift` (있다면)
   - 기타 샘플 파일들

2. 이 폴더(`DoSurfWidgetExtension`)의 파일들을 Widget Extension Target에 추가:
   - `DoSurfWidgetExtensionBundle.swift`
   - `SurfingLiveActivity.swift`

### 3. SurfingActivityAttributes.swift 공유 설정

`DoSurfApp/Domain/Model/SurfingActivityAttributes.swift` 파일이 양쪽 Target에서 사용되어야 합니다:

1. Xcode의 File Inspector에서 해당 파일 선택
2. **Target Membership** 섹션에서:
   - ✅ DoSurfApp
   - ✅ DoSurfWidgetExtension
   - 두 곳 모두 체크

### 4. Info.plist 설정 확인

**DoSurfApp의 Info.plist**에 다음 항목이 있는지 확인:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 5. App Group 설정 (선택사항)

메인 앱과 Widget Extension 간 데이터 공유가 필요한 경우:

1. **Signing & Capabilities**로 이동
2. `+ Capability` 클릭
3. **App Groups** 추가
4. 양쪽 Target에 동일한 App Group ID 설정 (예: `group.com.yourcompany.dosurf`)

### 6. 빌드 및 테스트

1. Widget Extension Scheme 선택
2. 실제 기기 또는 iOS 16.1+ 시뮬레이터에서 빌드
3. 메인 앱을 실행하고 서핑 시작 버튼 탭
4. Dynamic Island 또는 잠금 화면에서 Live Activity 확인

## 주의사항

- **Live Activity는 iOS 16.1 이상**에서만 작동합니다
- **시뮬레이터에서는 제한적으로 작동**할 수 있습니다 (실제 기기 권장)
- **Dynamic Island는 iPhone 14 Pro/Pro Max 이상**에서만 표시됩니다
- Live Activity는 **최대 8시간**까지 유지됩니다

## 문제 해결

### Live Activity가 표시되지 않는 경우:

1. iOS 버전 확인 (16.1 이상인지)
2. 설정 > 화면 시간 > 항상 켜기 > Live Activities 활성화 확인
3. `NSSupportsLiveActivities`가 Info.plist에 있는지 확인
4. Widget Extension Target이 올바르게 빌드되었는지 확인
5. 콘솔 로그에서 에러 메시지 확인

### 빌드 에러가 발생하는 경우:

1. ActivityKit 프레임워크가 임포트되었는지 확인
2. 최소 배포 타겟이 iOS 16.1 이상인지 확인
3. Clean Build Folder (`Cmd + Shift + K`) 후 다시 빌드
