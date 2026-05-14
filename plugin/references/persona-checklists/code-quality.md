# code-quality-reviewer 체크리스트 (2층)

> 1층 `agents/code-quality-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + tdd-guide.md 인용.

## 핵심 질문

> "버그 가능성·이름·테스트 빠짐·뻔한 perf 함정 어디?"

## sub-checklist

### A. correctness lens (버그 가능성)

- [ ] null / undefined check 누락 — 외부 입력·DB 응답·옵셔널 필드에서
- [ ] boundary condition — 배열 빈 케이스 / 첫·끝 인덱스 / 음수 입력
- [ ] off-by-one — 루프 `<` vs `<=`, slice 종료 인덱스
- [ ] 비동기 race condition — Promise.all 의도 / event handler 등록 순서 / mutable shared state

### B. readability lens

- [ ] 변수명·함수명이 의도 표현 (`tmp`·`data`·`result` 같은 의미 빈약 이름 0건)
- [ ] nested depth 3 초과 0건 (early return 또는 함수 추출로 평탄화)
- [ ] magic number — 상수 추출 없이 본문에 박힌 숫자 (단 `0`·`1`·`-1` 등 관용은 예외)

### C. 테스트 lens (tdd-guide.md 인용)

- [ ] RED 단계 실패 출력이 step 보고에 인용됨
- [ ] GREEN 단계 통과 출력이 step 보고에 인용됨
- [ ] 테스트가 production 코드 *전에* 작성됨 (커밋 순서 또는 작업 메모로 확인)
- [ ] `scope_class=light` + 운영자 명시 승인 외에 RGR skip 0건

### D. perf 함정 lens (본격 perf 분석 X — 뻔한 패턴만)

- [ ] N+1 query — 루프 안 DB 호출 / ORM lazy loading 트리거
- [ ] unbounded loop — 입력 크기 제한 없이 외부 입력 순회
- [ ] 메모리 누수 의심 — 이벤트 리스너 등록 후 해제 누락 / 캐시 무한 누적

> 본격 perf 분석은 §1.3 비목표 — 별도 도구 영역. 본 페르소나는 명백한 안티패턴만 flag.

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | 명백한 버그 (null dereference, off-by-one) / 테스트 없이 production 코드 + light scope 예외 적용 안 됨 / silent catch로 에러 삼킴 |
| Important | N+1 query 패턴 / 가독성 심각 (한 함수 100줄 + nested 5단) / 비동기 race 가능성 |
| Nit | 변수명 개선 / nested 3 → 2로 평탄화 권고 / magic number 상수 추출 |
| Optional | early return 으로 readability 개선 가능 (현재도 동작) / 함수 분할 |
| FYI | 같은 패턴이 다른 파일에도 보임 (본 PR 범위 외) |

## 출력 5단 보고 양식

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {파일 경로:라인 + 함수명 + 의도}
[문제] {어떤 입력·시나리오에서 무엇이 깨지는가 구체적으로}
[현재 영향] {운영 시 발생 시나리오 / 테스트 누락 시 회귀 위험}
[결정 권고] {Critical=차단 / Important=수정 후 머지 / Nit=운영자 선택 / Optional=보고서만}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **silent catch + 무지원 에러 전파** — `try { ... } catch (e) {}` 또는 `except: pass`로 에러 삼킴. observability-guide §에러 핸들링 위반과 동시 발생. Critical
2. **테스트 통과만 확인 + 명령 출력 인용 누락** — IDE 초록 표시 봤다고 GREEN 명령 출력 인용 생략. tdd-guide Rationalizations 위반. Critical
3. **루프 안 외부 호출 (N+1)** — 100개 row 처리에 100번 DB·API 호출. unbounded 입력일 경우 운영 장애 직결. Important
