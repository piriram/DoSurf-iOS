# CORE Implementation QA Plan

- date: 2026-03-06
- basis: fallback plan created because `CORE_IMPLEMENTATION_QA_PLAN.md` did not exist at execution time
- objective: run release preflight verification and document reproducible outcomes
- scope: iOS app build, watchOS app build, test-action availability, remaining release risks

## 1) Execution Items

1. Run `xcodebuild -list` and `-showdestinations` for environment/scheme validation.
2. Run iOS simulator build for `DoSurfApp`.
3. Run watchOS simulator build for `DoSurfWatch Watch App`.
4. Run `xcodebuild test` on `DoSurfApp` scheme and capture failure reason if blocked.
5. Add reproducible preflight script for repeatable release checks.
6. Produce final developed report with command/result/failure-cause/workaround.

## 2) Constraints

- Do not claim measured values without command evidence.
- Keep code change minimal and reversible.
- Record all failures with root cause and rerun command.

## 3) Pass/Fail Criteria

- PASS:
  - iOS build succeeds.
  - watchOS build succeeds.
  - all commands/log paths are reproducible from repo root.
- CONDITIONAL:
  - test command may fail if scheme has no test action; this must be documented with workaround.

## 4) Planned Outputs

- `scripts/release_preflight.sh`
- `collected_plan_watch/plan_related/qa_logs/*`
- `collected_plan_watch/plan_related/CORE_IMPLEMENTATION_QA_DEVELOPED.md`
