# completeness-reviewer 체크리스트 (2층)

> 1층 `agents/completeness-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + §6.1.3 분류 A 6 카테고리 + §6.3.4 step status 인용.

## 핵심 질문

> "spec/plan에 빠진 요구사항·미정의 항목 있나?"
> + "이 step을 다른 세션 LLM이 받았을 때 답 없이 진행 못 하는 질문(executing-plan 시점 `needs_context` 발생 후보)이 무엇인가? 시뮬레이션 1회 후 후보 0건 보장"

## sub-checklist

### A. 요구사항 → step 매핑

- [ ] spec의 모든 기능 요구사항이 plan의 어떤 step에 매핑됐는지 표 생성
- [ ] 매핑 안 된 요구사항 0건
- [ ] step에만 있고 spec에 없는 요구사항 0건 (역방향 누수 — scope creep 신호)

### B. step{N}.md 7섹션 빈 칸 0건

각 step{N}.md 파일이 다음 7섹션 모두 비어있지 않음:
- [ ] `## 읽어야 할 파일`
- [ ] `## 작업`
- [ ] `## Acceptance Criteria`
- [ ] `## 검증 절차`
- [ ] `## 금지사항`
- [ ] `## 결정 카탈로그` (6항목 모두 응답 — 결정값 / "default 따름" / "N/A")
- [ ] (필요 시) `## 영향 범위`

### C. 분류 A 6 카테고리 사전 응답 (§6.1.3)

- [ ] 보안 정책 — spec에 결정값 또는 "default 따름" 박힘
- [ ] 데이터 스키마 — 동일
- [ ] 비용 영향 — 동일
- [ ] scope — `## Out of Scope` 섹션에 명시
- [ ] TDD framework — tdd-guide.md trigger 또는 영역 분류 명시
- [ ] 로깅 정책 — observability-guide.md 인용 또는 별도 결정

### D. needs_context 시뮬레이션

- [ ] 본 plan을 fresh 세션 LLM이 받았다고 가정하고 1라운드 예측
- [ ] "이 부분은 어떻게 결정해야 하나요?" 같은 질문이 떠오를 위치 식별
- [ ] 후보 발생 시 spec/plan 갱신 권고 — 후보 0건 보장이 PASS 조건

### D.1 시뮬레이션 구체 절차

추상적 "예측" 아닌 다음 순서로 grep 기반 검출:

1. **모호 부사 grep**: `grep -nE "(적절히|적당히|필요시|추후|TBD|TODO|이후 결정)" step{N}.md`
   - 매치 1건마다 fresh LLM이 "구체 값 무엇인가?"로 질문 발동.
2. **의존 파일 미명시 grep**: `## 작업` 섹션에 파일 path는 있는데 어느 함수·어느 섹션을 봐야 할지 미명시.
   - 예: "`observability-guide.md` 참조"만 박혀 있고 어떤 § 섹션인지 미명시 → fresh LLM은 "어느 섹션?"으로 질문 발동.
3. **§6.1.3 6 카테고리 응답 누락 grep**: 결정 카탈로그 섹션에 6 카테고리 표가 있는지 검사.
   - 표 누락 또는 빈 셀 1개 이상 → 해당 카테고리에서 분류 A 발동.
4. **AC 명령이 검증 불가능 grep**: `## Acceptance Criteria`에 명령이 박혔는데 출력 형태·통과 조건 미명시.
   - 예: "테스트 통과"만 박힘 → fresh LLM은 "어느 테스트? 어떤 출력?"으로 질문 발동.

### D.2 시뮬레이션 출력 형식 (finding에 그대로 인용 가능)

```
[needs_context 후보 — step3.md 작성]
- L42 "에러 처리는 적절히" → 모호 부사. 결정값 또는 "default 따름(§1 에러 정책)" 박혀야 함
- L58 "observability-guide.md 참조" → 어느 § 섹션 인용? L60처럼 "§9.2.1 로깅 항목" 같은 정확도 필요
- L73 AC "테스트 통과" → 어느 test 파일? 출력 grep 패턴? 명령 1줄로 검증 가능한 형태로 박혀야 함

권고: 위 3건 spec/plan 갱신 후 executing-plan 재진입.
```

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | 분류 A 카테고리 1개 이상 미응답 (예: 보안 정책이 spec/plan 어디에도 박혀있지 않음) — executing-plan 시점 분류 A 발동 후 운영자 호출 강제 |
| Important | step{N}.md 7섹션 중 1개 이상 빈 칸 / needs_context 후보 1건 이상 식별 / 요구사항 → step 매핑 누락 |
| Nit | 요구사항 표현이 단계적으로 분해되어 있지 않음 (executing-plan이 step 안에서 자율 분해 가능) |
| Optional | 추가 step 분리 권고 (현재도 매핑 가능하나 step 크기 다소 큼) |
| FYI | 다음 차수에 추가 검토 권고 (본 spec/plan 통과는 가능) |

## 출력 5단 보고 양식

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {spec/plan 위치 + 누락 카테고리·요구사항}
[문제] {무엇이 빠졌고, executing-plan 시점에 어떤 질문이 발생할지 시뮬레이션 결과}
[현재 영향] {needs_context 발생 시 plan 진행 일시 중단 / 분류 A 발동 시 운영자 호출}
[결정 권고] {Critical=spec/plan 갱신 후 진입 / Important=수정 권고 / Nit=주석 보강}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **결정 카탈로그 6항목 모두 "default 따름"으로 채움** — 정말 default가 맞는지 검증 없이 일괄 적용. 실제로는 비용·스키마 카테고리에 운영자 결정이 필요한 step에서 발견. Important
2. **TDD framework 카테고리 미응답 + 코드 영역 step 존재** — tdd-guide.md "영역 판단 모호 시 TDD 적용" 안전 원칙 적용 안 되어 executing-plan이 자율 skip 결정. Critical
3. **새 요구사항 추가했는데 step 분해 없음** — spec에는 박혔으나 plan의 어떤 step에서 처리하는지 매핑 없음. needs_context 후보. Important
