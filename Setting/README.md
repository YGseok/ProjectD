# Setting

여러 PC에서 이 프로젝트(ProjectD)를 열었을 때 Claude Code가 같은 맥락(메모리·전역 설정)을
갖도록, 각 PC의 `~/.claude` 아래에만 있던 내용을 저장소 안으로 끌어온 폴더입니다.

- `memory/` — 이 프로젝트에 대해 Claude가 기록해 둔 메모리
  (원본 경로: `~/.claude/projects/<이 저장소 경로를 인코딩한 이름>/memory/`)
- `global-settings.json` — Claude Code 전역 설정 스냅샷 (테마 등)
- `sync-to-repo.ps1` — 이 PC의 최신 Claude 메모리/설정을 저장소로 가져옴 (업로드 전)
- `sync-from-repo.ps1` — 저장소 내용을 이 PC의 Claude 메모리/설정 경로로 반영함 (클론 직후)

**절대 포함하지 않는 것**: `.credentials.json` (로그인 인증 정보). 저장소에 커밋되면
안 되므로 두 스크립트 모두 이 파일을 다루지 않습니다. 새 PC에서는 `claude` 실행 후
별도로 로그인하세요.

수동 실행이 필요하면:

```powershell
powershell -File Setting\sync-to-repo.ps1
powershell -File Setting\sync-from-repo.ps1
```

평소에는 Claude Code에게 "깃허브에 업로드해줘" / "방금 받은 거 최신화해줘"라고 말하면
`CLAUDE.md`의 안내에 따라 자동으로 실행됩니다.
