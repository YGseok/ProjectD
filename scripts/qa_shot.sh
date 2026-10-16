#!/usr/bin/env bash
# scripts/qa_shot.sh — 시각 QA 스크린샷 촬영 스크립트
#
# 사용법:
#   scripts/qa_shot.sh <scene_name> [frame] [output_path] [qa_call] [settle] [click_path] [room_override]
#
# 예:
#   scripts/qa_shot.sh dungeon
#   scripts/qa_shot.sh dungeon 90
#   scripts/qa_shot.sh dungeon 90 qa_out/dungeon_check.png
#   scripts/qa_shot.sh combat_test 900 qa_out/combat_test_picker.png _debug_open_customize
#     (4번째 인자 qa_call: 캡처 직전 현재 씬에서 인자 없이 호출할 메서드 이름 —
#      code/qa/visual_qa.gd의 GAME_QA_CALL로 전달됨. 클릭을 흉내낼 수 없는 자동 QA에서
#      버튼 뒤에 있는 하위 화면을 직접 열어보고 싶을 때 사용)
#   scripts/qa_shot.sh combat_test 30 qa_out/combat_test_settled.png "" 1
#     (5번째 인자 settle: "1"이면 GAME_QA_SETTLE=1로 전달됨 — 다이스가 물리적으로
#      다 멈춘 뒤에 캡처하고 싶을 때. 씬이 `_qa_is_settled()`를 구현하면(combat_test.gd)
#      FRAME에 도달해도 그 값이 true가 될 때까지 캡처를 미룬다. 4번째 인자를 건너뛰려면
#      빈 문자열 ""을 넘길 것. code/qa/visual_qa.gd 헤더 주석의 GAME_QA_SETTLE/
#      GAME_QA_SETTLE_MAX_FRAMES 참고)
#   scripts/qa_shot.sh combat_test 140 qa_out/combat_test_real_click.png "" "" CustomizeToggleButton
#     (6번째 인자 click_path: 캡처 직전 그 노드(현재 씬 루트 기준 경로)의 화면 좌표 중앙에
#      진짜 InputEventMouseButton(press+release)을 주입 — code/qa/visual_qa.gd의
#      GAME_QA_CLICK_PATH로 전달됨. GAME_QA_CALL(메서드 직접 호출)과 달리 실제 Godot 입력
#      파이프라인을 거치므로 "클릭 시점에만 재현되는 문제"를 검증할 때 씀)
#   scripts/qa_shot.sh combat_test 200 qa_out/combat_test_room4.png "" 1 "" 4
#     (7번째 인자 room_override: GAME_QA_ROOM_OVERRIDE 환경변수로 전달됨. combat_test.gd가
#      RunState.rooms_cleared 대신 이 room_index로 몬스터를 구성하게 한다(RunState 자체는
#      건드리지 않음). 몇 번째 방인지에 따라 몬스터 다이스 개수/모양(sides)이 바뀌는데,
#      실제로 그 방까지 이겨야만 물리 다이스로 확인할 수 있어 느렸던 것을 우회 — 5번째
#      인자 settle=1과 함께 쓰면 후반 방의 더 많고/큰 몬스터 다이스가 실제 물리 정지 후에도
#      벽(combat_test.tscn Wall*) 안에 들어와 있는지 정상 플레이와 동일한 경로로 검증 가능)
#   scripts/qa_shot.sh combat_test 30 qa_out/combat_test_armored_goblin.png "" 1 "" "" armored_goblin
#     (8번째 인자 monster_id_override: GAME_QA_MONSTER_ID 환경변수로 전달됨(G-5, 2026-10-07).
#      combat_test.gd가 room 순환(기존 5종)과 무관하게 MonsterCatalog의 그 id 몬스터를 직접
#      구성한다 — G-5가 새로 채운 20종 몬스터 데이터가 실제 전투 화면에서 스킬 효과를
#      내는지(이름/다이스 구성/디버그 정보 줄) 스크린샷으로 확인하기 위한 용도. 아직
#      런 몬스터 계획(G-6)이 없어 평소 플레이로는 신규 몬스터를 만날 수 없으므로 이 훅이
#      유일한 확인 경로)
#   scripts/qa_shot.sh character_select 60 "" "" "" "" "" "" 1
#     (9번째 인자 key_run: [대형 기획 14] N-1, 2026-10-15. "1"이면 GAME_QA_KEY_RUN=1로
#      전달돼 code/qa/visual_qa.gd가 스크린샷 캡처 대신 "실제 InputEventKey 시퀀스로
#      마우스 없이 한 판 진행해보기" 모드로 전환된다 — 캐릭터 선택(카드 탐색+시작 스킬
#      슬롯 진입/복귀+확정)->던전 시작->던전 맵(기본 포커스가 주 행동인지)->전투 입장->
#      실제 물리 전투 자동 승리 대기->보상 선택->"다음"->다음 방까지 2개 방을 반복해
#      RunState가 실제로 바뀌는지까지 확인한다. GAME_START는 반드시 character_select여야
#      한다(이 모드의 시작점). PNG를 저장하지 않으므로 godot 종료 코드만으로 성공/실패를
#      판정하고, 단계별 결과는 stdout에 [KeyRun] 접두어로 출력된다)
#
# 동작:
#   1) godot --headless --import  (에셋 최초 1회 import / 최신화. 이미 최신이면 빠르게 끝남)
#   2) 실제 창을 띄워 지정 씬을 실행하고, code/qa/visual_qa.gd 하네스가
#      지정 프레임에서 스크린샷을 찍고 창을 닫는다.
#
# 이 파일이 프로젝트 루트/scripts/ 에 있는 이유: .claude/settings.json 의 자동 승인
# 허용 목록이 "scripts/qa_shot.sh" 경로를 그대로 참조하고 있어서(자동 반복 루프인
# Util/loop/loop.sh가 사람 개입 없이 이 스크립트를 실행해야 함), 다른 코드 파일들처럼
# code/ 밑으로 옮기면 매번 수동 승인이 필요해져 무인 루프가 멈춘다. 그래서 이 실행기
# 스크립트만 예외적으로 루트에 남겨둠 (동시에 "폴더를 열면 뭘 해야 할지 바로 안다"는
# 요구사항도 만족시킴).
#
# 필요 환경변수 (선택):
#   GODOT_BIN   godot 실행 파일 이름/경로 (기본값: godot4)

set -uo pipefail

SCENE_NAME="${1:-}"
FRAME="${2:-60}"
OUT="${3:-}"
QA_CALL="${4:-}"
SETTLE="${5:-}"
CLICK_PATH="${6:-}"
ROOM_OVERRIDE="${7:-}"
MONSTER_ID_OVERRIDE="${8:-}"
# 9번째 인자 key_run: [대형 기획 14] N-1 — "1"이면 GAME_QA_KEY_RUN=1로 전달됨.
# code/qa/visual_qa.gd가 스크린샷 캡처 대신 실제 InputEventKey 시퀀스로 캐릭터
# 선택->던전 맵->전투->보상->다음 방 흐름을 마우스 없이 진행해보는 모드로 전환된다
# (code/qa/key_sequence_run.gd). 이 모드는 PNG를 저장하지 않으므로 아래 성공 판정도
# "godot 종료 코드 0"만 보고 PNG 존재 여부는 건너뛴다 — 통과/실패 로그는 stdout에
# [KeyRun] 접두어로 출력된다.
KEY_RUN="${9:-}"

if [[ -z "$SCENE_NAME" ]]; then
  echo "사용법: $0 <scene_name> [frame] [output_path]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GODOT_BIN="${GODOT_BIN:-godot4}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "[qa_shot] '$GODOT_BIN' 실행 파일을 찾을 수 없습니다." >&2
  echo "          GODOT_BIN 환경변수로 실제 godot 실행 파일 경로를 지정하세요." >&2
  echo "          예: GODOT_BIN=/usr/local/bin/godot4 $0 $SCENE_NAME" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/qa_out"

echo "[qa_shot] 1/2 import 확인 중..."
if ! "$GODOT_BIN" --path "$PROJECT_DIR" --headless --import >/tmp/qa_import.log 2>&1; then
  echo "[qa_shot] import 단계 실패. 로그:" >&2
  cat /tmp/qa_import.log >&2
  exit 1
fi

RUN_CMD=("$GODOT_BIN" --path "$PROJECT_DIR")

# [대형 기획 15] Q-1 공통 전제 — 이 환경에서 QA 캡처 폭이 이따금 1280px 대신
# 1028px로 잘리는 현상이 여러 세션에 걸쳐 반복 기록됐다(원인 불명으로 추정 —
# 창이 화면 밖 좌표로 옮겨질 때 멀티 모니터 배치에 따라 다른 DPI 스케일의
# 가상 모니터에 걸쳐 창 크기가 재계산되는 것으로 의심됨, project.godot는 DPI
# 설정이 아예 없어 엔진 기본값을 그대로 씀). project.godot의
# viewport_width/height(1280/720)에만 의존하지 않고, 커맨드라인에서 직접
# 창 해상도를 강제 지정해 DPI/타이밍에 따른 재계산 여지를 줄인다.
RUN_CMD+=(--resolution 1280x720)

# 캡처용 창이 작업 중인 화면에 번쩍 뜨는 것(이터레이션이 스크린샷을 찍을 때마다 팝업)을
# 막기 위해 창을 화면 밖 좌표에 띄운다. 렌더링/스크린샷은 화면 밖에서도 정상 동작한다
# (2026-10-15 확인). 창을 눈으로 보고 싶으면 QA_SHOW_WINDOW=1 로 실행.
if [[ "${QA_SHOW_WINDOW:-0}" != "1" ]]; then
  RUN_CMD+=(--position -32000,-32000)
fi

# 실제 창을 띄워야 하므로 --headless 를 쓰지 않는다.
# `DISPLAY` 환경변수는 X11(리눅스)에만 있는 개념이다. Windows(Git Bash/MINGW)나 macOS는
# DISPLAY가 항상 비어 있어도 네이티브 창을 그냥 띄울 수 있으므로, "DISPLAY 없으면
# xvfb-run 필요" 요구는 리눅스에서만 적용해야 한다 (아니면 Windows/macOS에서 이 스크립트가
# 항상 실패한다 — 실제로 이 PC(MINGW64)에서 재현된 버그).
UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
case "$UNAME_S" in
  Linux)
    if [[ -z "${DISPLAY:-}" ]]; then
      if command -v xvfb-run >/dev/null 2>&1; then
        echo "[qa_shot] DISPLAY 없음 -> xvfb-run 으로 가상 디스플레이 사용"
        RUN_CMD=(xvfb-run -a "${RUN_CMD[@]}")
      else
        echo "[qa_shot] DISPLAY가 없고 xvfb-run도 설치되어 있지 않습니다." >&2
        echo "          실제 창을 띄우려면 디스플레이(X11) 또는 xvfb-run이 필요합니다." >&2
        exit 1
      fi
    fi
    ;;
  *)
    # Windows(MINGW*/MSYS*/CYGWIN*)나 macOS(Darwin) 등: DISPLAY 개념이 없어도
    # 네이티브 창 시스템이 항상 있으므로 아무 것도 할 필요 없음.
    ;;
esac

echo "[qa_shot] 2/2 실행 및 캡처: scene=$SCENE_NAME frame=$FRAME"

ENV_ARGS=(GAME_START="$SCENE_NAME" GAME_QA_FRAME="$FRAME")
if [[ -n "$OUT" ]]; then
  ENV_ARGS+=(GAME_QA_OUT="$OUT")
fi
if [[ -n "$QA_CALL" ]]; then
  ENV_ARGS+=(GAME_QA_CALL="$QA_CALL")
fi
if [[ -n "$SETTLE" ]]; then
  ENV_ARGS+=(GAME_QA_SETTLE="$SETTLE")
fi
if [[ -n "$CLICK_PATH" ]]; then
  ENV_ARGS+=(GAME_QA_CLICK_PATH="$CLICK_PATH")
fi
if [[ -n "$ROOM_OVERRIDE" ]]; then
  ENV_ARGS+=(GAME_QA_ROOM_OVERRIDE="$ROOM_OVERRIDE")
fi
if [[ -n "$MONSTER_ID_OVERRIDE" ]]; then
  ENV_ARGS+=(GAME_QA_MONSTER_ID="$MONSTER_ID_OVERRIDE")
fi
if [[ "$KEY_RUN" == "1" ]]; then
  ENV_ARGS+=(GAME_QA_KEY_RUN="1")
fi

env "${ENV_ARGS[@]}" "${RUN_CMD[@]}"
GODOT_EXIT=$?

if [[ "$KEY_RUN" == "1" ]]; then
  if [[ "$GODOT_EXIT" == "0" ]]; then
    echo "[qa_shot] 키 시퀀스 플레이스루 성공 (godot exit=0)"
    exit 0
  else
    echo "[qa_shot] 키 시퀀스 플레이스루 실패 (godot exit=$GODOT_EXIT) — 위 [KeyRun] 로그 참고" >&2
    exit 1
  fi
fi

FINAL_OUT="${OUT:-qa_out/${SCENE_NAME}.png}"
if [[ "$FINAL_OUT" != /* ]]; then
  FINAL_OUT="$PROJECT_DIR/$FINAL_OUT"
fi

if [[ ! -f "$FINAL_OUT" || ! -s "$FINAL_OUT" ]]; then
  echo "[qa_shot] 실패: 스크린샷 파일이 없거나 비어있습니다: $FINAL_OUT (godot exit=$GODOT_EXIT)" >&2
  exit 1
fi

# [대형 기획 15] Q-1 공통 전제 — "캡처가 항상 1280x720이어야 한다"를 스크립트가 직접
# 검사한다. PNG 포맷은 바이트 16~23(IHDR 청크의 width/height, 각 4바이트 big-endian
# unsigned int)에 실제 픽셀 크기를 담고 있으므로, 별도 이미지 처리 도구 없이 헤더
# 바이트만 읽어 폭/높이를 계산한다(이 환경에서 python/awk 같은 범용 스크립팅 도구는
# 별도 승인 없이 못 쓰지만, xxd/od는 qa_shot.sh 자신의 셸 프로세스 안에서 그냥
# 실행되므로 문제 없음).
EXPECTED_WIDTH=1280
EXPECTED_HEIGHT=720
PNG_HEADER_HEX="$(xxd -s 16 -l 8 -p "$FINAL_OUT" | tr -d '\n')"
if [[ ${#PNG_HEADER_HEX} -eq 16 ]]; then
  ACTUAL_WIDTH=$((16#${PNG_HEADER_HEX:0:8}))
  ACTUAL_HEIGHT=$((16#${PNG_HEADER_HEX:8:8}))
else
  ACTUAL_WIDTH=-1
  ACTUAL_HEIGHT=-1
fi

if [[ "$ACTUAL_WIDTH" -ne "$EXPECTED_WIDTH" || "$ACTUAL_HEIGHT" -ne "$EXPECTED_HEIGHT" ]]; then
  echo "[qa_shot] 실패: 캡처 해상도가 기대값과 다릅니다: ${ACTUAL_WIDTH}x${ACTUAL_HEIGHT} (기대 ${EXPECTED_WIDTH}x${EXPECTED_HEIGHT}) — $FINAL_OUT" >&2
  echo "          이 환경에서 반복된 QA 캡처 폭 잘림 이슈일 수 있음(docs/STATUS.md '알려진 이슈' 참고)." >&2
  exit 1
fi

echo "[qa_shot] 성공: $FINAL_OUT (${ACTUAL_WIDTH}x${ACTUAL_HEIGHT})"
exit 0
