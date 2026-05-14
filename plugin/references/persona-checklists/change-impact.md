# change-impact-reviewer 체크리스트 (2층)

> 1층 `agents/change-impact-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 인용. applying 검증 팀 3명 중 1명.

## 핵심 질문

> "이 변경이 영향 주는 컴포넌트·파일·외부 시스템 목록?"

## sub-checklist

### A. 변경 파일 → 의존 컴포넌트 매핑

- [ ] PR diff의 각 파일에 대해 grep으로 import 추적 — 본 파일을 import 하는 다른 파일 목록 확보
- [ ] import 추적 결과를 PR 본문 "영향 컴포넌트" 단락에 기재
- [ ] 추적 누락이 있는지 cross-check (import 7곳인데 본문엔 3곳만 명시 같은 사례)

### B. 외부 시스템 호출 변경

- [ ] API endpoint 추가·변경·삭제 (소비자 마이그레이션 영향)
- [ ] SQL 쿼리 변경 (인덱스·실행 계획·트랜잭션 영향)
- [ ] S3 키 / Datadog 메트릭 / SNS topic 등 외부 자산 식별자 변경
- [ ] 외부 API 응답 schema 1필드 추가·제거·타입 변경 (소비자 측 호환성)

### C. 영향 범위 단계별 평가

- [ ] L1: 변경 파일 본인
- [ ] L2: 변경 파일을 import 하는 직접 소비자
- [ ] L3: L2를 다시 import 하는 간접 소비자 (transitive — 통상 1단계까지만 본 페르소나가 추적)

### D. PR 본문 "영향 컴포넌트" 단락 검증

- [ ] PR 본문에 영향 범위 단락 존재
- [ ] 단락에 L1·L2 모두 명시 (L3는 선택)
- [ ] 외부 시스템 호출 변경이 있으면 별도 sub-단락으로 기재

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | 외부 API 응답 schema 변경 + 소비자 측 마이그레이션 미언급 — 머지 즉시 소비자 장애 / SQL 쿼리 변경 + 인덱스 영향 분석 없음 — 운영 시 슬로우 쿼리 |
| Important | import 추적 누락 (PR 본문 "단일 파일 수정"인데 grep 결과 7곳 import) — 영향 범위 과소 평가 / 외부 자산 식별자 변경 (S3 key 등) — 소비자 마이그레이션 권고 |
| Nit | 영향 범위 단락 표현이 단조롭다 (실제 정보는 정확) — 가독성 보강 |
| Optional | L3 transitive 영향까지 추적 권고 (현재 L1·L2 정확) |
| FYI | 같은 import 위치가 다른 PR에서도 자주 등장 — refactor 후보 |

## 출력 5단 보고 양식

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {PR 파일 + grep 결과 영향 컴포넌트 목록}
[문제] {PR 본문 명시 vs 실제 영향 범위 차이 / 외부 시스템 호환성 누락}
[현재 영향] {머지 시 소비자 장애 / 마이그레이션 누락 시나리오}
[결정 권고] {Critical=차단 + 영향 범위 갱신 / Important=수정 후 머지 / Nit=가독성 권고}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **단일 파일 수정처럼 보이지만 import 7곳** — PR 본문 영향 컴포넌트 누락. grep으로 import 추적 강제. Important
2. **외부 API 응답 schema 1필드 추가** — 소비자 측 마이그레이션 영향 미언급. 머지 즉시 schema validation 실패. Critical
3. **SQL 쿼리 변경 + 인덱스 영향 분석 누락** — `WHERE` 절 컬럼 추가 / `ORDER BY` 변경. 실행 계획 변화 + 운영 시 슬로우 쿼리 발생 가능. Important
