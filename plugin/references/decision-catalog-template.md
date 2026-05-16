# 결정 카탈로그 템플릿 (SRE/플랫폼 도메인 default)

> step{N}.md `## 결정 카탈로그` 섹션에서 "default 따름" 인용 시 본 파일 §X 참조. fork 시 다른 도메인 운영자는 본 default를 갈아끼움.
>
> 각 default 다음의 `근거:` 줄은 fork 운영자가 자기 도메인 default로 교체할 때 **무엇을 바꿔야 하는지 판단하는 anchor**다. 단순 복붙이 아니라 근거를 비교한 뒤 채택·교체·예외 처리한다.

## §1 에러 정책 default

- raise + 구조화 로그 (`{level: ERROR, stack, context.request_id}`)
- HTTP 응답 4xx는 입력 검증 실패, 5xx는 내부 에러로 분리

> 근거: SRE 도메인은 사후 분석(post-mortem)에서 에러 origin 추적이 필수. silent catch 대비 raise + 구조화 로그가 trace 보존. 4xx/5xx 분리는 외부 사용자 책임(클라이언트 측 수정) vs 내부 책임(개발자 측 수정) 구분을 HTTP semantics에 위임 — 별도 분기 코드 0건.

## §2 로깅 레벨 + 메시지 포맷 default

- INFO 기본. 함수 진입·외부 호출 직전/직후 INFO. 이상 분기 WARN. 예외 ERROR
- 포맷: JSON 구조화 + 필수 필드 (`timestamp`, `level`, `request_id`, `message`)

> 근거: 함수 진입·외부 호출 경계가 1분 안에 원인 짚는 anchor(`observability-guide.md` self-check 4항목). JSON + 필수 필드 4개는 Datadog/Loki/CloudWatch 등 다수 백엔드가 공통 파싱 가능한 최소 schema — 백엔드 교체 시 재작성 0건.

## §3 retry · timeout default

- 외부 호출 retry: 지수 backoff 3회 (초기 100ms, max 1s)
- timeout: 5s (long-running batch는 step 본문에 별도 명시)

> 근거: 3회 backoff = transient(0.1~1s 단위 일시 장애) 흡수 + cascade 방지 균형. 4회 이상은 cascade 위험·총 대기 시간 폭증. timeout 5s = 일반 HTTP API 평균 p99 대비 안전 margin. long-running batch는 timeout이 의미 없어 별도 처리.

## §4 입력 검증 정책 default

- whitelist + 거부 시 4xx + `Invalid input: {field}` 메시지
- 외부 입력은 함수 진입 직후 검증, 내부 호출은 검증 생략

> 근거: blacklist는 새 공격 패턴마다 패치 필요해 유지 부담 폭증. 외부 입력 = trust boundary 진입점 — 검증을 trust boundary에 집중하면 내부 함수는 신뢰 전제 + 코드 단순. 내부 호출까지 검증하면 코드 노이즈만 늘고 안전성은 동등.

## §5 데이터 스키마 default

- 영구 저장 없음. 임시 캐시는 in-memory dict
- DB 필요 시 분류 A 게이트로 격상 — spec §6.3.5 보안·데이터 스키마 카테고리

> 근거: 스킬 프레임워크 v1 자체가 stateless — DB 도입은 운영 부담 + backup·migration·schema evolution 책임 동반. v1 scope 밖. 분류 A 격상해 운영자 명시 결정 + ADR 필수.

## §6 의존성 import 방향 default

- domain → infra 단방향
- infra → domain 금지 (역방향 발견 시 architect-reviewer Critical)

> 근거: 역방향 import 허용 시 infra 변경이 domain 의미 변경을 강제 — 도메인 로직이 인프라 변경마다 부서짐. 단방향은 hexagonal/onion architecture 공통 원칙. mypower fork 시에도 도메인 무관 보존하는 게 권고 default.
