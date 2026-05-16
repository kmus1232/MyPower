# MyPower — Claude Code 작업 컨텍스트

본 파일은 본 repo에서 Claude Code 세션이 시작될 때 자동 로드되어 작업 컨텍스트를 주입한다.
프로젝트 전반·설치·결정 누적은 [README.md](README.md)와 `docs/`를 본다.

## 정체성

Claude Code 운영자용 멀티 에이전트 스킬 프레임워크 — toy / educational. 단, **외부 사용자가 `/plugin marketplace add <owner>/MyPower`로 받아 쓸 수 있는 범용 plugin 배포가 목표**다. 본 운영자 단독 사용 한정이 아니다.

작업 시 항상 **외부 사용자 시점**으로 검토한다.

## 두 영역 (반드시 구분)

| 영역 | 역할 | 노출 경로 |
|------|------|-----------|
| `plugin/` | Claude Code plugin source | `/plugin install` → `~/.claude/plugins/cache/`로 복사 |
| `docs/` | 의사결정 누적 (spec · plan · ADR) | `git clone` 시 학습 자료로 노출. **plugin install엔 무관** |

분리 근거: [docs-plugin-split ADR](docs/adrs/2026-05-12-mypower-docs-plugin-split.md). 루트 `.claude-plugin/marketplace.json`의 `plugins[0].source: "./plugin"`이 이 분리를 강제한다. 변경 금지.

## 작성 정책 — 운영자 개인정보 평문 금지 (Iron Law)

**git에 commit되는 모든 파일**(plugin/ · docs/ · README.md · 본 CLAUDE.md 등)에 다음을 평문 노출하지 않는다. 발견 즉시 placeholder로 치환한다:

| 노출 항목 | placeholder |
|-----------|-------------|
| 이름 | `<owner-name>` |
| 소속 | `<owner-org>` |
| 직무 | `<owner-role>` |
| 이메일 | `<owner-email>` |
| GitHub handle | `<owner>` 또는 `<owner-handle>` |
| 운영자 macOS 절대 경로 | `<HARNESS>` 또는 상대 경로 |

**ADR이 평문 노출을 "수용 결정"했더라도 범용 배포 의도가 우선한다.** 평문 유지는 운영자가 명시 동의한 경우에만.

본 운영자 인수인계용 임시 문서(handoff 등)는 본 repo 안에 commit하지 않는다 — 로컬 노트·brain vault 등 별도 위치에 보관.

## 현재 상태

v1 빌드 Step 0~3 완료 + Step 0~3 산출물 감사 fix 반영. 다음 = Step 4 (4 checklist — plan/verification/pr-review/applying).

| Step | 산출 | 기준 commit |
|---|---|---|
| 0 | plugin manifest + smoke.sh 정적 검증 | d451f1f |
| 1 | references 코어 7개 | 1515555 |
| 2 | persona-checklists 12개 (2층) | 5632aeb |
| 3 | agents 12개 (1층) | 477456f |
| audit-fix | Step 0~3 감사 후 Critical/Important 개선 일괄 반영 | (본 브랜치) |

audit-fix 반영 내역:
- **C1**: `plugin/hooks/applying-approval-gate.sh` stub 배치 (Step 5 미작성 동안 install 후 Bash 정지 위험 차단). Step 5 진입 시 실제 검출 로직으로 교체
- **C2**: `docs/adrs/2026-05-11-mypower-plugin-adopt.md`의 `mypower@mypower` 오타 3건 → `mypower@mypower-dev` 정정
- **I1**: 12 agent `# 검토 lens` 섹션에 페르소나별 "특히:" 라인 1줄 추가 — 1차 컨텍스트 차별화 강화 (각 파일 41 → 42줄)
- **I2**: `tech-currency-reviewer` frontmatter `tools`에 `WebFetch` 추가 (lens가 공식 docs 조회 명시)
- **I4**: `adr-template.md`에 최소 깊이 가이드 표 + worked example 인용 / `decision-catalog-template.md` 각 §1~§6 default 옆에 "근거:" 1줄
- **I5**: `rollback.md` composite 손실 시나리오(§E + 함정 4) / `tech-currency.md` MCP 결과 파싱 알고리즘(§C.1) / `completeness.md` needs_context 시뮬레이션 절차(§D.1·D.2)
- **N1·N2**: README install 경로 `~/Projects/MyPower` → `<install-dir>` placeholder + 명시 안내 / plan Step 1.7 grep에 post-build 재실행용 예외 4건 추가 (`step{N}.md`·`{slug}-tech-{n}`·ambiguity.md self-meta·completeness.md grep 패턴 인용)

- **빌드 plan**: [`docs/superpowers/plans/2026-05-11-mypower-v1-build.md`](docs/superpowers/plans/2026-05-11-mypower-v1-build.md) — Step 0~13 순서 실행. 각 Step acceptance criteria + 검증 grep 통과를 다음 Step 진입 조건으로 본다
- **남은 산출물 (Step 4~13)**:
  - `plugin/references/` — checklist 4개 (Step 4)
  - `plugin/hooks/applying-approval-gate.sh` — destructive 패턴 차단 본체 (Step 5 — 현재는 stub 상태)
  - `plugin/skills/` — 7개 (Step 6~12, 6 lifecycle 슬래시 스킬 + tdd sub-process)
  - 통합 테스트 — 6 lifecycle + tdd + hook 차단 동작 1회씩 검증 (Step 13)
- **v1 전체 종료 시점**에 본 섹션을 다시 압축한다

## 의사결정 누적 (단일 출처)

| 종류 | 파일 | 비고 |
|------|------|------|
| spec | [`docs/specs/2026-05-09-mypower-design.md`](docs/specs/2026-05-09-mypower-design.md) | 설계의 단일 출처 |
| plan | [`docs/superpowers/plans/2026-05-11-mypower-v1-build.md`](docs/superpowers/plans/2026-05-11-mypower-v1-build.md) | v1 빌드 Step 0~13 |
| ADR | [`docs/adrs/2026-05-11-mypower-plugin-adopt.md`](docs/adrs/2026-05-11-mypower-plugin-adopt.md) | plugin 채택 결정 |
| ADR | [`docs/adrs/2026-05-11-mypower-subagent-memory.md`](docs/adrs/2026-05-11-mypower-subagent-memory.md) | 서브에이전트 메모리 정책 |
| ADR | [`docs/adrs/2026-05-11-mypower-changelog-policy.md`](docs/adrs/2026-05-11-mypower-changelog-policy.md) | 변경 이력 정책 |
| ADR | [`docs/adrs/2026-05-12-mypower-docs-plugin-split.md`](docs/adrs/2026-05-12-mypower-docs-plugin-split.md) | docs/ vs plugin/ 분리 |
| ADR | [`docs/adrs/2026-05-13-ambiguity-protocol-adopt.md`](docs/adrs/2026-05-13-ambiguity-protocol-adopt.md) | 모호함 처리 규칙(ARP) 채택 + MVP 강제 메커니즘 설계 (hook·검증 에이전트 v1.1+) |
| ADR | [`docs/adrs/2026-05-17-autonomous-execution-strategy.md`](docs/adrs/2026-05-17-autonomous-execution-strategy.md) | `/goal`-style 자율 실행 전략 — v1.1+ 4종 hook(`prompt` type, Pre/PostToolUse·Stop·SubagentStop) 통합. ARP T-010 해소 |
| reference | [`docs/references/2026-05-16-goal-command-internals.md`](docs/references/2026-05-16-goal-command-internals.md) | Claude Code `/goal` 내부 동작 분석 — 4종 hook 매트릭스의 reference 모델 |

새 결정은 spec 갱신 또는 ADR 추가로 누적한다. README나 본 CLAUDE.md 본문에 결정을 박지 않는다.

## 자주 쓰는 명령

```bash
# 운영자 본인 설치 (시나리오 A — 로컬 working copy)
/plugin marketplace add <repo-root>
/plugin install mypower@mypower-dev

# 외부 사용자 설치 (시나리오 B — GitHub)
/plugin marketplace add <owner>/MyPower
/plugin install mypower@mypower-dev

# v1 빌드 중 정적 검증
plugin/tests/smoke.sh
```

marketplace 이름은 `mypower-dev`이며, install 명령은 항상 `mypower@mypower-dev` 형식이다. `mypower@mypower`로 잘못 입력하면 실패한다.

자세한 시나리오 A/B/C는 spec §4.2 또는 [README.md](README.md) 참조.

## 작업 시 gotcha

- **신규 파일 생성 전** spec · 관련 ADR에서 결정 존재 여부 먼저 grep. 결정 충돌 시 spec 갱신 또는 새 ADR 작성 — 즉흥 결정 금지
- **`plugin/` 변경 시**: placeholder 정책 준수 + Step 단위 acceptance criteria + 검증 grep 통과 + smoke.sh 통과
- **`docs/` 변경 시**: 의사결정 누적 흐름 유지. 임시 메모·handoff는 repo 외 보관
- **commit 메시지**: 한국어, 의도(왜)를 한 줄로 앞에 둔다
- **plugin install 검증**: `~/.claude/plugins/cache/<marketplace>/<plugin>/docs/` 부재 grep 필수 — `source: "./plugin"`이 docs/ 제외했는지 확인
- **빌드 plan은 Step 순서 준수**: Step 0~13 건너뛰지 않음. 각 Step의 acceptance criteria + 검증 grep 통과를 다음 Step 진입 조건으로 본다
- **운영자에게 의견·결정 묻는 모든 메시지는 가독성 우선**: 압축 표현·영어 약어 ID·하위 reviewer 산출물 jargon 패스스루 금지. 운영자가 별도 해석 없이 즉시 답할 수 있는 형태로 작성. 풀이 필요한 용어는 본문 내 첫 등장 시 풀어 쓴다
- **라이프사이클 슬래시 스킬 빌드·운영 시 모호함 만나면** `plugin/references/ambiguity-protocol.md` 4단계 따름. v1 MVP 단계는 슬래시 스킬 프롬프트만 강제, 검증 에이전트는 v1.1+ 예정
