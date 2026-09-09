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
##
## die_inventory: INBOX.md 피드백(2026-09-09) "다이스 승급 이벤트에서, 면 개수가
## 가장 작은것 교체가 아닌 획득으로 바꾼다. 눈금 획득 또는 다이스 승급시, 인벤토리로
## 들어와서 교체하도록 한다"를 반영. 기존에는 "다이스 승급" 아이템(kind=upgrade_die)을
## 고르면 systems/dice_item_pool.gd가 그 즉시 주머니에서 면 개수가 가장 작은 다이스를
## 찾아 자동으로 교체했는데, 이제는 pip_inventory와 같은 방식으로 "새 다이스의 면
## 개수"(정수)만 여기 쌓아두고, 실제로 어느 주머니의 어느 다이스와 바꿀지는
## code/scenes/customize_panel.gd에서 플레이어가 나중에 직접 고른다. 교환으로 밀려난
## 기존 다이스도 면 개수만 이 배열로 돌아와(면 값 자체는 표준으로 리셋되지만, 이전
## upgrade_die 자동교체도 같은 리셋을 했으므로 새로운 손해는 아님) 다른 자리에 다시
## 쓸 수 있다.
##
## shop_visits: 업적 "단골 손님"(shop_regular, docs/STATUS.md 큐 13이 예로 든 "상점
## 이용 횟수" 카운터)을 위해 추가. shop.gd가 상점을 나갈 때마다 1 증가시킨다.
##
## character_id: INBOX.md [대형 기획 1] "플레이어블 캐릭터 4종 추가"를 위해 신규 추가.
## character_select.gd에서 고른 character_profiles.gd의 프로필 id를 저장해두고,
## reset_run()이 새 주머니를 만들 때마다 해당 프로필의 시작 다이스 기믹을 다시
## 적용한다(패배 후 combat_test.gd/dungeon_map.gd가 인자 없이 reset_run()을 부르는
## 기존 호출부들도 "직전에 고른 캐릭터 유지"가 되도록, 인자를 안 주면 character_id를
## 그대로 둔다 — 새 캐릭터 선택 화면을 다시 거치지 않는 한 캐릭터가 바뀌지 않음).

const TOTAL_ROOMS := 5

var rooms_cleared := 0
var gold := 0
var shop_visits := 0
var character_id: String = CharacterProfiles.PROFILES[0]["id"]
var player_attack_bag: DiceBag
var player_defense_bag: DiceBag
var pip_inventory: Array[int] = []
var die_inventory: Array[int] = []


func _ready() -> void:
	reset_run()


## new_character_id를 비워두면(기본값) 기존 character_id를 그대로 유지한다 —
## "캐릭터 선택 화면을 거치지 않고 다시 시작하는" 기존 호출부(패배 후 재시작, 런 클리어
## 후 재시작)가 방금 고른 캐릭터를 잃지 않게 하기 위함.
func reset_run(new_character_id: String = "") -> void:
	if new_character_id != "":
		character_id = new_character_id
	rooms_cleared = 0
	gold = 0
	shop_visits = 0
	player_attack_bag = DiceBag.new(4, 3)
	player_defense_bag = DiceBag.new(4, 3)
	pip_inventory = []
	die_inventory = []
	_apply_character_gimmick()


## character_id에 해당하는 프로필의 시작 다이스 기믹을 새로 만든 주머니에 한 번만
## 적용한다(몬스터 기믹과 같은 "정적 적용" 방식 — combat_test.gd _ready() 참고).
func _apply_character_gimmick() -> void:
	var profile := CharacterProfiles.get_profile(character_id)
	match profile.get("gimmick", ""):
		"min_max_only":
			player_attack_bag.force_min_max_faces()
			player_defense_bag.force_min_max_faces()
		"fixed_defense_die":
			player_defense_bag.force_fixed_value_for_die(0, CharacterProfiles.fixed_defense_die_value(4))
		_:
			pass


func is_run_complete() -> bool:
	return rooms_cleared >= TOTAL_ROOMS
