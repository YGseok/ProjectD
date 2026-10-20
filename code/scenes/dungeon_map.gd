extends Node2D
## 던전 맵 허브 씬 (1차 버전).
##
## DESIGN.md 핵심 루프: "방 선택 -> 이벤트 발생 (전투/상점/선택지) -> 보상 -> 다음 방".
## 상점/선택지 이벤트는 아직 내용이 정해지지 않아(DESIGN.md "아직 정해지지 않은 것"),
## 지금은 전투 방 하나만 선택 가능한 최소 스켈레톤이다. combat_test.tscn을 그대로
## "전투 방"으로 재사용한다.
##
## RunState.TOTAL_ROOMS개를 클리어하면 런이 끝난다는 최소 구조를 추가함 (버튼 하나로
## 무한 반복 입장만 가능했던 이전 상태와의 차이).
##
## 방 선택지: INBOX.md 피드백("레벨 디자인된 여러 스테이지... 스텝 바이 스텝으로
## 수평적 선택지를 넓힌다")을 반영해 "전투 방" 하나뿐이던 것을 "전투 방" / "상점" /
## "특수 이벤트" 세 선택지로 넓힘. 어느 쪽을 골라도 방 하나를 소비한 것으로 치고
## (rooms_cleared 증가) 다음 방으로 넘어간다 — 상점/이벤트도 "방"이라는 슬롯을 쓰는
## 선택지로 취급.
##
## "특수 이벤트"는 INBOX.md 피드백("특수한 이벤트에서는 주사위를 늘리는 이벤트를
## 제공한다. 다면체 주사위가 나올 수 있다")을 반영한 무료 방으로, scenes/event.tscn에서
## systems/event_item_pool.gd(EventItemPool)의 D8/D10/D12급 아이템 중 하나를 골라
## 즉시 적용한다 (골드 불필요 — 상점과의 차별점).
##
## 방 선택지 무작위 노출: STATUS.md 다음 할 일 큐("3개 방 선택지가 매번 전부 노출되는
## 대신, 방마다 일부만 무작위로 제시되는 것이 레벨 디자인에 더 가까울 수 있음")를 잠정
## 반영. "전투 방"은 진행을 보장하기 위해 항상 노출한다. 특수 이벤트/스토리 이벤트는
## 방(= RunState.rooms_cleared)마다 결정되는 시드로 각각 독립적으로 등장 확률
## (EVENT_CHANCE/STORY_CHANCE)을 굴려 노출 여부를 정한다. "상점"은 2026-09-14
## INBOX.md 지시로 확률 노출에서 고정 노출(SHOP_FIXED_ROOM_INDICES)로 바뀜 — 5방
## 기준 2번째/4번째 방에만 상시 노출. 같은 방에서는 씬을 다시 그려도(_update_labels
## 재호출) 같은 결과가 나오도록 rooms_cleared 기반 시드를 쓰되, 게임 전체의
## randi()/randf()(전투 판정 등)와 섞이지 않도록 별도 RandomNumberGenerator를
## 사용한다. event/story 확률 자체는 감으로 잡은 잠정값 — 사람 피드백 필요.
##
## 선택지 순서 섞기: 위 항목이 "순서가 섞이는 것까지는 다루지 않았는데 이게 필요한지는
## 사람 피드백 필요"로 남겨뒀던 간극을 채운다. 상점/특수 이벤트/스토리 이벤트(노출된
## 것만) 세 종류의 표시 순서를 방마다 같은 결정적 RNG로 섞는다 — "전투 방"은 진행을
## 보장하는 항상-첫-자리 선택지라 순서 섞기 대상에서 제외(항상 맨 위). 노출 여부와
## 같은 방식(idx 기반 시드)으로 계산해 MapStrip 미리보기와 실제 버튼 순서가 항상
## 일치하도록 함.
##
## "스토리 이벤트"는 STATUS.md 다음 할 일 큐("순수 텍스트형/스토리형 선택지 이벤트")를
## 반영한 신규 방 종류. 상점/특수 이벤트가 다이스 아이템(DiceItemPool 형식)을 다루는
## 것과 달리, scenes/story_event.tscn은 다이스를 전혀 건드리지 않고 골드만 오가는
## 텍스트 선택지다 (systems/story_event_pool.gd 참고).
##
## 맵 전체 미리보기(MapStrip): INBOX.md 피드백("맵 전체를 봐야할 것 같음")을 반영.
## 방마다 어떤 선택지가 뜰지는 rooms_cleared(방 번호)로 시드가 고정된 결정적 RNG라서
## 아직 도달하지 않은 미래 방도 같은 공식으로 미리 계산할 수 있다 — 그래서 새 상태를
## 따로 들고 다닐 필요 없이(RunState 변경 없음), 이 화면에서 idx=0..TOTAL_ROOMS-1을
## 전부 그 공식으로 계산해 한 줄로 보여주기만 하면 "전체 맵 보기"가 된다.
## 다만 "첫 번째 선택지에 따라 다음 선택지가 어떻게 바뀌는지"(슬더스 스타일 분기 —
## 고른 경로에 따라 이후 노드 구성 자체가 달라지는 것)까지는 아니다: 지금은 방마다
## 노출 여부만 결정적일 뿐 서로 독립적이라, "무엇을 골랐는지"가 "다음 방에 뭐가
## 뜨는지"에 영향을 주지 않는다. 진짜 분기형 맵(노드 그래프 + 경로 선택)은 DESIGN.md가
## 이미 확정한 "일단은 선형으로" 방향을 벗어나는 더 큰 구조 변경이라 별도 설계 확인 후
## 착수하는 게 안전하다고 판단해 이번엔 다루지 않음 (docs/STATUS.md 다음 할 일 큐 참고).

const EVENT_CHANCE := 0.5
const STORY_CHANCE := 0.5
## INBOX.md [대형 기획 6] G-7(2026-10-07): "정예 전투"는 방 1~3(0부터 셀 때 idx 1..
## TOTAL_ROOMS-2, 즉 1번째/마지막(보스) 방은 제외)에서만, 일반 전투 "옆에 추가
## 선택지로" 확률 노출된다(INBOX.md 원문 "방 1~3에서 확률 35%"). shop처럼 고정 방이
## 아니라 event/story와 같은 "확률 노출" 계열이라 이 상수도 그 둘과 나란히 둔다.
const ELITE_CHANCE := 0.35
## INBOX.md 2026-09-14: "상점은 현재 5개의 방 기준, 2번째 4번째 방에만 추가한다."
## 예전에는 SHOP_CHANCE(0.6)로 방마다 확률 노출이었으나, 사용자가 고정 위치를
## 명시적으로 지시해 상점만 확률 노출에서 고정 노출로 바뀜(event/story는 그대로 확률
## 유지). idx는 0부터 시작하므로 "2번째/4번째 방"은 idx 1/3 — 지금의 TOTAL_ROOMS=5
## 기준으로 잡은 값이라 방 개수가 바뀌면 이 목록도 사람이 다시 정해야 함.
const SHOP_FIXED_ROOM_INDICES: Array[int] = [1, 3]
## [대형 기획 13] M-1: BUTTON_TOP_START는 더 이상 고정값이 아니라 MapStrip의 실제
## 높이(동적 계산, _build_map_strip 참고)에 따라 _layout_visible_buttons()가 매번
## 계산한다 — 이 상수는 MapStrip과 버튼 구역 사이의 여백(gap)만 의미한다.
const BUTTON_TOP_GAP := 20.0
## [대형 기획 15] Q-4a(12, 2026-10-17): 방 선택지(전투/상점/이벤트/스토리/정예)는 전부
## 같은 크기·같은 위계로 쌓는다 — M-1이 "전투만 크게"로 구분했던 것을 INBOX 피드백
## ("전투 방 선택지만 크고 그게 메인 선택지처럼 보인다")에 따라 되돌림. 커스터마이징은
## Q-5(15, 2026-10-17)로 이 스택에서 완전히 빠져 헤더의 고정 버튼("정비")이 됐다(아래
## _layout_visible_buttons() 참고).
const SECONDARY_BUTTON_SPACING := UIKit.SECONDARY_BUTTON_HEIGHT + 10.0
const SHOP_GOLD_LABEL_GAP := 22.0
## MapStrip 방 카드 높이를 내용(행 개수)에 맞춰 계산하는 데 쓰는 치수 — 고정 130px
## 대신 실제 보여줄 줄 수(제목 1 + 전투 1 + 노출된 선택지 수)로 계산한다(INBOX M-1
## "카드 높이를 내용에 맞춰 조절").
const MAP_CARD_TITLE_H := 22.0
const MAP_CARD_ROW_H := 22.0
const MAP_CARD_PAD := 20.0

## [미니 기획 M-7] 방 카드 accent 틴트 3색 — 기존 StyleBoxFlat 폴백이 쓰던
## border_color와 동일한 값(현재=금색/완료=초록/미래=중립 회색)을 그대로 재사용해,
## 스킨이 있을 때와 없을 때 색 의미가 일치하게 한다.
const MAP_CARD_TINT_CURRENT := Color(0.9, 0.75, 0.2)
const MAP_CARD_TINT_CLEARED := Color(0.3, 0.45, 0.3)
const MAP_CARD_TINT_FUTURE := Color(0.3, 0.3, 0.35)

## 업적 "눈금 수집가"/"다이스 수집가" 임계치 — 감으로 잡은 잠정값(achievement_manager.gd
## DEFINITIONS의 pip_hoarder/die_hoarder 문구와 맞춰뒀다).
const PIP_HOARDER_THRESHOLD := 10
const DIE_HOARDER_THRESHOLD := 5

## 업적 "단골 손님"(shop_regular) 임계치 — 감으로 잡은 잠정값.
const SHOP_REGULAR_THRESHOLD := 3

## 업적 "재질 수집가"(material_collector)가 재질을 판정하는 기준. combat_test.gd의
## _material_for_sides()와 같은 면 개수 -> 재질 매핑을 그대로 따른다(다이스 면
## 개수만으로 재질이 잠정 배정되는 현재 규칙, DESIGN.md "다이스 연출" 참고). 두 스크립트가
## class_name 없이 각자 씬에 귀속돼 있어 정적 참조 대신 매핑을 각자 갖는다 — 매핑 자체가
## 5줄짜리 단순 규칙이라 중복 비용보다 씬 간 결합을 피하는 이득이 크다고 판단.
const MATERIAL_SIDES := {
	"plastic": [4, 6],
	"wood": [8],
	"glass": [10],
	"metal": [12, 20],
}

## 방 종류별로 "무엇을 줄 수 있는지" 카테고리(RewardIcon.category 값). 실제 골드/눈금
## 수치나 상점 판매 품목은 매번 달라 정확한 값을 미리 보여주기 어려우므로, "카테고리"만
## 고정 목록으로 둔다 (STATUS.md 큐 0-A 판단 참고).
## - 전투: 승리 시 골드 + 눈금(확정 1개) + 다이스 아이템(2개 중 선택) 전부 보장.
## - 상점: 골드로 다이스 아이템을 구매.
## - 특수 이벤트: 무료로 다이스 아이템 또는 눈금 뭉치 중 하나 — 방마다 둘 중 뭐가
##   나올지 갈리므로, "dice"/"pip" 그대로 보여주면 결과를 미리 스포일링하게 된다.
##   INBOX.md 2026-09-14 "물음표 아이콘만 있으면 될 것 같다"를 반영해 "mystery"
##   하나로 통일(2026-09-15).
## - 스토리 이벤트: 선택에 따라 골드가 오르내림(다이스 무관).
const REWARD_CATEGORIES := {
	"combat": ["gold", "dice", "pip"],
	"shop": ["dice"],
	"event": ["mystery"],
	"story": ["gold"],
	# "정예": 일반 전투와 같은 카테고리(골드+다이스)를 주지만 수치만 더 큼(combat_test.gd
	#의 monster_is_elite 분기 — 골드 x2, 다이스 보상은 EliteRewardPool로 A급 이상 중심).
	# "카테고리" 수준에선 눈금(pip) 보상은 안 주므로 combat과 완전히 같지는 않다.
	"elite": ["gold", "dice"],
}

## shop.gd의 ITEM_COSTS 중 가장 싼 값(boost_weak_face=10). 두 스크립트가 class_name 없이
## 각자 씬에 귀속돼 있어(다른 잠정 매핑들과 같은 이유) 정적 참조 대신 값만 복제해 둔다 —
## shop.gd의 가격표가 바뀌면 이 상수도 같이 맞춰야 함.
const MIN_SHOP_ITEM_COST := 10

@onready var rooms_cleared_label: Label = $RoomsClearedLabel
@onready var gold_label: Label = $GoldLabel
@onready var enter_combat_button: Button = $EnterCombatButton
@onready var enter_shop_button: Button = $EnterShopButton
@onready var enter_event_button: Button = $EnterEventButton
@onready var enter_story_button: Button = $EnterStoryButton
@onready var enter_elite_button: Button = $EnterEliteButton
@onready var map_strip: Control = $MapStrip
@onready var customize_button: Button = $CustomizeButton
@onready var customize_panel: CustomizePanel = $CustomizePanel
@onready var deck_panel: DeckPanel = $DeckPanel
@onready var skill_codex_button: Button = $SkillCodexButton
@onready var skill_codex_panel: SkillCodexPanel = $SkillCodexPanel
@onready var quit_run_button: Button = $QuitRunButton
@onready var quit_confirm_dialog: ConfirmDialog = $QuitConfirmDialog

## [대형 기획 15] Q-4b(21, 2026-10-17) "던전 포기" 확인 문구 — "폐기되는 것"(진행도)과
## "유지되는 것"(업적/도감)을 명시해 INBOX 원문을 그대로 반영한다.
const QUIT_RUN_MESSAGE := "현재 진행도를 버리고 나갑니다. 지금까지 해금한 업적과 스킬 도감은 유지됩니다."

var _shop_available := true
var _event_available := true
var _story_available := true
var _elite_available := false
var _room_order: Array[String] = ["shop", "event", "story", "elite"]
var _map_line: ColorRect
var _map_hbox: HBoxContainer
var _reward_icon_rows: Dictionary = {} # room type -> HBoxContainer, 방 선택 버튼 "안"에 들어가는 보상 카테고리 아이콘 줄(Q-4a(14))
## [대형 기획 15] Q-4a(14, 2026-10-17): 버튼 텍스트("전투"/"상점" 등)를 보여주는 라벨 —
## 기존엔 Button.text를 직접 썼지만, 버튼 안에 아이콘+보상 칩까지 함께 넣으면서 전용
## Label 자식으로 바꿨다(room type -> Label).
var _button_name_labels: Dictionary = {}
var _shop_gold_label: Label # "상점 입장" 버튼 바로 아래에 보유 골드를 보여주는 라벨
## G-9(2026-10-07, INBOX.md [대형 기획 6]): "combat"/"elite" -> FamilyIcon, 버튼 내부 콘텐츠
## (_setup_button_content()) 맨 앞에 끼워 넣어 "다음 방에서 어떤 계열의 몬스터를 만날지"를
## 보여준다. 상점/이벤트와 달리 전투는 스포일링 문제가 없어 노출(INBOX.md 원문).
var _family_icon_by_type: Dictionary = {}

## 지금 화면에 보이는 방 선택 버튼들(+커스터마이징) — _layout_visible_buttons()가 매번
## 다시 채운다. FocusNav로 방향키(위/아래) 이동 체인을 만드는 데 쓴다(INBOX.md
## 2026-10-13 [대형 기획 11] K-1 — 기존 숫자 단축키를 대체).
var _shortcut_buttons: Array[Button] = []

## [대형 기획 13] M-1: 상단 HUD 바(라운드/진행도/골드)와 범례 띠 — 둘 다 코드로 생성해
## self에 바로 붙인다(기존 _setup_reward_legend()와 같은 패턴). _hud_round_value_label/
## _hud_gold_value_label은 _update_labels()가 매번 값을 갱신한다.
var _hud_round_value_label: Label
var _hud_dots_holder: VBoxContainer
var _hud_progress_dots: Control
var _hud_gold_value_label: Label
## 방마다 내용(행 수)이 달라도 한 줄(MapStrip)에서는 전부 같은 높이로 맞춰야 정렬이
## 흐트러지지 않는다 — _build_map_strip()이 런 전체에서 가장 긴 카드 기준으로 계산해
## 여기 저장하고, _layout_visible_buttons()가 그 아래 버튼 시작 y를 정하는 데 쓴다.
var _map_card_height := 130.0
## _hud_bar_panel/_legend_bar_panel: _setup_hud_bar()/_setup_reward_legend()가 반환하는
## HBoxContainer의 부모(PanelContainer) — QA 전용 _debug_set_character()가 캐릭터를
## 바꿀 때 다시 그릴 수 있도록 보관한다(일반 플레이에서는 캐릭터가 화면 생존 중 바뀌지
## 않아 _ready() 이후 다시 쓸 일이 없음).
var _hud_bar_panel: PanelContainer
var _legend_bar_panel: PanelContainer


func _ready() -> void:
	# L-3(2026-10-14, [대형 기획 12] K-3 후속): 배경/제목을 현재 캐릭터 퍼스널 컬러로.
	# M-5(b): resources/backgrounds/dungeon_map.png가 있으면 그 사진을 깐다(없으면 폴백).
	CharacterTheme.apply_background(self, RunState.character_id, false, 0.25, "dungeon_map")
	var title := get_node_or_null("Title")
	if title is Label:
		CharacterTheme.apply_label(title, RunState.character_id)
		# [대형 기획 13] M-1: "(테스트 허브)" 개발용 문구 제거. 테스트 전투 중일 때만
		# (RunState.test_battle) 맥락을 살려 "(테스트 전투)" 표기를 붙인다(INBOX M-1
		# 원문 "개발용 문구는 RunState.test_battle일 때만 '테스트 전투' 표기로 보여도 됨").
		(title as Label).text = "던전 맵 (테스트 전투)" if RunState.test_battle else "던전 맵"
	enter_combat_button.pressed.connect(_on_combat_button_pressed)
	enter_shop_button.pressed.connect(_on_shop_button_pressed)
	enter_event_button.pressed.connect(_on_event_button_pressed)
	enter_story_button.pressed.connect(_on_story_button_pressed)
	enter_elite_button.pressed.connect(_on_elite_button_pressed)
	_style_action_buttons()
	customize_button.pressed.connect(customize_panel.open)
	skill_codex_button.pressed.connect(_on_skill_codex_pressed)
	quit_run_button.pressed.connect(_on_quit_run_button_pressed)
	quit_confirm_dialog.confirmed.connect(_on_quit_run_confirmed)
	_setup_hud_bar()
	_setup_reward_legend()
	_setup_status_caption()
	_setup_map_strip()
	_setup_button_content()
	_setup_shop_gold_label()
	_roll_room_choices()
	_update_labels()


## [대형 기획 13] M-1: RoomsClearedLabel/GoldLabel(기존 평문, HUD 바로 대체됨)은 노드
## 자체(@onready 바인딩, 기존 텍스트 갱신 로직)는 그대로 두되 역할을 바꾼다 — GoldLabel은
## 완전히 숨기고(HUD 골드 칩이 대신함), RoomsClearedLabel은 "게임 클리어!" 등 여러 분기의
## 상세 문구(칩 하나로 압축하기 어려움)를 보여주는 작은 캡션으로 격하해 HUD/범례 바로
## 아래에 둔다.
func _setup_status_caption() -> void:
	gold_label.visible = false
	rooms_cleared_label.label_settings = null
	rooms_cleared_label.offset_left = 40.0
	rooms_cleared_label.offset_top = 170.0
	rooms_cleared_label.offset_right = 940.0
	rooms_cleared_label.offset_bottom = 192.0
	rooms_cleared_label.add_theme_font_size_override("font_size", 13)
	rooms_cleared_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.68))


## QA 전용(GAME_QA_CALL) — L-3 배경/패널 퍼스널 컬러를 눈으로 확인하기 위한 0-arity
## 래퍼. 밝은 색(해적)/어두운 색(주술사)을 각각 스크린샷으로 비교할 때 쓴다.
func _debug_qa_character_pirate() -> void:
	_debug_set_character("pirate")


func _debug_qa_character_shieldbearer() -> void:
	_debug_set_character("shieldbearer")


## QA 전용(GAME_QA_CALL) — [대형 기획 14] N-5(c) DeckPanel의 "이벤트 주사위 D12" 표시를
## 눈으로 확인하기 위한 0-arity 래퍼. `_debug_set_character()`는 배경/제목/버튼 틴트만
## 바꿀 뿐 RunState.event_die_sides는 안 건드리므로, 먼저 `reset_run()`으로 곡예사 값
## (12)까지 실제로 반영한다.
func _debug_qa_character_juggler() -> void:
	RunState.reset_run("juggler")
	_debug_set_character("juggler")


## [대형 기획 13] M-1: 위 두 훅의 공용 구현 — 배경/제목뿐 아니라 HUD 바/범례 띠/행동
## 버튼까지 캐릭터가 바뀌면 전부 다시 그린다(M-1부터 이 요소들이 생겨 기존 두 훅만으론
## 부족해짐). HUD 바/범례 띠는 캐릭터가 화면 생존 중 바뀌는 일이 정상 플레이에는 없어
## "다시 만들기"(기존 패널 제거 후 재생성)로 충분하다.
func _debug_set_character(character_id: String) -> void:
	RunState.character_id = character_id
	CharacterTheme.apply_background(self, RunState.character_id, false, 0.25, "dungeon_map")
	var title := get_node_or_null("Title")
	if title is Label:
		CharacterTheme.apply_label(title, RunState.character_id)
	_style_action_buttons()
	if _hud_bar_panel != null and is_instance_valid(_hud_bar_panel):
		_hud_bar_panel.queue_free()
	if _legend_bar_panel != null and is_instance_valid(_legend_bar_panel):
		_legend_bar_panel.queue_free()
	_setup_hud_bar()
	_setup_reward_legend()
	_update_labels()


## 보상 카테고리 아이콘(RewardIcon)이 무엇을 뜻하는지 설명하는 범례. INBOX.md 피드백
## ("던전 맵에서 각 보상 아이콘이 무엇을 의미하는지 아이콘 텍스트 또는 범례가 필요할 것
## 같다")을 반영 — 골드 라벨 옆 빈 공간에 아이콘+텍스트 3쌍을 고정으로 한 번만 그린다
## (방마다 달라지는 게 아니라 "아이콘 자체의 의미"라 정적으로 충분함).
## [대형 기획 13] M-1: 전엔 아무 틀 없이 배경 위에 떠 있던 텍스트 줄이라 "떠 있는
## 느낌"이었다(INBOX M-1 비평 원문) — 얇은 테두리 띠로 감싸 HUD 바 바로 아래에 붙인다.
func _setup_reward_legend() -> void:
	var legend := UIKit.make_bar(self, RunState.character_id, Vector2(40.0, 134.0))
	legend.add_theme_constant_override("separation", 16)
	_legend_bar_panel = legend.get_parent()
	var specs := [
		["gold", "골드"], ["pip", "눈금"], ["dice", "다이스"], ["mystery", "미정(이벤트)"],
		["elite", "정예(강적, 보상 큼)"],
	]
	for spec in specs:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 5)
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_child(_make_reward_icon(spec[0]))
		var label := Label.new()
		label.text = spec[1]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		pair.add_child(label)
		legend.add_child(pair)


## [대형 기획 13] M-1 → [대형 기획 15] Q-4a(12, 2026-10-17)로 수정: 방 선택지 버튼
## 5개(전투/상점/특수 이벤트/스토리/정예)를 전부 "보조 행동" 스타일 하나로 통일한다 —
## M-1 때는 전투만 꽉 채운 "주 행동" 스타일이었으나, INBOX 피드백("전투 방 선택지만
## 크고 메인 선택지처럼 보인다")에 따라 방 선택지끼리는 위계를 두지 않는다. "정비"
## (커스터마이징, 옛 CustomizeButton)는 Q-5(15)부터 방 선택지가 아니라 헤더의 고정
## 버튼이라 _style_maintenance_button()이 따로 담당한다(아래 참고).
## 버튼 텍스트/가시성은 매 _update_labels()마다 바뀌지만 스타일 자체는 캐릭터가 바뀌지
## 않는 한 고정이라 _ready()에서 한 번만 호출하면 된다(UIKit.style_*가 "focus" 슬롯은
## 건드리지 않아 FocusNav.chain_linear()가 나중에 덮어쓰는 포커스 테두리와 충돌 없음).
func _style_action_buttons() -> void:
	var cid := RunState.character_id
	UIKit.style_secondary_button(enter_combat_button, cid)
	UIKit.style_secondary_button(enter_shop_button, cid)
	UIKit.style_secondary_button(enter_event_button, cid)
	UIKit.style_secondary_button(enter_story_button, cid)
	_style_maintenance_button()
	# "정예 전투"만 INBOX.md [대형 기획 6] G-7 원문대로 위험을 알리는 빨간 테두리를
	# 유지 — UIKit.style_secondary_button의 tint 매개변수로 같은 틀(두께/모서리) 안에서
	# 색만 바꾼다(이전에는 틀 자체가 다른 버튼들과 달라 "같은 버튼 스타일"이 아니었음).
	UIKit.style_secondary_button(enter_elite_button, cid, Color(0.85, 0.2, 0.2))
	# [대형 기획 14] N-3(2026-10-15): "스킬 도감" 버튼이 이 함수에서 빠져 있어 UIKit
	# 스타일을 전혀 안 받고 기본 Godot 테마로만 그려지던 버그(전수 검색으로 발견 —
	# event.gd/shop.gd/story_event.gd는 이미 전부 스타일링하고 있었음).
	UIKit.style_secondary_button(skill_codex_button, cid)
	# [대형 기획 15] Q-4b(21): "던전 포기"도 "정예 전투"와 같은 경고색 tint — 되돌릴 수
	# 없는(진행도 폐기) 동작임을 방 선택지들과 다른 위치(헤더 줄)뿐 아니라 색으로도 구분.
	UIKit.style_secondary_button(quit_run_button, cid, Color(0.85, 0.2, 0.2))


## [대형 기획 15] Q-5(15, 2026-10-17): "정비" 버튼은 보유 눈금이 있을 때만 강조한다
## (INBOX 원문 "보유 눈금이 있을 때만 강조/활성") — 항상 클릭 가능(여분 다이스 열람/
## 교체는 눈금 없이도 쓸 수 있으므로 비활성화는 하지 않음)하되, 강조는 다른 화면들의
## "주 행동" 스타일(꽉 찬 캐릭터색)을 그대로 빌려 눈에 띄게 하고, 없으면 다른 고정
## 버튼(스킬 도감/던전 포기)과 같은 보조 스타일로 가라앉힌다.
func _style_maintenance_button() -> void:
	var cid := RunState.character_id
	if RunState.pip_inventory.is_empty():
		UIKit.style_secondary_button(customize_button, cid)
	else:
		UIKit.style_primary_button(customize_button, cid)


## [대형 기획 13] M-1: 라운드/진행도/골드를 "아이콘 + 큰 숫자 + 짧은 캡션" 칩 3개로
## 묶은 HUD 바 — 기존에 같은 크기(22px) 평문이던 RoomsClearedLabel/GoldLabel의 위계
## 없음 문제를 해결한다(INBOX M-1 원문 "진행도/골드를... 아이콘+큰 숫자+짧은 라벨").
## 자세한 상태 문구(게임 클리어! 등 — 여러 분기가 있어 칩 하나로 압축하기 어려움)는
## RoomsClearedLabel을 작은 캡션으로 격하해 그대로 보여준다(_update_labels() 참고).
func _setup_hud_bar() -> void:
	var cid := RunState.character_id
	var bar := UIKit.make_bar(self, cid, Vector2(40.0, 72.0))
	bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	_hud_bar_panel = bar.get_parent()

	var round_chip := UIKit.make_stat_chip(bar, null, "1/%d" % RunState.TOTAL_ROUNDS, "라운드", cid)
	_hud_round_value_label = round_chip["value_label"]

	_hud_dots_holder = VBoxContainer.new()
	_hud_dots_holder.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(_hud_dots_holder)
	_hud_progress_dots = UIKit.make_progress_dots(_hud_dots_holder, RunState.TOTAL_ROOMS, 0, 0, cid)
	var dots_caption := Label.new()
	dots_caption.text = "진행도"
	dots_caption.add_theme_font_size_override("font_size", 11)
	dots_caption.add_theme_color_override("font_color", Color(0.65, 0.65, 0.68))
	dots_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_dots_holder.add_child(dots_caption)

	var gold_icon := RewardIcon.new()
	gold_icon.custom_minimum_size = Vector2(20, 20)
	gold_icon.category = "gold"
	var gold_chip := UIKit.make_stat_chip(bar, gold_icon, str(RunState.gold), "골드", cid)
	_hud_gold_value_label = gold_chip["value_label"]


## HUD 진행도 점은 UIKit.make_progress_dots()가 매번 새 노드를 만드는 구조라(map_strip
## 카드처럼), _update_labels()가 호출될 때마다 이전 점 줄을 지우고 다시 그린다.
func _refresh_hud_progress_dots() -> void:
	if _hud_progress_dots != null and is_instance_valid(_hud_progress_dots):
		_hud_progress_dots.queue_free()
	var filled: int = clampi(RunState.rooms_cleared, 0, RunState.TOTAL_ROOMS)
	var current: int = -1 if RunState.is_run_complete() else RunState.rooms_cleared
	_hud_progress_dots = UIKit.make_progress_dots(_hud_dots_holder, RunState.TOTAL_ROOMS, filled, current, RunState.character_id)
	_hud_dots_holder.move_child(_hud_progress_dots, 0)


func _setup_shop_gold_label() -> void:
	_shop_gold_label = Label.new()
	_shop_gold_label.add_theme_font_size_override("font_size", 13)
	_shop_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_gold_label.visible = false
	add_child(_shop_gold_label)


## room type 문자열 -> 그 종류의 행동 버튼 노드. _setup_button_content()/dice_test.gd
## 양쪽이 같은 매핑을 쓴다(이 함수가 유일한 소스).
func _button_for_type(t: String) -> Button:
	match t:
		"combat":
			return enter_combat_button
		"shop":
			return enter_shop_button
		"event":
			return enter_event_button
		"story":
			return enter_story_button
		"elite":
			return enter_elite_button
	return null


## [대형 기획 15] Q-4a(14, 2026-10-17): 보상 카테고리 아이콘(+전투/정예의 계열 아이콘)을
## 버튼 옆에 따로 띄우는 대신 버튼 자식으로 넣어 "[종류 아이콘 + 이름 + 보상 칩들]" 한
## 덩어리 버튼으로 만든다(INBOX 원문) — 방향키 포커스도 자연히 버튼 단위로 유지된다
## (오버레이 노드가 아니라 버튼의 자손이라 FocusNav 체인과 무관). 이름 텍스트는
## Button.text 대신 전용 Label(_button_name_labels)에 넣는다 — 네이티브 텍스트와 커스텀
## 아이콘 레이아웃이 겹치지 않게 하기 위함.
func _setup_button_content() -> void:
	for t in REWARD_CATEGORIES.keys():
		var btn := _button_for_type(t)
		if btn == null:
			continue
		# .tscn에 박혀 있던 기본 텍스트("전투 방 입장 (1번째 방)" 등)를 지운다 — 이제
		# 이름은 name_label이 보여주고, 네이티브 Button.text와 겹치면 두 겹으로 보인다.
		btn.text = ""
		var content := HBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 8)
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 16.0
		content.offset_right = -16.0
		content.alignment = BoxContainer.ALIGNMENT_BEGIN
		# G-9: "전투"/"정예 전투"만 계열 아이콘을 보여준다(어떤 몬스터를 상대하는지는
		# 전투 쪽에만 해당, 상점/이벤트는 몬스터가 없어 대상 없음).
		if t == "combat" or t == "elite":
			var family_icon := FamilyIcon.new()
			family_icon.custom_minimum_size = Vector2(20, 20)
			content.add_child(family_icon)
			_family_icon_by_type[t] = family_icon
		var name_label := Label.new()
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
		content.add_child(name_label)
		_button_name_labels[t] = name_label
		var reward_row := HBoxContainer.new()
		reward_row.add_theme_constant_override("separation", 4)
		for cat in REWARD_CATEGORIES[t]:
			reward_row.add_child(_make_reward_icon(cat))
		content.add_child(reward_row)
		btn.add_child(content)
		_reward_icon_rows[t] = reward_row


func _make_reward_icon(category: String) -> RewardIcon:
	var icon := RewardIcon.new()
	icon.custom_minimum_size = Vector2(18, 18)
	icon.category = category
	return icon


## 현재 방(rooms_cleared) 기준으로 상점/특수 이벤트/스토리 이벤트 노출 여부를 결정한다.
## 전투 판정에 쓰이는 전역 randi()/randf()와 섞이지 않도록 별도 RNG를 씀.
func _roll_room_choices() -> void:
	var opts := _room_options_for_index(RunState.rooms_cleared)
	_shop_available = opts.shop
	_event_available = opts.event
	_story_available = opts.story
	_elite_available = opts.elite
	_room_order = opts.order


## idx번째 방(0부터 시작)에서 상점/특수 이벤트/스토리 이벤트가 노출될지, 그리고
## (노출된 것들끼리) 어떤 순서로 보여줄지를 결정적으로 계산한다. rooms_cleared 대신
## 임의의 idx를 받을 수 있어 아직 도달하지 않은 미래 방의 미리보기(MapStrip)에도
## 그대로 쓸 수 있다 — 실제로 그 방에 도달했을 때 _roll_room_choices()가 계산하는
## 값과 완전히 동일한 공식이라 미리보기와 실제 결과가 어긋나지 않는다.
##
## 버그 수정(2026-09-14, INBOX.md "방 다섯개 클리어 하고 새 런으로 돌게 되는데
## 라운드가 진행되어야 한다"): 라운드의 마지막 방(idx == TOTAL_ROOMS - 1)의 몬스터는
## combat_test.gd의 _monster_config_for_room()이 "보스"로 취급해 강화하고,
## 보스를 물리쳐야만(_apply_room_advance()) RunState.advance_round()가 불려 라운드가
## 넘어간다. 그런데 이 마지막 방에도 상점/특수 이벤트/스토리 이벤트가 노출될 수
## 있었고, shop.gd/event.gd/story_event.gd는 전투와 무관하게 각자
## RunState.rooms_cleared += 1만 하고 advance_round()를 전혀 모른다 — 그래서
## 플레이어가 마지막 방에서 전투 대신 상점/이벤트/스토리를 고르면 보스를 만나지도
## 않은 채 rooms_cleared가 TOTAL_ROOMS에 도달해버려(라운드는 그대로 1에 머문 채)
## "런 클리어" 상태가 되고, dungeon_map의 "새 런 시작" 버튼이 RunState.reset_run()을
## 불러 라운드 진행 없이 처음부터 다시 시작하는 것처럼 보였다. 라운드의 마지막 방은
## (보스를 반드시 거쳐야 라운드가 넘어가므로) 전투만 가능하도록 강제해 이 경로 자체를
## 막는다.
func _room_options_for_index(idx: int) -> Dictionary:
	if idx == RunState.TOTAL_ROOMS - 1:
		var empty_order: Array[String] = []
		return {"shop": false, "event": false, "story": false, "elite": false, "order": empty_order}
	var rng := RandomNumberGenerator.new()
	rng.seed = idx * 104729 + 7
	var opts := {
		"shop": SHOP_FIXED_ROOM_INDICES.has(idx),
		"event": rng.randf() < EVENT_CHANCE,
		"story": rng.randf() < STORY_CHANCE,
		# G-7(2026-10-07): "정예 전투"는 1번째 방(idx 0)과 보스 방(위 early-return)을 뺀
		# 나머지(idx 1 .. TOTAL_ROOMS-2, 5방 기준 1~3)에서만 확률 노출. rng.randf()를
		# shop/event/story와 같은 순서로 "항상" 호출해야(조건 바깥에서 먼저 굴리지 않고
		# and로 단락 평가) idx가 구조적으로 제외되는 구간에서도 이후 story/order 셔플에
		# 쓰는 rng 시퀀스가 어긋나지 않는다 — and는 왼쪽이 false면 오른쪽을 평가하지
		# 않으므로, 제외 구간에서는 의도적으로 randf()를 호출하지 않는다(그 구간은 결과가
		# 항상 false이므로 호출 여부가 결과엔 영향 없고, 셔플 시퀀스가 달라져도 결정성
		# 자체는 깨지지 않음 — "같은 idx는 항상 같은 결과"만 지키면 충분하기 때문).
		"elite": idx >= 1 and idx <= RunState.TOTAL_ROOMS - 2 and rng.randf() < ELITE_CHANCE,
	}
	var order: Array[String] = ["shop", "event", "story", "elite"]
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	opts["order"] = order
	return opts


## 순수 판정 함수 3종 — dice_test.gd가 script.new() 패턴(_bag_has_d20과 동일)으로
## 직접 호출해 검증한다.
func _is_pip_hoarder(pip_count: int) -> bool:
	return pip_count >= PIP_HOARDER_THRESHOLD


func _is_die_hoarder(die_count: int) -> bool:
	return die_count >= DIE_HOARDER_THRESHOLD


func _is_bag_maxed(bag: DiceBag) -> bool:
	return bag != null and bag.is_full()


func _is_shop_regular(visits: int) -> bool:
	return visits >= SHOP_REGULAR_THRESHOLD


## 공격/방어 두 주머니를 합쳐 MATERIAL_SIDES의 4개 재질을 전부 동시에 보유했는지 확인한다.
func _is_material_collector(attack_bag: DiceBag, defense_bag: DiceBag) -> bool:
	var found: Dictionary = {}
	for bag in [attack_bag, defense_bag]:
		if bag == null:
			continue
		for faces in bag.dice:
			for material in MATERIAL_SIDES:
				if faces.size() in MATERIAL_SIDES[material]:
					found[material] = true
	return found.size() >= MATERIAL_SIDES.size()


## G-9(2026-10-07): "전투" 선택지가 실제로 들어갈 몬스터의 카탈로그 프로필을 조회한다 —
## combat_test.gd의 `_monster_config_for_plan()`과 같은 소스(RunState.monster_plan,
## round_index 기준)를 읽어 미리보기가 실제 결과와 어긋나지 않게 한다. idx는 "이번 라운드
## 안에서의" 방 번호(RunState.rooms_cleared와 동일 기준) — MapStrip은 항상 현재 라운드
## 하나만 보여주므로 round_index는 항상 현재 값을 쓴다.
func _monster_profile_for_room(idx: int) -> Dictionary:
	var plan: Array = RunState.monster_plan
	if plan.is_empty():
		return MonsterCatalog.legacy_cycle_monster(idx)
	var r: int = clampi(RunState.round_index - 1, 0, plan.size() - 1)
	var round_slots: Array = plan[r]
	var rm: int = clampi(idx, 0, round_slots.size() - 1)
	return MonsterCatalog.get_by_id(round_slots[rm])


## G-9: "정예 전투" 선택지가 그 방에서 노출된다면 들어갈 몬스터 프로필 — 위와 같은
## 방식으로 RunState.elite_plan을 읽는다(combat_test.gd의 `_monster_config_for_elite()`와
## 같은 소스). 그 방이 정예 선택지가 없는 자리(0번째/보스 방)면 빈 Dictionary.
func _elite_profile_for_room(idx: int) -> Dictionary:
	var plan: Array = RunState.elite_plan
	if plan.is_empty():
		return {}
	var r: int = clampi(RunState.round_index - 1, 0, plan.size() - 1)
	var round_slots: Array = plan[r]
	if idx < 0 or idx >= round_slots.size():
		return {}
	var elite_id: String = round_slots[idx]
	return MonsterCatalog.get_by_id(elite_id)


## 버튼 옆 계열 아이콘(_family_icon_by_type)을 "지금 들어갈 방"(RunState.rooms_cleared)
## 기준으로 갱신한다. 런이 끝난 상태("새 런 시작"만 보이는 화면)는 다음 방 자체가 없어
## 갱신하지 않는다(이전 값이 남아있어도 그 행은 숨겨진 버튼 옆이라 안 보임).
func _update_family_icons() -> void:
	if RunState.is_run_complete():
		return
	if _family_icon_by_type.has("combat"):
		var profile := _monster_profile_for_room(RunState.rooms_cleared)
		var icon: FamilyIcon = _family_icon_by_type["combat"]
		icon.category = profile.get("family", "")
		icon.is_boss = profile.get("tier", "normal") == "boss"
		icon.is_elite = false
	if _family_icon_by_type.has("elite"):
		var eprofile := _elite_profile_for_room(RunState.rooms_cleared)
		var eicon: FamilyIcon = _family_icon_by_type["elite"]
		eicon.category = eprofile.get("family", "")
		eicon.is_boss = false
		eicon.is_elite = true


func _update_labels() -> void:
	gold_label.text = "보유 골드: %d" % RunState.gold
	# 상점 버튼 하단 골드 표시 — 가장 싼 품목(MIN_SHOP_ITEM_COST)조차 못 사는 상태면
	# "구매 가능한 품목 없음"까지 함께 보여줘 그 선택지가 지금 의미 없음을 미리 알린다.
	if RunState.gold < MIN_SHOP_ITEM_COST:
		_shop_gold_label.text = "보유 골드: %d (구매 가능한 품목 없음)" % RunState.gold
		_shop_gold_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	else:
		_shop_gold_label.text = "보유 골드: %d" % RunState.gold
		_shop_gold_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	# 업적 "눈금 수집가"/"다이스 수집가"/"가득 찬 주머니" — 어느 화면(상점/특수 이벤트/
	# 전투 승리 보상)에서 쌓였든 던전 맵으로 돌아올 때마다 검사한다(round1_clear와 같은
	# 패턴, unlock()이 멱등이라 매번 다시 그려도 안전).
	if _is_pip_hoarder(RunState.pip_inventory.size()):
		AchievementManager.unlock("pip_hoarder")
	if _is_die_hoarder(RunState.die_inventory.size()):
		AchievementManager.unlock("die_hoarder")
	if _is_bag_maxed(RunState.player_attack_bag) or _is_bag_maxed(RunState.player_defense_bag):
		AchievementManager.unlock("bag_maxed")
	if _is_shop_regular(RunState.shop_visits):
		AchievementManager.unlock("shop_regular")
	if _is_material_collector(RunState.player_attack_bag, RunState.player_defense_bag):
		AchievementManager.unlock("material_collector")
	if RunState.is_run_complete():
		# 라운드별 업적("round1_clear"/"round2_clear"/"game_clear"+캐릭터별 첫 클리어)은
		# 이제 combat_test.gd의 _apply_room_advance()가 보스를 잡는 정확한 시점에 직접
		# unlock한다 — 예전에는 여기서 RunState.is_run_complete() 기준으로 "round1_clear"를
		# 불렀지만, advance_round()가 매 라운드 즉시 rooms_cleared를 0으로 되돌리는 바람에
		# 이 분기 자체가 사실상 "최종 라운드까지 전부 클리어"할 때만 참이 되어, 이름과
		# 달리 라운드 1 클리어 시점에는 한 번도 불리지 않던 버그가 있었다(이번 이터레이션
		# 발견·수정, 아래 combat_test.gd _unlock_round_clear_achievements 참고).
		# [대형 기획 2] 조각 (c): combat_test.gd의 _apply_room_advance()가 보스를 잡을 때마다
		# 마지막 라운드가 아니면 즉시 RunState.advance_round()로 rooms_cleared를 0으로
		# 되돌리므로, 이 분기(is_run_complete()==true)는 실질적으로 "마지막 라운드의 보스까지
		# 잡은 진짜 최종 클리어" 상태에서만 도달한다 — RunState.is_last_round()로 다시 한 번
		# 명시적으로 구분해 "게임 클리어!"(3라운드 완주) 전용 문구를 보여준다(도달 조건이
		# 우연히 같더라도, 나중에 라운드별 스케일링 등이 바뀌어도 문구 의도가 어긋나지 않게).
		if RunState.is_last_round():
			rooms_cleared_label.text = "게임 클리어! 총 %d라운드 완주 (마지막 라운드 %d / %d 방 격파)" % [
				RunState.TOTAL_ROUNDS, RunState.rooms_cleared, RunState.TOTAL_ROOMS
			]
		else:
			rooms_cleared_label.text = "라운드 %d/%d · 던전 클리어! (%d / %d 방 격파)" % [
				RunState.round_index, RunState.TOTAL_ROUNDS, RunState.rooms_cleared, RunState.TOTAL_ROOMS
			]
		# [대형 기획 15] Q-4a(14, 2026-10-17): 버튼 텍스트는 이제 전용 Label(_button_name_labels)
		# 몫 — "새 런 시작" 상태에서는 그 방 종류의 계열/보상 아이콘이 의미가 없으므로
		# 숨긴다(combat 버튼 자체는 재사용되지만 "방 선택"이 아니라 "런 재시작" 의미로 바뀜).
		_button_name_labels["combat"].text = "새 런 시작"
		_reward_icon_rows["combat"].visible = false
		if _family_icon_by_type.has("combat"):
			(_family_icon_by_type["combat"] as Control).visible = false
		enter_shop_button.hide()
		enter_event_button.hide()
		enter_story_button.hide()
		enter_elite_button.hide()
	else:
		# 라운드 번호를 항상 함께 보여줘 보스를 잡고 새 라운드로 넘어갔을 때(rooms_cleared가
		# 0으로 리셋된 것) 플레이어가 "왜 방 개수가 줄었지"로 헷갈리지 않게 한다.
		rooms_cleared_label.text = "라운드 %d/%d · 클리어한 방: %d / %d" % [
			RunState.round_index, RunState.TOTAL_ROUNDS, RunState.rooms_cleared, RunState.TOTAL_ROOMS
		]
		# [대형 기획 15] Q-4a(14): 방 번호는 모든 선택지가 공통으로 가리키는 "다음 방"
		# 하나뿐이라(상태 캡션에 이미 표시됨) 버튼마다 반복하지 않고 이름만 짧게 보여준다.
		_button_name_labels["combat"].text = "전투"
		_reward_icon_rows["combat"].visible = true
		if _family_icon_by_type.has("combat"):
			(_family_icon_by_type["combat"] as Control).visible = true
		_button_name_labels["shop"].text = "상점"
		_button_name_labels["event"].text = "특수 이벤트"
		_button_name_labels["story"].text = "스토리 이벤트"
		_button_name_labels["elite"].text = "정예 전투"
		enter_shop_button.visible = _shop_available
		enter_event_button.visible = _event_available
		enter_story_button.visible = _story_available
		enter_elite_button.visible = _elite_available
	# [대형 기획 13] M-1: HUD 칩(라운드/진행도/골드)도 매번 함께 갱신한다 — 아래
	# _build_map_strip()이 map_strip.offset_bottom을 다시 계산하므로 버튼 레이아웃보다
	# 먼저 호출해도 안전하다(둘 다 RunState만 읽고 서로 의존하지 않음).
	_hud_round_value_label.text = "%d/%d" % [RunState.round_index, RunState.TOTAL_ROUNDS]
	_hud_gold_value_label.text = str(RunState.gold)
	_refresh_hud_progress_dots()
	_update_family_icons()
	_build_map_strip()
	_layout_visible_buttons()


## MapStrip 안에 배경 연결선(ColorRect) + 노드를 담을 HBoxContainer를 한 번만 세팅한다.
## [대형 기획 13] M-1: HUD 바/범례 띠/상태 캡션이 생긴 만큼 MapStrip 시작 y를 아래로
## 내린다(끝 y는 _build_map_strip()이 카드 높이에 맞춰 매번 다시 계산).
func _setup_map_strip() -> void:
	map_strip.offset_top = 198.0
	_map_line = ColorRect.new()
	_map_line.color = Color(0.35, 0.35, 0.4, 0.6)
	_map_line.anchor_left = 0.0
	_map_line.anchor_right = 1.0
	_map_line.anchor_top = 0.5
	_map_line.anchor_bottom = 0.5
	_map_line.offset_top = -1.5
	_map_line.offset_bottom = 1.5
	_map_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_strip.add_child(_map_line)

	_map_hbox = HBoxContainer.new()
	_map_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_map_hbox.add_theme_constant_override("separation", 16)
	map_strip.add_child(_map_hbox)


## 런 전체(TOTAL_ROOMS개)를 한 줄로 그려서 "지나온 방 / 지금 방 / 앞으로 나올 방의
## 선택지"를 한눈에 보여준다 (INBOX.md "맵 전체를 봐야할 것 같음" 반영).
func _build_map_strip() -> void:
	for c in _map_hbox.get_children():
		c.queue_free()
	# [대형 기획 15] Q-4a(13, 2026-10-17): 방 카드는 이제 "제목" + (해당하면) "정예/보스
	# 배지" 한 줄만 보여준다(아래 선택지 버튼과 중복이던 보상 칩·종류 목록은 전부 제거) —
	# 그래서 카드 높이가 더 이상 그 방에 노출된 선택지 개수에 좌우되지 않고 항상 고정
	# 2행(제목+배지 자리)이면 충분하다. 한 줄(MapStrip)에 나열되므로 전부 같은 높이를
	# 써야 정렬이 흐트러지지 않는다.
	_map_card_height = MAP_CARD_TITLE_H + MAP_CARD_ROW_H * 2 + MAP_CARD_PAD
	map_strip.offset_bottom = map_strip.offset_top + _map_card_height
	for idx in range(RunState.TOTAL_ROOMS):
		_map_hbox.add_child(_make_map_node(idx))


## [미니 기획 M-7](2026-10-16) → [대형 기획 15] Q-4a(13, 2026-10-17)로 단순화 — 던전 맵
## 방 카드(MapStrip) 스킨. 보상/상점/이벤트 카드(`item_card_style.build_card()`)와 달리
## 방 카드는 등급이 없어 기존에 이미 카드 프레임 테두리색으로 쓰던 "방 상태" 3색
## (현재=금색/완료=초록/미래=중립 회색)을 그대로 `UIKit.apply_card_skin()`의 tint로
## 넘긴다. Q-4a(13) 전에는 이 카드가 선택지 종류별 칩(전투/상점/이벤트/스토리/정예)을
## 전부 나열했지만, 그 정보는 아래 선택지 버튼에 이미 있어 중복이라는 피드백에 따라
## "방 번호/상태/정예·보스 배지"만 남기고 제거했다. 파일이 없으면 기존 StyleBoxFlat
## 3색 테두리로 폴백(호출부/기존 로직 불변).
func _make_map_node(idx: int, base_dir: String = UIKit.SKIN_BASE_DIR) -> Control:
	var is_cleared := idx < RunState.rooms_cleared
	var is_current := idx == RunState.rooms_cleared and not RunState.is_run_complete()

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, _map_card_height)
	var card_tint: Color
	if is_current:
		card_tint = MAP_CARD_TINT_CURRENT
	elif is_cleared:
		card_tint = MAP_CARD_TINT_CLEARED
	else:
		card_tint = MAP_CARD_TINT_FUTURE
	var skin_applied := UIKit.apply_card_skin(panel, card_tint, base_dir)
	if not skin_applied:
		var style := StyleBoxFlat.new()
		if is_current:
			style.bg_color = Color(0.25, 0.22, 0.12, 0.95)
			style.border_color = card_tint
			style.set_border_width_all(3)
		elif is_cleared:
			style.bg_color = Color(0.12, 0.16, 0.12, 0.85)
			style.border_color = card_tint
			style.set_border_width_all(1)
		else:
			style.bg_color = Color(0.12, 0.12, 0.15, 0.85)
			style.border_color = card_tint
			style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color(1, 1, 1, 0.55 if is_cleared else 1.0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = ("%d번째 방 (완료)" % (idx + 1)) if is_cleared else ("%d번째 방" % (idx + 1))
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4) if is_current else Color(0.8, 0.8, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	# [대형 기획 15] Q-4a(13, 2026-10-17): 방 번호/상태(위 title/테두리색)에 더해 "정예/보스"
	# 배지만 남긴다 — 보스 방(라운드 마지막 방)이 최우선, 아니면 그 방에 정예 전투가
	# 노출될 때만 배지를 붙인다(둘 다 아니면 배지 없이 제목만, 카드 높이는 고정이라 빈
	# 줄로 남아도 정렬은 안 흐트러짐).
	var is_boss_room := idx == RunState.TOTAL_ROOMS - 1
	if is_boss_room:
		vbox.add_child(_make_room_tier_badge(true, base_dir))
	else:
		var opts := _room_options_for_index(idx)
		if opts.elite:
			vbox.add_child(_make_room_tier_badge(false, base_dir))

	return panel


## [대형 기획 15] Q-4a(13, 2026-10-17) — 방 카드의 "정예/보스" 배지. 몬스터 티어 배지
## 이미지(`UIKit.tier_badge_texture`, combat_test.gd가 쓰는 것과 같은 badge/tier_*.png)가
## 있으면 아이콘+텍스트, 없으면 색 텍스트만(기존 폴백 패턴과 동일).
func _make_room_tier_badge(is_boss: bool, base_dir: String = UIKit.SKIN_BASE_DIR) -> Control:
	var kind := "boss" if is_boss else "elite"
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := UIKit.tier_badge_texture(kind, base_dir)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)
	var label := Label.new()
	label.text = "보스" if is_boss else "정예"
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if is_boss else Color(0.95, 0.4, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	return hbox


## 상점/이벤트가 숨겨져도 버튼 사이에 빈 틈이 남지 않도록, 보이는 버튼만 순서대로
## 다시 세로 배치한다 (전투 방은 항상 첫 자리). [대형 기획 15] Q-5(15, 2026-10-17):
## "정비"(커스터마이징, customize_button)는 더 이상 이 방 선택지 스택에 들어가지
## 않는다 — 헤더의 고정 버튼(.tscn에 위치 명시, _style_maintenance_button() 참고)으로
## 분리됐다. "스킬 도감"/"던전 포기"와 같은 이유(언제든 열 수 있는 별도 기능)로 포커스
## 체인 맨 끝에만 추가한다(아래 참고).
func _layout_visible_buttons() -> void:
	var type_button_map := {
		"shop": enter_shop_button,
		"event": enter_event_button,
		"story": enter_story_button,
		"elite": enter_elite_button,
	}
	var visible_buttons: Array[Button] = [enter_combat_button]
	var visible_types: Array[String] = ["combat"]
	for t in _room_order:
		var btn: Button = type_button_map[t]
		if btn.visible:
			visible_buttons.append(btn)
			visible_types.append(t)

	_shop_gold_label.visible = false

	# [대형 기획 15] Q-4a(12, 2026-10-17): 방 선택지(전투 포함)는 전부 같은 높이·간격으로
	# 쌓는다(기존 M-1의 "전투만 PRIMARY_BUTTON_HEIGHT로 크게" 위계 제거) — 보상 칩은 더
	# 이상 버튼 옆 별도 노드가 아니라 버튼 자식(_setup_button_content())이라 여기서
	# 위치를 따로 계산할 필요가 없다(버튼이 보이면 자동으로 함께 보임).
	var y := map_strip.offset_bottom + BUTTON_TOP_GAP
	for i in visible_buttons.size():
		var btn: Button = visible_buttons[i]
		var t: String = visible_types[i]
		btn.offset_top = y
		btn.offset_bottom = y + UIKit.SECONDARY_BUTTON_HEIGHT
		# "상점" 버튼 아래에 골드 라벨이 들어갈 여유(SHOP_GOLD_LABEL_GAP)만큼 다음 버튼과의
		# 간격을 늘린다 — 다른 버튼들은 기존 spacing 그대로 유지.
		var extra_gap := 0.0
		if t == "shop":
			_shop_gold_label.visible = true
			_shop_gold_label.position = Vector2(btn.offset_left, btn.offset_bottom + 2.0)
			_shop_gold_label.size = Vector2(btn.offset_right - btn.offset_left, 18.0)
			extra_gap = SHOP_GOLD_LABEL_GAP
		y += SECONDARY_BUTTON_SPACING + extra_gap
	# [대형 기획 12] L-2(c): "스킬 도감" 버튼은 방 선택지가 아니라 언제든 열 수 있는
	# 고정 위치 버튼(헤더 줄, .tscn에 명시)이라 위 y-스택 루프에 넣지 않고 체인에만
	# 맨 끝으로 추가한다 — 루프가 이미 끝난 뒤라 position은 그대로 유지되고, 방향키로는
	# 여전히 도달 가능하다. [대형 기획 15] Q-5(15): "정비"도 같은 이유로 같은 자리(헤더)에
	# 고정됐으므로 같은 방식으로 추가한다.
	visible_buttons.append(customize_button)
	visible_buttons.append(skill_codex_button)
	# [대형 기획 15] Q-4b(21): "던전 포기"도 커스터마이징/스킬 도감처럼 방 선택지가 아니라
	# 언제든 누를 수 있는 고정 위치 버튼이라 같은 방식으로 체인 맨 끝에만 추가한다.
	visible_buttons.append(quit_run_button)
	_shortcut_buttons = visible_buttons
	# K-3: 포커스 강조색도 현재 캐릭터 accent로(K-1의 ACCENT_DEFAULT 대신).
	FocusNav.chain_linear(_shortcut_buttons, false, false, false, CharacterTheme.ui_palette(RunState.character_id)["accent"])
	FocusNav.grab_first_focus(_shortcut_buttons)


func _on_combat_button_pressed() -> void:
	if RunState.is_run_complete():
		RunState.reset_run()
		_roll_room_choices()
		_update_labels()
	else:
		get_tree().change_scene_to_file("res://code/scenes/combat_test.tscn")


func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/shop.tscn")


func _on_event_button_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/event.tscn")


func _on_story_button_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/story_event.tscn")


## G-7(2026-10-07): "정예 전투" 버튼 — RunState.pending_elite_fight를 세팅해 combat_test.gd
## _ready()가 일반 던전 순환(RunState.monster_plan) 대신 RunState.elite_plan에서 몬스터를
## 고르게 한다. 씬 전환 자체는 일반 전투와 완전히 같은 combat_test.tscn을 재사용.
func _on_elite_button_pressed() -> void:
	RunState.pending_elite_fight = true
	get_tree().change_scene_to_file("res://code/scenes/combat_test.tscn")


## [대형 기획 12] L-2(c): 던전 진행 중에는 "이번 회차 보유"가 반영돼야 하므로
## RunState.skill_flags를 그대로 넘긴다(캐릭터 선택 화면의 _on_skill_codex_pressed()가
## 항상 빈 배열을 넘기는 것과의 차이 — INBOX.md L-2(c) 원문 "던전 진행 중에는 현재 런
## 기준 '이번 회차 보유'가 반영").
func _on_skill_codex_pressed() -> void:
	if skill_codex_panel.visible:
		skill_codex_panel.close()
	else:
		skill_codex_panel.open(RunState.character_id, RunState.skill_flags)


## [대형 기획 15] Q-4b(21, 2026-10-17): "던전 포기" 버튼 — 즉시 폐기하지 않고 확인
## 팝업(ConfirmDialog)부터 띄운다. 실제 폐기는 _on_quit_run_confirmed()에서만 일어난다.
func _on_quit_run_button_pressed() -> void:
	quit_confirm_dialog.open(QUIT_RUN_MESSAGE, RunState.character_id, "던전 포기", "취소")


## 실제 폐기 로직만 분리 — dice_test.gd가 event.gd._apply_pick()과 같은 이유(이터레이션
## 45 패턴, 아래 참고)로 change_scene_to_file() 없이 이 부분만 직접 호출해 검증할 수
## 있게 한다.
##
## "포기는 패배 통계/업적을 부당하게 올리거나 깎지 않는다"(INBOX 원문): 이 경로는
## combat_test.gd의 _resolve_exchange()/_apply_room_advance()(승/패 시 업적 unlock,
## 골드/눈금 보상, round_index 진행)를 전혀 거치지 않고 RunState.reset_run()만 직접
## 호출하므로, 애초에 "패배"나 "클리어"로 집계될 경로 자체를 타지 않는다 — 명시적으로
## 막은 게 아니라 구조적으로 그 코드 경로에 도달하지 않는 것.
##
## "미저장 업적이 있으면 저장"(INBOX 원문): AchievementManager.unlock()/SkillCodex.
## mark_discovered() 둘 다 호출 즉시 JSON 파일에 동기 저장하는 write-through 방식이라
## (achievement_manager.gd/skill_codex.gd의 _save() 참고)애초에 "아직 디스크에 안 쓰인
## 해금 상태"가 존재할 수 없다 — 그래서 이 함수가 별도로 "저장"을 호출할 필요가 없다.
func _abandon_run() -> void:
	RunState.reset_run()


## 확인 시에만 실행 — _abandon_run()으로 이번 런의 골드/다이스 주머니/스킬/방 진행을
## 전부 버리고(캐릭터는 유지, reset_run() 기본 동작) 캐릭터 선택 화면으로 돌아간다.
## dice_test.gd의 _check_event_double_pick_guard() 주석이 설명하는 것과 같은 이유로
## change_scene_to_file()을 포함하는 이 함수 전체는 QA 테스트 하네스에서 직접 호출하면
## 안 되고(현재 실행 중인 dice_test 씬 자체가 바뀌어버림), 위 _abandon_run()만 따로
## 호출해 부작용 없이 검증한다.
func _on_quit_run_confirmed() -> void:
	_abandon_run()
	get_tree().change_scene_to_file("res://code/scenes/character_select.tscn")


## QA 전용 — [대형 기획 15] Q-4b(11) "보유 스킬 팝업"을 실제 화면에서 캡처하기 위한
## 훅. RunState.skill_flags를 채우고 DeckPanel의 보유 스킬 행을 직접 activated시켜
## SkillDetailPopup을 연다(_debug_open_customize()가 CustomizePanel을 여는 것과 같은
## 패턴 — DeckPanel은 dungeon_map의 자식이라 GAME_QA_CALL이 씬 루트에만 걸 수 있는
## 제약을 이 래퍼로 우회).
func _debug_open_skill_popup() -> void:
	RunState.skill_flags = ["deep_breath"]
	deck_panel._rebuild()
	var card := deck_panel._q4b_debug_first_skill_card()
	if card != null:
		card.activated.emit()


## QA 전용 — 포커스+확정 경로로 "던전 포기" 버튼까지 이어지고, 확인 팝업이 뜨는지
## 확인한다(_debug_press_shortcut_customize와 같은 패턴).
func _debug_press_shortcut_quit_run() -> void:
	var btn := quit_run_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 확인 팝업에서 "던전 포기"(확인) 버튼까지 눌러 실제로 RunState가 리셋되고
## 씬이 전환되는지 확인한다.
func _debug_confirm_quit_run() -> void:
	_on_quit_run_button_pressed()
	quit_confirm_dialog._confirm_button.grab_focus()
	quit_confirm_dialog._confirm_button.pressed.emit()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅. 실제 전투 승리를 끝까지
## 거쳐야만 rooms_cleared가 늘어나는데, MapStrip의 "완료/현재/미래" 표시가 방이 실제로
## 진행됐을 때 제대로 갱신되는지 확인하려고 몇 방을 건너뛰어 본다.
func _debug_advance_rooms(count: int = 2) -> void:
	RunState.rooms_cleared = min(RunState.rooms_cleared + count, RunState.TOTAL_ROOMS)
	_roll_room_choices()
	_update_labels()


## QA 전용 — [대형 기획 2] 조각 (b) 검증용. 실제로 3라운드 중 첫 보스까지 잡아야만
## round_index가 2로 바뀌는데(느림), 여기서는 combat_test.gd의 _apply_room_advance()가
## 이미 다룬 RunState 상태 전이(dice_test.gd 참고)를 그대로 흉내내 "라운드 2로 넘어간
## 직후의 던전 맵"이 화면에서 겹침 없이 표시되는지만 스크린샷으로 확인한다.
func _debug_show_round2() -> void:
	RunState.round_index = 2
	RunState.rooms_cleared = 0
	_roll_room_choices()
	_update_labels()


## QA 전용 — [대형 기획 2] 조각 (c) 검증용. 실제로 3라운드 전부(보스 3번)를 깨야만
## 도달하는 "게임 클리어!" 화면을, round_index/rooms_cleared를 마지막 라운드 완료
## 상태로 직접 맞춰서 겹침 없이 표시되는지만 스크린샷으로 확인한다.
func _debug_show_final_clear() -> void:
	RunState.round_index = RunState.TOTAL_ROUNDS
	RunState.rooms_cleared = RunState.TOTAL_ROOMS
	_roll_room_choices()
	_update_labels()


## QA 전용 — 2026-09-14 버그 수정 검증용. 실제로 4개 방을 다 이겨야만 도달하는
## 라운드 마지막 방(보스 방, rooms_cleared == TOTAL_ROOMS - 1) 상태를 직접 만들어,
## 상점/특수 이벤트/스토리 이벤트 버튼이 전부 숨겨지고 전투 버튼만 보이는지 확인한다.
func _debug_show_boss_room() -> void:
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	_roll_room_choices()
	_update_labels()


## QA 전용 — 2026-09-15 "상점은 2번째/4번째 방에만" 고정 노출 검증용. idx=1(2번째 방)은
## SHOP_FIXED_ROOM_INDICES에 포함돼 상점 버튼이 보여야 하고, idx=2(3번째 방)는 빠져있어
## 상점 버튼이 안 보여야 한다.
func _debug_show_room2() -> void:
	RunState.rooms_cleared = 1
	_roll_room_choices()
	_update_labels()


func _debug_show_room3() -> void:
	RunState.rooms_cleared = 2
	_roll_room_choices()
	_update_labels()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅. CustomizePanel은
## dungeon_map의 자식 노드라 GAME_QA_CALL(현재 씬 루트에서만 호출 가능)이 직접 열 수
## 없으므로, 씬 루트(이 스크립트)에 얇은 래퍼를 둔다.
func _debug_open_customize() -> void:
	customize_panel.open()


## QA 전용 — [대형 기획 15] Q-5(16) 재설계 후: 통합 화면에서 "눈금 선택 + 면 선택"까지
## 끝난 "미리보기" 상태(적용/취소 버튼까지 보이는 상태)를 직접 열어 그 레이아웃을
## 확인하기 위함.
func _debug_open_customize_face() -> void:
	customize_panel.debug_open_face_picker()


## QA 전용 — 인벤토리에 눈금이 여러 개 쌓인 상태에서 1단계(눈금 선택) 화면의
## 실제 레이아웃(칩 버튼이 여러 개 나열된 상태)을 확인하기 위함.
func _debug_open_customize_with_pips() -> void:
	RunState.pip_inventory = [3, 5, 2]
	customize_panel.open()


## QA 전용 — 눈금을 선택해 통합 화면이 "면 선택" 단계(공격/방어 주머니 칩 활성화)로
## 바뀐 레이아웃을 확인하기 위함.
func _debug_open_customize_die() -> void:
	if RunState.pip_inventory.is_empty():
		RunState.pip_inventory = [3, 5, 2]
	customize_panel.open()
	customize_panel._show_die_picker(0)


## QA 전용 — 화면(스크린샷)으로는 확인할 수 없는 "실제 교환 로직"(눈금 소모, 밀려난
## 값이 인벤토리로 돌아오는 것, 상한 클램프)을 콘솔 출력으로 검증하기 위한 일회성 훅.
func _debug_verify_pip_swap() -> void:
	RunState.pip_inventory = [7]
	var bag := RunState.player_attack_bag
	var before: PackedInt32Array = bag.dice[0].duplicate()
	customize_panel._on_face_chosen(bag, 0, 0, 0)
	print("[pip_swap_check] before=%s after=%s pip_inventory=%s (기대: face0=min(7,%d)=%d, inventory=[%d])" % [
		before, bag.dice[0], RunState.pip_inventory, before.size(), min(7, before.size()), before[0],
	])


## QA 전용 — 인벤토리에 다이스가 여러 개 쌓인 상태에서 1단계(다이스 선택) 화면의
## 실제 레이아웃(D6/D8/D10 칩 버튼이 여러 개 나열된 상태)을 확인하기 위함.
func _debug_open_customize_die_inventory() -> void:
	RunState.die_inventory = [6, 8, 10]
	customize_panel.open()
	customize_panel._show_die_inventory_picker()


## QA 전용 — 2단계(교체할 자리 선택) 화면의 레이아웃(승급인 자리/아닌 자리 버튼 구분)을
## 확인하기 위함.
func _debug_open_customize_die_target() -> void:
	customize_panel.debug_open_die_target_picker()


## QA 전용 — 이 세션 환경에서 스크린샷 캡처 폭이 1280px 대신 1028px로 잘리는 현상
## 때문에 화면 오른쪽 끝(x>=980)에 있는 DeckPanel(캐릭터 정보 섹션 포함, 2026-09-15
## 신규)이 매번 잘려서 안 보임 — 확인용으로 패널을 화면 왼쪽으로 옮겨 캡처한다
## (게임 로직에는 영향 없음, 이 훅은 QA에서만 호출).
func _debug_move_deck_panel_left() -> void:
	deck_panel.offset_left = 20.0
	deck_panel.offset_right = 280.0


## QA 전용 — 위와 같은 이유 + 캐릭터 설명 중 가장 긴 축(광전사)으로도 줄바꿈이 패널
## 높이를 넘기지 않는지 확인하기 위함.
func _debug_move_deck_panel_left_berserker() -> void:
	RunState.character_id = "berserker"
	deck_panel.offset_left = 20.0
	deck_panel.offset_right = 280.0


## QA 전용 — 방향키/스페이스 조작(K-1)으로 "상점 입장"(방 2/4일 때 고정 노출) 버튼까지
## 포커스가 실제로 이어지는지 확인하기 위함. grab_focus() + pressed emit으로 "방향키 이동
## 후 스페이스 확정"을 흉내낸다(change_scene_to_file()로 씬을 바꾸는 버튼이라 이 노드가
## 트리에서 빠져나가도 크래시하지 않는지도 함께 확인 — 2026-09-15 (105) 버그의 재발 방지).
func _debug_press_shortcut_2() -> void:
	RunState.rooms_cleared = 1  # 2번째 방으로 이동 — SHOP_FIXED_ROOM_INDICES=[1,3]이라 상점 확정 노출
	_roll_room_choices()
	_update_labels()
	var btn := enter_shop_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — G-7(2026-10-07) "정예 전투" 버튼이 포커스+확정 경로를 거쳐 combat_test
## 씬까지 전환하고, override 없이 RunState.elite_plan에서 몬스터를 고르는지 확인하기
## 위함(_debug_press_shortcut_2와 같은 패턴). 2번째 방(idx=1)은 ELITE_CHANCE 시드가
## 고정적으로 "정예 전투"를 노출시키는 자리라 재현 가능(qa_out/dungeon_g7_room2.png로
## 먼저 확인한 값).
func _debug_press_shortcut_elite() -> void:
	RunState.rooms_cleared = 1
	_roll_room_choices()
	_update_labels()
	var btn := enter_elite_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 포커스+확정 경로(클릭 시뮬레이션(GAME_QA_CLICK_PATH)의 키보드판)로 헤더의
## 고정 버튼 "정비"까지 이어지는지 확인한다(전투/상점/특수 이벤트/스토리 이벤트가 몇 개
## 보이든 무관 — [대형 기획 15] Q-5(15)부터 방 선택지 스택과 완전히 분리된 자리라서)
## — 씬 전환이 없어 스크린샷으로 결과를 바로 확인할 수 있다.
func _debug_press_shortcut_customize() -> void:
	var btn := customize_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — [대형 기획 12] L-2(c). 포커스+확정 경로로 "스킬 도감" 버튼까지 이어지고,
## 실제로 패널이 RunState.skill_flags(이번 회차 보유)를 반영해 열리는지 확인한다
## (_debug_press_shortcut_customize와 같은 패턴).
func _debug_press_shortcut_skill_codex() -> void:
	RunState.skill_flags = ["deep_breath", "start_expand"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — [대형 기획 15] Q-8(c) 1/4(전설 스킬, 2026-10-19): "보유" 상태의 전설
## 스킬 카드가 도감에서 어떻게 보이는지 확인한다(_debug_press_shortcut_skill_codex와
## 같은 패턴, RunState.skill_flags에 전설 id를 넣어 실제 "보유" 상태로 연다).
func _debug_press_shortcut_skill_codex_legendary() -> void:
	RunState.character_id = "novice"
	RunState.skill_flags = ["legend_novice_harmony"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 위와 같은 이유, 광전사 전설 3종(광전 돌격/유혈광란/불굴의 보복, 신규
## legend_nuke/true_strike 모티프)을 한 화면에서 확인하기 위해 3종 전부를 동시에
## "보유" 상태로 넣는다(실제 플레이에서는 한 런에 전설 하나만 가능하지만, 이건 아이콘
## 렌더만 보는 QA 전용 우회).
func _debug_press_shortcut_skill_codex_legendary_berserker() -> void:
	RunState.character_id = "berserker"
	RunState.skill_flags = ["legend_berserker_ragenuke", "legend_berserker_bloodlust", "legend_berserker_vengeance"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — [대형 기획 15] Q-8(c) 2/4(2026-10-19): 위 베르세르커 훅과 같은 이유, 수호자
## 전설 3종(최후의 보루/반격의 벽/불굴의 벽)을 한 화면에서 확인하기 위해 동시에 "보유"
## 상태로 넣는다(실제 플레이에서는 한 런에 전설 하나만 가능하지만 아이콘 렌더 확인용
## QA 우회).
func _debug_press_shortcut_skill_codex_legendary_guardian() -> void:
	RunState.character_id = "guardian"
	RunState.skill_flags = ["legend_guardian_bulwark", "legend_guardian_overguard", "legend_guardian_bastion"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 위와 같은 이유, 폭발병 전설 3종(연쇄 폭발의 고리/절대 폭발/최후의 폭발)을
## 한 화면에서 확인.
func _debug_press_shortcut_skill_codex_legendary_explosive() -> void:
	RunState.character_id = "explosive"
	RunState.skill_flags = ["legend_explosive_chainblast", "legend_explosive_absolute", "legend_explosive_lastblast"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — [대형 기획 15] Q-8(c) 3/4(2026-10-20): 위 수호자/폭발병 훅과 같은 이유,
## 주술사 전설 3종(저주의 흡수/저주의 전이/저주의 종결, 신규 life_siphon/curse_mark
## 모티프 + 재사용 guard_stack 모티프)을 한 화면에서 확인.
func _debug_press_shortcut_skill_codex_legendary_shieldbearer() -> void:
	RunState.character_id = "shieldbearer"
	RunState.skill_flags = ["legend_shieldbearer_lifecurse", "legend_shieldbearer_curseseal", "legend_shieldbearer_curseend"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 위와 같은 이유, 매혹사 전설 3종(매혹의 포로/매혹의 극치/매혹의 응보,
## 재사용 curse_mark/dice_flip/true_strike 모티프)을 한 화면에서 확인.
func _debug_press_shortcut_skill_codex_legendary_enchantress() -> void:
	RunState.character_id = "enchantress"
	RunState.skill_flags = ["legend_enchantress_captive", "legend_enchantress_ascend", "legend_enchantress_retribution"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — [대형 기획 15] Q-8(c) 4/4(2026-10-20, 전체 24종 마지막): 위 수호자/폭발병/
## 주술사/매혹사 훅과 같은 이유, 곡예사 전설 3종(끝없는 저글링/완벽한 묘기/운명의
## 보정, 재사용 dice_swap/dual_boost/reroll 모티프)을 한 화면에서 확인.
func _debug_press_shortcut_skill_codex_legendary_juggler() -> void:
	RunState.character_id = "juggler"
	RunState.skill_flags = ["legend_juggler_evershuffle", "legend_juggler_balance", "legend_juggler_fatecorrect"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 위와 같은 이유, 해적 전설 3종(무한 장전/처형자의 포격/전면 포격, 재사용
## cycle_strike/true_strike 모티프)을 한 화면에서 확인.
func _debug_press_shortcut_skill_codex_legendary_pirate() -> void:
	RunState.character_id = "pirate"
	RunState.skill_flags = ["legend_pirate_overload", "legend_pirate_execute", "legend_pirate_fullbroadside"]
	var btn := skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 인벤토리의 다이스가 두 주머니의 모든 다이스보다 작거나 같아 승급 자리가
## 하나도 없는 상태에서 2단계 화면에 "승급할 곳이 없다" 안내 문구가 정상 표시되는지
## 확인하기 위함(이터레이션 74, 모든 버튼이 비활성화된 채 설명 없이 남던 것을 고침).
func _debug_open_customize_die_target_none() -> void:
	RunState.die_inventory = [4]
	customize_panel.open()
	customize_panel._show_die_target_picker(0)


## QA 전용 — DeckPanel "보유 스킬" 섹션(2026-09-28 신규)이 여러 개(공용/고유/"+" 강화판
## 섞어서 이름 길이도 다양하게) 쌓였을 때 캐릭터/공격/방어 섹션과 겹치지 않는지 확인하기
## 위함. 캡처 폭이 1028px로 잘리는 환경 이슈 때문에 기존 _debug_move_deck_panel_left류와
## 같은 이유로 패널을 왼쪽으로 옮긴다.
func _debug_move_deck_panel_left_with_skills() -> void:
	RunState.skill_flags = ["deep_breath", "spare_die_plus", "frenzy_deepen_plus", "start_expand"]
	deck_panel.offset_left = 20.0
	deck_panel.offset_right = 280.0


## QA 전용 — [대형 기획 15] Q-5(15) "정비" 버튼의 강조(primary) 스타일을 패널을 열지
## 않은 헤더 상태로 직접 확인하기 위함(패널이 열리면 오버레이가 화면 대부분을 가려
## 버튼 자체의 전/후 비교가 어려워짐).
func _debug_show_maintenance_highlighted() -> void:
	RunState.pip_inventory = [4]
	_style_action_buttons()


## QA 전용 — [셀프 피드백 수정] 공격/방어 주머니가 DiceBag.MAX_DICE(6)까지 찬 후반
## 런을 흉내내 "정비" 통합 화면의 미리보기 단계가 720px를 넘고, 포커스가 '닫기' 버튼
## 까지 이동했을 때 수동 스크롤(_ensure_step_button_visible())이 실제로 화면 안으로
## 보여주는지(qa_out/q5_preview.png 캡처로 처음 발견된 버그) 확인하기 위함.
func _debug_open_customize_overflow_close_focus() -> void:
	RunState.player_attack_bag = DiceBag.new(4, DiceBag.MAX_DICE)
	RunState.player_defense_bag = DiceBag.new(4, DiceBag.MAX_DICE)
	RunState.pip_inventory = [4]
	customize_panel.open()
	customize_panel._selected_pip_index = 0
	customize_panel._pending_face = {"bag": RunState.player_attack_bag, "die_index": 0, "face_index": 0}
	customize_panel._show_pip_picker()
	# open()의 첫 _show_pip_picker() 호출(미리보기 없음)이 만든 "닫기" 버튼은
	# _clear_ui()의 queue_free()가 지연 해제라 이 프레임 안에서는 아직 트리에 남아있다
	# — find_children()은 등장 순서대로 찾으므로 뒤에서부터(이번 redraw가 만든 최신
	# 버튼) 찾아야 한다.
	var buttons := customize_panel._content_root.find_children("*", "Button", true, false)
	for i in range(buttons.size() - 1, -1, -1):
		var b := buttons[i] as Button
		if b.text == "닫기":
			b.grab_focus()
			break


## QA 전용 — 화면으로는 확인할 수 없는 "실제 교환 로직"(다이스 소모, 밀려난 다이스가
## 인벤토리로 돌아오는 것)을 콘솔 출력으로 검증하기 위한 일회성 훅.
func _debug_verify_die_swap() -> void:
	RunState.die_inventory = [8]
	var bag := RunState.player_attack_bag
	var before_sides := bag.dice[0].size()
	customize_panel._on_die_target_chosen(bag, 0, 0)
	print("[die_swap_check] before_sides=%d after_sides=%d die_inventory=%s (기대: after_sides=8, inventory=[%d])" % [
		before_sides, bag.dice[0].size(), RunState.die_inventory, before_sides,
	])
