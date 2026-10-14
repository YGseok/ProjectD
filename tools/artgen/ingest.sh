#!/usr/bin/env bash
# tools/artgen/ingest.sh — ChatGPT 화면에서 직접 만들어 받은 이미지를 규격 후보로 후처리한다(무료 경로).
# 사용법: bash tools/artgen/ingest.sh <이미지 파일> <full|face|icon> [이름(기본: 파일명)]
#   결과: tools/artgen/out/<이름>/<시각>/candidate_1.png (+ 아이콘은 _128) — 검수 후 adopt.sh
#   불투명 단색 배경이면 자동으로 지운다(full/face).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$ROOT/tools/artgen"
SRC="${1:?이미지 파일 경로}"; KIND="${2:?full|face|icon}"
NAME="${3:-$(basename "${SRC%.*}")}"
GODOT_BIN="${GODOT_BIN:-/d/Godot/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$HERE/out/$NAME/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"
"$GODOT_BIN" --headless --script "$HERE/postprocess.gd" -- "$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")" "$KIND" "$OUT" 2>&1 \
  | grep -E "^\[post\]|ERROR" || true
echo "[ingest] 완료: $OUT"
