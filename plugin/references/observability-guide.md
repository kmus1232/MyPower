# Observability 가이드

> 본 가이드는 executing-plan 코드 작성 subagent + pr-review observability-reviewer가 공유한다. spec §9.2.1 + §6.3.3-1 단일 진실 출처.

## 로깅

- 함수 진입·이상 분기·외부 호출 직전/직후
- 로그 레벨: DEBUG / INFO / WARN / ERROR
- 에러 로그에 stack trace + context (request_id, user_id 등)

## 메트릭

- 외부 호출 latency (histogram)
- 실패율 (counter)
- 큐/배치 처리량

## Trace / Correlation ID

- 요청 단위 추적 위해 모든 외부 호출에 trace_id 전파
- 비동기 작업에 correlation_id

## 에러 핸들링

- silent catch 금지 (`except: pass` 같은)
- 에러는 로그 + rethrow 둘 중 하나
- 에러 메시지에 충분한 context (어디서·왜·무엇이)

## 민감정보

- secret·PII·토큰 절대 로깅 금지
- 마스킹 필요 시 첫 4자만 노출

## self-check 4항목 (코드 영역 step 종료 직전 lead 점검)

`observability-reviewer`는 PR 리뷰 단계에서만 동작하므로 코드 작성 시점 누락이 PR까지 발견되지 않을 수 있다. 코드 영역 step 종료 직전 lead가 다음 4항목을 직접 점검한다.

| # | 항목 | 검증 방법 |
|---|---|---|
| 1 | 함수 진입·이상 분기·외부 호출 직전/직후 로깅 존재 | 변경 파일에 로그 호출 grep |
| 2 | 외부 호출 latency 메트릭 또는 명시적 면제 사유 | 변경된 외부 호출 함수 인근 메트릭 호출 grep |
| 3 | 에러 핸들링에 stack trace + context | `try`/`catch` 블록 grep, silent catch 0건 |
| 4 | 민감정보 로깅 0건 | 비밀번호·토큰·API key 변수명 + 로그 호출 grep |

self-check 결과는 `index.json`의 해당 step에 `observability_check: {1: pass|fail, 2: pass|fail, 3: pass|fail, 4: pass|fail}` 형태로 기록한다. PASS 못 하면 step status `done_with_concerns` + concerns 배열에 항목 추가 → PR 리뷰 단계 architect/observability reviewer가 우선 확인.
