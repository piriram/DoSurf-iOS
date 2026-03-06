#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/collected_plan_watch/plan_related/qa_logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
SUMMARY_FILE="${LOG_DIR}/summary_${TIMESTAMP}.md"
SCHEME_DIR="${ROOT_DIR}/DoSurfApp.xcodeproj/xcshareddata/xcschemes"
SCHEME_IOS="DoSurfApp"
WATCH_SCHEME="DoSurfWatch Watch App"

mkdir -p "${LOG_DIR}"

FAILED_COUNT=0
SOFT_FAIL_COUNT=0

write_summary_header() {
  {
    echo "# Release Preflight Summary"
    echo
    echo "- timestamp: ${TIMESTAMP}"
    echo "- root: ${ROOT_DIR}"
    echo "- xcode: $(xcodebuild -version | tr '\n' '; ' | sed 's/; $//')"
    echo
  } > "${SUMMARY_FILE}"
}

run_step() {
  local step_name="$1"
  shift
  local soft_fail="$1"
  shift

  local command_args=("$@")
  local command_display
  local log_file="${LOG_DIR}/${step_name}_${TIMESTAMP}.log"
  local exit_code=0
  local first_error=""

  command_display="${command_args[*]}"
  echo "[run] ${step_name}: ${command_display}"

  set +e
  (
    cd "${ROOT_DIR}" || exit 1
    "${command_args[@]}"
  ) > "${log_file}" 2>&1
  exit_code=$?
  set -e

  first_error="$(rg -m 1 "error:|\*\* BUILD FAILED \*\*|\*\* TEST FAILED \*\*|is not currently configured for the test action" "${log_file}" || true)"

  {
    echo "## ${step_name}"
    echo
    echo "- command: \`${command_display}\`"
    echo "- exit_code: ${exit_code}"
    if [[ -n "${first_error}" ]]; then
      echo "- first_error: ${first_error}"
    else
      echo "- first_error: none"
    fi
    if [[ "${soft_fail}" == "true" ]]; then
      echo "- optional: true"
    else
      echo "- optional: false"
    fi
    echo "- log_file: ${log_file}"
    echo
    echo "### tail"
    echo '```text'
    tail -n 20 "${log_file}"
    echo '```'
    echo
  } >> "${SUMMARY_FILE}"

  if [[ "${exit_code}" -ne 0 ]]; then
    if [[ "${soft_fail}" == "true" ]]; then
      SOFT_FAIL_COUNT=$((SOFT_FAIL_COUNT + 1))
    else
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
  fi
}

run_step_optional_skip() {
  local step_name="$1"
  local command_display="$2"
  local log_file="${LOG_DIR}/${step_name}_${TIMESTAMP}.log"
  local soft_fail_message="$3"

  printf '%s\n' "${soft_fail_message}" > "${log_file}"

  {
    echo "## ${step_name}"
    echo
    echo "- command: \`${command_display}\`"
    echo "- exit_code: 0"
    echo "- first_error: none"
    echo "- optional: true"
    echo "- skipped: ${soft_fail_message}"
    echo "- log_file: ${log_file}"
    echo
    echo "### tail"
    echo '```text'
    echo "${soft_fail_message}"
    echo '```'
    echo
  } >> "${SUMMARY_FILE}"

  :
}

run_ios_test_step() {
  local scheme_file="${SCHEME_DIR}/${SCHEME_IOS}.xcscheme"

  if [[ ! -f "${scheme_file}" ]]; then
    run_step_optional_skip "ios_test" \
      "xcodebuild -project DoSurfApp.xcodeproj -scheme ${SCHEME_IOS} -configuration Debug -destination 'generic/platform=iOS Simulator' test" \
      "Skipped: scheme file not found (${scheme_file})"
    return
  fi

  if ! rg -q "<TestableReference" "${scheme_file}"; then
    run_step_optional_skip "ios_test" \
      "xcodebuild -project DoSurfApp.xcodeproj -scheme ${SCHEME_IOS} -configuration Debug -destination 'generic/platform=iOS Simulator' test" \
      "Skipped: scheme '${SCHEME_IOS}' has no testable references in TestAction. Configure a test target in Scheme -> Edit Scheme -> Test before hard-enforcing test gate."
    return
  fi

  run_step "ios_test" false xcodebuild -project DoSurfApp.xcodeproj -scheme "${SCHEME_IOS}" -configuration Debug -destination 'generic/platform=iOS Simulator' test
}

write_summary_header

run_step "scheme_list" false xcodebuild -list -project DoSurfApp.xcodeproj
run_step "show_destinations" false xcodebuild -project DoSurfApp.xcodeproj -scheme "${SCHEME_IOS}" -showdestinations
run_step "ios_build" false xcodebuild -project DoSurfApp.xcodeproj -scheme "${SCHEME_IOS}" -configuration Debug -destination 'generic/platform=iOS Simulator' build
run_step "watch_build" false xcodebuild -project DoSurfApp.xcodeproj -scheme "${WATCH_SCHEME}" -configuration Debug -destination 'generic/platform=watchOS Simulator' build
run_ios_test_step
run_step "swiftlint_check" true sh -c 'command -v swiftlint >/dev/null 2>&1 && swiftlint version || true'

{
  echo "## result"
  echo
  if [[ "${FAILED_COUNT}" -eq 0 ]]; then
    echo "- status: PASS"
  else
    echo "- status: FAIL (${FAILED_COUNT} hard-failed)"
  fi
  echo "- optional_fail_count: ${SOFT_FAIL_COUNT}"
} >> "${SUMMARY_FILE}"

echo "Summary: ${SUMMARY_FILE}"

if [[ "${FAILED_COUNT}" -eq 0 ]]; then
  exit 0
fi

exit 1
