# loop/ — 헤드리스 반복 개발 루프

## 시작

```bash
chmod +x loop/loop.sh scripts/qa_shot.sh
./loop/loop.sh
```

## 중단

```bash
touch loop/STOP
```

루프가 진행 중인 이터레이션을 마친 뒤 STOP 파일을 확인하고 정상 종료한다.
다시 시작하려면 STOP 파일을 지우고 `./loop/loop.sh` 를 다시 실행하면 된다:

```bash
rm loop/STOP
./loop/loop.sh
```

## 로그

각 이터레이션의 전체 출력은 `loop/logs/iter_<N>_<timestamp>.log` 에 저장된다.

## 왜 --continue를 안 쓰는가

각 이터레이션은 이전 세션을 전혀 기억하지 못하는 완전히 새로운 `claude -p` 세션이다.
이게 핵심 설계다 — AI가 이전 대화의 편향이나 누적된 잘못된 가정에 갇히지 않고,
매번 파일(docs/DESIGN.md, docs/STATUS.md, docs/feedback/INBOX.md)에 적힌
"객관적으로 기록된 현재 상태"만 보고 판단하게 만든다.
따라서 STATUS.md 갱신을 소홀히 하면 다음 세션은 정말로 아무것도 모른 채 시작한다.
