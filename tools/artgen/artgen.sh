#!/usr/bin/env bash
# tools/artgen/artgen.sh — OpenAI 이미지 API로 아트 후보를 생성하고 규격에 맞게 후처리한다.
#
# 사용법:  bash tools/artgen/artgen.sh <job_id> [후보 수(기본 2)]
#   job 정의: tools/artgen/jobs/<job_id>/job.env + prompt.txt
#   결과:     tools/artgen/out/<job_id>/<타임스탬프>/candidate_N.png  (게임에 바로 넣지 않음 — 검수 후 adopt.sh)
#
# 필요: 환경변수 OPENAI_API_KEY (사용자가 직접 설정. 이 스크립트는 키를 파일에 쓰거나 출력하지 않는다)
# 선택: OPENAI_IMAGE_MODEL(기본 gpt-image-1), OPENAI_IMAGE_QUALITY(기본 medium), GODOT_BIN
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$ROOT/tools/artgen"
JOB="${1:?job_id가 필요합니다 (tools/artgen/jobs/ 아래 폴더 이름)}"
N="${2:-2}"
JOB_DIR="$HERE/jobs/$JOB"
[ -f "$JOB_DIR/job.env" ] || { echo "[artgen] $JOB_DIR/job.env 없음" >&2; exit 1; }
[ -n "${OPENAI_API_KEY:-}" ] || { echo "[artgen] OPENAI_API_KEY 환경변수가 없습니다." >&2; exit 1; }

# job.env: KIND(full|face|icon), SIZE(예: 1024x1536), REFS(참고 이미지 경로들, 프로젝트 루트 기준, 공백 구분, 비우면 생성 모드)
KIND=""; SIZE=""; REFS=""
# shellcheck disable=SC1091
source "$JOB_DIR/job.env"
MODEL="${OPENAI_IMAGE_MODEL:-gpt-image-1}"
QUALITY="${OPENAI_IMAGE_QUALITY:-medium}"
GODOT_BIN="${GODOT_BIN:-/d/Godot/Godot_v4.7.2-stable_win64_console.exe}"

PROMPT="$(cat "$HERE/style_$KIND.txt")

$(cat "$JOB_DIR/prompt.txt")"

OUT="$HERE/out/$JOB/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"
printf '%s\n' "$PROMPT" > "$OUT/prompt_used.txt"

echo "[artgen] job=$JOB kind=$KIND size=$SIZE n=$N model=$MODEL quality=$QUALITY refs=[${REFS}]"
if [ -n "$REFS" ]; then
  args=()
  for r in $REFS; do args+=(-F "image[]=@$ROOT/$r"); done
  curl -sS --fail-with-body https://api.openai.com/v1/images/edits \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -F "model=$MODEL" -F "prompt=$PROMPT" -F "n=$N" -F "size=$SIZE" \
    -F "quality=$QUALITY" -F "background=transparent" -F "output_format=png" \
    "${args[@]}" -o "$OUT/response.json"
else
  # 프롬프트를 JSON 문자열로 안전하게 만들기: 줄바꿈 -> 공백, 큰따옴표 -> 작은따옴표,
  # 역슬래시 제거(프롬프트 의미에는 영향 없음 — 이스케이프 처리를 단순화하려는 것)
  esc=$(printf '%s' "$PROMPT" | tr '\r\n' '  ' | tr -d '\134' | tr '"' "'")
  printf '{"model":"%s","prompt":"%s","n":%s,"size":"%s","quality":"%s","background":"transparent","output_format":"png"}' \
    "$MODEL" "$esc" "$N" "$SIZE" "$QUALITY" > "$OUT/request.json"
  curl -sS --fail-with-body https://api.openai.com/v1/images/generations \
    -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
    --data-binary "@$OUT/request.json" -o "$OUT/response.json"
fi

"$GODOT_BIN" --headless --script "$HERE/postprocess.gd" -- "$OUT/response.json" "$KIND" "$OUT" 2>&1 \
  | grep -E "^\[post\]|ERROR" || true
rm -f "$OUT/response.json"   # 수 MB짜리 base64 원본은 후보 PNG로 풀었으니 지움
echo "[artgen] 완료: $OUT"
