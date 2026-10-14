#!/usr/bin/env bash
# tools/artgen/ingest_ui.sh — UI 키트 이미지 후처리 (크기 맞춤 + 마젠타 장식 → base/accent 분리)
# 사용법: bash tools/artgen/ingest_ui.sh <이미지> <WxH> <이름> [split|plain]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$ROOT/tools/artgen"
SRC="${1:?이미지}"; SIZE="${2:?WxH}"; NAME="${3:?이름}"; MODE="${4:-split}"
GODOT_BIN="${GODOT_BIN:-/d/Godot/Godot_v4.7.2-stable_win64_console.exe}"
OUT="$HERE/out/$NAME/$(date +%Y%m%d_%H%M%S)"; mkdir -p "$OUT"
ABS="$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")"
cp "$ABS" "$OUT/raw.png"
"$GODOT_BIN" --headless --script "$HERE/ui_split.gd" -- "$ABS" "$SIZE" "$OUT" "$MODE" 2>&1 | grep -E "^\[ui\]|ERROR" || true
echo "[ingest_ui] 완료: $OUT"
