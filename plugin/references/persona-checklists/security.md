# security-reviewer 체크리스트 (2층)

> 1층 `agents/security-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + observability-guide.md "민감정보" + decision-catalog-template.md §4 인용.

## 핵심 질문

> "보안 취약점·인증 우회·secret 노출 가능성?"

## sub-checklist

### A. OWASP Top 10 핵심 (본 페르소나 lens는 코드 영역 한정)

- [ ] SQL injection — 사용자 입력이 raw SQL 문자열에 박힘 / parameterized query 미사용
- [ ] XSS — HTML 응답에 사용자 입력 escape 없이 박힘 / `innerHTML` 직접 사용
- [ ] CSRF — 상태 변경 endpoint (POST/PUT/DELETE)에 CSRF token / SameSite cookie 보호 없음
- [ ] 인증 우회 — endpoint 진입 직후 인증 미들웨어 또는 권한 체크 누락
- [ ] insecure deserialization — pickle / unsafe YAML loader / 신뢰 안 되는 JSON.parse 후 직접 실행
- [ ] SSRF — 사용자 입력 URL을 서버에서 직접 fetch (내부 IP·metadata endpoint 접근 가능)

### B. secret 노출

- [ ] API key / 토큰 / DB 패스워드가 코드 본문에 평문 박힘 0건
- [ ] `.env` / `credentials.json` / `*.key` / `*.pem` 같은 secret 파일 commit 0건 (.gitignore 검증)
- [ ] 로그 호출에 비밀번호·토큰·세션ID 직접 출력 0건 (observability-guide.md §민감정보 위반)
- [ ] PR diff 본문에 secret 인용 (재발급 필요)

### C. 입력 검증 (decision-catalog-template.md §4 default — whitelist + 거부 시 4xx)

- [ ] 외부 입력은 함수 진입 직후 검증
- [ ] `eval` / `exec` / `Function()` 호출 0건 (테스트 코드 제외)
- [ ] file path 입력에 path traversal 방지 (`../` 정규화)
- [ ] command injection — shell 호출에 사용자 입력 직접 박힘 0건 (parameterized / escape)

### D. 권한 / IAM

- [ ] 새 endpoint에 인증 + 권한(role/scope) 체크 명시
- [ ] IAM policy에 `Action: "*"` 또는 `Resource: "*"` 과도 권한 0건 (least privilege)
- [ ] secret manager / KMS 키 접근 권한이 최소 필요 principal로 제한

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | 인증 우회 / SQL injection / XSS exploitable / secret 코드 commit / `eval`에 사용자 입력 직결 — 머지 차단 + 즉시 보고 |
| Important | 입력 검증 약화 (whitelist → blacklist) / IAM 과도 권한 / 로그에 토큰 마스킹 안 됨 / CSRF 보호 누락 |
| Nit | secret 변수명이 grep 친화적이지 않음 (검색 시 누락 위험) / 에러 메시지에 내부 path 노출 |
| Optional | secret rotation 주기 명시 권고 / KMS 키 권한 추가 분리 권고 |
| FYI | 같은 OWASP 카테고리 안티패턴이 다른 모듈에 보임 (본 PR 범위 외 — 후속 audit 권고) |

## 출력 5단 보고 양식

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {파일 경로:라인 + endpoint·함수명 + 노출 자산}
[문제] {어떤 입력·시나리오로 어떤 자산이 노출되는지 구체적으로}
[현재 영향] {exploit 시 영향 범위 + 데이터 손실·인증 우회·코드 실행 가능성}
[결정 권고] {Critical=즉시 차단 / Important=수정 후 머지 + 운영자 결정 / Nit=권고}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

### A. SQL injection — 교묘한 우회 패턴

1. **string concat → parameterized query "절반 적용"** — Critical
   ```python
   # nope: 사용자 입력의 일부만 parameterized
   query = f"SELECT * FROM users WHERE role = '{role}' AND id = ?"
   cursor.execute(query, (user_id,))  # id만 안전, role은 raw concat
   ```
   parameterized query는 모든 동적 값에 적용해야 함. 한 변수라도 raw concat이면 우회 가능.

2. **ORM 사용 중에도 raw query 부분 호출** — Critical
   ```python
   # nope: ORM 쓰지만 ORDER BY를 사용자 입력으로 string concat
   User.objects.raw(f"SELECT * FROM users ORDER BY {sort_field}")
   ```
   `sort_field`에 `id; DROP TABLE users; --` 박히면 실행. ORM 사용 외관이 false sense of security 유발.

3. **stored procedure도 dynamic SQL 호출 시 injection 가능** — Important
   procedure 내부 `EXECUTE @sql` 패턴에 외부 입력 박힘. 호출 측 parameterized로는 막을 수 없음 — procedure 본문 검증 필요.

### B. XSS — escape 적용 누락 패턴

1. **template engine 자동 escape 우회 호출** — Critical
   ```html
   <!-- Jinja2 / Django template -->
   {{ user_bio | safe }}
   {{ user_html_content | raw }}
   ```
   `|safe` / `|raw` 필터는 자동 escape 비활성화. 사용자 입력을 본 필터로 통과시키면 XSS exploitable.

2. **DOM API로 직접 HTML 삽입** — Critical
   ```javascript
   // nope: innerHTML / outerHTML / document.write 사용자 입력 직결
   element.innerHTML = userComment;
   ```
   `textContent` / `innerText` 또는 DOM API(`createTextNode`)로 우회.

3. **URL 컨텍스트에서 escape 누락** — Important
   ```html
   <a href="{{ user_provided_url }}">Click</a>
   ```
   `javascript:alert(1)` 형식 URL 박히면 click 시 실행. URL allowlist(http/https만) 검증 필요.

### C. SSRF — 내부 IP / metadata endpoint 접근

1. **사용자 URL fetch + 검증 없음** — Critical
   ```python
   # nope: 사용자가 169.254.169.254(AWS metadata) URL 박을 수 있음
   response = requests.get(user_provided_url)
   ```
   private IP 대역(10.x / 172.16.x / 192.168.x / 169.254.x / localhost) 차단 + redirect 추적 차단 필요.

2. **DNS rebinding 미고려** — Important
   초기 DNS lookup은 public IP인데 retry 시점 DNS가 private IP로 응답하는 공격. URL fetch 라이브러리 자체에서 IP pinning + private 대역 차단해야 함.

### D. 인증 / 권한 우회

1. **로그에 토큰 평문 출력** — Critical
   ```python
   logger.info(f"Auth header: {request.headers}")
   logger.debug(f"Session: {session.cookies}")
   ```
   observability + security 동시 위반. 로그 수집 시스템(Datadog 등)에 토큰 누적 → exposure window 확장.

2. **인증 미들웨어 우회용 path 추가** — Critical
   새 endpoint 추가 시 인증 라우터 그룹 밖에 박음 ("내부용이라 괜찮음" 정당화). 사후 노출 시 인증 우회.

3. **권한 체크를 client-side로 위임** — Critical
   ```javascript
   // nope: 프론트가 role 보고 endpoint 호출 차단
   if (user.role === "admin") fetch("/api/delete-user")
   ```
   client는 우회 가능. 항상 server-side에서 권한 검증 + role claim 서명 확인.

4. **JWT 검증에 `alg: none` 허용** — Critical
   라이브러리 default 설정 또는 `verify=False` 호출. 공격자가 임의 JWT 생성 후 통과 가능.

### E. secret 노출

1. **`.env.example`에 placeholder로 박았는데 실제 값 포함** — Critical
   git diff 시 발견되면 즉시 rotation 필요. `git log -p`로 history에도 박혔으면 force-push 정리 + secret rotation 필수.

2. **commit 후 revert로 "지운 줄 알았는데" history 잔존** — Critical
   revert는 diff만 되돌릴 뿐 history에서 제거 X. `git filter-repo` 또는 BFG로 history 재작성 후 force-push 필요.

3. **CI 로그에 secret 출력** — Important
   `set -x` + secret 변수 사용 시 CI 로그에 echo됨. GitHub Actions의 `mask` 기능 / secret env 직접 사용 + log redaction 필요.
