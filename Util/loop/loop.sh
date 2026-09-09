#!/usr/bin/env bash
# Util/loop/loop.sh — Claude Code 헤드리스 무한 반복 루프
#
# 매 이터레이션마다 완전히 새로운 claude -p 세션을 띄운다 (--continue 사용 안 함).
# 즉, 세션 간 기억은 없다. 모든 상태는 파일(docs/DESIGN.md, docs/STATUS.md,
# docs/feedback/INBOX.md)로만 이어진다.
#
# 중단하려면: touch Util/loop/STOP
# (다음 이터레이션 시작 전, 그리고 진행 중 이터레이션이 끝난 직후에 확인한다)
#
# 로그: Util/loop/logs/iter_<N>_<timestamp>.log

set -uo pipefail
# 주의: -e 를 쓰지 않는다. 한 이터레이션이 실패해도 루프 자체는 계속 돌아야 한다.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
STOP_FILE="$SCRIPT_DIR/STOP"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

# 절전모드 등으로 네트워크가 끊기면 claude -p가 응답 없이 무한정 멈출 수 있다.
# 이터레이션당 최대 대기 시간(초)을 두어 자동으로 죽이고 다음 이터레이션으로 넘어가게 한다.
ITER_TIMEOUT="${ITER_TIMEOUT:-1800}"

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
   - **큐의 남은 항목 전부가 "사람 피드백/설계 결정 필요"라 실제로 진행할 수 있는
     독립적인 작업이 하나도 없다면(코드를 다시 읽어봐도 고칠 새 버그가 안 나오는
     상태 포함), 그 사실 자체가 이번 이터레이션의 결론이다.** 이럴 때는:
     - **git commit을 만들지 마라.** "재확인했지만 코드 변경 없음" 같은 빈 커밋을
       반복해서 남기지 말 것 — 실제로 2026-09-09에 이런 빈 커밋이 30개 넘게 쌓여서
       API 사용량만 낭비하고 git 히스토리만 지저분해진 사고가 있었다. 같은 결론을
       매번 새 커밋으로 재확인할 필요 없다.
     - docs/STATUS.md의 "알려진 이슈 / 막힌 것"에 (아직 그 내용이 없다면) "다음
       진행을 위해 사람의 플레이테스트/피드백 또는 설계 결정이 필요함 — 구체적으로
       무엇이 필요한지"를 한 번만 적어두고, 그대로 세션을 끝내라.
5. 코드/씬을 수정했으면 scripts/qa_shot.sh 로 관련 화면을 스크린샷으로 찍어
   실제로 확인하라. 예: scripts/qa_shot.sh dungeon
   - 크래시가 나거나 스크린샷이 저장되지 않으면 그 이터레이션은 실패다. 원인을 고치고 다시 찍어라.
   - 스크린샷 결과가 의도와 다르면(레이아웃 깨짐 등) 눈으로 보고 고쳐라.
6. 작업을 마치면 docs/STATUS.md 를 인수인계서처럼 갱신하라:
   - "마지막 갱신"과 "지금 위치"는 **덧붙이지 말고 완전히 새로 써서 교체하라** —
     둘 다 "지금 이 순간의 스냅샷"이어야 한다. 이전 이터레이션들의 문구가 그대로
     쌓여 남아있으면 안 된다(매 이터레이션 통째로 읽는 파일이라 계속 누적되면
     읽기 비용이 무한정 커진다 — 실제로 2026-09-07에 275KB까지 불어나서
     docs/STATUS_ARCHIVE.md로 정리한 적 있음, 그 사고를 반복하지 말 것).
   - "다음 할 일 큐" 갱신 (끝낸 항목 제거, 새로 발견한 작업 추가)
   - "완료 기록"에 이번 이터레이션에서 실제로 한 일을 새 항목으로 추가하되,
     이 섹션의 항목 수가 10개를 넘으면 가장 오래된 항목들을(10개가 될 때까지)
     잘라서 docs/STATUS_ARCHIVE.md 맨 위(또는 적절한 위치)에 옮겨 적어라 — 파일이
     없으면 새로 만들어라. 내용을 요약하거나 버리지 말고 그대로 옮기기만 하라.
   - 막힌 것이 있으면 "알려진 이슈 / 막힌 것"에 명시
7. INBOX.md에서 이번에 반영한 항목이 있으면, 그 파일 맨 위 "사용 규칙"을 그대로
   따라 처리하라 — 태그만 붙이지 말고 반드시 해당 섹션("처리됨"/"부분 처리됨")까지
   실제로 옮기고, "처리됨"이 12개를 넘으면 오래된 것부터 docs/INBOX_ARCHIVE.md로
   옮길 것 (INBOX.md 자체에 이 규칙이 적혀 있으니 그대로 따르면 된다).
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

  # 이 스크립트는 시작할 때 자기 위치(SCRIPT_DIR 등)를 한 번만 계산해서 고정해둔다.
  # 이터레이션 도중 에이전트가 프로젝트 구조를 재구성하면서 이 스크립트가 실행 중인
  # 폴더 자체를 옮기거나 지우면, 이후 로그 파일 쓰기가 계속 조용히 실패하면서
  # (claude 세션은 시작도 못 됨) 아무 흔적 없이 무한 재시도만 반복하게 된다.
  # 그런 상황을 조용히 반복하는 대신 여기서 즉시 크게 알리고 종료한다.
  if [[ ! -d "$SCRIPT_DIR" ]] || [[ ! -f "${BASH_SOURCE[0]}" ]]; then
    echo "[loop] 오류: 이 스크립트가 시작된 폴더($SCRIPT_DIR) 또는 스크립트 파일 자체가" >&2
    echo "        더 이상 존재하지 않습니다. 이터레이션 도중 프로젝트 구조가 재구성되어" >&2
    echo "        옮겨지거나 삭제된 것으로 보입니다. 이 루프 인스턴스는 여기서 종료합니다." >&2
    echo "        새(현재) 위치에서 이 스크립트를 다시 실행해주세요." >&2
    break
  fi

  ITER=$((ITER + 1))
  TS="$(date +%Y%m%d_%H%M%S)"
  LOG_FILE="$LOG_DIR/iter_${ITER}_${TS}.log"

  echo "[loop] --- 이터레이션 $ITER 시작 ($TS) ---"

  (
    cd "$PROJECT_DIR" && timeout -k 30 "$ITER_TIMEOUT" claude -p "$PROMPT"
  ) >"$LOG_FILE" 2>&1
  EXIT_CODE=$?

  if [[ "$EXIT_CODE" -eq 124 ]]; then
    echo "[loop] 이터레이션 $ITER 타임아웃(${ITER_TIMEOUT}초 초과, 예: 절전모드로 인한 응답 없음) -> 강제 종료함. 로그: $LOG_FILE"
  else
    echo "[loop] 이터레이션 $ITER 종료 (exit=$EXIT_CODE). 로그: $LOG_FILE"
  fi

  if [[ -f "$STOP_FILE" ]]; then
    echo "[loop] STOP 파일 발견. 루프를 종료합니다."
    break
  fi

  sleep 2
done

echo "[loop] 종료. 총 $ITER 회 이터레이션 실행됨."
