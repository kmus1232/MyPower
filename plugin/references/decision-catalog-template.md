# 결정 카탈로그 템플릿 (SRE/플랫폼 도메인 default)

> step{N}.md `## 결정 카탈로그` 섹션에서 "default 따름" 인용 시 본 파일 §X 참조. fork 시 다른 도메인 운영자는 본 default를 갈아끼움.

## §1 에러 정책 default

- raise + 구조화 로그 (`{level: ERROR, stack, context.request_id}`)
- HTTP 응답 4xx는 입력 검증 실패, 5xx는 내부 에러로 분리

## §2 로깅 레벨 + 메시지 포맷 default

- INFO 기본. 함수 진입·외부 호출 직전/직후 INFO. 이상 분기 WARN. 예외 ERROR
- 포맷: JSON 구조화 + 필수 필드 (`timestamp`, `level`, `request_id`, `message`)

## §3 retry · timeout default

- 외부 호출 retry: 지수 backoff 3회 (초기 100ms, max 1s)
- timeout: 5s (long-running batch는 step 본문에 별도 명시)

## §4 입력 검증 정책 default

- whitelist + 거부 시 4xx + `Invalid input: {field}` 메시지
- 외부 입력은 함수 진입 직후 검증, 내부 호출은 검증 생략

## §5 데이터 스키마 default

- 영구 저장 없음. 임시 캐시는 in-memory dict
- DB 필요 시 분류 A 게이트로 격상 — spec §6.3.5 보안·데이터 스키마 카테고리

## §6 의존성 import 방향 default

- domain → infra 단방향
- infra → domain 금지 (역방향 발견 시 architect-reviewer Critical)
