# MyPower

Claude Code 운영자용 멀티 에이전트 스킬 프레임워크 — toy / educational project.

## 두 영역

- `plugin/` = Claude Code plugin source. `skills/` (6 lifecycle 슬래시 + tdd) + `agents/` (12 reviewer 페르소나) + `references/` + `hooks/` + `tests/`. `/plugin install`로 cache에 복사되는 install 대상
- `docs/` = 의사결정 누적 (spec · plan · ADR). git commit + clone에 포함되지만 `/plugin install`엔 무관. 외부 사용자도 학습 자료로 열람 가능

## 현재 상태

v1 빌드 Step 0~3 완료 — references 코어 7개 + persona-checklists 12개 + agents 12개 + plugin manifest + smoke.sh가 plugin/ 하위에 배치됨. 남은 작업: Step 4 (4 검토 checklist) → Step 5 (hook script) → Step 6~12 (skills 7개) → Step 13 (통합 테스트). v1 완료 시 v1.0.0 tag.

## 설치 (v1 빌드 완료 후 사용 가능)

`<install-dir>` = git clone한 디렉토리(예: `~/Projects/MyPower` 또는 원하는 위치).

```bash
# 운영자 본인 시나리오 A (로컬 working copy)
git clone https://github.com/<owner>/MyPower <install-dir>
/plugin marketplace add <install-dir>
/plugin install mypower@mypower-dev

# 외부 사용자 시나리오 B (fork·marketplace)
/plugin marketplace add <owner>/MyPower
/plugin install mypower@mypower-dev
```

`docs/`(spec·plan·ADR)는 `git clone`에 포함되지만 plugin install로 cache에 안 따라감 — 학습 자료로 보고 싶으면 git clone 후 본 repo cd.

## 의사결정 누적

- spec: [`docs/specs/2026-05-09-mypower-design.md`](docs/specs/2026-05-09-mypower-design.md)
- v1 빌드 plan: [`docs/superpowers/plans/2026-05-11-mypower-v1-build.md`](docs/superpowers/plans/2026-05-11-mypower-v1-build.md)
- ADR: `docs/adrs/` (plugin-adopt / subagent-memory / changelog-policy / docs-plugin-split / 추후 v1 빌드 완료 ADR)

## License

MIT.
