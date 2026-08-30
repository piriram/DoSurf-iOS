# 두섭이 (DoSurf)

서핑 조건을 차트로 보여주고 서핑 기록을 관리하는 iOS + watchOS 앱.
**App Store 라이브.** 회귀가 곧 사용자 피해이므로 변경은 보수적으로.

- App Store: [두섭이](https://apps.apple.com/kr/app/id6753593506)
- 배포 타겟: iOS 16.2+ / watchOS 9.6+

## 커밋할 때

**author는 반드시 사용자 본인.** 이름은 본인 이름, 이메일은 `pyoram25@gmail.com`.

원격/클라우드 세션 컨테이너는 전역 git 설정이 AI 명의로 되어 있어서,
**아무 설정 없이 커밋하면 author가 사용자가 아닌 이름으로 찍힌다.**
DoSurf-API에서 실제로 그렇게 나가 커밋을 되돌린 적이 있다.
저장소 로컬 설정은 새 클론이면 사라지므로 **커밋 전에 확인할 것.**

```sh
git config user.name
git config user.email
```

**AI 공동저자(Co-Authored-By) 라인 절대 금지.**
"Generated with ..." 문구, 🤖 이모지도 금지.

**형식**: `type: 설명` — 소문자, 타입은 `feat` `fix` `refactor` `docs` `update`

**기본 브랜치는 `develop`** (main 아님).

**커밋 전 `git diff --cached`로 민감정보를 확인한다.**
`GoogleService-Info.plist`는 `.gitignore`에 있다.

## 이 프로젝트에서 헷갈리기 쉬운 것

- **백엔드는 [`DoSurf-API`](https://github.com/piriram/DoSurf-API)다.**
  `do-surf-functions`는 레거시 초기 사본이다. Cloud Run 서비스명이 `do-surf-functions`라
  헷갈리기 쉬우니 주의. DoSurf 관련 서버 작업은 별도 언급이 없어도 `DoSurf-API`를 대상으로 한다
- **스택이 섞여 있다.** iOS는 UIKit + RxSwift + Firestore + CoreData,
  워치 앱(`DoSurfWatch Watch App`)은 SwiftUI
- 워치 핵심 파일: `SurfWorkoutManager.swift`(HealthKit 세션), `WatchConnectivityManager.swift`(동기화)
- **`enableWaterLock()` 호출은 없다.** 서핑은 수면 활동이라 넣지 않았다

## 디자인 시스템

현재 파일: `DoSurfApp/Core/Extensions/` 의
`DesignSystem+Colors.swift`, `DesignSystem+Typography..swift`(파일명 점 2개 오타), `FontSize.swift`

알려진 문제 — 손댈 일이 있으면 참고:
- 색 이름이 용도가 아니라 색깔이다 (파랑 계열만 7개). 다크모드 대응 없음
- `applyStyle`에 순서 함정이 있다. 스타일을 먼저 주고 `label.text`를 나중에 넣으면
  자간·행간이 조용히 사라진다
- `FontSize` enum이 `TypographySystem`과 중복이다
- 오타: `lableBlack`. `.heading2Medium`의 `name`이 "Heading2 Bold",
  `.subheadingBold`와 `.subheadingMedium`의 `name`이 둘 다 "Subheading Bold"

[piri-design-system](https://github.com/piriram/piri-design-system)으로 이관 예정이지만
**두섭이는 라이브 앱이라 이관 순서상 마지막이다.** 지금 서둘러 바꾸지 않는다.

## 문서 규칙

`CLAUDE.md` 는 이 파일(`AGENTS.md`)로 향하는 심볼릭 링크다. **내용은 `AGENTS.md` 만 수정한다.**
