# ADR — mypower 변경 이력 관리 정책 (spec slim + git/ADR 단일 진실 출처)

> 작성: 2026-05-11 | 상태: 채택 | 관련 spec: `docs/specs/2026-05-09-mypower-design.md`

## 1. 컨텍스트

mypower spec은 v3.3(1376줄)에서 v3.13(2278줄)까지 누적 65+ 변경 항목 + 자잘한 (T1)~(T12), (D1)~(D7), (E1)~(E13) 마이너 정정 마커를 frontmatter changelog 표 + 본문 인라인 v3.X 마커로 박아왔다. 이는 두 가지 비용을 발생시킨다:

1. **spec 본문 분량 증가** — frontmatter changelog 표 자체가 약 50줄, 본문 인라인 v3.X 마커가 100개소 이상 (v3.12 백로그 R3가 정리 대상으로 분리)
2. **LLM 컨텍스트 토큰 부담** — spec을 자기완결 단일 진실 출처로 사용하는 LLM이 매 호출마다 변경 이력 전체를 메모리에 로드. 의사결정 추적에는 ADR이 이미 충분하지만 changelog 행이 중복 정보 제공

운영자 직관(v3.13 review 시 제기):

> "변경 기록 같은 건 깃으로 관리하는게 맞지 않을까? 최종 산출물에 덕지덕지 다 붙이는게 맞아? 깃 히스토리로 변경 이유를 찾고, 산출물은 슬림하게 가야 컨텍스트를 덜 쓸 것 같아. 중요한 의사결정만 ADR에 남기는거지."

## 2. 결정 (v3.14 갱신 — 통째 슬림화)

**spec 본문에서 모든 변경 이력 표기를 제거**. 과거 차수 history도 보존 안 함 — git + ADR이 단일 진실 출처. spec은 "현재 상태"만 담음.

| 항목 | 이전 (v3.13까지) | 이후 (v3.14부터) |
|---|---|---|
| frontmatter changelog 표 | 차수별 행 누적 (v3.3 ~ v3.13까지 11행) + 누적 변경 통계 단락 | **표 + 부속 단락 통째 제거**. 모든 차수 history는 git log + ADR 누적으로 확인 |
| 본문 인라인 v3.X 마커 | 매 결정 위치에 박음 (예: "(v3.10 G2 추가)", "(v3.7 정정)", "v3.9 — 단순화") | **모든 인라인 마커 제거**. v3.12 R3 백로그 정리 함께 처리. 결정 결과만 본문에 남기고 "왜 그렇게 결정했나"는 ADR/git blame |
| frontmatter top "최종 갱신" 한 줄 | 차수 명시 (`최종 갱신: 2026-05-11 (v3.13)`) | **갱신 유지** — spec 첫 줄 단일 표기. spec 본문에서 차수를 인용하는 유일한 위치 |
| 의사결정 근거 | frontmatter changelog 본문 + ADR 둘 다에 박음 | **ADR이 단일 진실 출처**. spec 본문은 "결정의 결과만" 박음 (왜 그렇게 결정했는지는 ADR 참조) |
| 변경 위치 추적 | spec frontmatter 변경 위치 컬럼 + ADR §5 영향 범위 둘 다 | ADR §5 영향 범위가 단일 진실 출처. spec 본문에서 ADR 1회 인용으로 갈음 |

운영자 v3.14 review 시 추가 결정 (본 ADR 첫 작성 후 갱신):

> "스펙도 그냥 이전 내역 포함해서 슬림화 하자. 따로 의사 결정 내역 파일로 분리하든가 깃으로 남기든가 하고, 스펙 자체에는 최종 결과만"

초안의 "history 보존" 절충은 폐기. v3.13까지의 history도 spec에서 완전히 제거.

## 3. 의사결정 근거

### 3.1 git history는 이미 변경 추적의 표준

git log + git blame이 "언제 누가 무엇을 왜 바꿨는지" 추적의 산업 표준. spec frontmatter changelog는 git이 없던 시절의 보완책 — 운영자가 git 워크플로우를 일관 사용하므로 중복 발생.

### 3.2 ADR이 의사결정 단일 진실 출처

핸드오프 §1·§2 + spec §9.3에 이미 "운영자 결정·LLM 자율 결정·agent-team 합의 모두 ADR로 기록"이 박혀 있다. v3.13에 도입된 `2026-05-11-mypower-plugin-adopt.md` ADR이 plugin 채택 + 일반화 두 결정의 근거·트레이드오프·영향 범위·향후 확인 사항을 모두 자기완결로 담음 — spec frontmatter changelog 행이 추가 정보 제공 없이 같은 내용 중복.

### 3.3 LLM 컨텍스트 효율

운영자가 spec을 LLM에 매 호출 로드해 의사결정 합의·plan 작성·executing-plan 검증에 사용. spec 분량이 1줄 줄면 모든 호출에서 그만큼 토큰 절약. v3.13 기준 2278줄 중 약 50줄(frontmatter changelog 표) + 약 100개소 인라인 마커 = 누적 토큰 부담 무시 못함.

### 3.4 spec slim의 정합성 확보

spec은 "현재 상태"의 단일 진실 출처. "과거에 어떻게 왔는지"는 별도 책임. 이 분리는 코드 베이스의 상식(소스 코드는 현재 동작 정의, git log는 변천사) — spec도 동일 원칙 적용.

## 4. 트레이드오프

| 채택 측면 | 포기한 측면 |
|---|---|
| spec slim → LLM 토큰 절약 + 운영자 검토 가독성 | spec 단일 파일 열어 변경 이력 전체 확인 불가 (git log + ADR 둘 다 봐야 함) |
| ADR 단일 진실 출처로 의사결정 추적 정밀도 ↑ | ADR 작성 부담 (자잘한 변경은 ADR 면제 가능 — light scope) |
| 인라인 마커 새로 안 박음 | "이 단락이 어느 차수에 추가됐나" 본문에서 즉시 확인 불가 (git blame으로 확인) |
| frontmatter 단일 line(최종 갱신 차수) 유지 | 차수별 영향 범위는 ADR에서 확인 |

## 5. 적용 범위 — v3.14 이후 (통째 슬림화)

본 정책은 다음에 자동 적용:
- spec 본문 신규 변경
- spec 본문 기존 v3.X 인라인 마커 + frontmatter changelog 표 통째 제거 (v3.14 처리)
- ADR 신규 작성 (이미 ADR-first 원칙이므로 변화 없음)
- handoff 문서 — "차수 변화 요약" 단락도 슬림화. 다음 세션은 ADR 목록(`docs/adrs/`) + spec 본문(현재 상태) + 최신 1개 차수 결정 요약 정도로 진입 가능

본 정책은 ADR 본문에는 적용 안 함:
- 기존 ADR (이력 보존 + 트레이드오프·향후 확인 사항 단일 출처 역할)
- 신규 ADR (자기완결 결정 기록 — 차수와 무관)
- git history (당연히 그대로 유지 — git이 변경 이력 1순위 출처)

## 6. 결정 적용 첫 사례 — v3.14 sub-agent memory 추가

본 ADR과 동시에 작성되는 `2026-05-11-mypower-subagent-memory.md` ADR이 첫 적용 사례. v3.14 변경 내용:
- §4.1 `agents/` 디렉토리 행에 `memory` 필드 명시
- §7.2 페르소나 1층 골격 frontmatter에 `memory: project` 추가
- §13 검증 체크리스트에 sub-agent memory 항목 추가
- frontmatter top "최종 갱신: v3.14" 갱신 (1줄)
- **frontmatter changelog 표에 v3.14 행 추가 안 함**
- **본문 인라인 v3.14 마커 안 박음**

이 ADR이 변경 위치·근거·트레이드오프 단일 진실 출처. spec에서는 §7.2 frontmatter 예시 한 줄 옆에 "(공식 docs + ADR `2026-05-11-mypower-subagent-memory.md` 참조)" 인용 1회로 갈음.

## 7. 향후 확인 사항

- v3.14 첫 적용 후 운영자가 본인이 의사결정 추적·검토 시 ADR + git log 흐름이 spec changelog만큼 편리한가 평가. 불편 시 본 ADR 부분 철회 또는 frontmatter 한 줄 changelog table 부활 검토
- v3.12 R3 백로그(인라인 v3.X 마커 ~100개소 정리)는 본 정책 채택과 함께 v3.14 또는 후속 차수에서 정리 우선순위 ↑ (slim 정책과 정합)
- handoff 문서 차수 변화 요약 단락 분량 가이드라인 — "각 차수 핵심 결정 한 줄, 상세는 ADR 인용" 패턴 시도
