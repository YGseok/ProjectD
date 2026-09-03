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
##
## gold: INBOX.md 피드백("승리하면 골드를 주며, 상점 이벤트에서 사용할 수 있다")을
## 반영. 전투 승리 시 combat_test.gd가 더하고, 상점(shop.gd)에서 아이템 구매 시 뺀다.
##
## pip_inventory: INBOX.md 피드백(2026-09-03) "주사위 눈금 바꾸는 방법을 인지하기
## 어렵다. 인벤토리 창에 눈금이 쌓이고, 해당 눈금과 주사위 눈금이 교환되는 형태여야할
## 것 같다"를 반영. 기존에는 커스터마이징이 "면을 고르고 1..면개수 범위에서 아무 값이나
## 직접 골라 교체"하는 자유 입력 방식이었는데, 이제 "눈금"(정수 값 하나)이 전투 승리
## 보상으로 여기 쌓이고, code/scenes/customize_panel.gd에서 인벤토리의 눈금 하나와
## 다이스의 면 하나를 맞바꾸는 상호작용으로 바뀐다(customize_panel.gd 참고). 바꿔치기
## 되어 밀려난 기존 면 값은 다시 이 배열로 돌아온다(교환이므로 눈금이 사라지지 않음).

const TOTAL_ROOMS := 5

var rooms_cleared := 0
var gold := 0
var player_attack_bag: DiceBag
var player_defense_bag: DiceBag
var pip_inventory: Array[int] = []


func _ready() -> void:
	reset_run()


func reset_run() -> void:
	rooms_cleared = 0
	gold = 0
	player_attack_bag = DiceBag.new(4, 3)
	player_defense_bag = DiceBag.new(4, 3)
	pip_inventory = []


func is_run_complete() -> bool:
	return rooms_cleared >= TOTAL_ROOMS
