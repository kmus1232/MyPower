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

v1 빌드 진입 직전. `plugin/` 하위는 빈 골격(`.claude-plugin/` · `agents/` · `references/` · `skills/`).

- **빌드 plan**: [`docs/superpowers/plans/2026-05-11-mypower-v1-build.md`](docs/superpowers/plans/2026-05-11-mypower-v1-build.md) — Step 0~13 순서 실행
- **v1 완료 시 채워질 산출물**:
  - `plugin/skills/` — 7개 (6 lifecycle 슬래시 스킬 + tdd 스킬)
  - `plugin/agents/` — 12 reviewer 페르소나
  - `plugin/references/` — 코어 6개 + persona-checklists 12개
  - `plugin/hooks/` — destructive 패턴 차단 hook
  - `plugin/tests/smoke.sh` — install/uninstall + 인식 + hook 검증

## 의사결정 누적 (단일 출처)

| 종류 | 파일 | 비고 |
|------|------|------|
| spec | [`docs/specs/2026-05-09-mypower-design.md`](docs/specs/2026-05-09-mypower-design.md) | v3.15 — 설계의 단일 출처 |
| plan | [`docs/superpowers/plans/2026-05-11-mypower-v1-build.md`](docs/superpowers/plans/2026-05-11-mypower-v1-build.md) | v1 빌드 Step 0~13 |
| ADR | [`docs/adrs/2026-05-11-mypower-plugin-adopt.md`](docs/adrs/2026-05-11-mypower-plugin-adopt.md) | plugin 채택 결정 |
| ADR | [`docs/adrs/2026-05-11-mypower-subagent-memory.md`](docs/adrs/2026-05-11-mypower-subagent-memory.md) | 서브에이전트 메모리 정책 |
| ADR | [`docs/adrs/2026-05-11-mypower-changelog-policy.md`](docs/adrs/2026-05-11-mypower-changelog-policy.md) | 변경 이력 정책 |
| ADR | [`docs/adrs/2026-05-12-mypower-docs-plugin-split.md`](docs/adrs/2026-05-12-mypower-docs-plugin-split.md) | docs/ vs plugin/ 분리 |

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

- **신규 파일 생성 전** spec(v3.15) · 관련 ADR에서 결정 존재 여부 먼저 grep. 결정 충돌 시 spec 갱신 또는 새 ADR 작성 — 즉흥 결정 금지
- **`plugin/` 변경 시**: placeholder 정책 준수 + Step 단위 acceptance criteria + 검증 grep 통과 + smoke.sh 통과
- **`docs/` 변경 시**: 의사결정 누적 흐름 유지. 임시 메모·handoff는 repo 외 보관
- **commit 메시지**: 한국어, 의도(왜)를 한 줄로 앞에 둔다
- **plugin install 검증**: `~/.claude/plugins/cache/<marketplace>/<plugin>/docs/` 부재 grep 필수 — `source: "./plugin"`이 docs/ 제외했는지 확인
- **빌드 plan은 Step 순서 준수**: Step 0~13 건너뛰지 않음. 각 Step의 acceptance criteria + 검증 grep 통과를 다음 Step 진입 조건으로 본다
