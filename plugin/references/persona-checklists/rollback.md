# rollback-reviewer 체크리스트 (2층)

> 1층 `agents/rollback-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 인용. applying 검증 팀 3명 중 1명.

## 핵심 질문

> "실수했을 때 복구 명령은? 자동인가 수동인가? 시간은?"

## sub-checklist

### A. rollback 명령 명시

- [ ] PR 본문 또는 ADR에 "rollback" 단락 존재
- [ ] rollback 명령이 구체적으로 박혀 있음 (`git revert <sha>` / `terraform apply -target=...` / `kubectl rollout undo` 등)
- [ ] rollback이 자동인지 수동인지 분류
- [ ] rollback 추정 시간 명시 (~1분 / ~5분 / ~30분 / 불가)

### B. 데이터 손실 가능성

- [ ] DB migration이 `DROP COLUMN` / `DROP TABLE` 포함 — 데이터 손실 위험
- [ ] backfill 없이 rollback 시 복구 불가한 상태 발생 여부
- [ ] S3 / 파일 시스템 destructive 동작 (`rm` / `delete-object` / `--recursive`)

### C. rollback 불가 작업 식별

- [ ] `terraform destroy` — 자원 삭제 후 복구 불가
- [ ] `aws s3 rm --recursive` — 휴지통 없는 destructive
- [ ] DB drop column + backfill 없는 forward migration
- [ ] 외부 시스템 webhook 전송 / 이메일 발송 — 사후 회수 불가

### D. rollback 시나리오 사전 시뮬레이션

- [ ] "장애 발생 시 어떤 순서로 rollback 하는지" 단계별 명령 기재
- [ ] rollback 권한 (운영자 본인 / on-call / 관리자) 명시
- [ ] rollback 후 데이터 정합성 검증 명령 (예: count·hash 비교)

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | rollback 명령 미명시 + 데이터 손실 가능 (DROP COLUMN / S3 --recursive) / rollback 불가 작업 도입 + ADR 없음 / webhook·이메일 비동기 발송 후 회수 절차 부재 |
| Important | rollback 시간 5분 이상 + 영향 범위 큰 작업 / rollback 명령은 있으나 권한 분류 불명확 / backfill 없는 forward migration |
| Nit | rollback 단락 표현이 단조 (정보는 정확) / 시간 추정이 누락 |
| Optional | rollback 후 정합성 검증 명령 추가 권고 (현재도 진행 가능) |
| FYI | 본 PR rollback 정상이나 같은 작업이 자주 반복 — runbook 자동화 후보 |

## 출력 5단 보고 양식 — spec §7.2 인용

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {PR 변경 + rollback 명령 명시 위치 또는 누락}
[문제] {rollback 절차의 어떤 부분이 미명시 / 데이터 손실 위험}
[현재 영향] {장애 발생 시 복구 소요 시간 + 데이터 손실 범위}
[결정 권고] {Critical=차단 + rollback 절차 추가 / Important=수정 후 머지 / Nit=권고}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **"revert 가능" 문구만** — PR 본문에 rollback 가능하다고만 적고 실제 명령·소요시간 미기재. 장애 시점에 절차 모름. Critical
2. **DB migration drop column + backfill 없음** — 운영 후 rollback 시 데이터 손실. forward-only migration이라면 ADR + 운영자 승인 강제. Critical
3. **S3 `rm --recursive`** — 휴지통 없는 destructive 동작. rollback 불가. ADR + 백업 절차 동반 강제. Critical
