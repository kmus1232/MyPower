# observability-reviewer 체크리스트 (2층)

> 1층 `agents/observability-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + observability-guide.md 인용.

## 핵심 질문

> "이 코드 이상 동작 시 운영자가 1분 안에 원인 짚을 단서 있나?"

## sub-checklist

본 체크리스트는 observability-guide.md self-check 4항목을 그대로 인용한 뒤 추가 lens를 덧붙인다.

### A. self-check 4항목 (observability-guide.md §self-check)

- [ ] 1: 함수 진입·이상 분기·외부 호출 직전/직후 로깅 존재 (변경 파일 grep)
- [ ] 2: 외부 호출 latency 메트릭 존재 또는 명시적 면제 사유 (변경된 외부 호출 함수 인근 grep)
- [ ] 3: 에러 핸들링에 stack trace + context (try/catch 블록 grep, silent catch 0건)
- [ ] 4: 민감정보 로깅 0건 (비밀번호·토큰·API key 변수명 + 로그 호출 grep)

### B. trace 전파

- [ ] 모든 외부 호출에 `trace_id` 또는 `correlation_id` 전파 (헤더 / 컨텍스트 / 미들웨어)
- [ ] 비동기 작업(큐·이벤트·worker)에 correlation_id 보존
- [ ] 로그 entry 1건마다 request_id 또는 동등 식별자 존재

### C. silent catch 0건

- [ ] `try { ... } catch (e) {}` 같은 빈 catch 0건
- [ ] `except: pass` / `rescue nil` 0건
- [ ] 에러를 잡은 후 단순히 `return null`로 흘려보내는 패턴 0건 — 최소 WARN 로그 + 명시적 fallback

### D. 에러 메시지 context

- [ ] 에러 메시지에 "어디서·왜·무엇이" 모두 포함 (식별자·입력값 일부·시도한 동작)
- [ ] generic 메시지 (`"Something went wrong"`) 0건
- [ ] PII/secret 마스킹 — 첫 4자만 노출 또는 hash 처리

### E. 메트릭 cardinality

- [ ] 사용자 ID·트레이스 ID 같은 high-cardinality 값을 메트릭 label로 박지 않음 (큐 폭증 위험)
- [ ] Datadog 커스텀 메트릭은 분류 A 비용 영향 — 신규 도입 시 ADR 동반

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | 외부 호출 직전/직후 로깅 전무 + 운영 시 장애 원인 추적 불가 / silent catch 다수 / 비밀번호·토큰 로그 평문 |
| Important | trace_id 전파 끊김 (외부 호출에서 새 요청 ID 발급) / 에러 메시지 context 부족 / 메트릭 cardinality 폭증 위험 |
| Nit | 로그 레벨 부적절 (정상 흐름인데 WARN) / 메시지 포맷 일관성 약함 |
| Optional | 추가 로그 권고 (현재도 추적 가능) / 메트릭 추가 권고 |
| FYI | 같은 누락 패턴이 다른 모듈에도 보임 — 후속 audit 후보 |

## 출력 5단 보고 양식

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {파일 경로:라인 + 함수명 + 외부 호출 / 에러 경로}
[문제] {어떤 self-check 항목 위반 + 운영 시 발생 시나리오}
[현재 영향] {장애 발생 시 운영자가 원인 짚기까지 추정 시간 / context 부족도}
[결정 권고] {Critical=차단 + 로깅 추가 / Important=수정 후 머지 / Nit=권고}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

### A. 메트릭 cardinality 폭증

1. **user_id를 메트릭 라벨로 직접 박음** — Critical
   ```python
   # nope: user_id N명마다 시계열 1개씩 폭증
   metrics.increment("api.calls", tags=[f"user_id:{user_id}"])
   ```
   Datadog / Prometheus 메트릭 라벨은 cardinality(고유값 수) 제한 — 라벨 수 × 라벨값 수가 폭증하면 storage·query 비용 폭증 + 라이선스 한도 초과로 메트릭 drop. **올바른 패턴**: `region` / `service` / `endpoint` 같은 bounded set만 라벨로. user-level 정보는 trace 또는 log에.

2. **error_message 전체를 라벨로** — Critical
   ```go
   metrics.Inc("errors", []string{"message:" + err.Error()})
   ```
   에러 메시지에 file path / line number / random 값 포함 시 cardinality 무한대. 에러는 `error.type` 같은 분류명만 라벨로, 상세는 trace의 `error.message` attribute로.

3. **request URL 전체를 라벨로** — Important
   `path:/users/12345/orders/67890`처럼 path parameter 값이 라벨에 박힘. **올바른 패턴**: route template만 (`path:/users/:id/orders/:order_id`).

### B. 분산 추적(trace context) 끊김

1. **trace_id 새로 발급 + 상류 무시** — Critical
   ```python
   # nope: 외부 호출 진입 시 새 request_id 만들고 상류 trace_id 전파 안 함
   def handler(request):
       trace_id = uuid.uuid4()  # 새로 생성 — 상류와 연결 끊김
   ```
   상류 서비스가 박은 `traceparent` header(W3C Trace Context) 또는 `x-datadog-trace-id`를 받아 propagate 해야 함. 본인이 root span이 아니라면 새로 발급 금지.

2. **async / queue / background job에 context 전달 누락** — Critical
   ```python
   # nope: Celery / Sidekiq에 trace context 안 박음
   task.delay(user_id, order_id)
   ```
   Datadog APM / OpenTelemetry는 thread-local로 context 추적. async boundary 넘을 때 명시적 inject/extract 필요(`tracer.context_provider`).

3. **outbound HTTP 호출에 trace header 누락** — Important
   `requests.get(url)` 직접 호출 시 trace propagation 안 됨. instrumented client(`ddtrace.requests` / `opentelemetry.instrumentation.requests`) 또는 수동 header 주입 필요.

### C. 로그 컨텍스트 부족

1. **외부 API 호출 + 에러만 로그** — Important
   정상 호출 로깅 없음. 운영 시 "이 endpoint가 호출 됐는지조차 모름". observability-guide.md §로깅 위반. **올바른 패턴**: 호출 시작·완료 양쪽 로그 (latency 메트릭 + DEBUG/INFO 로그).

2. **silent catch + return null** — Critical
   ```python
   try: return fetch(...)
   except: return None  # 어떤 에러인지 흔적 0
   ```
   호출자가 빈 결과인지 에러인지 구분 못 함. **올바른 패턴**: catch 안에서 logger.exception(원본 traceback) + 에러를 재throw 또는 domain-specific 에러로 wrap.

3. **에러 로그에 input 컨텍스트 누락** — Important
   ```python
   logger.error(f"Failed to process: {e}")  # 어떤 input에 실패했는지 없음
   ```
   reproduce 불가. **올바른 패턴**: structured logging — `logger.error("process_failed", extra={"order_id": id, "user_id": uid, "error": str(e)})`.

### D. 메트릭 / 로그 / trace 분리

1. **logger.error + trace span에 에러 미반영** — Important
   에러 발생을 log에만 박고 active span에는 status=error 안 박음. APM에서 에러로 잡히지 않아 error rate 통계 누락.
   ```python
   # 올바른 패턴
   span = tracer.current_span()
   span.set_tag("error", True)
   span.set_tag("error.msg", str(e))
   logger.exception("...")
   ```

2. **count 메트릭만 박고 latency 누락** — Important
   `metrics.increment("api.calls")`만 있고 `metrics.histogram("api.latency_ms", ...)` 없음. 운영 시 "느려졌는지 빨라졌는지" 추적 불가. RED 패턴(Rate·Errors·Duration) 권고.

3. **healthcheck 호출이 트래픽 메트릭에 섞임** — Nit
   `/health` endpoint 호출이 일반 API 호출과 같은 메트릭에 박힘. cardinality 폭증은 아니나 운영 노이즈. 별도 메트릭 또는 label 분리 권고.
