# mypower

Claude Code plugin — 6단계 lifecycle 스킬(brainstorming / writing-plan / executing-plan / verifying / pr-review / applying) + tdd sub-process + 12명 reviewer 페르소나.

## 설계 문서

본 repo의 `docs/specs/2026-05-09-mypower-design.md`. plugin source(skills·agents·references·hooks·tests)는 `plugin/` 하위. v3.15 디렉토리 분리 결정 — ADR `docs/adrs/2026-05-12-mypower-docs-plugin-split.md`.

## 설치

### 시나리오 A — 운영자 본인 default (로컬 git working copy)

```bash
git clone https://github.com/<owner>/MyPower ~/Projects/MyPower
/plugin marketplace add ~/Projects/MyPower        # root .claude-plugin/marketplace.json 자동 발견
/plugin install mypower@mypower-dev               # plugin/ 디렉토리만 cache로 복사 — docs/ 무관
```

이후 갱신:

```bash
cd ~/Projects/MyPower && git pull
claude plugin update mypower@mypower-dev
```

### 시나리오 B — 외부 사용자 (fork·marketplace)

```bash
/plugin marketplace add <owner>/MyPower
/plugin install mypower@mypower-dev
```

> docs/(spec·plan·ADR)는 `git clone`엔 포함되지만 `/plugin install`로 cache에 안 따라감 — 학습 자료로 보고 싶으면 git clone 후 본 repo 직접 cd.

### 시나리오 C — 개발 중 빠른 테스트 보조

```bash
claude --plugin-dir ~/Projects/MyPower/plugin     # plugin/ 디렉토리 직접 지정
```

설치 후 6 lifecycle 슬래시 호출:

| 단계 | 슬래시 |
|---|---|
| 1 | /brainstorming |
| 2 | /writing-plan |
| 3 | /executing-plan |
| 4 | /verifying |
| 5 | /pr-review |
| 6 | /applying |

`/tdd`는 executing-plan 코드 영역 step에서 sub-process로 자동 호출.

## 강제력 장치

prompt-level 4종 (`<HARD-GATE>` / Iron Law / mermaid 종료 노드 / `REQUIRED SUB-SKILL`) + hooks 1개 (`applying-approval-gate.sh` — destructive 명령 차단).

## License

MIT.
