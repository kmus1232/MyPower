# ambiguity-hunter 체크리스트 (2층)

> 1층 `agents/ambiguity-hunter.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + §6.1.3 분류 A 카테고리 + ambiguity-protocol.md 인용.

## 핵심 질문

> "둘 이상 해석 가능한 표현·모호 부사 어디?"
> + "§6.1.3 분류 A 6개 카테고리(보안/스키마/비용/scope/TDD framework/로깅 정책)가 spec에 결정값으로 박혔나? '적절히/필요시/추후' 같은 부사가 분류 A 결정 자리에 들어가 있나?"

## sub-checklist

### A. placeholder 잔존 grep

- [ ] `TBD` / `TODO` / `FIXME` / `XXX` 0건 (단 의도된 섹션 헤더는 예외 — 예: ARP의 `## 5. 미해소 항목 (TODO)`)
- [ ] 본문 `{slug}` / `{name}` / `{N}` 0건 (단 가이드성 ADR 파일명 패턴 또는 템플릿 본문은 예외)
- [ ] `...` 으로 끝나는 결정 자리 (예: "응답 형식은 ...")

### B. 한국어 모호 부사 — 분류 A 결정 자리

§6.1.3 분류 A 6 카테고리 결정 자리에 다음 부사가 박혔는지 맥락 인식 검사 (단순 grep 아님):

- [ ] "적절히" — "권한은 적절히 부여" 같은 표현이 보안 정책 자리에 박힘
- [ ] "필요시" — "필요시 캐시 도입" 같은 표현이 비용 영향 자리에 박힘
- [ ] "추후" — "스키마는 추후 결정" 같은 표현이 데이터 스키마 자리에 박힘
- [ ] "유연하게" / "상황에 맞게" / "기본값으로" (구체적 default 없이)

### C. 다중 해석 가능 요구사항

- [ ] "사용자가 빠르게 검색할 수 있어야 한다" 같은 비측정 표현 (몇 ms? 어떤 쿼리?)
- [ ] "안전하게 처리" — 어떤 위협 모델·어떤 검증 단계인지
- [ ] "효율적으로" — 시간 / 메모리 / 토큰 어느 쪽인지

### D. 산문 영역 vs 결정 영역 구분

- [ ] 모호 부사가 산문(배경 설명 / 트레이드오프 단락)에 등장 → 의도적 일반화 → 허용
- [ ] 모호 부사가 결정 자리(spec §의 결정값 / step `## 작업` / 분류 A 응답) → 모호성으로 처리 → flag

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | 분류 A 결정 자리에 모호 부사 ("인증 정책: 추후 결정") / placeholder 잔존 (`TBD`·`TODO`) — executing-plan 시점 needs_context 발동 강제 |
| Important | 기능 요구사항 다중 해석 가능 ("빠르게" / "효율적으로") — 측정 단위 / 임계값 결정 권고 |
| Nit | 산문 영역에 모호 부사가 결정처럼 보이는 위치 — 단락 재배치 권고 |
| Optional | 의도적 일반화로 둘 수 있지만 명시화 권고 (현재도 진행 가능) |
| FYI | 본인 user memory에 누적된 패턴 인용 — 다른 PR에도 보이는 재발 이슈 (anchoring 방지 lens 1층 적용) |

## 출력 5단 보고 양식

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {spec/plan 위치 + 모호 표현 인용}
[문제] {둘 이상 해석 가능한 지점 또는 분류 A 결정 자리 누락}
[현재 영향] {executing-plan 시점 needs_context 발생 가능성 / 운영자 해석 차이로 인한 의도 이탈}
[결정 권고] {Critical=결정값 박기 / Important=측정 단위 명시 / Nit=단락 재배치}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **"기본값 사용"으로 분류 A 회피** — "에러 응답은 기본값 사용"이라고만 적고 default가 어디 정의됐는지 명시 없음. decision-catalog-template.md 인용 강제. Critical
2. **이전 PR에서 본 패턴 anchoring** — user memory에 박힌 이전 결정값을 새 PR에 강제 적용. 실제로는 도메인 다름. memory는 참고용 — 현재 코드 본문이 1순위 증거. Important
3. **placeholder 의도적 vs 누락 혼동** — `{slug}` 같은 표기가 가이드 안내 의도일 때 false positive flag. ambiguity-protocol.md "미해소 항목 (TODO)" 같은 정상 섹션도 false positive 위험 — 의도 구분 lens 필요
