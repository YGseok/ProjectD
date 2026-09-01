#!/usr/bin/env bash
# loop/loop.sh — Claude Code 헤드리스 무한 반복 루프
#
# 매 이터레이션마다 완전히 새로운 claude -p 세션을 띄운다 (--continue 사용 안 함).
# 즉, 세션 간 기억은 없다. 모든 상태는 파일(docs/DESIGN.md, docs/STATUS.md,
# docs/feedback/INBOX.md)로만 이어진다.
#
# 중단하려면: touch loop/STOP
# (다음 이터레이션 시작 전, 그리고 진행 중 이터레이션이 끝난 직후에 확인한다)
#
# 로그: loop/logs/iter_<N>_<timestamp>.log

set -uo pipefail
# 주의: -e 를 쓰지 않는다. 한 이터레이션이 실패해도 루프 자체는 계속 돌아야 한다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STOP_FILE="$SCRIPT_DIR/STOP"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

ITER=0

read -r -d '' PROMPT <<'EOF'
너는 이 Godot 4.x 로그라이크 프로젝트를 한 세션 동안 개선하는 에이전트다.
너는 이전 세션을 전혀 기억하지 못한다. 모든 컨텍스트는 아래 파일들에서 읽어야 한다.

반드시 이 순서로 작업하라:

1. docs/DESIGN.md 를 읽어라. (무엇을 만드는가, "이 정도면 됐다"의 기준)
2. docs/STATUS.md 를 읽어라. (지금 위치, 다음 할 일 큐, 완료 기록, 알려진 이슈)
3. docs/feedback/INBOX.md 를 읽어라. (사용자의 지시 — 최우선으로 반영해야 한다)
4. STATUS.md의 "다음 할 일 큐"에서 작업을 하나(또는 서로 연결된 작은 묶음) 골라 진행하라.
   INBOX.md에 미처리 항목이 있으면 큐보다 그것을 우선한다.
5. 코드/씬을 수정했으면 scripts/qa_shot.sh 로 관련 화면을 스크린샷으로 찍어
   실제로 확인하라. 예: scripts/qa_shot.sh dungeon
   - 크래시가 나거나 스크린샷이 저장되지 않으면 그 이터레이션은 실패다. 원인을 고치고 다시 찍어라.
   - 스크린샷 결과가 의도와 다르면(레이아웃 깨짐 등) 눈으로 보고 고쳐라.
6. 작업을 마치면 docs/STATUS.md 를 인수인계서처럼 갱신하라:
   - "지금 위치" 갱신
   - "다음 할 일 큐" 갱신 (끝낸 항목 제거, 새로 발견한 작업 추가)
   - "완료 기록"에 이번 이터레이션에서 실제로 한 일을 구체적으로 추가
   - 막힌 것이 있으면 "알려진 이슈 / 막힌 것"에 명시
7. INBOX.md에서 이번에 반영한 항목이 있으면 지우지 말고
   앞에 "[처리됨 - 오늘 날짜]" 를 붙여 표시하라.
8. git add 후 git commit 으로 변경사항을 남겨라. 커밋 메시지에 무엇을, 왜 했는지 간단히 남겨라.

한 세션에 너무 많은 것을 한 번에 바꾸려 하지 마라. 작은 단위로, 검증 가능하게 진행하라.
EOF

echo "[loop] 시작. 중단하려면: touch $STOP_FILE"
echo "[loop] 로그 디렉토리: $LOG_DIR"

while true; do
  if [[ -f "$STOP_FILE" ]]; then
    echo "[loop] STOP 파일 발견. 루프를 종료합니다."
    break
  fi

  ITER=$((ITER + 1))
  TS="$(date +%Y%m%d_%H%M%S)"
  LOG_FILE="$LOG_DIR/iter_${ITER}_${TS}.log"

  echo "[loop] --- 이터레이션 $ITER 시작 ($TS) ---"

  (
    cd "$PROJECT_DIR" && claude -p "$PROMPT"
  ) >"$LOG_FILE" 2>&1
  EXIT_CODE=$?

  echo "[loop] 이터레이션 $ITER 종료 (exit=$EXIT_CODE). 로그: $LOG_FILE"

  if [[ -f "$STOP_FILE" ]]; then
    echo "[loop] STOP 파일 발견. 루프를 종료합니다."
    break
  fi

  sleep 2
done

echo "[loop] 종료. 총 $ITER 회 이터레이션 실행됨."
