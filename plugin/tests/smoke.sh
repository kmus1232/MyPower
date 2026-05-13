#!/usr/bin/env bash
# mypower v1 smoke test — plugin install/uninstall + skills/agents 인식 + hook 차단 동작
# v1 빌드 step별로 점진 확장:
#   - Step 0: plugin marketplace add / install / uninstall + skills·agents 인식 grep
#   - Step 5: hook script 실행 + destructive 패턴 stub → exit 1 + stderr 메시지 검증
#   - Step 13: 6 lifecycle 통합 (운영자 토이 프로젝트로 별도 검증, smoke.sh는 정적 검증만)

set -euo pipefail

# --- 사전 가드 ---
if ! command -v claude >/dev/null 2>&1; then
    echo "FAIL: claude CLI 미설치 — PATH 확인" >&2
    exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "FAIL: jq 미설치 — manifest 검증 도구 필요" >&2
    exit 1
fi

# --- 분기점 1a: plugin 명령 존재 사전 검증 (spec §4.2 NOTE 박스 인용) ---
echo "[1a] claude plugin --help 출력 확인"
claude plugin --help 2>&1 | grep -E "update|install|uninstall" >/dev/null || {
    echo "FAIL: claude plugin 명령 변경됨 — fallback ADR 필요 (docs/adrs/YYYY-MM-DD-plugin-cmd-fallback.md)" >&2
    exit 1
}

# --- manifest 정적 검증 ---
# tests/smoke.sh 기준 디렉토리 anchor: PLUGIN_DIR = tests/.. = plugin/ / ROOT_DIR = plugin/.. = repo root
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT_DIR="$(cd "${PLUGIN_DIR}/.." && pwd)"

echo "[2] plugin/.claude-plugin/plugin.json 6필드 검증"
jq -e '.name and .version and .description and .author and .repository and .license' "${PLUGIN_DIR}/.claude-plugin/plugin.json" >/dev/null \
    || { echo "FAIL: plugin.json 필드 누락" >&2; exit 1; }

echo "[3] root .claude-plugin/marketplace.json 5필드 + source 검증 (spec §4.1 minimal schema)"
jq -e '.name and .description and .owner and (.plugins[0].name) and (.plugins[0].source == "./plugin")' "${ROOT_DIR}/.claude-plugin/marketplace.json" >/dev/null \
    || { echo "FAIL: marketplace.json 필드 누락 또는 source != \"./plugin\"" >&2; exit 1; }

echo "[4] hooks.json PreToolUse Bash matcher 검증"
jq -e '.hooks.PreToolUse[0].matcher == "Bash"' "${PLUGIN_DIR}/hooks/hooks.json" >/dev/null \
    || { echo "FAIL: hooks.json matcher 누락" >&2; exit 1; }
jq -e '.hooks.PreToolUse[0].hooks[0].command | contains("applying-approval-gate.sh")' "${PLUGIN_DIR}/hooks/hooks.json" >/dev/null \
    || { echo "FAIL: hooks.json command 인용 누락" >&2; exit 1; }

# --- plugin install/uninstall 흐름 ---
echo "[5] /plugin marketplace add → install → uninstall 흐름"
echo "    수동 검증 항목 — 운영자가 Claude Code에서 다음 명령 실행 후 출력 캡처:"
echo "    /plugin marketplace add ${ROOT_DIR}"
echo "    /plugin install mypower@mypower-dev"
echo "    ls ~/.claude/plugins/ | grep mypower"
echo "    /plugin uninstall mypower@mypower-dev"
echo "    ls ~/.claude/plugins/ | grep mypower   # 0줄 기대"
echo "    위 5개 명령 출력 인용은 Step 0 검증 절차에 별도 기록"

echo "PASS: Step 0 정적 검증 완료. plugin install 흐름은 운영자 수동 검증 필요."
