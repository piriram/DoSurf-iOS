# CORE Implementation QA Developed Report

- 작성일시: 2026-03-06 21:54 (KST)
- 수행 기준: `collected_plan_watch/plan_related/CORE_IMPLEMENTATION_QA_PLAN.md`
- 수치 표기 원칙: `[측정]`은 실제 명령 실행 결과, `[추정]`은 미측정 예상

## 1) 수행한 개발/보완 항목

1. 누락된 QA 선행 계획 문서 보완
- 신규: `collected_plan_watch/plan_related/CORE_IMPLEMENTATION_QA_PLAN.md`
- 내용: 실행 항목, 제약, pass/fail 기준, 산출물 경로를 최소 구조로 정의

2. 릴리즈 전 검증 자동화 스크립트 추가
- 신규: `scripts/release_preflight.sh`
- 기능:
  - 스킴/목적지 확인(`-list`, `-showdestinations`)
  - iOS/watchOS 빌드 실행
  - iOS test 실행 및 실패 원인 추출
  - 단계별 로그 + 요약 파일 자동 저장

3. 재현 로그 생성
- 신규 폴더/파일:
  - `collected_plan_watch/plan_related/qa_logs/summary_20260306_215156.md`
  - `collected_plan_watch/plan_related/qa_logs/scheme_list_20260306_215156.log`
  - `collected_plan_watch/plan_related/qa_logs/show_destinations_20260306_215156.log`
  - `collected_plan_watch/plan_related/qa_logs/ios_build_20260306_215156.log`
  - `collected_plan_watch/plan_related/qa_logs/watch_build_20260306_215156.log`
  - `collected_plan_watch/plan_related/qa_logs/ios_test_20260306_215156.log`

## 2) 수행한 검증(명령어, 결과, 실패 원인)

1. 환경/스킴 확인
- 명령어: `xcodebuild -list -project DoSurfApp.xcodeproj`
- 결과: `[측정] 성공(exit 0)`
- 비고: 빌드 대상/스킴 식별 가능

2. 목적지 확인
- 명령어: `xcodebuild -project DoSurfApp.xcodeproj -scheme DoSurfApp -showdestinations`
- 결과: `[측정] 성공(exit 0)`
- 비고: `iPhone 16 (iOS 18.6)` 포함 시뮬레이터 목적지 확인

3. iOS 빌드
- 명령어: `xcodebuild -project DoSurfApp.xcodeproj -scheme DoSurfApp -configuration Debug -destination 'generic/platform=iOS Simulator' build`
- 결과: `[측정] 성공(exit 0, BUILD SUCCEEDED)`

4. watchOS 빌드
- 명령어: `xcodebuild -project DoSurfApp.xcodeproj -scheme 'DoSurfWatch Watch App' -configuration Debug -destination 'generic/platform=watchOS Simulator' build`
- 결과: `[측정] 성공(exit 0, BUILD SUCCEEDED)`

5. iOS 테스트
- 명령어: `xcodebuild -project DoSurfApp.xcodeproj -scheme DoSurfApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' test`
- 결과: `[측정] 실패(exit 66)`
- 실패 원인: `Scheme DoSurfApp is not currently configured for the test action.`
- 재현: 위 명령 단독 실행 시 동일 메시지로 반복 실패
- 우회안(즉시):
  - 릴리즈 게이트를 `build` 중심으로 유지하고, 테스트는 수동 시나리오 체크리스트로 보강
- 근본해결(후속):
  - `DoSurfApp` 스킴의 Test action 활성화
  - 최소 unit test target(또는 UI smoke test target) 연결 후 CI에 `xcodebuild test` 추가

6. 정적 검증 도구 가용성 확인
- 명령어: `command -v swiftlint || true`
- 결과: `[측정] 경로 미검출(설치/설정 없음)`
- 우회안: 현재는 `xcodebuild build` 경고/오류 기반 검증 유지

## 3) 변경 파일 목록 + 핵심 diff 요약

1. `collected_plan_watch/plan_related/CORE_IMPLEMENTATION_QA_PLAN.md` (신규)
- 핵심 diff 요약:
  - 누락 선행 계획을 최소 구조로 작성
  - 실행 항목/제약/pass-fail/산출물을 명시

2. `scripts/release_preflight.sh` (신규)
- 핵심 diff 요약:
  - 릴리즈 전 필수 검증 명령을 순차 실행
  - 단계별 로그 파일 분리 저장
  - 요약 markdown 자동 생성(실패 step/first error 포함)

3. `collected_plan_watch/plan_related/qa_logs/*` (신규 실행 산출물)
- 핵심 diff 요약:
  - 실제 실행 결과(raw log + summary) 보존
  - 실패 단계가 `ios_test`임을 재현 가능 형태로 기록

## 4) 남은 리스크/즉시 후속 액션

1. 리스크: 자동 테스트 게이트 부재
- 상태: `[측정] xcodebuild test 불가(스킴 test action 미구성)`
- 즉시 액션: 스킴 test action 활성화 여부 점검

2. 리스크: 정적 분석 도구 미연결
- 상태: `[측정] swiftlint 경로 없음`
- 즉시 액션: 팀 표준 린트 도구 채택 여부 결정 후 CI 연결

3. 리스크: 현재 preflight는 local 실행 전제
- 상태: `[측정] 로컬 재현 가능, CI 파이프라인은 미연결`
- 즉시 액션: CI job에 `scripts/release_preflight.sh` 이식(시뮬레이터 목적지 고정 포함)

## 5) 릴리즈 전 체크리스트(체크박스)

- [x] QA 계획 문서 존재/갱신 확인 (`CORE_IMPLEMENTATION_QA_PLAN.md`)
- [x] iOS Debug 빌드 성공
- [x] watchOS Debug 빌드 성공
- [x] 검증 로그/요약 산출물 저장 경로 확인
- [x] 실패 항목의 원인/재현/우회안 기록
- [ ] `DoSurfApp` 스킴 Test action 활성화
- [ ] 최소 1개 테스트 타깃 연결 후 `xcodebuild test` 통과
- [ ] 정적 검증(slint/swiftlint 등) 도구 및 규칙 확정
- [ ] CI에 preflight 자동화 연결
