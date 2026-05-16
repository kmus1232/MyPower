#!/usr/bin/env bash
# applying-approval-gate.sh — destructive 명령 차단 hook
#
# 본 파일은 Step 0 시점의 **임시 stub**. Step 5에서 실제 destructive 패턴 검출 로직으로 교체된다.
# Step 5 진입 전까지 hooks.json이 본 스크립트를 가리키되 install 후 모든 Bash tool 호출이
# 멈추는 사태를 막기 위해 무조건 통과(exit 0)만 한다.
#
# Step 5 acceptance criteria: 본 stub을 실제 검출 스크립트로 교체 + smoke.sh `[10]` 추가
# (destructive 패턴 stub 입력 → exit 1 + stderr 메시지 검증).
#
# 안전상 주의: 본 stub은 destructive 명령(`rm -rf`·`terraform destroy`·`kubectl delete` 등)을
# 차단하지 않는다. Step 5 완료 전 install된 환경은 hook 보호 0 — 운영자가 직접 주의해야 한다.

exit 0
