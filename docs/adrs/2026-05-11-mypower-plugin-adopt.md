# ADR — mypower plugin 형식 채택 (v3 결정 뒤집기) + 운영자 식별자 일반화

> 작성: 2026-05-11 | 상태: 채택 | 관련 spec: `docs/specs/2026-05-09-mypower-design.md` v3.13

## 1. 컨텍스트

mypower 설계 v3 차수에서 "Claude Code plugin 폐기 → GitHub repo + `~/.claude/`로 symlink install" 결정. 근거:
- dotfiles 패턴 (git pull로 즉시 반영, install 절차 1회만)
- plugin marketplace 배포 의도 없음 — 운영자 본인용
- plugin 시스템이 superpowers 채택 시점 기준 미성숙

v3.4~v3.12 동안 install.sh가 symlink 7개(skills) + 12개(agents) 생성 + `~/.claude/settings.json` 직접 편집(hooks 등록) + `~/.zshrc`에 `$MYPOWER_HOME` 환경변수 추가하는 형태로 발전.

v3.12 review 직후 운영자가 직관 제기:

> "install해서 symlink로 관리하는 게 Claude Code plugin 시스템과 좀 다르지 않아? plugin 방식이 더 관리하기 좋지 않을까."

## 2. 결정

**v3.13에서 plugin 형식 채택 — v3 결정 뒤집기**:
- `install.sh` 폐기 → `.claude-plugin/plugin.json` (manifest)
- 직접 settings.json 편집 폐기 → `hooks/hooks.json` (plugin manifest 표준)
- `$MYPOWER_HOME` 환경변수 폐기 → `${CLAUDE_PLUGIN_ROOT}` (Claude Code가 plugin install 시 자동 설정)
- symlink 생성 폐기 → plugin 디렉토리 하위 `skills/`·`agents/`를 Claude Code가 자동 인식
- 갱신 흐름: `git pull` + `claude plugin update mypower@mypower-dev` (alias로 한 줄 명령화 가능). install 진입점은 로컬 marketplace 등록 1회 (`/plugin marketplace add <install-dir>`) → `/plugin install mypower@mypower-dev`
- **운영자 본인 default 시나리오 = A (로컬 git working copy)**. 본인이 plugin owner + 사용자이므로 코드 편집·commit·push 가능한 working copy가 필수. 외부 사용자(fork·marketplace 받는 사람)는 시나리오 B(GitHub repo 직접 marketplace add — 로컬 working copy 없음). 개발 중 빠른 테스트는 시나리오 C(`claude --plugin-dir`)로 install 미발생

**부수 결정 — 운영자 식별자 일반화 (배포 가능성 확보)**:
- 운영자 본인 식별자(이름·회사·이메일·도메인 명시) 제거 → "Claude Code 운영자"로 일반화
- SRE/플랫폼 도메인 가정은 references default 영역에만 남김 (fork 시 갈아끼우는 영역)
- 페르소나 system prompt도 회사명 → "mypower 검토 팀"으로 일반화

## 3. 의사결정 근거

### 3.1 운영자 직관 — symlink + install.sh는 plugin 시스템 흉내내기

본질적으로 mypower install.sh가 하는 일이 plugin install이 표준화해 해주는 일과 거의 동일:

| install.sh가 하는 일 (v3.12까지) | Claude Code plugin 표준 |
|---|---|
| `~/.claude/skills/mypower-*` symlink 7개 | plugin manifest 디렉토리 하위 `skills/` 자동 인식 |
| `~/.claude/agents/<12명>` symlink 12개 | plugin manifest 디렉토리 하위 `agents/` 자동 인식 |
| `~/.claude/settings.json`에 hook 등록 + 백업 + uninstall 시 mypower-* 만 제거 | `hooks/hooks.json` manifest 등록 + plugin uninstall 시 자동 해제 |
| `~/.zshrc`에 `$MYPOWER_HOME` 추가 | `${CLAUDE_PLUGIN_ROOT}` 자동 설정 |

운영자가 직접 작성·유지보수해야 하는 shell script로 plugin 표준이 보장하는 동작을 재현하는 것. 표준이 보장해주는 영역에서 운영자가 짊어지는 코드·검증·디버깅 부담을 그대로 떠안는 셈.

### 3.2 두 전문가 팀 공수 산정 — ~2시간 합리적

v3.12 검토 시점에 시나리오 A(v3.12 install.sh 방식으로 v1 빌드 → v1.1에서 plugin 마이그레이션)와 시나리오 B(처음부터 plugin 형식 v1 빌드)를 두 가지 별도 산정:

- 시나리오 B 추가 공수 = 약 2시간 (spec 변경 ~1시간 + plugin manifest 작성 ~30분 + smoke.sh 검증 항목 변경 ~30분)
- 시나리오 A 마이그레이션 공수 = v1.1에서 약 4시간 (install.sh + symlink + settings.json 편집 코드 폐기 + 마이그레이션 plan 작성 + 이미 사용 중인 운영자 환경 backout)
- 시나리오 B가 합계 공수 + 운영자 인지 부담 둘 다 우수

### 3.3 dotfiles 패턴 양보 분석 — 1단계 추가는 허용 가능

v3 결정의 핵심 근거였던 "git pull로 즉시 반영":

| 흐름 | v3.12까지 (symlink) | v3.13 (plugin) |
|---|---|---|
| 갱신 | `cd <install-dir> && git pull` (symlink이라 즉시 반영) | `cd <install-dir> && git pull && claude plugin update mypower@mypower-dev` (1단계 추가) |
| alias 한 줄 명령화 | `alias mpup='cd <install-dir> && git pull'` | `alias mpup='cd <install-dir> && git pull && claude plugin update mypower@mypower-dev'` |

alias 한 줄로 동등화 가능. 양보 1단계가 plugin 표준 채택의 이득(hooks 자동 등록 / 환경변수 자동 처리 / marketplace 배포 가능)에 비해 작음.

### 3.4 부수 결정 — 일반화의 동기

운영자가 "이거 플러그인으로 다른 사람도 사용하게 하고싶다" 의사 표시. plugin 형식 자체가 fork·marketplace 배포 경로를 자연스럽게 확보 — 운영자 식별자가 spec·페르소나 prompt·references에 박혀 있으면 fork 시 매번 갈아끼워야 함. 일반화 작업을 plugin 채택과 같은 차수에 묶어 처리하는 게 합리적.

도메인 가정(SRE/플랫폼)은 references default 영역에만 남기고 코어 lifecycle 로직은 도메인 독립. 다른 도메인 운영자는 `decision-catalog-template.md` + §6.1.3 사전 체크리스트 카테고리만 갈아끼우면 사용 가능.

## 4. 트레이드오프 / 포기한 것

| 채택 측면 | 포기한 측면 |
|---|---|
| plugin 표준 hooks 등록 — settings.json 편집 코드 폐기 | install.sh shell script 단순성 (운영자가 한 번에 코드 다 읽을 수 있던 것) |
| `${CLAUDE_PLUGIN_ROOT}` 자동 설정 — `.zshrc` 편집 폐기 | env var 미보장 환경 대비 절대 경로 박는 우회 (plugin 환경 외에서 동작 안 함 — Claude Code 단일 타깃이라 비목표) |
| marketplace 배포 경로 무료 확보 | (없음 — marketplace 배포는 v1.1 백로그였으므로 기각된 옵션 아님) |
| fork·일반화 가능 spec | 운영자 본인 도메인(SRE/MSP) 컨텍스트의 구체성 — 글로벌 CLAUDE.md에 보존됨 (spec에서 제거되어도 본인 워크플로우 손해 없음) |
| `claude plugin update` 1단계 alias로 흡수 | "git pull = 즉시 반영" 슬로건 (실제 흐름은 동등) |

## 5. 영향 범위 — v3.13 spec 변경

- §1.1 운영자 컨텍스트 (식별자 제거 + 일반화 + plugin 형식 언급)
- §1.4 분류 A 응답 (TDD framework + 로깅 정책 행 plugin 반영)
- §4.1 디렉토리 트리 (`.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` + `hooks/hooks.json` 추가, `install.sh` 폐기, marketplace.json minimal schema 코드블록 박음)
- §4.2 install 단락 (symlink 절차 → plugin install 3 시나리오 — A 운영자 default / B 외부 사용자 / C 개발 보조)
- §4.5 hooks 등록 (settings.json 편집 → `hooks/hooks.json` 표준, `${CLAUDE_PLUGIN_ROOT}` unset 가드 명시)
- §6.1.3 default 도메인 (SRE 직접 명시 → "default — fork 시 갈아끼움")
- §6.4.2 mypower 자체 빌드 행 (검증 대상 변경 — marketplace add + install + uninstall 흐름)
- §7.2 페르소나 system prompt (회사명 → 일반화)
- §10.2 hooks (plugin manifest 등록 명시)
- §11.2 step 0 (산출물 plugin manifest 2개 + hooks.json + smoke.sh, AC 변경)
- §11.3 agent-team v1 포함 (결함 4종 검출 시 자동 fallback ADR 작성 명시)
- §12 트레이드오프 (plugin 채택 행 추가, 기존 GitHub repo + symlink 행 갱신)
- §13 검증 체크리스트 (plugin manifest 2개 검증 + marketplace.json 5필드 grep + 운영자 식별자 grep + 일반화 self-judge 항목)
- frontmatter v3.13 changelog 행 추가 (R3·R5 v3.14 백로그 미룸 결정 동반 명시)
- spec 전체 `$MYPOWER_HOME` → `${CLAUDE_PLUGIN_ROOT}` 일괄 치환

## 6. 향후 확인 사항 (v1.1 백로그 후보)

- marketplace 등록 절차 + 검수 가이드 (plugin 표준 채택으로 추가 작업 거의 없을 것 예상, 실제 등록 시점에 확인)
- `${CLAUDE_PLUGIN_ROOT}` 환경변수가 모든 hook script 실행 컨텍스트에서 일관되게 설정되는지 (Claude Code plugin 문서 본문 검증)
- `claude plugin update`·`/reload-plugins` 동작이 hooks·skills·agents 변경을 모두 한 번에 반영하는지 (실제 v1 빌드 후 smoke.sh로 검증). 명령 존재 자체는 공식 문서(plugins-reference) 인용으로 확인 완료 — 동작 변화 시 fallback ADR로 정정
- agent-team experimental flag와 plugin 형식의 상호작용 (Claude Code plugin manifest가 env 설정도 지원하는지 — 지원 시 manifest로 통합)
