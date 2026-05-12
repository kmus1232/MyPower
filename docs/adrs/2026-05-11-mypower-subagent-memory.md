# ADR — mypower 12 페르소나에 sub-agent persistent memory 도입

> 작성: 2026-05-11 | 상태: 채택 | 관련 spec: `docs/specs/2026-05-09-mypower-design.md` §4.1, §7.2 | 변경 이력 관리: `2026-05-11-mypower-changelog-policy.md` 적용 첫 사례

## 1. 컨텍스트

Claude Code 공식 문서 [sub-agents — Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)에서 sub-agent에 `memory` frontmatter 필드를 제공. 활성 시 sub-agent가 대화 간 누적 학습을 유지할 수 있는 디렉토리 접근권 + `MEMORY.md` auto-load + Read/Write/Edit tools 자동 활성화.

mypower의 12 페르소나 reviewer(`agents/<lens>-reviewer.md`)는 PR 리뷰·spec 평가·plan 평가 시 lens별 finding 생성. 운영자가 mypower를 사용하는 동안:
- 같은 lens가 매번 처음부터 검토 — 이전에 잡은 패턴·재발 이슈를 기억 못함
- 한 프로젝트에서 본 보안·관측성·아키텍처 패턴이 다음 호출에 전이되지 않음
- 운영자가 finding을 직접 검토·수정 → 같은 lens가 다음에 또 비슷한 finding 반복 가능성

운영자 결정(v3.13 review 통과 직후):

> "각 에이전트가 메모리를 갖도록 설정 추가하자"

## 2. 결정

**12 페르소나 reviewer 중 도메인 invariant 2명은 `memory: user`, 나머지 10명은 `memory: project`** (v3.14 운영자 결정 — 초안 일괄 `project`에서 격상):

| scope | 페르소나 | 근거 |
|---|---|---|
| `user` | `ambiguity-hunter`, `tech-currency-reviewer` | 도메인 무관 lens (언어 자체 모호함 검사 / 라이브러리 deprecation 검사) — cross-project 패턴 누적이 의미 있음 |
| `project` | 나머지 10명 (spec-compliance, code-quality, architect, security, observability, completeness, scope-clarity, change-impact, rollback, safety-checks) | 도메인·프로젝트 종속 lens — 한 프로젝트 패턴이 다른 프로젝트로 잘못 전이되지 않게 격리 |

agents/<lens>-reviewer.md frontmatter:

```yaml
---
name: <persona-name>
description: <한국어 트리거 + 영문 Use when>.
tools: Read, Glob, Grep, Bash
model: sonnet
memory: project  # ambiguity-hunter·tech-currency-reviewer 는 user
---
```

저장 위치:
- `project` scope → `.claude/agent-memory/<persona-name>/MEMORY.md` (운영자 프로젝트 작업 디렉토리)
- `user` scope → `~/.claude/agent-memory/<persona-name>/MEMORY.md` (운영자 홈 — 모든 프로젝트 공유)

## 3. 의사결정 근거

### 3.1 scope 선택 — `project` default

| scope | 위치 | mypower 적합성 |
|---|---|---|
| `user` | `~/.claude/agent-memory/<name>/` | 모든 프로젝트 통합. 도메인 invariant 패턴(예: TDD Rationalizations 표) 누적에 좋지만, project-specific 노이즈 우려 |
| `project` | `.claude/agent-memory/<name>/` | 프로젝트별 격리. 한 프로젝트의 보안·관측 패턴이 다른 프로젝트로 잘못 전이되지 않음. git 버전 관리 가능 → 팀 공유 |
| `local` | `.claude/agent-memory-local/<name>/` | 프로젝트별 격리 + git 미체크인. 운영자 개인 메모만 |

**`project` 채택 근거**:
- mypower 페르소나의 finding은 대부분 codebase 패턴·아키텍처·보안 이슈 기반 — 프로젝트 도메인에 종속적
- git 버전 관리 가능 → 운영자가 본인 dotfiles + 프로젝트 양쪽에서 메모리 누적 확인 가능
- 외부 사용자(fork·marketplace 받는 사람)도 본인 프로젝트의 .claude/agent-memory/로 자연스럽게 확장

`user` 적용 — v3.14 운영자 결정으로 즉시 격상:
- `ambiguity-hunter` (언어 자체 검사 — 도메인 무관)
- `tech-currency-reviewer` (라이브러리 deprecation — 도메인 일부 무관)
- `tdd`는 페르소나가 아니라 sub-process 스킬이므로 본 결정 범위 외

### 3.2 mypower 페르소나 두 층 구조와의 정합

§7.2 페르소나 두 층 구조:
- 1층 = `agents/<name>.md` frontmatter + Iron Law (체크리스트 Read 강제)
- 2층 = `references/persona-checklists/<name>.md` (상세 체크리스트)

memory는 **3층으로 추가**:
- 3층 = `.claude/agent-memory/<persona-name>/MEMORY.md` (운영 중 누적된 패턴·재발 이슈)

1층 system prompt는 2층 체크리스트 Read 강제 + Iron Law 유지. 공식 docs에 의하면 memory 활성 시 system prompt에 자동으로 메모리 read/write 지시 + `MEMORY.md` 첫 200줄/25KB prepend → 1층 골격 자체는 손대지 않고 frontmatter 한 줄 추가로 3층 활성화.

### 3.3 자동 활성화 tools와 §7.2 `tools` 필드 충돌 검토

공식 docs: "Read, Write, and Edit tools are automatically enabled so the subagent can manage its memory files."

§7.2 페르소나 1층 frontmatter 현재 `tools: Read, Glob, Grep, Bash`. memory 활성화 시 Read는 이미 있고, Write·Edit가 자동 추가됨.

**잠재 위험**: Write·Edit이 페르소나에 부여되면 doubt-driven 격리(§7.2 — reviewer는 spawn 프롬프트가 준 정보만 본다 + 다른 페르소나 결과 못 본다) 원칙에 영향 가능. reviewer가 memory에 본인 finding 외 다른 정보 박을 위험.

**완화**: 페르소나 1층 system prompt 본문에 Iron Law 추가 — "Write·Edit tool은 본인 memory(`.claude/agent-memory/<persona-name>/`) 디렉토리 안에서만 사용. 다른 경로에 Write 시도 시 격리 위반 = finding 무효 처리." spec §7.2 본문에 명시.

### 3.4 메모리 누적 패턴

운영자가 페르소나에 memory 활용을 자연스럽게 요구하도록 1층 frontmatter 본문에 두 줄 추가 (공식 docs Tips 인용):
- 호출 시작: "검토 시작 전 본인 memory의 MEMORY.md를 확인. 이전에 본 유사 패턴·재발 이슈 인용 가능 시 finding에 reference"
- 호출 종료: "검토 종료 시 새로 발견한 패턴·재발 이슈를 MEMORY.md에 누적. `MEMORY.md` 200줄/25KB 한도 시 curate"

## 4. 트레이드오프

| 채택 측면 | 포기한 측면 |
|---|---|
| 페르소나 학습 누적 → 같은 프로젝트에서 lens별 finding 품질 ↑ | 메모리 노이즈·anchoring 위험 (이전 finding이 다음 검토를 편향시킬 수 있음) |
| `project` scope으로 격리 + git 공유 | `user` scope의 cross-project invariant 패턴 학습 기회 (v1.1 후속 검토) |
| Write·Edit 자동 활성화로 페르소나 자율 누적 | doubt-driven 격리 영역 침해 위험 — Iron Law 한 줄 추가로 완화 |
| 공식 표준(`memory:` 필드) 사용으로 fork·외부 사용자 호환 | 운영 초기 메모리 schema가 페르소나 자율 결정 — v1.1에서 일관 schema 검토 가능 |

## 5. 영향 범위 — v3.14 spec 변경

본 ADR 채택과 함께 spec 변경 (변경 이력 관리 정책 ADR 적용 — frontmatter changelog 표 신규 행 없음, 본문 인라인 v3.14 마커 없음):

- §4.1 디렉토리 트리 `agents/` 행 한 줄에 "frontmatter `memory: project` 명시 — 페르소나 3층(누적 학습)" 인용
- §7.2 페르소나 1층 골격 frontmatter 예시에 `memory: project` 필드 추가 + Iron Law 한 줄 추가 (Write/Edit 사용 범위 제한)
- §13 검증 체크리스트에 sub-agent memory 항목 추가 — 12 페르소나 frontmatter에 `memory: project` 누락 0건 grep + 격리 Iron Law grep
- frontmatter top 한 줄 "최종 갱신: v3.14" 갱신

## 6. anchoring 방지 — 운영 초기 모니터

§5.5 평가 점수 루프 §5.5.5(페르소나 anchoring 방지 — 옵션 c)와 정합. 메모리 누적이 anchoring 위험 ↑ 가능성. v1 운영 초기에 다음 사례 모니터:
- 같은 페르소나가 비슷한 finding을 반복적으로 박음 (메모리에 박힌 패턴 그대로 새 코드에 적용)
- 운영자가 finding 거부한 패턴이 메모리에 잔존해 같은 finding 재발

발생 시 운영자가 `.claude/agent-memory/<persona>/MEMORY.md` 직접 편집 → 잘못 누적된 패턴 제거. 빈도 ↑ 시 v1.1에서 페르소나별 메모리 schema 정형화 + curate 자동화 검토.

## 7. 향후 확인 사항

- v1 빌드 step 3(agents/*.md 12개 작성) AC에 `memory: project` frontmatter 명시 + Iron Law 본문 grep 추가
- 운영 초기 1~2개월 후 anchoring 사례 누적 검토 — §14 v1.1 백로그
- 도메인 invariant 페르소나(`ambiguity-hunter`, `tech-currency-reviewer`) `user` scope 격상 후보 검토
- agent-team Phase 2 hybrid 모드에서 memory 동작 — agent-team teammate가 동일 memory 디렉토리 공유하는지 vs teammate별 별도인지 (공식 docs 확인 필요, v1 빌드 smoke.sh에 검증 step 추가)
