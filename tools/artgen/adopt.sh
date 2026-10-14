#!/usr/bin/env bash
# tools/artgen/adopt.sh — 검수한 후보 1장을 게임 경로에 채택한다.
# 사용법: bash tools/artgen/adopt.sh <후보 png 경로> <대상 경로(프로젝트 루트 기준, 예: resources/characters/pirate/full.png)>
# 아이콘은 candidate_N_128.png 를 resources/skills/<id>.png 로, 256 원본(candidate_N.png)은 _reference/skills/ 로 넣는다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="${1:?후보 경로}"; DST="$ROOT/${2:?대상 경로}"
mkdir -p "$(dirname "$DST")"
cp "$SRC" "$DST"
echo "[adopt] $SRC -> $DST"
