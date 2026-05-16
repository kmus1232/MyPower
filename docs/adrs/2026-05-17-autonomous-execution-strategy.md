# ADR — `/goal`-style 자율 실행 전략 (v1.1+ 4종 hook 통합)

> 작성: 2026-05-17 | 상태: 채택 (v1.1+ 진입 시) | 분류: B (자율 결정 후 ADR 흡수) | 후속 ADR: ARP `2026-05-13-ambiguity-protocol-adopt.md` T-010 해소

## 배경

운영자가 MyPower의 enforcement 메커니즘을 Claude Code 내장 `/goal` 슬래시 커맨드의 핵심 패턴 — **Stop hook + LLM-as-judge + 사용자 입력 없이 다음 turn 자율 진행** — 에 맞추기를 요구.

`/goal` 분석은 별도 reference [`docs/references/2026-05-16-goal-command-internals.md`](../references/2026-05-16-goal-command-internals.md)에 누적. 분석 결과 본 ADR이 닫는 의문 두 가지:

1. **MyPower 플러그인 영역에서 `/goal`-style enforcement가 schema 적합하게 가능한가?**
2. **가능하다면 어떤 event·어떤 hook type로 박을 것인가?**

본 ADR 작성 직전 anchor 반전이 있었음. 초기 분석은 Claude Code 바이너리에 임베디드된 도움말 string ("Only available for tool events: PreToolUse, PostToolUse, PermissionRequest")에 의존해 *플러그인 영역에서 `type: "prompt"` Stop hook 불가*로 결론냄. **공식 hooks 문서**(`https://code.claude.com/docs/en/hooks`)는 정반대 — `type: "prompt"`·`type: "agent"`가 **Stop 포함 대부분 event에서 허용**, CHANGELOG v2.0.30이 "Added prompt-based stop hooks"로 명시. 본 ADR은 공식 문서 anchor를 따른다.

ARP ADR [`2026-05-13-ambiguity-protocol-adopt.md`](2026-05-13-ambiguity-protocol-adopt.md) §2.2가 *hook 신호 설계는 v1.1+ ADR로 미룸*(T-010)이라고 결정했음 — 본 ADR이 T-010을 해소한다.

## 결정

### A. 영역 선택 — 플러그인 단일 통합 (개인 로컬 분기 안 함)

v1.1+ 자율 실행 enforcement는 **플러그인 영역 (`plugin/hooks/hooks.json`)** 에서 박는다. `~/.claude/settings.json` 개인 로컬 분기는 *선택지로만 인정*하고 본 ADR이 권고하지 않음.

이유: 공식 docs 기준 플러그인 영역에서 `/goal` 정확 재현이 schema-compatible하게 가능 + Claude Code 내장 small fast model 사용으로 외부 사용자 API key 부담 0. 영역 분기는 MyPower 정체성(범용 plugin 배포)에 마찰. 보안 정책(transcript 외부 API 전송 차단 등) 필요 운영자만 §5 개인 로컬 분기 별도 채택.

### B. 4종 hook 통합 enforcement 매트릭스

v1.1+에 다음 4종 hook을 플러그인 `hooks.json`에 추가:

| event | hook type | 역할 | MyPower 매핑 자리 |
|---|---|---|---|
| **PreToolUse** | `prompt` | destructive 명령 직전 안전성 평가 | applying-approval-gate (Step 5 — 현재 `type: "command"` stub) |
| **PostToolUse** | `prompt` | 도구 실행 결과 즉시 검증 | observability self-check (spec §6.3.3-1) hook 강제 |
| **Stop** | `prompt` | turn 종료 시점 lifecycle step 완료 조건 평가 | executing-plan Step 0 schema 게이트 (Step 8) — `/goal` 핵심 |
| **SubagentStop** | `prompt` | 페르소나 12명 finding 출력 종료 시 5단 보고 양식 검증 | persona-checklists §출력 양식 grep을 hook 강제 |

이 4종 조합이 MyPower의 기존 prompt-level 강제(`<HARD-GATE>`·Iron Law·mermaid 종료 노드)에 **system-level 강제**를 더한다. ARP §4.3 T-010 "어떤 신호로 어느 단계 enforce할지"가 본 매트릭스로 해소.

### C. 다음 turn 모델 가이드 전달 — `additionalContext` 사용 강제

공식 docs 정의:

| 필드 | 전달 대상 |
|---|---|
| `reason` | **사용자에게만 표시** — Claude 모델 컨텍스트 미주입 |
| `additionalContext` | Claude 컨텍스트 창에 system reminder로 주입 |

→ 본 ADR의 4종 hook 모두 judge 결과를 **`additionalContext` 필드**로 모델에 전달한다. `reason`만 쓰면 사용자만 보고 모델은 못 봐서 자율 루프가 작동 안 함.

`/goal` 자체도 `additionalContext` 메커니즘 활용 (내부 sentinel attachment + system reminder 주입).

### D. undocumented 가드 의존 최소화

다음 두 항목은 공식 미문서화:

- `stop_hook_active` 플래그 — 무한루프 가드로 알려져 있으나 안정성 보장 안 됨
- `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` env var — 기본값 미문서화

→ 본 ADR의 권고 설계는 **공식 spec(`decision: "block"` + `additionalContext`) 안에서 완결**. 위 2 항목엔 명시적으로 의존하지 않음. 단 hook prompt 본문에서 *judge가 직접 cap 인지*하도록 강제: `additionalContext`에 "이미 N번 시도. 영구 불가능이면 `ok:true` 반환" 가이드 박음.

### E. 도입 시점 — v1.1+

v1.0(현재)은 변경 없음. v1.1 빌드 plan 새 Step에서 박는다:

- Step 5 갱신 (applying-approval-gate): `type: "command"` stub → `type: "prompt"` PreToolUse로 진화
- Step 8 갱신 (executing-plan SKILL.md): Stop hook `type: "prompt"` 결합
- 신규 Step (TBD): PostToolUse + SubagentStop hook 본문 작성

v1.2+에서 운영 데이터 누적 후 토큰 비용·judge 정확도 측정 결과로 4종 중 일부 비활성화 검토.

## 이유

### 왜 플러그인 영역 단일 통합인가

| 측면 | 플러그인 (채택) | 개인 로컬 (비채택 권고) |
|---|---|---|
| `/goal` 정확 재현 | 가능 (공식 docs 명시) | 가능 |
| 외부 사용자 배포 | ✓ | ✗ (운영자 한정) |
| 구현 자유도 | hook 3 type 한정 | 임의 shell script + `type: "command"` |
| API key | Claude Code 내장 small fast model | 운영자 본인 키 (만약 type:command + 자체 script) |
| MyPower 정체성 부합 | ✓ (범용 plugin 배포) | ✗ |
| 운영자 학습 가치 | 중간 (hook prompt 본문 작성) | 높음 (hook + judge script 직접) |

MyPower가 외부 사용자 marketplace 배포를 목표로 하는 한 *외부 사용자에게 dotfiles 영역 작업을 강요할 수 없다*. 플러그인 영역 단일 통합이 정체성에 부합.

### 왜 4종 hook 통합인가

ARP가 이미 4단계 처리(스스로 찾기 → 가정 기록 → 위임 → 운영자 질문)를 정의했고, 각 단계의 enforcement 자리가 다음과 같이 매핑됨:

- 도구 호출 직전(PreToolUse) = 4단(운영자 질문) 직전 안전성 평가 자리
- 도구 호출 직후(PostToolUse) = 1단(스스로 찾기) 결과 검증 자리
- turn 종료(Stop) = 전체 lifecycle step 완료 조건 평가 자리
- subagent 종료(SubagentStop) = 페르소나 위임(3단) 결과 양식 검증 자리

4종 동시 활용이 ARP 4단계 enforcement를 system-level까지 끌어올림. 단일 hook(예: Stop만)은 강제력이 부분적.

### 왜 `additionalContext` 강제인가

공식 docs가 `reason`을 *사용자 표시 전용*으로 명시. judge가 "조건 미충족 + reason X" 반환해도 모델은 그 reason을 못 본다. 다음 turn에서 모델이 무작정 다시 시도 → 루프 무한 반복. `additionalContext`로 박아야 모델이 reason을 학습하고 행동 수정.

### 왜 v1.1+ 진입 시점인가

v1.0 Step 0~13 빌드 일정 보호. v1.0이 끝나야 운영 데이터(어디서 무한 루프 잡혔나·judge 정확도) 누적 시작 가능. 그 데이터로 4종 중 어디부터 강제할지 우선순위 결정.

## 트레이드오프

### 잃는 것

- **토큰 비용 증가**: turn당 최대 4 judge call (4종 hook 활성 시). prompt-level 강제만 있던 v1.0보다 토큰 4배+ 가능성
- **지연 증가**: judge timeout 기본 30초. 4종 직렬 발동 시 누적 지연. user-facing 응답성 영향
- **복잡도 증가**: hook prompt 본문 4종 작성·테스트·튜닝 부담. judge가 잘못된 ok 판정 시 silent regression 위험
- **undocumented 가드 미사용**: `stop_hook_active`·block cap 의존 안 하므로 무한 루프 차단을 judge 본문 가이드에 의존. judge 모델이 가이드 무시 시 안전망 없음 (Claude Code 내장 가드는 작동하지만 명시적 제어 안 함)

### 얻는 것

- **`/goal`-style 자율 실행 정확 재현** — 플러그인 영역에서 schema 합법적
- **enforcement 강도 비대칭 해소**: prompt-level → system-level 추가 → LLM이 무시 못 함
- **외부 사용자 부담 0**: Claude Code 내장 small fast model 사용 — API key·shell script 추가 의존 없음
- **ARP T-010 해소**: 별도 ADR 신규 작성 의존 제거 — 본 ADR이 T-010 닫음
- **4종 통합 매트릭스가 ARP 4단계와 자연 정렬** — 설계 일관성

### 결정 보류 (v1.1 빌드 시 결정)

- 4종 hook 모두 동시 활성 vs 단계 도입 — v1.1 진입 시 우선순위 표 작성
- judge 모델 명시 지정 vs 내장 default — Claude Code 내장 small fast model 변경 시 영향 분석 필요
- hook prompt 본문 *최대 길이* — 4000자 한도 인지 (공식 docs 인용 필요)
- 4종 hook이 동시 발동 시 *순서 보장* 여부 — 공식 docs 인용 필요

## 영향

본 ADR 채택과 함께 갱신할 파일:

| 파일 | 변경 |
|---|---|
| `plugin/references/ambiguity-protocol.md` §4.3 + §5 | T-010 해소 명시 — 4종 hook 매트릭스 인용 + `additionalContext` 사용 강제 |
| `docs/specs/2026-05-09-mypower-design.md` §10.2 | hooks hard enforcement에 4종 매트릭스 추가 + Stop event 자율 루프 메커니즘 |
| `docs/specs/2026-05-09-mypower-design.md` §11.2 | Step 5·Step 8 AC에 hook prompt 본문 + 검증 grep 자리 명시 |
| `docs/specs/2026-05-09-mypower-design.md` §14 | v1.1 백로그 #23(hooks 추가 도입)에 본 ADR 인용 |
| `docs/references/2026-05-16-goal-command-internals.md` §8 | MyPower 시사점 정정 — 영역 분기 불필요·플러그인 단일 통합 + anchor reversal 기록 |
| `CLAUDE.md` 의사결정 누적 표 | 본 ADR 줄 추가 |

v1.1 빌드 plan(별도 작성)에 새 Step 추가 — 본 ADR 후속:

- (가칭) Step 14: 4종 hook prompt 본문 작성 + smoke.sh 통합 검증

## 후속 추적

본 ADR이 닫지 않는 결정. v1.1 빌드 진행 중 또는 운영 데이터 누적 후 별도 ADR로 누적:

| 항목 | 트리거 |
|---|---|
| 4종 hook 우선순위 + 단계 도입 순서 | v1.1 빌드 Step 14 진입 시 |
| judge 모델 명시 지정 vs 내장 | small fast model 변경 시점 또는 토큰 비용 한도 도달 |
| 4종 hook prompt 본문 길이·내용 합의 | v1.1 빌드 Step 14 작성 시 |
| undocumented 가드(`stop_hook_active`·`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) 공식 docs 등재 여부 | Claude Code 분기별 changelog 추적 |
| 토큰 비용·지연 실측 결과 | v1.1 운영 1개월 후 ADR |
| judge 오판정 사례 누적 | 운영 중 발생 시점마다 |
| 4종 hook 비활성화 결정 (운영 데이터 기반) | v1.2+ 진입 시 |
| 개인 로컬 분기 채택 (보안 정책 필요 시) | 회사 코드 transcript 외부 API 전송 차단 필요 운영자 등장 시 |

본 ADR 후속에 v1.1 빌드 Step 14가 추가되고 4종 hook prompt 본문이 작성되면 MyPower의 `/goal`-style 자율 실행이 완성된다.
