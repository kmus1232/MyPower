# tech-currency 가이드 (deprecated 회피)

> 목적은 **deprecated 회피**이지 "무조건 최신 메이저 버전 강요"가 아니다. stable이고 deprecation 표시 없으면 OK. 한 메이저 뒤처진 버전이라도 active maintenance면 통과.

`executing-plan` 코드 작성 subagent + `pr-review` `tech-currency-reviewer` 두 곳에서 공유. 매번 호출하면 토큰 폭증 + 시간 낭비라 **trigger 조건** 명시.

## 호출 trigger (다음 중 하나 해당 시만 도구 호출)

1. 사용하려는 API/메서드가 deprecated 후보군에 속함
   - AWS SDK v2 EOL 영역, Python 2.x 잔존 API, jQuery 같은 legacy 라이브러리 등
2. 라이브러리/프레임워크의 changelog에 deprecation warning 가능성 있는 영역
3. LLM 지식 cutoff 이후 명시적 deprecation 알려진 영역
4. 운영자가 "deprecated 여부 확인" 명시 요청

## 호출하지 않는 경우

- 최신 메이저 버전 아니라는 이유만으로 — stable + deprecation 없으면 OK
- 사용 중인 라이브러리가 oss community에서 충분히 maintained
- "더 좋은 대안" 찾기 — 이건 별도 리팩터링 영역

## 어떤 도구로 확인하나

| 도메인 | 1순위 도구 | 2순위 |
|---|---|---|
| AWS API · 서비스 | AWS Knowledge MCP (`aws___read_documentation`, `aws___search_documentation`) | web_search |
| 라이브러리 · 프레임워크 (npm, PyPI 등) | Context7 MCP (`resolve-library-id` → `get-library-docs`) | web_search |
| 그 외 (K8s, Terraform provider, 오픈소스) | web_search → 공식 문서 | (없음) |

## 무엇을 확인하나

1. **Deprecation 명시 여부** — 공식 문서/changelog에 "deprecated", "removed in vX", "use Y instead" 등 표시
2. **잘못된 사용 패턴** — 공식 문서가 명시적으로 "Don't do this" 적은 안티패턴 위반
3. **버전 호환성 깨짐** — 사용 중인 버전이 호출 API와 호환되지 않음 (런타임 에러 발생 가능)

> "최신 사용 권장" 알림은 출력 안 함. **명시적 deprecation 또는 깨진 사용 패턴만** flag.

## 출력 규칙

확인 결과는 **자율 결정 ADR**로 기록 (`docs/adrs/YYYY-MM-DD-{slug}-tech-{n}.md`):
- 확인한 라이브러리·API + 버전
- 사용한 도구 (MCP / web_search) + 출처 URL
- 결론: `safe` (deprecation 없음, 패턴 정상) / `deprecated` (공식 deprecation 표시) / `wrong-pattern` (안티패턴 위반)
- `deprecated` 또는 `wrong-pattern`인 경우만 대체재·수정 권고

## 안티패턴

- 호출 결과 추측해서 적기 — 반드시 실제 도구 호출 + 출력 인용
- 최신 메이저 버전 아니라는 이유로 경고 — 톤 위반
- 모든 dependency에 대해 도구 사용 — trigger 조건 외에는 토큰 낭비
- 한 번 확인했다고 영구 신뢰 — 캐시 유효 기간은 같은 PR 범위 내까지

PR 리뷰 단계에서 `tech-currency-reviewer`가 이 가이드의 trigger 조건에 해당하는 변경이 있으면 같은 도구로 검증. 발견 시 5-tier severity 부여.
