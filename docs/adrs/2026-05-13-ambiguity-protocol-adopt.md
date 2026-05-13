# ADR — 모호함 처리 규칙(ARP) 채택 + MVP 강제 메커니즘 설계

> 작성: 2026-05-13 | 상태: 채택 | 분류: B (자율 결정 후 ADR 흡수) | spec 영향: v3.15 → v3.16

## 1. 배경

본 ADR은 별도 컨셉으로 작성된 "모호함 처리 규칙(Ambiguity Resolution Protocol, 이하 **ARP** = 모호함 처리 규칙)"을 MyPower plugin이 공식 채택하기로 한 결정과, MVP(v1) 단계에서의 강제 메커니즘 설계 결정을 누적한다.

ARP의 핵심: 에이전트가 모호한 상황을 만나면 운영자에게 묻기 전 4단계 처리 순서(스스로 찾기 → 가정 기록 → 전문 서브에이전트 위임 → 운영자 질문)를 거친다. 운영자 개입을 실패 신호로 간주하되 추측을 더 큰 실패로 보는 비대칭 처리.

ARP 본문은 별도 작성됨: [`plugin/references/ambiguity-protocol.md`](../../plugin/references/ambiguity-protocol.md).

본 ADR 작성 직전 두 reviewer 에이전트의 컨셉 비평으로 Critical 4건 + Important 7건 + 누락 시나리오 5건 도출. 중요 결정 둘은 v1.1+로 미룸 — 비용 분류에 가역성 축 추가(ARP §5 T-001), hook 신호 설계(ARP §5 T-010).

**메타 — 본 ADR 작성 세션 자체가 ARP 4단계를 안 따른 사례**: 메인 에이전트가 (a) ARP 본문 위치(docs/ vs plugin/) (b) hook 도입 의도 두 가지에서 1단(스스로 찾기 — 본 repo CLAUDE.md·ADR grep) 누락 + 가정 기록 누락으로 운영자 정정을 두 번 받음. 후속 세션에서 같은 실수 방지를 위해 운영자에게 묻는 메시지 가독성 정책을 별도 4곳(운영자 글로벌 CLAUDE.md, 본 repo CLAUDE.md, 운영자 본인 프로젝트 메모리 feedback, ARP §3.4)에 추가.

## 2. 결정

### 2.1 ARP 채택과 본문 위치

ARP 4단계 처리 규칙 + 4종 분류 taxonomy를 MyPower plugin이 공식 채택. ARP 본문 위치는 [`plugin/references/ambiguity-protocol.md`](../../plugin/references/ambiguity-protocol.md).

이유: plugin install 시 외부 사용자 cache에 따라가야 외부 사용자가 본인 프로젝트에서 4단계를 적용 가능. docs/에 박으면 plugin install에 안 따라감([docs-plugin-split ADR](2026-05-12-mypower-docs-plugin-split.md)). 본 ADR과 같은 의사결정 누적은 docs/에, 적용 protocol은 plugin/에 분리.

### 2.2 MVP 강제 메커니즘 — 슬래시 스킬 프롬프트 단독

v1 MVP에서 ARP 강제는 **7개 슬래시 스킬 프롬프트 단독**. hook과 검증 에이전트는 v1.1+로 미룸.

**hook v1.1+ 결정**:
- hook은 본 규칙의 **핵심 강제 메커니즘으로 인정**. 코드 편집·도구 호출·운영자 질문 발화 시점에 즉각 발동 가능한 유일한 수단
- 다만 신호 설계(어떤 신호로 어느 단계를 enforce할지)가 v1 시점에 미합의. 후보 4개 모두 채택 보류:
  - mtime 비교 — 정상 흐름(가정 없는 작은 편집)과 비정상 흐름(가정 누락) 구분 못함
  - 계획 파일 내용 분석 — hook이 LLM 분석을 못함
  - 코드 변경량 임계 — 가정 유무와 무관
  - 에이전트 자체 메타 보고 — 우회 인센티브 생성
- v1.1+ 별도 ADR(T-010)에서 신호 설계 후 도입

**검증 에이전트 v1.1+ 결정**:
- v1 빌드 plan Step 0~13에 검증 에이전트 작성 task 없음
- v1 빌드 일정 보호 우선
- v1.1+에서 작성 step 추가

**v1 강제력 약함 인정**:
- 위 두 결정에 따라 v1 동안 ARP 강제는 슬래시 스킬 프롬프트가 LLM에 "이렇게 하라" 부탁하는 수준
- LLM이 무시할 가능성 존재
- 운영자가 transcript 사후 검토해 ARP 위반을 잡아야 하는 부담 v1 동안 유지

### 2.3 슬래시 스킬 흡수 방식 — 단일 출처 참조

각 슬래시 스킬은 ARP 본문 파일을 **참조**하되 본문 내용을 **복사하지 않는다**.

스킬 본문 내 패턴:
- "본 스킬은 모호함 만나면 `${CLAUDE_PLUGIN_ROOT}/references/ambiguity-protocol.md` 4단계 따름" 한 줄 명시
- 단계별 진입 조건·강제 형식은 ARP §3을 인용 (복제 아님)

이유: ARP 본문 갱신 시 7개 스킬에 자동 반영. 복사 방식이면 본문 변경마다 7곳 동기화 필요. T-001~T-010 9개 미해소 항목이 향후 본문 갱신을 빈번하게 만들 가능성 — 단일 출처가 유일한 합리적 선택.

### 2.4 references 카탈로그 6 → 7 갱신

ARP 본문이 `plugin/references/`에 추가되며 references 코어 자료 수가 6에서 7로 늘어남. 본 ADR이 다음 위치를 동시 갱신:

| 위치 | 변경 |
|------|------|
| spec §9.1 references 카탈로그 표 | ARP 항목 행 추가 (코어 6 → 7) |
| spec 버전 메타 + 변경 로그 | v3.15 → v3.16 + 변경 로그 한 줄 추가 |
| plan Step 1.7 통합 검증 | `# 6 파일 존재` 코멘트와 `기대: 6` 둘 다 7로 갱신 |
| 본 repo `CLAUDE.md` "의사결정 누적" 표 | 본 ADR 줄 추가 |
| ARP 본문 §4.2 | 검증 에이전트 v1.1+ 명시 톤다운 |

ADR이 spec/plan 갱신을 같이 끌고 가지 않으면 ADR이 단독으로 떠다님 — 단일 commit으로 묶는다.

### 2.5 ARP 본문 §4.2 톤다운

결정 2.2에 따라 ARP 본문 §4.2 "MVP 단계 차단 권한은 검증 에이전트 단독" 표현이 사실과 어긋남. 다음과 같이 갱신:

- 변경 전: "MVP 단계에서는 차단 권한을 본 에이전트가 단독 보유"
- 변경 후: "v1 MVP에서는 검증 에이전트 미도입. v1.1+에서 차단 권한 갖춤. v1 동안 ARP 강제는 슬래시 스킬 프롬프트 단독"

## 3. 트레이드오프

### 잃는 것
- **v1 동안 ARP 강제력 약함** — 슬래시 스킬이 LLM에 부탁하는 수준. 운영자 사후 검토 부담 v1 기간 동안 유지
- **hook 결정이 v1.1+로 미뤄짐** — 본 ADR이 hook 신호 설계 결정 안 함. 별도 ADR(T-010) 필요
- **검증 에이전트 인터페이스 결정도 v1.1+** — commit 차단 방식·예외 케이스·운영자 override 정책 미결정

### 얻는 것
- **v1 빌드 일정 보호** — Step 0~13 추가 작업 없음
- **ARP 본문 단일 출처** — 7개 스킬 작성 시 인용 패턴이 일관됨. 본문 갱신 비용 낮음
- **placeholder 정책 일관** — ARP 본문이 plugin/references/에 있어 외부 사용자에게 자연스럽게 따라감

### 결함 인정
- 본 세션 메인 에이전트가 (a) ARP 본문 위치 (b) hook 도입 의도 두 곳에서 운영자 정정을 받음
- 본 ADR이 채택하는 ARP 4단계를 본 ADR 작성 세션 자체가 안 따름 (1단 스스로 찾기 누락, 2단 가정 기록 누락)
- 후속 세션 동일 실수 방지 조치: 운영자 질문 메시지 가독성 정책 4곳에 추가 (운영자 글로벌 CLAUDE.md, 본 repo CLAUDE.md, 프로젝트 메모리, ARP §3.4)

## 4. 영향 — 본 ADR 채택과 함께 갱신할 파일

본 ADR 채택 직후 다음을 **단일 commit으로 묶어** 갱신:

| 파일 | 변경 내용 |
|------|----------|
| `plugin/references/ambiguity-protocol.md` §4.2 | 검증 에이전트 v1.1+ 명시 톤다운 |
| `docs/specs/2026-05-09-mypower-design.md` §9.1 | references 카탈로그 표에 ARP 항목 추가 |
| `docs/specs/2026-05-09-mypower-design.md` 버전 메타 + 변경 로그 | v3.15 → v3.16 + v3.15 → v3.16 변경 로그 한 줄 추가 |
| `docs/superpowers/plans/2026-05-11-mypower-v1-build.md` Step 1.7 통합 검증 | `# 6 파일 존재` 코멘트와 `기대: 6` 둘 다 7로 갱신 |
| `CLAUDE.md` "의사결정 누적" 표 | 본 ADR 줄 추가 |

7개 슬래시 스킬 작성 단계(plan Step 4~9 예정)에서 추가 영향:
- 각 스킬 본문이 ARP 본문 파일 참조 패턴 사용
- ARP §3 단계별 진입 조건·강제 형식 인용

## 5. 후속 추적

본 ADR이 닫지 않는 결정. v1.1+에서 별도 ADR 또는 spec 갱신으로 누적:

| 항목 | 트리거 |
|------|--------|
| T-001 비용 분류에 가역성 축 추가 | v1.1 진입 시 분류 정교화 ADR |
| T-010 hook 신호 설계 | v1.1 진입 시 hook 신호·강제 단계 매핑 ADR |
| 검증 에이전트 인터페이스 정의 | v1.1 검증 에이전트 작성 step 추가 시 |
| ARP §5 T-002~T-009 | 운영 중 발견 시점마다 |
| spec placeholder grep 영역이 `plugin/**/*.md`로 확장 안 됨 (reviewer 보너스 발견) | v1 빌드 진행 중 별도 ADR 또는 spec 갱신 |

본 ADR 후속에 v1.1 진입 시점 hook + 검증 에이전트 두 가지가 빌드 plan에 추가되면 ARP 강제력이 완성된다.
