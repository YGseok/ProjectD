#!/usr/bin/env bash
# scripts/qa_shot.sh — 시각 QA 스크린샷 촬영 스크립트
#
# 사용법:
#   scripts/qa_shot.sh <scene_name> [frame] [output_path] [qa_call]
#
# 예:
#   scripts/qa_shot.sh dungeon
#   scripts/qa_shot.sh dungeon 90
#   scripts/qa_shot.sh dungeon 90 qa_out/dungeon_check.png
#   scripts/qa_shot.sh combat_test 900 qa_out/combat_test_picker.png _show_customize_picker
#     (4번째 인자 qa_call: 캡처 직전 현재 씬에서 인자 없이 호출할 메서드 이름 —
#      code/qa/visual_qa.gd의 GAME_QA_CALL로 전달됨. 클릭을 흉내낼 수 없는 자동 QA에서
#      버튼 뒤에 있는 하위 화면을 직접 열어보고 싶을 때 사용)
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

# 실제 창을 띄워야 하므로 --headless 를 쓰지 않는다.
# 디스플레이가 없는 환경(예: CI, 컨테이너)이면 xvfb-run 으로 가상 디스플레이를 띄운다.
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

echo "[qa_shot] 2/2 실행 및 캡처: scene=$SCENE_NAME frame=$FRAME"

ENV_ARGS=(GAME_START="$SCENE_NAME" GAME_QA_FRAME="$FRAME")
if [[ -n "$OUT" ]]; then
  ENV_ARGS+=(GAME_QA_OUT="$OUT")
fi
if [[ -n "$QA_CALL" ]]; then
  ENV_ARGS+=(GAME_QA_CALL="$QA_CALL")
fi

env "${ENV_ARGS[@]}" "${RUN_CMD[@]}"
GODOT_EXIT=$?

FINAL_OUT="${OUT:-qa_out/${SCENE_NAME}.png}"
if [[ "$FINAL_OUT" != /* ]]; then
  FINAL_OUT="$PROJECT_DIR/$FINAL_OUT"
fi

if [[ -f "$FINAL_OUT" && -s "$FINAL_OUT" ]]; then
  echo "[qa_shot] 성공: $FINAL_OUT"
  exit 0
else
  echo "[qa_shot] 실패: 스크린샷 파일이 없거나 비어있습니다: $FINAL_OUT (godot exit=$GODOT_EXIT)" >&2
  exit 1
fi
