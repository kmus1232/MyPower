# TDD 가이드 (executing-plan sub-process — 코드 영역 한정)

본 가이드는 `executing-plan`이 코드 영역 step에 진입할 때 호출하는 `mypower-tdd` sub-process가 공유한다. spec §6.4 (특히 §6.4.1 핵심 / §6.4.2 영역 판단 / §6.4.3 절차 / §6.4.5 Rationalizations) 단일 진실 출처.

## 절대 법칙 (Iron Law)

> **NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**
> 실패하는 테스트 없이 production 코드 작성 금지. 글자 어김 = 정신 어김.

**단 하나의 예외**: `scope_class=light` 코드 step에서 운영자 명시 승인을 받은 경우만 RGR skip 가능. 그 외 모든 경우 절대 우회 금지. hook 강제 없음 — prompt-level Iron Law + PR 리뷰 `code-quality-reviewer` 테스트 lens가 유일한 검증.

HARD-GATE 금지:
- 테스트 없이 코드 작성 (light scope + 운영자 명시 승인 예외 외)
- Green 단계 명령 실행 생략
- "테스트 나중에"
- scope_class=light 외 작업에서 자율 skip 결정

## 적용 영역 판단 (호출 trigger)

| step 영역 | scope_class=light | scope_class=standard/heavy | 대신 |
|---|---|---|---|
| 일반 프로그래밍 코드 (TS/JS/Python/Go/Rust 등) | **운영자 1회 확인 후 RGR skip 가능** | **적용** (RGR 강제) | — |
| IaC (Terraform / K8s manifest / Helm) | 미적용 | 미적용 | `terraform plan/validate` + verifying |
| 스크립트 (bash / Datadog 쿼리 / SQL 마이그레이션 등) | 미적용 | 미적용 | 명령 실행 + 출력 검증 |
| 문서 (.md / spec / plan) | 미적용 | 미적용 | grep placeholder/금칙어 검사 |
| 설정 파일 (.json / .yaml — 코드 아닌 것) | 미적용 | 미적용 | schema validate |
| **MyPower 자체 빌드** | 해당 없음 | 해당 없음 | markdown 산출물 = grep placeholder + 본문 절차 grep. plugin manifest + hooks.json + shell script = `plugin/tests/smoke.sh`로 install/uninstall + hook 동작 검증 |

판단 모호 시: **TDD 적용으로 분류**. 안전 원칙 — 테스트 작성 비용 < 테스트 누락 비용.

> [!NOTE]
> `scope_class=light`(typo·rename·dependency bump 같은 한 PR 한 step) 코드 step에서 TDD RGR 강요는 운영자 우회 유발. 따라서 light 코드 step은 영역 판단 후 운영자에 "TDD 적용할까 / skip할까" **1회 확인**. 운영자 명시 결정만 인정 — 자동 skip 아님. hook 강제 없음 + `index.json.steps[].tdd_skip` 필드 미사용 — skip 결정은 `_review.md` 또는 step 본문에 자연어로 기록. PR 리뷰 `code-quality-reviewer` 테스트 lens가 skip 결정의 사후 검증.

## 절차 (Red-Green-Refactor)

### Step 0 (setup gate) — TDD framework 존재 여부 확인 (greenfield 대응)

| 상태 | 행동 |
|---|---|
| `package.json` / `requirements.txt` / `go.mod` 등에 test runner 명시되어 있고 실행 가능 | 다음 단계 진행 |
| test runner 미설치 (greenfield) | **`tdd-setup` 게이트 발동** — Red 단계 진입 전 운영자에 "어떤 framework 쓸까" 1회 질문 (jest/vitest/pytest/go test 등). 답 받으면 `executing-plan`이 setup step 자동 추가 → install + 최소 config + smoke test 실행 → setup 통과 후 Red-Green-Refactor 진입 |
| test runner는 있으나 step 영역 언어 미지원 (예: jest만 있는데 Python 코드) | 운영자에 "추가 framework 설치할까 / 영역 분류 변경할까" 1회 질문 |

setup 단계 비용을 plan에 포함시키지 않으면 Red 단계가 "framework 없음 = 실패"로 잘못 통과되어 GREEN 진입 가능. 따라서 setup 게이트는 HARD-GATE.

### Step 1~3 (Red-Green-Refactor 사이클)

1. **RED**: 실패하는 테스트 작성 + 명령 실행 → **실패 출력을 본문에 인용**. 출력에 "framework not found" / "module not installed" 등이 보이면 setup 게이트로 회귀
2. **GREEN**: 통과시키는 최소 production 코드 작성 + 명령 재실행 → **통과 출력을 본문에 인용**
3. **REFACTOR**: 코드 정리 + 명령 재실행 → 통과 유지 출력 인용
4. 다음 테스트 케이스로 1번 회귀

각 RED/GREEN/REFACTOR 단계의 출력 인용은 `_review.md` 또는 verifying 단계 보고서에 보존. PR 리뷰 `code-quality-reviewer`가 테스트 lens로 사후 검증. hook 강제 없음 — Iron Law + Rationalizations + Red Flags prompt-level 강제력에 의존.

## 검증

기계 검증:
- [ ] 각 케이스에 RED 단계 실패 출력 인용 존재
- [ ] 각 케이스에 GREEN 단계 통과 출력 인용 존재
- [ ] REFACTOR 단계 후 통과 유지 출력 인용

self-judge:
- [ ] 테스트가 production 코드 작성 *전에* 작성됨 (커밋 순서 또는 작업 메모로 확인)
- [ ] "테스트 나중에" / "이번만 통과 확인 안 해도 됨" 같은 우회 시도 0건

## Rationalizations (자주 하는 변명 — 그리고 반박)

| 변명 | 반박 |
|---|---|
| "이번 코드는 너무 단순해서 TDD 필요 없음" | 단순할수록 RED-GREEN 사이클이 빠름. 비용 < 누락 위험 |
| "테스트 먼저 짜면 시간 2배 듦" | TDD 안 한 후 디버깅·재작성 비용 포함하면 짧음 |
| "IDE에서 통과 표시 봤으니 GREEN 명령 안 돌려도 됨" | hearsay 금지. 출력 인용 강제 |
| "이건 코드 영역인지 모호함" | 모호하면 적용. 안전 원칙 |
| "Red 단계 실패 메시지 너무 명확하니 인용 생략" | 출력 인용은 강제력 장치. 생략 = HARD-GATE 위반 |

## Red Flags

- "테스트는 step 끝나고 한 번에"
- "이번 케이스는 작아서 GREEN만"
- "기존 테스트 통과하니까 새 케이스 안 써도 됨"

## ADR 트리거

tdd는 executing-plan sub-process로 **독립 ADR 발생 없음**. tdd 사이클 안에서 발생하는 자율 결정(테스트 framework 선택, 모킹 전략 등)은 호출자 executing-plan의 분류 B ADR로 흡수. 즉 `docs/adrs/`에 별도 tdd ADR 파일을 만들지 않고, executing-plan ADR 본문의 "tdd 결정" 항목으로 통합 기록.

**예외**: TDD framework setup 결정(jest/vitest/pytest 선택 등)은 분류 A 운영자 승인 필요 → 운영자 결정 ADR로 별도 작성.
