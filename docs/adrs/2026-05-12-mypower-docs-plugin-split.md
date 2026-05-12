# ADR — MyPower repo의 docs/ vs plugin/ 분리

> 작성: 2026-05-12 | 상태: 채택 | 분류: B (자율 결정 후 ADR 흡수) | spec 영향: v3.14 → v3.15

## 1. 배경

v3.14까지 spec §4.1은 `mypower/` 단일 디렉토리에 plugin source(`skills/`·`agents/`·`hooks/`·`references/`·`tests/`)와 운영자 의사결정 산출물(`docs/specs/`·`docs/adrs/`·`docs/superpowers/plans/`)이 혼재한 구조를 전제했다. marketplace.json schema는 `plugins[0].source: "./"`로 plugin repo root 전체를 install 대상으로 지정한 형태.

2026-05-12 운영자 검토 시점에 두 사실 발견:

1. **superpowers v5.1.0 plugin cache 검증**: `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/`을 직접 확인한 결과 `source: "./"` 사용 시 docs/까지 plugin install 대상에 포함되어 `~/.claude/plugins/cache/`에 복사된다. 외부 사용자의 cache가 plugin과 무관한 spec·plan·ADR 본문으로 오염됨.
2. **운영자 워크스페이스 git 미관리**: 작업 디렉토리(`~/Library/Mobile Documents/com~apple~CloudDocs/home-work/My-Harness/`)는 iCloud 동기화 경로 위에 있고 git init 안 된 상태였음. MyPower와 My-Harness가 사실상 같은 프로젝트인데 폴더가 두 곳(`My-Harness/` 워크스페이스 + `My-Harness/mypower/` plugin 골격)으로 분리되어 의사결정 누적과 plugin 산출물의 단일 출처 부재.

운영자는 (1) v1 빌드 진입 전 의사결정 누적도 git에 commit해 v1.0.0 tag 시점 상태 보존, (2) plugin 사용자에겐 docs/ 노출 안 함, (3) `~/Projects/MyPower/`로 이동해 iCloud 밖에서 git 관리 — 셋을 동시에 만족할 구조를 요구.

## 2. 결정

MyPower repo를 단일 git repo로 통합하되 **루트 `.claude-plugin/marketplace.json`에서 `plugins[0].source: "./plugin"`으로 plugin install 대상을 하위 디렉토리로 한정**.

```
~/Projects/MyPower/                       ← git repo root
├── .git/
├── .gitignore                            # macOS·iCloud·Claude cache·secrets·node·python·build·.claude/agent-memory/
├── README.md                             # 프로젝트 전체 안내
├── .claude-plugin/
│   └── marketplace.json                  # plugins[0].source: "./plugin"
├── docs/                                 # 의사결정 누적 — git commit + clone에 포함, /plugin install엔 무관
│   ├── specs/
│   ├── adrs/
│   └── superpowers/plans/
└── plugin/                               # /plugin install 대상 — 본 디렉토리만 ~/.claude/plugins/cache/로 복사
    ├── .claude-plugin/plugin.json
    ├── skills/ · agents/ · references/ · hooks/ · tests/
    └── README.md
```

결정 적용 범위:
- spec §4.1 v3.14 → v3.15 갱신 (디렉토리 트리·marketplace.json schema·install 시나리오 A/B/C 3곳)
- 마켓플레이스 이름 `mypower-dev` 명확화 — 시나리오 A/B의 `/plugin install`은 `mypower@mypower-dev` 형식
- v1 빌드 plan path는 `${HARNESS}/mypower/*` → `${HARNESS}/plugin/*`로 일괄 갱신 (`${HARNESS}` = `~/Projects/MyPower/`)
- 폴더 이동: iCloud → `~/Projects/MyPower/` + `git init -b main` + GitHub remote `<owner>/MyPower` public push

## 3. 이유

- **사용자 cache 오염 방지**: superpowers cache 실측 결과 `source: "./"`는 docs/까지 끌고 옴. plugin 사용자가 본인 `~/.claude/plugins/cache/`에서 spec·plan·ADR을 보게 되는 건 학습 자료 의도가 아니라 noise. fork 시점(`git clone`)에 docs/ 포함은 OK — 본인이 직접 cd해서 봐야 학습 자료로 의미 있음.
- **단일 git repo의 명확성**: 의사결정 누적과 plugin 산출물이 같은 commit 흐름에 살게 되어 v1.0.0 tag 시점 spec·plan·ADR 본문이 plugin과 묶여 보존됨. v1.1 self-application 시 "당시 어떻게 결정했는지" 정확한 git checkout으로 복원 가능.
- **`/plugin marketplace add` 호환**: 외부 사용자 시나리오 B(`/plugin marketplace add <owner>/MyPower`)는 GitHub repo root의 `.claude-plugin/marketplace.json`을 자동 발견 — root에 marketplace.json 유지가 표준 동작.
- **iCloud 회피**: `~/Projects/`는 iCloud sync 밖. `.git/index` 충돌·lock·objects inflate 동기화 문제 없음.

## 4. 트레이드오프

- **`.claude-plugin/` 두 곳**: root(`.claude-plugin/marketplace.json`) + `plugin/.claude-plugin/plugin.json`로 manifest 디렉토리가 분산. superpowers v5.1.0은 `.claude-plugin/`에 marketplace.json + plugin.json을 같이 두는 단일 위치 패턴이라 본 결정은 변형 — 그러나 source 필드 분리가 핵심이고 marketplace.json 위치는 root 강제(GitHub repo root 인식)라 manifest 분산은 불가피.
- **docs/ fork 시 학습 자료로 노출**: 외부 사용자가 본 운영자의 brainstorming·의사결정 패턴·운영자 식별자(`<owner-name>` placeholder만 정리됨)를 git clone으로 보게 됨. MyPower가 toy/educational project라 의도된 노출이지만 production plugin이었으면 docs/는 별도 private repo로 분리 권고. 현 결정은 학습 목적 한정.
- **외부 사용자 marketplace 이름 혼선**: marketplace.json `name: "mypower-dev"`라 install 명령은 `mypower@mypower-dev`. 사용자가 `mypower@mypower`로 잘못 쳐 실패 가능. README에 명확 표기로 완화.
- **GitHub public**: 운영자 본인 학습 결정 흐름·spec·plan·ADR 본문이 공개됨. `<owner-name>` placeholder 처리되어 있어도 git commit 메시지·email은 본인 정보 노출 가능. 운영자 명시 결정(2026-05-12 public 선택)으로 수용.

## 5. 영향

- **spec v3.14 → v3.15** 갱신 (§4.1 디렉토리 트리·marketplace.json schema·install 시나리오 본문)
- **v1 빌드 plan 본문 path 일괄 갱신** — 약 50건의 `${HARNESS}/mypower/*` 경로를 `${HARNESS}/plugin/*`로 sed 치환. plan 헤더 anchor 박스도 `~/Projects/MyPower/` 기준으로 변경
- **빌드 결과물 위치 변경** — Step 0~13에서 plugin manifest는 `plugin/.claude-plugin/`, hook은 `plugin/hooks/`, 12 agents는 `plugin/agents/`, skills 7개는 `plugin/skills/`, references는 `plugin/references/`, 통합 테스트는 `plugin/tests/`로 일관
- **smoke.sh 동작 영역**: PLUGIN_DIR = `${HARNESS}/plugin/` 기준으로 모든 검증 명령 갱신 필요. install 검증은 root에서 `/plugin marketplace add ./` 실행 후 plugin/만 cache에 복사됐는지 추가 검증(`ls ~/.claude/plugins/cache/.../mypower/docs/` 부재 grep)
- **v1.0.0 tag 시점 git log**: docs/specs/2026-05-09-mypower-design.md v3.15 + 본 ADR + plan + plugin source 모두 첫 commit ~ Step 13.4 commit 흐름에 박힘

## 6. 후속 추적

- **외부 사용자 install 실측 검증**: 본 ADR 적용 후 운영자 본인 시나리오 A로 `/plugin install mypower@mypower-dev` 1회 실행 + `~/.claude/plugins/cache/<marketplace>/<plugin>/docs/` 부재 grep. Step 13.4 통합 테스트 체크리스트에 항목 추가
- **v1.1 self-application 시점**: plan §1.6 `decision-catalog-template.md`가 spec §9.1 references 카탈로그 외 신규 파일이라는 round 2 finding(Important 3)이 self-application 시점에 잡힐 가능성 — 그때 spec §9.1 갱신 ADR 별도 작성
- **superpowers cache 패턴 변경 모니터링**: superpowers v5.2 이상에서 `source: "./"` 동작이 docs 제외하도록 바뀌면 본 분리 결정 재검토 (그래도 source 필드 분리는 명확성 위해 유지 권고)
