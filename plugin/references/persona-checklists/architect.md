# architect-reviewer 체크리스트 (2층)

> 1층 `agents/architect-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + decision-catalog-template.md §6 인용.

## 핵심 질문

> "이 변경이 아키텍처 경계 깨거나 의존성 방향 뒤집는가?"

## sub-checklist

### A. 의존성 import 방향 (decision-catalog-template.md §6 default)

- [ ] domain → infra 단방향 보존 — domain 모듈이 infra 구현체를 직접 import 안 함
- [ ] infra → domain 0건 — DB·HTTP·외부 SDK 모듈이 domain 타입을 거꾸로 import 시 critical
- [ ] cross-domain (예: A domain → B domain) 시 별도 ADR 또는 application 레이어 경유

### B. 아키텍처 경계 신규 추가

- [ ] 새 레이어·모듈·경계 도입 시 `docs/adrs/YYYY-MM-DD-{slug}-arch-{n}.md` ADR 존재
- [ ] `docs/ARCHITECTURE.md` 파일이 repo에 있으면 같은 PR에서 갱신 동반
- [ ] 분류 B 아키텍처 변경 자율 결정 → ADR 작성 후 진행 (spec §6.3.5 분류 B 인용)

### C. 추상화 누수

- [ ] infra 세부사항(SQL 쿼리·HTTP 헤더·외부 API 응답 schema)이 domain 시그니처에 새지 않음
- [ ] domain 함수가 infra 예외(SQLException, HttpException 등) 직접 throw 안 함 — domain 예외로 래핑
- [ ] domain 타입에 infra 의존 필드(`postgres_id`, `http_status_code`) 노출 0건

### D. 단일 책임 / 의도 보존

- [ ] 새 함수·클래스가 단일 책임 — 한 함수에 입력 검증 + DB 쓰기 + 외부 호출 + 응답 변환 동시 0건
- [ ] step{N}.md `## 작업` 섹션의 "시그니처 수준"과 PR 시그니처 일치

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | infra → domain 역방향 import 발생 / `terraform destroy` 같은 의존 역전이 도입됨 / 아키텍처 경계 추가했는데 ADR + ARCHITECTURE.md 갱신 둘 다 누락 |
| Important | 추상화 누수 (domain이 SQL 예외 throw) / 단일 책임 위반 심각 (한 함수 100줄 + 3가지 책임) |
| Nit | 함수 분할 권고 (현재도 단일 책임 만족하나 더 작게 분할 가능) / domain 타입에 미세한 infra 명칭 노출 |
| Optional | `docs/ARCHITECTURE.md` 본문 다이어그램 보강 권고 (변경 자체는 정상) |
| FYI | 같은 추상화 누수 패턴이 다른 모듈에도 보임 (본 PR 범위 외 — 후속 ADR 권고) |

## 출력 5단 보고 양식

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {파일 경로:라인 + 모듈·레이어 위치}
[문제] {어떤 경계가 깨졌나 / 의존성 방향이 어떻게 뒤집혔나 구체적으로}
[현재 영향] {추후 모듈 분리·테스트 격리·재사용에 어떤 비용 발생하는지}
[결정 권고] {Critical=차단 + ADR 요구 / Important=수정 후 머지 / Nit=권고}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

### A. 의존성 방향 역전 (infra → domain)

1. **DB 마이그레이션을 domain 함수에 박음** — Critical
   ```python
   # domain/user.py — nope
   import psycopg2  # infra 모듈 직접 import
   def get_user(user_id):
       conn = psycopg2.connect(...)
       row = conn.execute("SELECT ... WHERE id=%s", (user_id,))
   ```
   domain이 PostgreSQL에 강결합. 다른 DB 교체 / 테스트 격리 / mock 작성 불가. **올바른 패턴**: domain은 `UserRepository` 인터페이스만 선언, `infra/postgres/user_repository.py`가 구현.

2. **infra의 SQL 예외가 domain까지 누수** — Critical
   ```python
   # nope: domain 함수가 psycopg2.OperationalError 직접 throw
   def get_user(user_id):
       try: return repo.find(user_id)
       except psycopg2.OperationalError: raise  # domain 시그니처에 infra 예외 노출
   ```
   호출자가 PostgreSQL 예외에 의존. **올바른 패턴**: infra layer에서 catch + `UserNotFoundError` 같은 domain 예외로 wrap.

3. **infra 모듈이 domain 타입을 import** — Critical
   ```python
   # infra/postgres/user_repo.py — nope
   from infra.s3 import S3Client  # ok (cross-infra)
   from domain.user import User  # OK (interface 구현이므로 의존 허용)
   from infra.auth import Token  # cross-infra 직접 의존 = 분리 필요
   ```
   cross-infra는 application layer 경유. 직접 import는 ADR 없으면 차단.

### B. 추상화 누수 (abstraction leak)

1. **domain 타입에 HTTP / SQL 명칭** — Important
   ```python
   # domain/order.py — nope
   class Order:
       postgres_id: int      # SQL 의존 명칭
       http_status_code: int # HTTP 의존 명칭
   ```
   **올바른 패턴**: `id: OrderId` + `status: OrderStatus` (domain enum).

2. **응답 변환을 controller에 빠뜨리고 domain이 HTTP status code 결정** — Important
   ```python
   # nope
   def get_order(id):
       order = repo.find(id)
       if order is None: return 404, None  # HTTP 코드 domain이 결정
       return 200, order
   ```
   **올바른 패턴**: domain은 `Optional[Order]` 반환, controller가 `None → 404` 매핑.

3. **JSON serialize 코드가 domain에 박힘** — Important
   ```python
   # domain/user.py — nope
   class User:
       def to_dict(self): return {"id": str(self.id), ...}  # serialize 의존
   ```
   **올바른 패턴**: `infra/serializers/user.py`에 직렬화 코드 분리.

### C. 단일 책임 위반

1. **한 함수에 입력 검증 + DB 쓰기 + 외부 호출 + 응답 변환** — Important
   ```python
   def create_order(req):
       if not req.user_id: raise ValueError(...)  # 검증
       order = db.insert(...)                      # DB
       payment.charge(order.total)                 # 외부 호출
       return {"id": str(order.id), ...}           # 변환
   ```
   100줄 + 4가지 책임. **올바른 패턴**: validator / repository / payment service / serializer 분리.

2. **하나의 모듈이 application + infra 책임 양쪽** — Important
   `services/order_service.py`가 DB 호출 + business logic + HTTP 응답 변환. layer 책임 명확화 필요.

### D. 분류 B 자율 결정 + ADR 누락

1. **새 외부 SDK 도입 + ARCHITECTURE.md 미갱신 + ADR 미작성** — Critical
   의존성 도입은 분류 B(라이브러리 추가). ADR 없으면 향후 의존성 추적 누수 + 의존성 보안 audit 누락.

2. **새 layer 도입 (application → service layer 추가) + ADR 없음** — Critical
   layer 경계 신규 = 분류 B 자율 결정 대상이나 ADR + ARCHITECTURE.md 갱신 동반 필수.

3. **cross-domain 직접 import (A domain → B domain) + 정당화 없음** — Important
   `domain/order` → `domain/user` 직접 import. **올바른 패턴**: application layer 경유 또는 별도 ADR.

### E. 페르소나 본인 lens 일탈

1. **"이상해 보이는" 코드를 architect lens로 flag** — Nit
   단순 가독성 / 함수명 / 변수명 문제는 code-quality-reviewer 영역. architect는 layer 경계·의존 방향·추상화 누수에 한정.

2. **타입 시스템 미사용 자체를 architect critical로 박음** — Nit
   타입 추가는 분류 B 자율 결정. architect는 타입 시스템이 어떤 layer 경계를 표현하는지에만 관심.
