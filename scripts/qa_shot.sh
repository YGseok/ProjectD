#!/usr/bin/env bash
# scripts/qa_shot.sh — 시각 QA 스크린샷 촬영 스크립트
#
# 사용법:
#   scripts/qa_shot.sh <scene_name> [frame] [output_path]
#
# 예:
#   scripts/qa_shot.sh dungeon
#   scripts/qa_shot.sh dungeon 90
#   scripts/qa_shot.sh dungeon 90 qa_out/dungeon_check.png
#
# 동작:
#   1) godot --headless --import  (에셋 최초 1회 import / 최신화. 이미 최신이면 빠르게 끝남)
#   2) 실제 창을 띄워 지정 씬을 실행하고, qa/visual_qa.gd 하네스가
#      지정 프레임에서 스크린샷을 찍고 창을 닫는다.
#
# 필요 환경변수 (선택):
#   GODOT_BIN   godot 실행 파일 이름/경로 (기본값: godot4)

set -uo pipefail

SCENE_NAME="${1:-}"
FRAME="${2:-60}"
OUT="${3:-}"

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
