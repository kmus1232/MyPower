# scope-clarity-reviewer 체크리스트 (2층)

> 1층 `agents/scope-clarity-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + §6.3.5 분류 A "plan scope 위반" 인용.

## 핵심 질문

> "Out of scope 명시됐나? scope creep 있나?"

## sub-checklist

### A. spec `## Out of Scope` 섹션 존재 + 명시적 항목

- [ ] spec 본문에 `## Out of Scope` 또는 동등 섹션 존재
- [ ] out-of-scope 항목이 1개 이상 명시 (빈 섹션 불가)
- [ ] out-of-scope 항목이 "다른 IDE 지원" 같은 비목표 + "v1.1 백로그 항목" 두 종류 분리

### B. plan step의 in-scope 검증

- [ ] plan의 모든 step이 spec in-scope 영역만 다룸
- [ ] 어느 step도 out-of-scope 항목을 작업 대상으로 박지 않음
- [ ] step{N}.md `## 작업` 섹션 파일 경로가 spec 영역 안에 위치

### C. PR scope creep 식별

- [ ] PR diff에 plan 없이 추가된 새 항목 0건
- [ ] PR 본문에 "while I was here" / "겸사겸사" 류 부가 변경 0건
- [ ] LLM이 자율 판단으로 추가한 step이 plan 본문에 사후 반영됨 (반영 안 됐으면 분류 A 격상)

### D. out-of-scope → in-scope 이동 절차

분류 A "plan scope 위반" 발생 시 spec §6.3.5 절차 준수:
- [ ] 운영자 승인 텍스트 인용
- [ ] `docs/adrs/YYYY-MM-DD-{slug}-scope-{n}.md` ADR commit 동반
- [ ] plan/spec out-of-scope → in-scope 이동 commit 동반
- [ ] scope_class 재검토 (light → standard → heavy 격상 여부)

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | spec out-of-scope 명시 항목을 PR이 침범 / plan scope 위반인데 ADR·plan 갱신 commit 없음 / 운영자 승인 텍스트 인용 없음 |
| Important | scope creep — plan에 없는 부가 변경이 PR에 포함 / "while I was here" 류 사후 합리화 / 자율 추가 step이 plan 본문에 미반영 |
| Nit | out-of-scope 항목 표현이 모호 ("기타 등등") — 명시화 권고 |
| Optional | scope 변경 사유가 PR 본문에 1줄로만 박힘 — ADR로 격상 권고 (현재도 진행 가능) |
| FYI | 본 PR 통과 가능하지만 같은 패턴이 다른 PR에 자주 보임 — 후속 audit 후보 |

## 출력 5단 보고 양식 — spec §7.2 인용

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {PR 변경 위치 + spec/plan scope 정의 위치}
[문제] {어떤 out-of-scope 침범 / scope creep 어디서}
[현재 영향] {운영자 의도(brainstorming 합의) 사후 무효화 / 통제력 상실}
[결정 권고] {Critical=BLOCK + ADR 요구 / Important=수정 후 머지 / Nit=명시화}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **"while I was here"로 부가 변경** — scope에 명시되지 않은 신규 endpoint·파일 신설을 PR 본문에 부가 변경으로 포함. BLOCK 권고. Critical
2. **out-of-scope 항목을 refactor 명목으로 추가** — spec "Out of Scope"에 박힌 항목을 PR에서 슬쩍 추가하면서 refactor라고 정당화. BLOCK 권고. Critical
3. **LLM 자율 step 추가 + plan 미갱신** — executing-plan이 자율로 step 만들어 진행했는데 plan 본문은 그대로. plan을 죽은 문서로 만듦 — BLOCK + plan 갱신 요구. Critical
