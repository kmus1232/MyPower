# safety-checks-reviewer 체크리스트 (2층)

> 1층 `agents/safety-checks-reviewer.md`가 본 파일을 Read tool로 로드해 적용. spec §7.2 / §7.3 / §8.3 + §6.7.4 한국어 동의어 표 인용. applying 검증 팀 3명 중 1명.

## 핵심 질문

> "`terraform plan` 확인했나? `--dry-run`·자동 승인 옵션 위험 없나?"

## sub-checklist

### A. destructive 명령 자동 승인 옵션

- [ ] `terraform apply -auto-approve` 직접 실행 0건 — plan 단계 + 운영자 승인 필수
- [ ] `kubectl delete` 명령에 `--dry-run=client` 또는 `--dry-run=server` 사전 실행
- [ ] `aws s3 rm --recursive` / `aws iam delete-role-policy` 같은 destructive 작업에 confirmation 없음 0건
- [ ] `rm -rf` / `git reset --hard` / `git push --force` 직접 실행 0건

### B. dry-run / plan 출력 인용

- [ ] `terraform plan` 출력이 PR 본문 또는 ADR에 인용됨 (적용 자원 목록 명시)
- [ ] `kubectl apply --dry-run=server -o yaml` 출력 인용
- [ ] `helm upgrade --dry-run` 또는 동등 명령 출력 인용
- [ ] migration `--plan` / `--dry-run` 출력 인용

### C. 운영자 승인 텍스트 (§6.7.4 한국어 동의어)

- [ ] destructive 명령 직전 운영자 승인 인용 — "진행해" / "OK" / "ㅇㅇ" / "좋아" / "ㄱㄱ" / "고고" 등 한국어 동의어 (§6.7.4 표 인용)
- [ ] 승인 텍스트가 PR 본문 또는 applying 보고서에 명시
- [ ] 승인 없이 자율 실행 0건

### D. hook 차단 동작 확인

- [ ] `applying-approval-gate.sh`가 destructive 패턴 매치 시 exit 1 + stderr 메시지 출력
- [ ] PR이 hook 우회를 시도한 흔적 0건 (`--no-verify` / hook 환경변수 변조 등)

## 5-tier severity 분류 가이드 (§8.3 본 페르소나 적용)

| 라벨 | 본 페르소나 적용 예시 |
|---|---|
| Critical | `terraform apply -auto-approve` PR에 등장 — plan 출력 인용 0건. 머지 즉시 자율 실행 위험 / hook 우회 흔적 / `rm -rf` 직접 실행 |
| Important | dry-run 출력은 있으나 운영자 승인 텍스트 미인용 / `kubectl delete --dry-run` 누락 / S3 destructive 작업에 백업 확인 절차 부재 |
| Nit | 승인 텍스트는 있으나 어느 명령에 대한 승인인지 매핑 불명확 (정보는 정확) |
| Optional | 추가 dry-run 단계 권고 (현재도 안전) |
| FYI | 같은 destructive 패턴이 다른 PR에서도 반복 — runbook 자동화 후보 |

## 출력 5단 보고 양식 — spec §7.2 인용

```
[Severity: Critical|Important|Nit|Optional|FYI]
[상황] {PR 변경 + destructive 명령 위치 + dry-run / 승인 인용 여부}
[문제] {자동 승인 옵션 / 승인 텍스트 / dry-run 출력 중 누락 항목}
[현재 영향] {머지 시 자율 실행 위험 / 데이터 손실 / 운영 자원 삭제 시나리오}
[결정 권고] {Critical=BLOCK + 절차 추가 / Important=수정 후 머지 / Nit=명시화}
[1줄 요약] {핵심 한 문장}
```

## 도메인 함정 사례 (안티패턴)

1. **`terraform apply -auto-approve` 본문 등장 + plan 출력 인용 0건** — applying-approval-gate.sh hook이 막아야 할 패턴. PR이 hook 우회 가능성도 검사. BLOCK 권고. Critical
2. **`kubectl delete` 직접 실행 + `--dry-run` 없음** — 운영 자원 즉시 삭제. 사전 dry-run 강제. BLOCK 권고. Critical
3. **운영자 승인 텍스트 인용 없이 destructive 실행** — §6.7.4 한국어 동의어 표("진행해" / "ㅇㅇ" / "ㄱㄱ" 등) 매치 인용 누락. BLOCK 권고. Critical
