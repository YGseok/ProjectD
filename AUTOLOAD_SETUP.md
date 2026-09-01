# 연결 방법 (기존 Godot 프로젝트에 이 키트 붙이기)

이 킷은 독립 실행되는 파일 묶음입니다. 실제 Godot 프로젝트 루트(D:\Claude\ProjectD 등,
project.godot 이 있는 위치)에 아래처럼 병합하세요.

## 1. 파일 복사

`docs/`, `qa/`, `scripts/`, `loop/` 폴더와 `AUTOLOAD_SETUP.md`, `.gitignore` 를
프로젝트 루트에 그대로 복사합니다.

## 2. project.godot 에 autoload 등록

프로젝트를 Godot 에디터로 열고: **프로젝트 → 프로젝트 설정 → Autoload** 탭에서

- Path: `res://qa/visual_qa.gd`
- Node Name: `VisualQA`

로 추가하세요. 또는 `project.godot` 파일을 직접 열어서 `[autoload]` 섹션에 아래 한 줄을
추가해도 됩니다 (섹션이 없으면 새로 만들면 됩니다):

```ini
[autoload]

VisualQA="*res://qa/visual_qa.gd"
```

(이미 다른 autoload가 있다면 그 아래에 한 줄만 추가하면 됩니다.)

이 스크립트는 `GAME_START` 환경변수가 비어 있으면 아무 것도 하지 않으므로,
평소 에디터에서 F5로 플레이하는 것에는 전혀 영향을 주지 않습니다.

## 3. 첫 씬 만들기 (예: dungeon)

`res://scenes/dungeon/dungeon.tscn` (또는 `res://scenes/dungeon.tscn`) 을 만드세요.
이름이 `GAME_START` 값과 일치해야 컨벤션으로 자동 인식됩니다.
다른 위치에 두고 싶다면 `GAME_START_PATH` 환경변수로 전체 경로를 직접 지정할 수 있습니다.

## 4. 확인 (Windows / PowerShell 기준)

```powershell
cd D:\Claude\ProjectD
bash scripts/qa_shot.sh dungeon
```

(Git Bash, WSL 등 bash 실행 환경이 필요합니다. `.sh` 스크립트는 리눅스 셸 스크립트라
순정 PowerShell/cmd에서는 바로 실행되지 않습니다. Git for Windows 설치 시 함께 오는
Git Bash 사용을 권장합니다.)

`qa_out\dungeon.png` 가 생성되면 성공입니다.

## 5. Godot 실행 파일 이름이 다르다면

기본값은 `godot4` 입니다. Windows에서 godot 실행 파일이 `godot4.exe` 이고
PATH에 등록되어 있지 않다면:

```bash
GODOT_BIN="/c/Program Files/Godot/godot4.exe" scripts/qa_shot.sh dungeon
```

(Git Bash 경로 표기 기준. `C:\Program Files\Godot\godot4.exe` → `/c/Program Files/Godot/godot4.exe`)

## 6. 반복 루프 시작

```bash
./loop/loop.sh
```

멈추려면:

```bash
touch loop/STOP
```

## 7. git

이미 `D:\Claude\ProjectD` 에 git 저장소가 있다면 그냥 파일을 병합하고 커밋하면 됩니다.
없다면:

```bash
cd D:\Claude\ProjectD
git init
git add -A
git commit -m "chore: add visual QA harness, run script, loop.sh, docs"
```
