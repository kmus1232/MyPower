# spec-compliance-reviewer 체크리스트 (2층)

> 1층 `agents/spec-compliance-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 단일 진실 출처.

## 핵심 질문

> "이 PR이 spec/plan과 정확히 일치하는가? 추가/누락/scope 위반?"

## sub-checklist

### A. PR diff와 plan의 대응

- [ ] PR diff의 모든 파일 변경이 plan의 명시된 step에 매핑된다 (step{N}.md의 `## 작업` 섹션과 파일 경로 1:1 비교)
- [ ] step{N}.md `## 작업` 섹션에 명시되지 않은 파일을 PR에서 수정 안 함 (공통 import 파일 제외 — 사전 합의된 경우만)
- [ ] step{N}.md `## 금지사항`에 박힌 행위가 PR에 없음
- [ ] step{N}.md `## Acceptance Criteria` 명령이 PR 본문 또는 verifying 보고서에 출력 인용으로 박혀 있음

### B. spec out-of-scope 침범 여부

- [ ] spec `## Out of Scope` 섹션 항목 중 PR에 포함된 것 0건
- [ ] 새 endpoint / 새 파일 / 새 의존성 / 새 데이터 모델이 plan에 사전 명시됨

### C. 자율 결정 갱신 동반

- [ ] 분류 B 자율 결정 발생 시 `docs/adrs/YYYY-MM-DD-{slug}-{n}.md` ADR 동반 commit
- [ ] 분류 A 도달 시 운영자 승인 텍스트 인용 + plan/spec 갱신 commit이 PR에 포함

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | plan에 없는 새 endpoint·새 파일·새 의존성을 PR에서 자율 도입했고 ADR·plan 갱신 commit 없음 (spec §6.3.5 분류 A "plan scope 위반"). spec `Out of Scope` 명시 항목을 PR이 침범 |
| Important | plan AC 명령 출력 인용 누락 / 분류 B 자율 결정 발생했는데 ADR 파일 없음 / 공통 import 파일 사전 합의 없이 수정 |
| Nit | 변수명·함수명이 plan 시그니처와 다름 (의도 보존되면 통과) / step{N}.md `## 금지사항` 인용 누락 |
| Optional | plan AC 출력 인용 형식이 일관성 부족 (PASS 흐름은 정상) |
| FYI | step{N}.md `## 읽어야 할 파일` 목록이 실제 참조 파일과 약간 어긋남 (참조는 정확) |

## 출력 5단 보고 양식

페르소나가 finding 작성 시 그대로 복사:

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {PR 변경 위치 + plan/spec 인용 위치}
[문제] {spec/plan과 어긋난 지점 명확히}
[현재 영향] {머지 시 무엇이 깨지는가 / 운영자 의도 이탈 여부}
[결정 권고] {Critical=차단 / Important=수정 후 머지 / Nit=운영자 선택}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **"while I was here" 리팩터링** — 다른 파일 수정 김에 plan에 없는 리네이밍·구조 변경 슬쩍 추가. PR diff 변경 행수가 plan 시그니처 추정 범위 초과 시 의심
2. **공통 import lib 사후 추가** — 새 helper 함수·utility 모듈을 "공통이라 예외"로 정당화. plan에 사전 합의 없으면 scope 위반
3. **out-of-scope 데이터 모델 변경** — spec `Out of Scope`에 박힌 DB schema 변경이 PR에 포함되는데 plan 갱신 없음 / ADR 없음. 분류 A 격상 대상
