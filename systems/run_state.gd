extends Node
## 던전 런(run) 전체에 걸쳐 유지되는 최소 상태.
## Autoload(RunState)로 등록해서 씬 전환(dungeon_map <-> combat_test) 사이에도 값이
## 유지되게 한다.
##
## TOTAL_ROOMS(런 전체 방 개수)는 아직 DESIGN.md에서 확정된 값이 아니라, "런에 끝이
## 있다"는 구조를 검증하기 위해 임시로 잡은 값이다. 상점/선택지 등 다른 방 종류가
## 생기면 이 값과 구조 자체를 다시 정해야 한다.
##
## player_attack_bag / player_defense_bag: 플레이어의 다이스 주머니도 여기서 들고
## 있어야 전투(combat_test)를 여러 번 오가도 다이스 개조(아이템) 결과가 유지된다
## (combat_test.gd 씬은 매번 새로 로드되므로 그 안의 로컬 변수로는 지속 불가능).

const TOTAL_ROOMS := 5

var rooms_cleared := 0
var player_attack_bag: DiceBag
var player_defense_bag: DiceBag


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	rooms_cleared = 0
	player_attack_bag = DiceBag.new(4, 3)
	player_defense_bag = DiceBag.new(4, 3)


func is_run_complete() -> bool:
	return rooms_cleared >= TOTAL_ROOMS
