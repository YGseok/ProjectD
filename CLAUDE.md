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
