#!/usr/bin/env bash
# tools/artgen/prompt.sh — job을 ChatGPT에 붙여넣을 프롬프트로 출력한다(무료 경로).
# 사용법: bash tools/artgen/prompt.sh <job_id>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$ROOT/tools/artgen"
JOB_DIR="$HERE/jobs/${1:?job_id}"
KIND=""; SIZE=""; REFS=""
# shellcheck disable=SC1091
source "$JOB_DIR/job.env"
case "$SIZE" in 1024x1536) RATIO="portrait 2:3";; 1536x1024) RATIO="landscape 3:2";; *) RATIO="square 1:1";; esac
echo "===== 첨부할 참고 이미지 ====="
if [ -n "$REFS" ]; then for r in $REFS; do echo "  $ROOT/$r"; done; else echo "  (없음)"; fi
echo "===== ChatGPT에 붙여넣을 프롬프트 ====="
cat "$HERE/style_$KIND.txt"
echo
cat "$JOB_DIR/prompt.txt"
echo
echo "Output: one image, $RATIO, PNG with a transparent background (if transparency is not possible, use a plain flat white background)."
