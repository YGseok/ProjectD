extends Node
## 던전 런(run) 전체에 걸쳐 유지되는 최소 상태.
## Autoload(RunState)로 등록해서 씬 전환(dungeon_map <-> combat_test) 사이에도 값이
## 유지되게 한다. 던전 길이/런 구조 자체는 아직 미정(DESIGN.md 참고)이라, 지금은
## "클리어한 방 개수" 하나만 추적하는 최소 스켈레톤이다.

var rooms_cleared := 0


func reset_run() -> void:
	rooms_cleared = 0
