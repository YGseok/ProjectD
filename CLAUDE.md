# CLAUDE.md

## PC 간 Claude 설정/메모리 동기화 (`Setting/`)

이 저장소는 여러 PC에서 열립니다. 각 PC의 `~/.claude`에만 있는 이 프로젝트의 Claude
메모리와 전역 설정을 `Setting/` 폴더를 통해 저장소로 함께 실어 나릅니다. 자세한 내용은
[Setting/README.md](Setting/README.md) 참고.

**사용자가 "깃허브에 업로드해줘 / push해줘 / 올려줘"라고 하면**, 커밋하기 전에 항상:
1. `powershell -File Setting/sync-to-repo.ps1` 실행 — 이 PC의 최신 Claude 메모리/설정을
   `Setting/`에 반영
2. `Setting/`의 변경분을 포함해서 평소대로 add → commit → push

**사용자가 이 저장소를 새 PC에서 막 클론/pull 받은 뒤 "최신화해줘 / 싱크해줘 / 환경 맞춰줘"
라고 하면**:
1. `powershell -File Setting/sync-from-repo.ps1` 실행 — 저장소의 `Setting/` 내용을 이 PC의
   `~/.claude/projects/.../memory/` 및 `~/.claude/settings.json`으로 복사

**절대 하지 말 것**: `.credentials.json`(로그인 인증 정보)을 `Setting/`이나 커밋에 포함하지
않는다. 두 스크립트 모두 이 파일을 다루지 않도록 작성돼 있음 — 수정 시에도 이 원칙 유지.

**`Setting/memory/.gitkeep` 정리**: 이 파일은 `Setting/memory/`가 비어 있던 시점에 Git이
빈 폴더를 커밋하지 못해서 넣어둔 자리표시 파일이다. `sync-to-repo.ps1` 실행 등으로
`Setting/memory/`에 실제 메모리 파일이 하나라도 생기면, 그다음 커밋 시 `.gitkeep`을
삭제한다(더 이상 필요 없는 파일이므로).

## 언어

**모든 답변은 한국어로 한다.** 최종 답변뿐 아니라 작업 중간에 띄우는 짧은 진행 상황 문장까지 전부 한국어. (외부 도구에 보내는 요청문은 예외)

## 아트 결과물 검수 (2026-11-13 사용자 지시)

Art 스레드는 결과물을 사용자에게 보내기 전에 반드시:
1. **체크리스트 증거 첨부** — 해당 항목의 체크리스트(예: `docs/art/OOZE_TIARA_SPEC.md`, `docs/art/FACE_FEEDBACK_2026-11-12.md`) 각 항목에 ✓/✗와 그 부분 확대 이미지를 붙인다. 증거 없는 "통과"는 없음.
2. **ProjectD Manager 선검수** — 결과물 경로 + 체크리스트를 "ProjectD Manager" 세션에 보내 독립 검수를 받고, PASS 받은 것만 사용자에게 가져간다. (Work 세션이 아님)
