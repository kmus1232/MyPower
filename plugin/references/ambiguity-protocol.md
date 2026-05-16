# 모호함 처리 규칙 (Ambiguity Resolution Protocol)

본 파일은 MyPower plugin의 lifecycle 슬래시 스킬이 공통 참조하는 단일 출처. 에이전트가 작업 중 모호한 상황을 만났을 때 운영자에게 묻기 전에 스스로 풀어가는 4단계 규칙과 강제 방법을 정의한다.

## 1. 핵심 전제

- **운영자 개입은 실패 신호**다. 매번 운영자에게 물어야 한다면 에이전트가 너무 일찍 포기했거나, 계획 단계에서 빠진 질문이거나, 에이전트가 스스로 찾을 수 있었던 정보를 미접근한 것이다.
- 단, **모르면서 추측하는 건 더 나쁘다**. 작업물을 다 버려야 한다.
- "묻기 vs 추측"을 평균내지 않는다. **모호함 종류별로 다르게 처리**한다.

## 2. 모호함 분류 (4종)

에이전트가 만나는 모호함은 다음 4종 중 하나로 분류된다. **분류 결과가 어느 단계로 가는지를 결정**한다.

| 분류 | 정의 | 예시 | 처리 단계 |
|------|------|------|-----------|
| **답이 코드에 있음** (discoverable) | 시스템 안 어딘가에 사실로 존재하는 답 | "이 함수가 뭘 하지?", "이 프로젝트는 어떤 HTTP 라이브러리 쓰지?" | 1단 |
| **비슷한 비용의 갈래** (cost-symmetric) | 두 선택지가 구현 비용·후속 영향에서 동등 | "에러를 throw할까 return할까" | 2단 |
| **큰 비용차의 갈래** (cost-asymmetric) | 두 선택지가 구현 비용 2배 이상 차이 | "새 서비스로 분리할까 기존 모듈에 추가할까" | 4단 |
| **취향·전략** (preference) | 코드로는 답 안 나오는 운영자 취향·비즈니스 의도 | "이 기능 기본 ON이야 OFF야?" | 4단 (계획 단계에 미리) |

**가장 흔한 오분류**: "답이 코드에 있음"을 "취향"으로 잘못 분류해 운영자에게 안 물어도 됐던 질문을 던지는 것.

## 3. 4단계 처리 순서

위에서부터 차례로 시도. **건너뛰면 규칙 위반**.

### 3.1 1단 — 스스로 찾기

분류가 "답이 코드에 있음"이면 본 단계에서 처리. 다음 출처를 직접 탐색한다:

- 코드 (grep, file read, AST 탐색)
- 문서 (README, AGENTS.md, ADR, 코드 주석)
- 히스토리 (최근 commit, 관련 PR, 이전 대화)
- 런타임 증거 (코드 실행, 타입 확인, 스키마 점검)

**1단에서 답이 나오는 질문을 운영자에게 묻는 것이 본 규칙의 최악 실패 모드**다. 운영자가 에이전트 신뢰를 잃는 가장 빠른 길.

### 3.2 2단 — 가정하고 기록

분류가 "비슷한 비용의 갈래"이면 본 단계에서 처리. 한 선택지를 고르고 진행하되 **계획 파일에 가정을 명시적으로 기록**한다.

가정 기록 형식:
- **위치**: 계획 파일의 `## Assumptions` 섹션 (계획 파일 경로는 프로젝트별 컨벤션. MyPower repo 기준 `docs/superpowers/plans/<날짜>-<이름>.md`)
- **형식**: `[가정 ID] 어떤 갈래에서 무엇을 선택했고, 이유는 무엇인가`
- **예시**: `[A-001] 에러를 throw로 처리. 본 코드베이스의 다른 에러 처리도 throw 패턴이라 일관성 유지.`

**기록 없이 가정만 하는 것은 침묵 추측과 동일**. 운영자가 사후에 "뭘 가정했어?" 물었을 때 완전히 재구성할 수 있어야 한다.

### 3.3 3단 — 전문가 서브에이전트에 위임

본 분류에 직접 안 들어가지만 1단·2단에서 처리 어려운 케이스에 적용. 더 전문적인 서브에이전트에 위임한다.

- **위임 깊이 1로 제한**. 서브에이전트가 또 다른 서브에이전트에 위임하는 것은 금지. 추적 불가 + 무한 위임 위험.
- 서브에이전트는 1단·2단까지만 처리. 4단 도달 시 위로 escalate.

### 3.4 4단 — 운영자에게 물음 (최후 수단)

분류가 "큰 비용차의 갈래" 또는 "취향·전략"이면 본 단계. 1단·2단·3단으로 해결 불가능할 때만 진입.

**질문 형식 요구사항** (모두 충족):
- **한 번에 한 질문**. 다부 질문 금지.
- **2~4개 옵션** + 추천 default 표시.
- **비용 trade-off 명시** — 각 옵션의 비용·되돌릴 수 있는지.
- **fallback 명시** — 응답 timeout 시 default 진행 정책. 구체 timeout 값(`<timeout>`)은 운영자 미응답 timeout 정책(T-007 미결) 결정 전까지 운영자가 명시 지정한 경우에만 적용. 비가역 옵션은 fallback 없이 운영자 답을 대기.
- **가독성 우선** — 압축 표현·영어 약어 ID·다른 도구가 만든 jargon 패스스루 금지. 운영자가 별도 해석 없이 즉시 답할 수 있는 형태로. 풀이 필요한 용어는 본문 내 첫 등장 시 풀어 쓴다.

좋은 예:
> "X를 처리할 건데 두 갈래: (A) 30분, 되돌릴 수 있음. (B) 3시간, 되돌릴 수 없음. `<timeout>` 후 A로 진행, 막으려면 답해." (timeout은 운영자가 명시 지정한 경우에만)

나쁜 예:
> "X를 어떻게 처리할까요?"

**취향·전략 분류는 계획 단계에 미리 묻는다.** 구현 중간에 발견하면 비용이 폭증한다.

## 4. 강제 방법

본 규칙을 실제로 어떻게 enforce하는가.

### 4.1 슬래시 스킬 프롬프트 (1차 강제)

MyPower plugin의 6 lifecycle 슬래시 스킬 + tdd 스킬(총 7개. brainstorming, planning, execution, tdd 등) 본문이 각 단계에서 본 reference를 참조한다. LLM은 스킬 본문 지시에 따라 4단계 순서·분류·질문 형식을 준수.

### 4.2 검증 에이전트 (2차 강제, MVP 단계 차단 권한 단독)

**commit 직전 1회 실행**되는 별도 에이전트. 계획 파일의 `## Assumptions` 섹션 vs 실제 코드 변경을 대조해 다음을 검사:

- 새 가정이 코드에 반영됐는데 계획 파일에 기록 없음 → **차단**
- 계획에 기록된 가정과 실제 구현이 어긋남 → **차단**
- 운영자 질문(4단) 이력에 분류 라벨 없음 → **차단**

**v1 MVP에서는 검증 에이전트 미도입.** v1.1+에서 작성 step이 빌드 plan에 추가되고 차단 권한을 갖춤. **v1 동안 ARP 강제는 슬래시 스킬 프롬프트 단독** — LLM이 무시할 가능성 존재하므로 운영자 사후 transcript 검토 부담이 v1 기간 동안 유지된다. 차단 권한 분배는 v1.1+에서 hook 도입과 함께 재설계된다(§4.3).

### 4.3 hook — v1.1+ 4종 hook 통합 enforcement (T-010 해소)

**hook은 본 규칙의 핵심 강제 메커니즘**. 코드 편집·도구 호출·턴 종료·서브에이전트 종료 시점에 즉각 발동 가능한 유일한 수단이라, 검증 에이전트(commit 시점)만으론 잡히지 않는 즉각성 영역을 hook이 채운다.

**MVP(v1) — hook 미도입**. v1 빌드 일정 보호 우선. v1 동안 ARP 강제는 슬래시 스킬 프롬프트 단독 — LLM 무시 가능성 인정.

**v1.1+ — 4종 hook 통합 채택** (T-010 해소). 본 ADR [`docs/adrs/2026-05-17-autonomous-execution-strategy.md`](../../docs/adrs/2026-05-17-autonomous-execution-strategy.md)가 hook 신호 설계를 닫음. 공식 hooks 문서(`https://code.claude.com/docs/en/hooks`) 기준 schema-compatible:

| event | hook type | ARP 매핑 — enforce할 단계 |
|---|---|---|
| **PreToolUse** | `prompt` | 4단(운영자 질문) 직전 안전성 평가 — destructive 명령 진입 차단 |
| **PostToolUse** | `prompt` | 1단(스스로 찾기) 결과 검증 — 도구 실행 결과 즉시 lens 통과 |
| **Stop** | `prompt` | 턴 종료 시점 lifecycle step 완료 조건 평가 — `/goal` 핵심 메커니즘과 동일 (v2.0.30+ 지원) |
| **SubagentStop** | `prompt` | 3단(전문 서브에이전트 위임) 결과 양식 검증 — 페르소나 12명 finding 5단 보고 양식 강제 |

(나머지 hook 후보는 폐기 — mtime 비교·코드 변경량 임계는 ARP 단계와 무관. 에이전트 자체 메타 보고는 우회 인센티브.)

**`additionalContext` 사용 강제 (결정적)**:

공식 docs:

| 필드 | 전달 대상 |
|---|---|
| `reason` | **사용자에게만 표시** — Claude 모델 컨텍스트 미주입 |
| `additionalContext` | Claude 컨텍스트 창에 system reminder로 주입 |

→ 본 4종 hook의 judge가 ARP 단계 위반 감지 시 결과를 **`additionalContext` 필드**에 박는다. `reason`만 사용하면 사용자만 보고 모델은 못 봐서 자율 루프가 작동 안 함. judge prompt 본문에 "Return JSON `{ok, additionalContext}`" 강제.

**undocumented 가드 의존 최소화**: `stop_hook_active`·`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`은 공식 미문서화. 본 ARP는 명시적 의존 안 함. 무한루프 방지는 judge prompt 본문 가이드("이미 N번 시도. 영구 불가능이면 `ok:true` 반환")로 처리.

v1.1+ 빌드 plan에 4종 hook prompt 본문 작성 Step 추가 — 본 ADR 후속.

## 5. 미해소 항목 (TODO)

본 규칙이 답을 못 가진 시나리오. 향후 결정 누적 대상.

| ID | 내용 |
|----|------|
| **T-001** | **가역성 축 추가** — 비용 비율 외에 "되돌릴 수 있나" 축으로 분류 정교화. 현재는 비가역 작업도 비율 2배 미만이면 2단으로 빠질 위험 |
| T-002 | 가정이 N개 누적된 후 운영자 일괄 검토 강제 시점 |
| T-003 | "답이 있긴 한데 탐색 비용이 비대칭"인 경우 (예: git 200 commit 거슬러야 함) 1단 직진 정책 |
| T-004 | 운영자도 즉답 못 하는 취향 질문의 추가 분기 |
| T-005 | 에이전트가 4단계 자체를 우회할 인센티브 ("답이 있음"으로 잘못 분류 후 추측) 차단 |
| T-006 | 계획 확정 후 외부 상황 변동(라이브러리 버전 업·별도 브랜치 동일 코드 수정) 처리 |
| T-007 | 운영자 미응답 timeout 정책 (특히 비가역 default) |
| T-008 | 실행 에이전트의 계획 수정 권한 경계 (append-only 강제 여부) |
| T-009 | 컨텍스트 압축 후 계획 파일 재로드 경로 |
| ~~T-010~~ | ~~hook 신호 설계~~ — **§4.3에서 해소**: 4종 hook 매트릭스(PreToolUse·PostToolUse·Stop·SubagentStop, 모두 `type: "prompt"` + `additionalContext`) v1.1+ 채택. 결정 ADR [`2026-05-17-autonomous-execution-strategy.md`](../../docs/adrs/2026-05-17-autonomous-execution-strategy.md) |

## 6. 참조

- ARP 채택 결정·trade-off·hook 폐기 근거·검증 에이전트 단일 차단 권한 결정: ADR [`docs/adrs/2026-05-13-ambiguity-protocol-adopt.md`](../../docs/adrs/2026-05-13-ambiguity-protocol-adopt.md)
- T-010 hook 신호 설계 해소 결정 (v1.1+ 4종 hook 매트릭스): ADR [`docs/adrs/2026-05-17-autonomous-execution-strategy.md`](../../docs/adrs/2026-05-17-autonomous-execution-strategy.md)
- Claude Code `/goal` 내부 동작 분석 (4종 hook 매트릭스의 reference 모델): [`docs/references/2026-05-16-goal-command-internals.md`](../../docs/references/2026-05-16-goal-command-internals.md)
- Claude Code hooks 공식 docs: `https://code.claude.com/docs/en/hooks` — `additionalContext` 정의·event별 hook type 매트릭스의 공식 anchor
