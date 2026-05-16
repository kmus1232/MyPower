# `/goal` 슬래시 커맨드 — 내부 동작 분석

> 작성: 2026-05-16 | 대상: Claude Code 2.1.143 native binary | 분석 방법: §9 참조

## TL;DR

**`/goal`은 Claude Code 본체에 내장된 슬래시 커맨드.** 세션 한정 Stop hook 1개를 등록하고, **매 턴 종료 시점에 별도 LLM 호출(LLM-as-judge)로 자연어 조건이 충족됐는지 평가**한다. 조건 미충족이면 Stop event를 차단해 모델이 계속 작업하도록 강제. cmux 래퍼·superpowers·플러그인 시스템 모두 무관 — Claude Code 자체 기능.

## 1. 위치 / 외부 의존성

| 구분 | 값 |
|---|---|
| 정의 위치 | Claude Code native 바이너리 (`~/.local/bin/claude`, Mach-O 64-bit executable arm64) |
| 패키징 방식 | JavaScript 번들이 바이너리 안에 평문 string으로 포함 (Bun `--compile` 또는 Node SEA 추정) |
| 무관 | cmux(`/Applications/cmux.app`)·superpowers·플러그인 hooks.json |

## 2. 등록 흐름 — `QiH` 함수

`/goal <condition>` 입력 시 핸들러 (변수명은 minified JS 원본 그대로):

```javascript
function QiH(H, _) {  // H = condition, _ = session context
    let q = jy8();  // 가드 체크 — trust_gate / hooks_gate
    if (q !== null) {
        M6("goal_set", q.code);  // 텔레메트리
        return q.message;
    }

    let K = k_();  // session key

    // 1) 이전 goal hook 제거 (한 번에 1개만 활성)
    for (let T of giH(_.getAppState(), K))
        _.sessionHooksRegistry.remove(K, "Stop", T);

    // 2) 새 Stop hook 등록 — type: "prompt"
    _.sessionHooksRegistry.add(K, "Stop", "", { type: "prompt", prompt: H });

    // 3) appState.activeGoal 기록
    let O = {
        condition: H,
        iterations: 0,
        setAt: Date.now(),
        tokensAtStart: tf()
    };
    _.setAppState((T) => ({ ...T, activeGoal: O }));

    // 4) 대화에 sentinel attachment 추가 (goal 미충족 상태)
    _.applyMessageOp({ type: "append", messages: [Wo7(false, H)] });

    // 5) 텔레메트리
    d("tengu_stop_hook_added", { promptLength: H.length, via: "goal" });
    EH("goal_set");

    return null;  // 성공
}

// sentinel attachment 생성
function Wo7(met, condition) {
    return {
        type: "attachment",
        uuid: fo7.randomUUID(),
        timestamp: new Date().toISOString(),
        attachment: { type: "goal_status", met, sentinel: true, condition }
    };
}
```

핵심: hook이 `settings.json`의 hooks와 **같은 인프라**(`sessionHooksRegistry`)를 쓰되, 키를 *세션 한정*으로 등록 → 세션 종료 시 자동 소멸.

## 3. 모델에 주입되는 system-reminder

`SY6` 템플릿이 매 `/goal` 호출 직후 모델 컨텍스트에 삽입 (바이너리에 그대로 hardcode):

```
A session-scoped Stop hook is now active with condition: "<condition>".
Briefly acknowledge the goal, then immediately start (or continue) working toward it —
treat the condition itself as your directive and do not pause to ask the user what to do.
The hook will block stopping until the condition holds.
It auto-clears once the condition is met —
do not tell the user to run /goal clear after success; that's only for clearing a goal early.
```

원본 코드:

```javascript
SY6 = (H) => `A session-scoped Stop hook is now active with condition: "${H}". Briefly acknowledge the goal, then immediately start (or continue) working toward it — treat the condition itself as your directive and do not pause to ask the user what to do. The hook will block stopping until the condition holds. It auto-clears once the condition is met — do not tell the user to run \`/goal clear\` after success; that's only for clearing a goal early.`
```

## 4. Stop event 판정 — `UhK` 함수 (핵심)

모델이 turn 종료(Stop event)를 시도할 때마다 **별도 LLM 호출**로 판정.

### 4.1 Judge에 보내는 system prompt

```
You are evaluating a stop-condition hook in Claude Code.
Read the conversation transcript carefully, then judge whether the user-provided
condition is satisfied.

- {"ok": true, "reason": "..."}  또는
- {"ok": false, "reason": "..."} 또는
- {"ok": false, "impossible": true, "reason": "<영원히 충족 불가 사유>"}

Always include a "reason" field, quoting specific text from the transcript whenever
possible. If the transcript does not contain clear evidence that the condition is
satisfied, return {"ok": false, "reason": "insufficient evidence in transcript"}.
```

### 4.2 Judge에 보내는 user prompt

```
Based on the conversation transcript above, has the following stopping condition
been satisfied? Answer based on transcript evidence only.
Condition: <condition>
```

### 4.3 결과 schema (Zod)

```typescript
{
  ok: boolean,           // 충족 여부
  reason?: string,       // transcript 인용 권장
  impossible?: boolean   // 영원히 충족 불가 (ok=false일 때만 의미)
}
```

원본 schema 정의:

```javascript
aZ_ = hH(() => y.object({
    ok: y.boolean().describe("Whether the condition was met"),
    reason: y.string().describe("Reason, if the condition was not met").optional(),
    impossible: y.boolean()
        .describe("Whether the condition can never be satisfied (only meaningful when ok is false)")
        .optional()
}))
```

### 4.4 결과별 분기

| 판정 | 동작 |
|---|---|
| `ok: true` | Stop hook 자동 제거 + `goal_status met=true` attachment 박힘 + 정상 종료 |
| `ok: false` | Stop event 차단 → 모델 다음 턴 진입 (system reminder가 다시 들어와서 계속 작업) |
| `ok: false, impossible: true` | Stop 차단 + 운영자에게 `/goal clear` 권장 신호. 무한 루프 안전망 |

### 4.5 Judge 모델 선택

```javascript
let D = H.model ?? PX();  // 별도 지정 없으면 PX() 기본 모델
let f = H.timeout ? H.timeout * 1000 : 30000;  // 기본 timeout 30s
```

## 5. 해제 — `diH` 함수

`/goal clear` (또는 동의어) 입력 시 또는 judge가 `ok: true` 반환 시:

```javascript
function diH(H) {  // H = session
    let _ = k_();
    let q = giH(H.getAppState(), _);
    if (q.length === 0) return null;  // 활성 goal 없음

    let K = q[0].prompt;  // 원래 condition 보존 (반환용)

    // 1) sessionHooksRegistry에서 Stop hook 모두 제거
    for (let O of q) H.sessionHooksRegistry.remove(_, "Stop", O);

    // 2) appState.activeGoal 비움
    H.setAppState((O) => O.activeGoal === void 0 ? O : { ...O, activeGoal: void 0 });

    // 3) 대화에 sentinel attachment 추가 (met=true)
    H.applyMessageOp({ type: "append", messages: [Wo7(true, K)] });

    // 4) 텔레메트리
    d("tengu_stop_hook_removed", { via: "goal" });

    return K;
}
```

## 6. 제약·가드

| 가드 | 트리거 조건 | 메시지 |
|---|---|---|
| `trust_gate` | 신뢰 안 된 워크스페이스 | `/goal is only available in trusted workspaces. Restart, accept the trust dialog, and try again.` |
| `hooks_gate` | `disableAllHooks` 또는 `allowManagedHooksOnly` 설정 켜져 있음 | `/goal can't run while hooks are disabled (disableAllHooks or allowManagedHooksOnly is set in settings or by policy).` |
| condition 길이 | `FiH = 4000`자 초과 | `Goal condition is limited to ...` |
| 동시성 | 한 세션에 1개만 활성 — 새 `/goal` 입력 시 이전 hook 교체 | (silent replace) |

### clear 동의어 (6개)

```javascript
H83 = new Set(["clear", "stop", "off", "reset", "none", "cancel"])
EY6 = (H) => H83.has(H.toLowerCase())
```

## 7. 함의 — 트레이드오프

| 측면 | 영향 |
|---|---|
| **토큰 비용** | Stop event마다 judge LLM 호출 1회 추가. 짧은 답변에도 발동 |
| **지연** | 매 turn 종료에 judge 대기 시간 포함 (timeout 기본 30s) |
| **모호 조건 위험** | "잘 작성" 같은 모호 조건은 judge가 영구히 `ok: false` 반환 가능 → `impossible: true` 분기가 발동되지 않으면 turn 무한 진입 |
| **`type: "prompt"` hook 인프라** | `settings.json` `hooks` 필드의 같은 메커니즘. `/goal`은 세션 한정 + UI wrapper일 뿐. 운영자가 `~/.claude/settings.json`에 `Stop` hook을 `type: "prompt"`로 직접 박으면 같은 동작 가능 |
| **enforcement 강도** | prompt-level reminder + **system-level Stop 차단** — MyPower의 `<HARD-GATE>`·Iron Law·mermaid 종료 노드보다 강함 (LLM이 무시해도 hook이 system 레벨에서 차단) |

## 8. MyPower 관점 시사점

- MyPower의 destructive 차단 hook (Step 5)은 **PreToolUse** 영역 — `/goal`(Stop)과 직교
- MyPower의 슬래시 스킬(brainstorming~applying)이 작업 종료 조건을 LLM-as-judge로 강제하려면 본 메커니즘 모방 가능. 단:
  - `type: "prompt"` hook이 플러그인 `hooks.json` 스키마에 지원되는지 별도 확인 필요. 본 분석에선 `sessionHooksRegistry` 내부 API만 확인 — 외부 hooks.json 스키마 명세는 추가 검증 필요
  - 토큰 비용·지연 트레이드오프 인식 필수 (페르소나 12명 + judge 1회/턴 → 누적 비용 폭증)
- ARP(ambiguity-protocol)의 4단계 처리 + 검증 에이전트 v1.1 설계가 본 `/goal` 메커니즘에서 영감 받을 여지: judge를 ARP 분류 검증용으로 재활용

## 9. 분석 방법 — 어떻게 추출했나

**전제**: 디스어셈블·디컴파일 *안 함*. 머신 코드 해독 *안 함*. 디버거·후킹 *안 함*.

### 9.1 핵심 원리

Claude Code native 바이너리는 **JavaScript 번들이 평문 string으로 포함**된 형태로 컴파일됨 (Bun `--compile` 또는 Node SEA 추정). 즉 머신 코드 + 큰 JS 텍스트 블롭이 한 파일에 들어 있고, 런타임에 JS 엔진이 그 텍스트를 읽어 실행함. 따라서 일반적인 `strings` 도구로 *원본 JS 소스가 그대로 추출 가능*.

C/C++로 컴파일된 일반 바이너리였다면 string만으론 함수 본문 추출 불가능 — 본 추출이 성공한 건 **번들링 방식이 압축·암호화 없는 평문 임베딩**이었기 때문.

### 9.2 사용한 도구

```bash
# 1. 바이너리 안의 모든 printable string 추출
strings ~/.local/bin/claude

# 2. anchor 문자열로 grep — "사용자가 본 메시지 = 코드에 박힌 string"이라는 점 활용
strings ~/.local/bin/claude | grep -F "A session-scoped Stop hook is now active"

# 3. 함수 본문 추출 — anchor 앞뒤 byte 범위를 한 chunk로 뽑기
grep -oE ".{200}A session-scoped Stop hook.{500}" ~/.local/bin/claude
```

세 번째 단계가 결정적. `grep -oE`로 anchor 앞 200 byte + 뒤 500 byte를 한 매치로 출력하면 **JS 함수 본문이 통째로 노출됨**. 변수명은 `H`/`_`/`q`/`K` 등으로 minify됐지만 다음은 모두 평문:

- 함수 정의 syntax (`function QiH(H, _) { ... }`)
- 제어 흐름 (`if`, `for`, `return`)
- string literal (system prompt·user 메시지)
- Zod schema 정의 (`y.object({...})`)
- 텔레메트리 이벤트명 (`tengu_stop_hook_added`)
- attachment payload 구조

### 9.3 추출 절차 — 실제 시간 순서

1. `/goal`이 슬래시 명령인지 hook인지 확인 — system reminder 본문에 "session-scoped Stop hook" 문구가 anchor
2. cmux 래퍼 분석 → cmux는 단지 hook injector. `/goal` 본체는 cmux 외부
3. real claude binary 위치 추적 → `~/.local/bin/claude` Mach-O 확인
4. `strings | grep -F "Goal set"` → 슬래시 명령 메시지 다수 확인 (`/goal active`, `Goal achieved` 등)
5. `grep -oE` byte range로 함수 본문 dump → `QiH`/`diH`/`SY6`/`Wo7`/`UhK`/`aZ_` 6개 핵심 함수 추출
6. judge용 system prompt + Zod schema 추출 → §4 완성

### 9.4 추출한 정보 신뢰도

| 정보 | 신뢰도 | 근거 |
|---|---|---|
| 함수 이름·logic | 높음 | 평문 JS, minified지만 구조 그대로 |
| 사용자 메시지 문자열 | 매우 높음 | string literal 그대로 |
| Zod schema | 매우 높음 | `y.object({...})` 본문 평문 |
| 변수명 의미 | 낮음 | minified — 의미 추정 |
| 함수 호출 순서 외부 의존성 | 중간 | `H4`·`PX`·`UvH` 같은 외부 함수는 다른 위치 추가 grep 필요 |

### 9.5 안 한 것

- `objdump`/`lldb`/`Hopper`/`IDA Pro`/`Ghidra` 같은 디스어셈블러
- Bun/Node 런타임 분석
- source map 복원
- 동적 trace/디버깅
- 함수명 demangle

## 10. 참조

- 분석 대상: `/Users/kimminseok/.local/bin/claude` (Claude Code 2.1.143, Mach-O 64-bit executable arm64)
- npm 패키지 (참고용): `/opt/homebrew/lib/node_modules/@anthropic-ai/.claude-code-2DTsDk1V/cli.js`
- 관련 cmux 래퍼: `/Applications/cmux.app/Contents/Resources/bin/claude` (bash script, hook injection만 담당)
- 분석 일자: 2026-05-16
- 재현성: 같은 anchor 문자열로 다른 위치에서 grep 시 동일 함수 본문 재현 가능
