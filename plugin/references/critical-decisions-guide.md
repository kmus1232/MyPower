# 크리티컬 의사결정 가이드

`executing-plan` subagent가 결정 갈림길에 부딪힐 때 적용. 본 가이드는 spec §6.3.5 + §9.2.3 단일 진실 출처.

## 모호 시 원칙

분류가 애매하면 **분류 A로 분류**. 안전 원칙 — 잘못 A로 분류한 비용은 "운영자 한 번 더 누름"이지만, 잘못 B로 분류한 비용은 "운영자 의도 이탈 + 사후 발견·복구".

## 분류 A — 크리티컬 (운영자 명시 승인 필수, 진행 일시 중단)

| 카테고리 | 예시 |
|---|---|
| 보안 정책 | 인증/권한 변경, secret 처리, 입력 검증 정책 |
| 데이터 스키마 | DB migration, 테이블/컬럼 변경, 데이터 손실 가능성 |
| 비용 영향 큼 | 새 AWS 서비스, 비싼 인스턴스, Datadog 커스텀 메트릭 카디널리티 폭증 |
| **plan scope 위반** | plan에 없는 기능·endpoint·파일 추가. 자율 진행 시 운영자 합의 사후 무효화 위험. **반드시 운영자 승인 후 plan/spec 갱신** |

## 분류 B — 자율 + ADR

자율 진행하되 ADR(`docs/adrs/YYYY-MM-DD-{slug}-{n}.md`)로 기록 → 운영자 사후 검토.

| 카테고리 | 자동 처리 |
|---|---|
| 라이브러리 버전·외부 호출 retry/timeout·에러 정책·기본값·로깅 레벨·새 dependency·test coverage·perf 함정 | ADR 작성 후 진행 |
| **아키텍처 경계 변경** | ADR + (있다면) `docs/ARCHITECTURE.md` 자동 갱신. PR 리뷰 단계에서 architect-reviewer가 사후 검토 |

### plan scope 위반은 분류 B에서 제외 — 분류 A로 격상

이유: 자율 진행 시 운영자가 brainstorming에서 합의한 scope가 사후 무효화되어 통제력 상실. plan scope 변경은 의도 변경이므로 운영자 승인 필요. 절차:

1. 즉시 진행 일시 중단 (분류 A 동작)
2. 운영자에 분류 A 게이트 형식으로 보고 — 무엇을·왜 추가하려 하는지 + 트레이드오프
3. 운영자 답:
   - "승인 + plan 갱신" → ADR 작성 + plan/spec 갱신 후 재개
   - "거부, 우회 방법 제시" → 다른 옵션 모색
   - "plan 갱신 후 재시작" → writing-plan으로 회귀
4. 승인 후 ADR (`docs/adrs/YYYY-MM-DD-{slug}-scope-{n}.md`) + plan 파일 + spec out-of-scope→in-scope 이동
5. scope_class 재검토 — light/standard/heavy 격상 발생 시 운영자에 별도 보고 후 `index.json.scope_class` 갱신

## 분류 C — 자율 (ADR 불필요)

변수명·함수명 (프로젝트 컨벤션 따름) / 로깅 위치 (observability-guide 따름) / 사소한 코드 구조·주석.

## 게이트 형식 (분류 A 도달 시 운영자 호출)

```
[크리티컬 결정 요청] {카테고리}

## 상황
{왜 결정 필요}

## 옵션
1. {옵션 1} — 트레이드오프
2. {옵션 2} — 트레이드오프

## 추천
{LLM 추천 + 이유}

## 영향
{시스템에 미치는 영향}
```

운영자 답: "옵션 N으로 진행" / "다른 옵션 X" / "plan 갱신 후 재시작".

## 안티패턴

- "이번만 운영자 안 물어보고 진행" — 분류 A 우회 시도
- "분류 B인데 ADR 생략" — 사소한 결정 누적 = 의도 이탈
- "scope 위반인데 plan 갱신 안 함" — plan을 죽은 문서로 만듦

> [!CAUTION]
> 자율 결정을 ADR로 기록하지 않고 진행하면 HARD-GATE 위반. 검증 체크리스트에서 grep으로 점검 (`docs/adrs/` 갱신 시점이 step 진행과 일치하는지).
