extends Node2D
class_name TestBattleSetup
## 테스트 전투 설정 화면 (INBOX.md [대형 기획 8] H-2, 2026-10-08. H-3(2026-10-08)로
## "성장"/"보유 스킬" 섹션 추가).
##
## H-1(플러밍만)이 만든 RunState.test_battle/test_monster_id/test_difficulty를 실제로
## 채워서 combat_test.tscn으로 보내는 진입 화면 — 캐릭터/시작 스킬/몬스터/난이도를
## 전부 직접 골라 즉시 붙어볼 수 있게 한다. H-1 원칙 그대로: ① 진짜 전투 씬/규칙을
## 쓴다(RunState.reset_run() + _on_start_pressed()가 combat_test.tscn으로 보냄, 별도
## 시뮬 없음). ② 진행도를 건드리지 않는다(여기서는 업적 unlock을 아예 하지 않음 —
## "던전 시작"의 first_run_start 업적도 포함해 전혀 호출하지 않음). ③ 시작 스킬 잠금은
## 무시한다(SkillPool.starting_skills_for_character()가 주는 후보 전부를 해금 여부와
## 무관하게 선택 가능하게 한다 — character_select.gd와 달리 is_slot_requirement_met()을
## 전혀 참조하지 않음).
##
## "직전 선택 유지"(반복 테스트 편의, INBOX.md 원문): 캐릭터/시작 스킬/몬스터/난이도
## 선택은 UI를 바꿀 때마다 즉시 RunState.test_character_id/test_starting_skill_id/
## test_monster_id/test_round_index/test_room_index에 반영한다 — 이 필드들은
## RunState.reset_run()이 건드리지 않는 "테스트 설정 전용" 필드라(run_state.gd 주석
## 참고) 전투 후 "설정으로 돌아가기"로 이 씬이 다시 로드돼도 그대로 남아있다.
##
## test_character_id는 RunState.character_id(실제 플레이 중인 캐릭터)와 별개다 — 여기서
## 캐릭터를 둘러보는 것만으로 실제 진행 캐릭터가 바뀌면 안 되므로, "전투 시작"을 눌렀을
## 때만 RunState.reset_run(선택한 id)로 실제 character_id에 반영된다. 같은 이유로
## RunState.chosen_starting_skill_id(character_select.gd가 쓰는 "다음 실제 런의 시작
## 스킬" 선택)도 전투 시작 순간에만 잠깐 선택한 스킬로 바꿔 reset_run()이 skill_flags에
## 그 스킬을 그대로 부여하게 하고, 즉시 원래 값으로 복원한다(_apply_start_selection()
## 참고) — 테스트 전투를 돌렸다고 해서 실제 캐릭터 선택 화면의 "다음 런 시작 스킬"
## 선택이 조용히 바뀌면 안 되기 때문.

## H-3 "성장" 섹션: 공격/방어 다이스 개수·공통 면 개수·골드·눈금/다이스 인벤토리
## 개수를 직접 조절하거나, 프리셋 버튼 하나로 한 번에 맞출 수 있다. "delta"는
## 선택한 캐릭터의 기본 공격/방어 다이스 개수(CharacterProfiles)에 더하는 값 —
## 캐릭터마다 시작 배분이 달라도("확정된 세부 사항" 참고) 같은 프리셋이 "그 캐릭터
## 기준으로 N개씩 늘어난" 결과를 내도록 절대값이 아니라 상대값으로 잡았다. 정확한
## delta/sides 수치는 감으로 잡은 잠정값(INBOX.md H-3 원문 "구현자가 잠정값으로
## 정한다") — 실제로 라운드 중반 체감과 맞는지는 사람 피드백 필요.
const GROWTH_PRESETS: Array[Dictionary] = [
	{"name": "시작 그대로", "delta": 0, "sides": 4},
	{"name": "R1 중반 정도", "delta": 2, "sides": 6},
	{"name": "R2 중반 정도", "delta": 3, "sides": 8},
	{"name": "R3 중반 정도", "delta": 4, "sides": 10},
]

## "면 개수(공통)" 선택지 — DESIGN.md가 구현한 D4~D20 6종 전부(커스텀 일부 면만
## 바꾸는 세밀 조정은 INBOX.md H-3 원문이 "불필요"라고 명시해 두지 않음).
const GROWTH_SIDES_OPTIONS: Array[int] = [4, 6, 8, 10, 12, 20]

const TIER_LABELS := {"normal": "일반", "elite": "정예", "boss": "보스"}

## 몬스터 스킬 프리미티브 id -> 짧은 한글 설명(DESIGN.md "스킬 프리미티브 범례" 표를
## 그대로 옮긴 것, "%d"는 skill dict의 "amount" 값으로 채운다). 이 화면 전용 — 실제
## 효과 계산은 monster_skills.gd(MonsterSkills)가 하고, 여기서는 "뭘 고르는지 미리
## 알 수 있게" 설명만 보여준다.
const SKILL_PRIMITIVE_DESCRIPTIONS := {
	"armor": "몬스터 방어 합계 +%d",
	"guard_up": "HP 절반 이하면 방어 다이스 결과 +1",
	"counter": "공격이 완전히 막히면 플레이어에게 %d 반사 피해",
	"steady_guard": "방어 다이스 결과가 면 개수 절반 미만이면 그 값으로 보정(하한선)",
	"sticky": "플레이어 공격 다이스 중 최고값 1개 -1(최소 1)",
	"seal": "플레이어 공격 다이스 중 최저값 1개를 0으로",
	"dull": "플레이어 다이스 중 최댓값이 나온 것은 전부 최댓값-1로",
	"numb": "플레이어 방어 다이스 중 최고값 1개 -1",
	"anger_stack": "공격 다이스가 최댓값일 때마다 분노 스택, 임계치에서 1D20",
	"min_max_only": "공격/방어 다이스가 최소·최댓값만 나옴(중간값 없음)",
	"pounce": "전투 첫 공격턴에만 공격 다이스 결과 +%d",
	"bloodlust": "HP 절반 이하부터 공격 다이스 결과 +1",
	"fixed_value": "공격/방어 다이스가 항상 같은 값(안 굴림)",
	"drain": "입힌 피해의 절반(내림)만큼 HP 회복",
	"revive": "전투당 1회, HP 0 이하가 되면 최대 HP 30%로 부활",
	"chill": "플레이어 공격 다이스 중 최고값 1개 -1",
}

## H-3로 섹션이 늘어나 전체 화면이 1280x720보다 길어졌다 — 루트에 바로 붙던 자식
## 노드들을 전부 MainScroll/MainList(ScrollContainer+VBoxContainer) 아래로 옮기고,
## 각 노드에 "unique_name_in_owner"를 켜서 "%이름" 문법으로 찾는다(씬 구조가 더
## 바뀌어도 아래 @onready 줄들을 고칠 필요가 없게). Background/Title/BackButton만
## 스크롤 밖(화면 상단 고정)에 남는다.
@onready var back_button: Button = $BackButton
@onready var character_row: HBoxContainer = %CharacterRow
@onready var skill_row: HBoxContainer = %SkillRow
@onready var skill_desc_label: Label = %SkillDescLabel
@onready var growth_preset_row: HBoxContainer = %GrowthPresetRow
@onready var growth_controls_grid: GridContainer = %GrowthControlsGrid
@onready var growth_preview_label: Label = %GrowthPreviewLabel
@onready var skill_flags_list: VBoxContainer = %SkillFlagsList
@onready var family_filter_row: HBoxContainer = %FamilyFilterRow
@onready var tier_filter_row: HBoxContainer = %TierFilterRow
@onready var monster_list: VBoxContainer = %MonsterList
@onready var monster_detail_label: Label = %MonsterDetailLabel
@onready var difficulty_row: HBoxContainer = %DifficultyRow
@onready var difficulty_value_label: Label = %DifficultyValueLabel
@onready var start_button: Button = %StartButton

## RoundSpin/RoomSpin은 DifficultyRow 안에 코드로 만든다 — 다른 화면들의 관례대로
## Container의 동적 자식은 .tscn에 정적으로 두지 않고 전부 런타임에 구성한다
## (character_select.gd/shop.gd 등 기존 화면 전부 같은 패턴, _build_difficulty_row() 참고).
var round_spin: SpinBox
var room_spin: SpinBox

## 성장 섹션 스핀/옵션 컨트롤 — RoundSpin/RoomSpin과 같은 이유로 전부 코드에서
## 동적으로 만든다(_build_growth_controls() 참고).
var _attack_count_spin: SpinBox
var _defense_count_spin: SpinBox
var _sides_option: OptionButton
var _gold_spin: SpinBox
var _pip_spin: SpinBox
var _die_spin: SpinBox

var _selected_character_id: String = ""
var _selected_skill_id: String = ""
var _selected_monster_id: String = ""
var _family_filter: String = ""
var _tier_filter: String = ""
var _selected_skill_flags: Array[String] = [] # "보유 스킬" 토글 상태

var _character_buttons: Dictionary = {} # id -> Button
var _skill_buttons: Dictionary = {} # id -> Button
var _monster_buttons: Dictionary = {} # id -> Button
var _family_filter_buttons: Dictionary = {} # id -> Button
var _tier_filter_buttons: Dictionary = {} # id -> Button
var _skill_flag_checkboxes: Dictionary = {} # id -> CheckBox


func _ready() -> void:
	_selected_character_id = RunState.test_character_id if RunState.test_character_id != "" else RunState.character_id
	if CharacterProfiles.get_profile(_selected_character_id).is_empty():
		_selected_character_id = CharacterProfiles.PROFILES[0]["id"]

	var fallback_monster: Dictionary = MonsterCatalog.MONSTERS[0]
	_selected_monster_id = RunState.test_monster_id
	if _selected_monster_id == "" or MonsterCatalog.get_by_id(_selected_monster_id).is_empty():
		_selected_monster_id = fallback_monster["id"]

	# 성장 센티널(0) 처리 — "아직 아무것도 선택 안 함"일 때만 선택한 캐릭터의
	# "시작 그대로" 프리셋으로 한 번 채운다(run_state.gd 필드 주석 참고).
	if RunState.test_growth_attack_count <= 0 or RunState.test_growth_defense_count <= 0 or RunState.test_growth_sides <= 0:
		var base_growth := preset_growth(_selected_character_id, 0)
		RunState.test_growth_attack_count = base_growth["attack_count"]
		RunState.test_growth_defense_count = base_growth["defense_count"]
		RunState.test_growth_sides = base_growth["sides"]
	_selected_skill_flags = RunState.test_skill_flags.duplicate()

	_build_difficulty_row()

	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	KeyboardShortcuts.apply_hints([start_button])

	_build_character_row()
	_rebuild_skill_slots()
	_build_growth_preset_row()
	_build_growth_controls()
	_rebuild_skill_flag_rows()
	_build_filter_rows()
	_rebuild_monster_list()
	_update_difficulty_label()


## 숫자 키 단축키는 "전투 시작"([1]) 하나뿐이다(INBOX.md H-2 원문 — 이 화면은
## KeyboardShortcuts를 전부 적용할 필요 없음).
func _unhandled_input(event: InputEvent) -> void:
	var idx := KeyboardShortcuts.digit_index(event)
	if idx != 0:
		return
	var viewport := get_viewport()
	if KeyboardShortcuts.try_press([start_button], idx) and viewport != null:
		viewport.set_input_as_handled()


## selected면 금테(다른 화면들과 같은 색 언어), 아니면 회색 테두리 — 캐릭터 카드/시작
## 스킬 슬롯/몬스터 목록/필터 버튼이 전부 이 스타일 하나를 공유한다.
func _selection_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	if selected:
		style.bg_color = Color(0.22, 0.19, 0.08, 0.95)
		style.border_color = Color(0.85, 0.68, 0.25)
		style.set_border_width_all(3)
	else:
		style.bg_color = Color(0.14, 0.14, 0.16, 0.9)
		style.border_color = Color(0.35, 0.35, 0.35)
		style.set_border_width_all(1)
	return style


func _apply_selection_style(button: Button, selected: bool) -> void:
	var style := _selection_style(selected)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)


## 캐릭터 7종 — 초상(원화 있으면 썸네일, 없으면 도형 플레이스홀더, character_select.gd의
## _add_placeholder_thumb/_make_card와 같은 패턴 축소판) + 이름 버튼.
func _build_character_row() -> void:
	for c in character_row.get_children():
		c.queue_free()
	_character_buttons.clear()
	for profile in CharacterProfiles.PROFILES:
		var button := _make_character_button(profile)
		character_row.add_child(button)
		_character_buttons[profile["id"]] = button
	_refresh_character_highlight()


func _make_character_button(profile: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 76)
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 2)
	button.add_child(content)

	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(36, 44)
	content.add_child(icon_holder)
	var thumb := CharacterArt.load_thumb(profile["id"])
	if thumb != null:
		var thumb_rect := TextureRect.new()
		thumb_rect.texture = thumb
		thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		thumb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_holder.add_child(thumb_rect)
	else:
		var portrait := CharacterPortraitPlaceholder.new()
		portrait.scale = Vector2(0.18, 0.18)
		portrait.position = Vector2(18, 19)
		portrait.set_palette(profile["hair_color"], profile["dress_color"])
		icon_holder.add_child(portrait)

	var name_label := Label.new()
	name_label.text = profile["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content.add_child(name_label)

	button.pressed.connect(_on_character_selected.bind(profile["id"]))
	return button


func _refresh_character_highlight() -> void:
	for id in _character_buttons:
		_apply_selection_style(_character_buttons[id], id == _selected_character_id)


func _on_character_selected(id: String) -> void:
	_selected_character_id = id
	RunState.test_character_id = id
	_refresh_character_highlight()
	_rebuild_skill_slots()
	_rebuild_skill_flag_rows()


## 시작 스킬 — SkillPool.starting_skills_for_character()의 3슬롯 전부를 잠금 무시로
## 선택 가능하게 한다(character_select.gd의 _make_starting_skill_slot()과 달리
## unlocked 분기 자체가 없음).
func _rebuild_skill_slots() -> void:
	for c in skill_row.get_children():
		c.queue_free()
	_skill_buttons.clear()

	var candidates := SkillPool.starting_skills_for_character(_selected_character_id)
	var want: String = RunState.test_starting_skill_id
	var valid := false
	for skill in candidates:
		if skill["id"] == want:
			valid = true
			break
	if not valid:
		want = candidates[0]["id"] if not candidates.is_empty() else ""
	_selected_skill_id = want
	RunState.test_starting_skill_id = _selected_skill_id

	for skill in candidates:
		var button := _make_skill_slot_button(skill)
		skill_row.add_child(button)
		_skill_buttons[skill["id"]] = button

	_refresh_skill_highlight()
	_update_skill_description(candidates)


func _make_skill_slot_button(skill: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 56)
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_label := Label.new()
	name_label.text = skill["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content.add_child(name_label)
	button.add_child(content)

	button.pressed.connect(_on_skill_selected.bind(skill["id"]))
	return button


func _refresh_skill_highlight() -> void:
	for id in _skill_buttons:
		_apply_selection_style(_skill_buttons[id], id == _selected_skill_id)


func _on_skill_selected(id: String) -> void:
	_selected_skill_id = id
	RunState.test_starting_skill_id = id
	_refresh_skill_highlight()
	_update_skill_description(SkillPool.starting_skills_for_character(_selected_character_id))


func _update_skill_description(candidates: Array[Dictionary]) -> void:
	for skill in candidates:
		if skill["id"] == _selected_skill_id:
			skill_desc_label.text = "효과: %s" % skill["description"]
			return
	skill_desc_label.text = ""


## H-3 "성장" 섹션 ------------------------------------------------------------
##
## 프리셋 계산을 @onready 노드 없이도 테스트할 수 있도록 static 함수로 분리했다
## (F-3 원칙 — "플래그가 들어갔는가"가 아니라 "계산 결과"를 dice_test.gd가 직접
## 검증한다). character_id 기본 공격/방어 다이스 개수에 preset["delta"]를 더하고
## DiceBag.MAX_DICE로 상한, 1로 하한을 건다.
static func preset_growth(character_id: String, preset_index: int) -> Dictionary:
	var preset: Dictionary = GROWTH_PRESETS[preset_index]
	var profile := CharacterProfiles.get_profile(character_id)
	var base_attack: int = profile.get("attack_count", 3)
	var base_defense: int = profile.get("defense_count", 3)
	return {
		"attack_count": clampi(base_attack + int(preset["delta"]), 1, DiceBag.MAX_DICE),
		"defense_count": clampi(base_defense + int(preset["delta"]), 1, DiceBag.MAX_DICE),
		"sides": int(preset["sides"]),
	}


func _build_growth_preset_row() -> void:
	for c in growth_preset_row.get_children():
		c.queue_free()
	for i in GROWTH_PRESETS.size():
		var button := Button.new()
		button.text = GROWTH_PRESETS[i]["name"]
		button.pressed.connect(_on_growth_preset_pressed.bind(i))
		growth_preset_row.add_child(button)


func _on_growth_preset_pressed(preset_index: int) -> void:
	var result := preset_growth(_selected_character_id, preset_index)
	_attack_count_spin.value = result["attack_count"]
	_defense_count_spin.value = result["defense_count"]
	var sides_index: int = GROWTH_SIDES_OPTIONS.find(result["sides"])
	_sides_option.selected = sides_index if sides_index != -1 else 0
	_sync_growth_to_run_state()
	_update_growth_preview()


## 공격/방어 개수·면 개수·골드·눈금/다이스 인벤토리 6개 컨트롤을 GrowthControlsGrid
## (columns=2, "라벨/컨트롤" 쌍이 쌓이는 그리드)에 동적으로 만든다 — RoundSpin/
## RoomSpin과 같은 이유로 .tscn에 정적으로 두지 않음. 시작값은 RunState.test_growth_*
## (직전 선택 유지, _ready()의 센티널 처리 참고)에서 읽는다.
func _build_growth_controls() -> void:
	for c in growth_controls_grid.get_children():
		c.queue_free()

	_attack_count_spin = _make_growth_spin(1, DiceBag.MAX_DICE, RunState.test_growth_attack_count)
	_defense_count_spin = _make_growth_spin(1, DiceBag.MAX_DICE, RunState.test_growth_defense_count)
	_gold_spin = _make_growth_spin(0, 200, RunState.test_growth_gold)
	_pip_spin = _make_growth_spin(0, 12, RunState.test_growth_pip_count)
	_die_spin = _make_growth_spin(0, 6, RunState.test_growth_die_count)

	_sides_option = OptionButton.new()
	_sides_option.custom_minimum_size = Vector2(90, 0)
	for sides in GROWTH_SIDES_OPTIONS:
		_sides_option.add_item("D%d" % sides)
	var sides_index: int = GROWTH_SIDES_OPTIONS.find(RunState.test_growth_sides)
	_sides_option.selected = sides_index if sides_index != -1 else 0

	_add_growth_row("공격 다이스 개수", _attack_count_spin)
	_add_growth_row("방어 다이스 개수", _defense_count_spin)
	_add_growth_row("면 개수 (공통)", _sides_option)
	_add_growth_row("골드", _gold_spin)
	_add_growth_row("눈금 인벤토리", _pip_spin)
	_add_growth_row("다이스 인벤토리", _die_spin)

	_attack_count_spin.value_changed.connect(_on_growth_changed)
	_defense_count_spin.value_changed.connect(_on_growth_changed)
	_sides_option.item_selected.connect(_on_growth_sides_changed)
	_gold_spin.value_changed.connect(_on_growth_changed)
	_pip_spin.value_changed.connect(_on_growth_changed)
	_die_spin.value_changed.connect(_on_growth_changed)

	_update_growth_preview()


func _make_growth_spin(min_v: int, max_v: int, val: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.value = clampi(val, min_v, max_v)
	spin.custom_minimum_size = Vector2(90, 0)
	return spin


func _add_growth_row(label_text: String, control: Control) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	growth_controls_grid.add_child(label)
	growth_controls_grid.add_child(control)


func _on_growth_changed(_value: float) -> void:
	_sync_growth_to_run_state()
	_update_growth_preview()


func _on_growth_sides_changed(_index: int) -> void:
	_sync_growth_to_run_state()
	_update_growth_preview()


func _sync_growth_to_run_state() -> void:
	RunState.test_growth_attack_count = int(_attack_count_spin.value)
	RunState.test_growth_defense_count = int(_defense_count_spin.value)
	RunState.test_growth_sides = GROWTH_SIDES_OPTIONS[_sides_option.selected]
	RunState.test_growth_gold = int(_gold_spin.value)
	RunState.test_growth_pip_count = int(_pip_spin.value)
	RunState.test_growth_die_count = int(_die_spin.value)


func _update_growth_preview() -> void:
	var sides: int = GROWTH_SIDES_OPTIONS[_sides_option.selected]
	growth_preview_label.text = "적용될 구성: 공격 D%d x%d개 / 방어 D%d x%d개 / 골드 %d / 눈금 인벤토리 %d개 / 다이스 인벤토리 %d개" % [
		sides, int(_attack_count_spin.value), sides, int(_defense_count_spin.value),
		int(_gold_spin.value), int(_pip_spin.value), int(_die_spin.value),
	]


## H-3 "보유 스킬" 섹션 --------------------------------------------------------
##
## 토글 가능한 행 목록을 계산하는 부분도 static으로 분리(F-3 원칙) — 공용 2종
## (deep_breath/spare_die) + 선택한 캐릭터의 고유 스킬 1종(있으면), 각각 "+"
## 강화판(있으면)을 같은 행에 같이 둔다. plus id가 없으면 "" — 호출부가 빈 문자열을
## "강화판 없음"으로 처리한다.
static func skill_flag_rows_for_character(character_id: String) -> Array:
	var rows: Array = [
		{"base": "deep_breath", "plus": "deep_breath_plus"},
		{"base": "spare_die", "plus": "spare_die_plus"},
	]
	for skill in SkillPool.UNIQUE_SKILLS:
		if skill.get("character_id", "") == character_id:
			var plus_id := ""
			for up in SkillPool.UPGRADE_SKILLS:
				if up.get("upgrades", "") == skill["id"]:
					plus_id = up["id"]
					break
			rows.append({"base": skill["id"], "plus": plus_id})
	return rows


## flags 중 "그 캐릭터가 가질 수 있는 id"(위 rows의 base/plus)만 남기고, "+"는 base가
## 함께 있을 때만 유지한다 — 캐릭터를 바꿔서 더 이상 맞지 않는 고유 스킬/강화판이
## 조용히 RunState.skill_flags로 새어나가지 않게 하기 위함(INBOX.md H-3 원문
## "캐릭터를 바꾸면 해당 캐릭터에 맞지 않는 항목은 자동 해제").
static func sanitize_skill_flags(flags: Array, character_id: String) -> Array[String]:
	var rows := skill_flag_rows_for_character(character_id)
	var allowed: Array = []
	var plus_to_base: Dictionary = {}
	for row in rows:
		allowed.append(row["base"])
		if row["plus"] != "":
			allowed.append(row["plus"])
			plus_to_base[row["plus"]] = row["base"]
	var result: Array[String] = []
	for f in flags:
		if allowed.has(f):
			result.append(f)
	for plus_id in plus_to_base:
		if result.has(plus_id) and not result.has(plus_to_base[plus_id]):
			result.erase(plus_id)
	return result


func _rebuild_skill_flag_rows() -> void:
	for c in skill_flags_list.get_children():
		c.queue_free()
	_skill_flag_checkboxes.clear()

	_selected_skill_flags = sanitize_skill_flags(_selected_skill_flags, _selected_character_id)
	RunState.test_skill_flags = _selected_skill_flags.duplicate()

	for row in skill_flag_rows_for_character(_selected_character_id):
		var base_id: String = row["base"]
		var plus_id: String = row["plus"]
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		skill_flags_list.add_child(hbox)

		var base_skill := SkillPool.find_skill(base_id)
		var base_check := CheckBox.new()
		base_check.text = base_skill.get("name", base_id)
		base_check.button_pressed = _selected_skill_flags.has(base_id)
		base_check.toggled.connect(_on_skill_flag_base_toggled.bind(base_id, plus_id))
		hbox.add_child(base_check)
		_skill_flag_checkboxes[base_id] = base_check

		if plus_id != "":
			var plus_skill := SkillPool.find_skill(plus_id)
			var plus_check := CheckBox.new()
			plus_check.text = plus_skill.get("name", plus_id)
			plus_check.button_pressed = _selected_skill_flags.has(plus_id)
			plus_check.disabled = not base_check.button_pressed
			plus_check.toggled.connect(_on_skill_flag_plus_toggled.bind(plus_id))
			hbox.add_child(plus_check)
			_skill_flag_checkboxes[plus_id] = plus_check


func _on_skill_flag_base_toggled(pressed: bool, base_id: String, plus_id: String) -> void:
	if pressed:
		if not _selected_skill_flags.has(base_id):
			_selected_skill_flags.append(base_id)
	else:
		_selected_skill_flags.erase(base_id)
		if plus_id != "":
			_selected_skill_flags.erase(plus_id)
			if _skill_flag_checkboxes.has(plus_id):
				_skill_flag_checkboxes[plus_id].button_pressed = false
	if plus_id != "" and _skill_flag_checkboxes.has(plus_id):
		_skill_flag_checkboxes[plus_id].disabled = not pressed
	RunState.test_skill_flags = _selected_skill_flags.duplicate()


func _on_skill_flag_plus_toggled(pressed: bool, plus_id: String) -> void:
	if pressed:
		if not _selected_skill_flags.has(plus_id):
			_selected_skill_flags.append(plus_id)
	else:
		_selected_skill_flags.erase(plus_id)
	RunState.test_skill_flags = _selected_skill_flags.duplicate()


## 몬스터 필터(계열 4종+전체 / 등급 3종+전체) 버튼 행. 필터 자체는 목록만 좁히고
## RunState에는 아무것도 쓰지 않는다(선택된 몬스터 id만 저장 대상).
func _build_filter_rows() -> void:
	for c in family_filter_row.get_children():
		c.queue_free()
	for c in tier_filter_row.get_children():
		c.queue_free()
	_family_filter_buttons.clear()
	_tier_filter_buttons.clear()

	var family_entries: Array = [["", "전체"]]
	for fid in MonsterCatalog.family_ids():
		family_entries.append([fid, MonsterCatalog.FAMILIES[fid]["name"]])
	for entry in family_entries:
		var button := _make_filter_button(entry[1])
		button.pressed.connect(_on_family_filter_selected.bind(entry[0]))
		family_filter_row.add_child(button)
		_family_filter_buttons[entry[0]] = button

	var tier_entries: Array = [["", "전체"], ["normal", "일반"], ["elite", "정예"], ["boss", "보스"]]
	for entry in tier_entries:
		var button := _make_filter_button(entry[1])
		button.pressed.connect(_on_tier_filter_selected.bind(entry[0]))
		tier_filter_row.add_child(button)
		_tier_filter_buttons[entry[0]] = button

	_refresh_filter_highlight()


func _make_filter_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 26)
	return button


func _refresh_filter_highlight() -> void:
	for id in _family_filter_buttons:
		_apply_selection_style(_family_filter_buttons[id], id == _family_filter)
	for id in _tier_filter_buttons:
		_apply_selection_style(_tier_filter_buttons[id], id == _tier_filter)


func _on_family_filter_selected(id: String) -> void:
	_family_filter = id
	_refresh_filter_highlight()
	_rebuild_monster_list()


func _on_tier_filter_selected(id: String) -> void:
	_tier_filter = id
	_refresh_filter_highlight()
	_rebuild_monster_list()


## 몬스터 35종(필터 적용) 스크롤 목록 — 한 행에 FamilyIcon + 이름 + 등급 배지.
func _rebuild_monster_list() -> void:
	for c in monster_list.get_children():
		c.queue_free()
	_monster_buttons.clear()

	for monster in MonsterCatalog.MONSTERS:
		if _family_filter != "" and monster.get("family", "") != _family_filter:
			continue
		var tier: String = monster.get("tier", "normal")
		if _tier_filter != "" and tier != _tier_filter:
			continue
		var button := _make_monster_row(monster)
		monster_list.add_child(button)
		_monster_buttons[monster["id"]] = button

	_refresh_monster_highlight()
	_update_monster_detail()


func _make_monster_row(monster: Dictionary) -> Button:
	var tier: String = monster.get("tier", "normal")
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 28)
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)
	button.add_child(hbox)

	var icon := FamilyIcon.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.category = monster.get("family", "")
	icon.is_boss = tier == "boss"
	icon.is_elite = tier == "elite"
	hbox.add_child(icon)

	var name_label := Label.new()
	name_label.text = monster.get("name", monster.get("id", ""))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hbox.add_child(name_label)

	var tier_label := Label.new()
	tier_label.text = "[%s]" % TIER_LABELS.get(tier, tier)
	tier_label.custom_minimum_size = Vector2(50, 0)
	tier_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	hbox.add_child(tier_label)

	button.pressed.connect(_on_monster_selected.bind(monster["id"]))
	return button


func _refresh_monster_highlight() -> void:
	for id in _monster_buttons:
		_apply_selection_style(_monster_buttons[id], id == _selected_monster_id)


func _on_monster_selected(id: String) -> void:
	_selected_monster_id = id
	RunState.test_monster_id = id
	_refresh_monster_highlight()
	_update_monster_detail()


func _skill_desc(skill: Dictionary) -> String:
	var id: String = skill.get("id", "")
	var template: String = SKILL_PRIMITIVE_DESCRIPTIONS.get(id, id)
	if skill.has("amount") and template.find("%d") != -1:
		return template % int(skill["amount"])
	return template


func _update_monster_detail() -> void:
	var monster := MonsterCatalog.get_by_id(_selected_monster_id)
	if monster.is_empty():
		monster_detail_label.text = ""
		return
	var family_name: String = MonsterCatalog.FAMILIES.get(monster.get("family", ""), {}).get("name", "")
	var tier_label: String = TIER_LABELS.get(monster.get("tier", "normal"), "일반")
	var skill_lines: Array = []
	for s in monster.get("skills", []):
		skill_lines.append(_skill_desc(s))
	for s in monster.get("phase2_skills", []):
		skill_lines.append("[2페이즈] " + _skill_desc(s))
	var skills_text: String = ", ".join(skill_lines) if not skill_lines.is_empty() else "없음"
	monster_detail_label.text = "%s [%s / %s]\n\n스킬: %s\n\n성격: %s" % [
		monster.get("name", ""), family_name, tier_label, skills_text, monster.get("personality", "")
	]


## 난이도 스피너(라운드 1~3 / 방 0~4) — "직접 수치 입력도 허용"(INBOX.md H-2 원문)은
## SpinBox 자체가 값 칸을 직접 편집 가능하게 해주므로 추가 UI 없이 만족된다.
func _build_difficulty_row() -> void:
	for c in difficulty_row.get_children():
		c.queue_free()

	var round_label := Label.new()
	round_label.text = "라운드"
	difficulty_row.add_child(round_label)

	round_spin = SpinBox.new()
	round_spin.custom_minimum_size = Vector2(80, 0)
	round_spin.min_value = 1
	round_spin.max_value = RunState.TOTAL_ROUNDS
	round_spin.value = clampi(RunState.test_round_index, 1, RunState.TOTAL_ROUNDS)
	difficulty_row.add_child(round_spin)

	var room_label := Label.new()
	room_label.text = "방"
	difficulty_row.add_child(room_label)

	room_spin = SpinBox.new()
	room_spin.custom_minimum_size = Vector2(80, 0)
	room_spin.min_value = 0
	room_spin.max_value = RunState.TOTAL_ROOMS - 1
	room_spin.value = clampi(RunState.test_room_index, 0, RunState.TOTAL_ROOMS - 1)
	difficulty_row.add_child(room_spin)

	round_spin.value_changed.connect(_on_difficulty_spin_changed)
	room_spin.value_changed.connect(_on_difficulty_spin_changed)


func _on_difficulty_spin_changed(_value: float) -> void:
	_update_difficulty_label()


## 스피너의 현재 값(=단일 소스)을 읽어 RunState.test_round_index/test_room_index/
## test_difficulty에 반영한다 — _ready()의 초기 호출 시점에도(스피너 값을 먼저 만든
## 뒤 신호를 연결하므로 value_changed가 아직 한 번도 안 불렸을 수 있음) 항상 RunState를
## 스피너의 실제 표시값과 일치시키기 위해, RunState 필드를 직접 읽는 대신 round_spin/
## room_spin.value를 유일한 소스로 삼는다.
func _update_difficulty_label() -> void:
	var round_index := int(round_spin.value)
	var room_index := int(room_spin.value)
	var difficulty := room_index + (round_index - 1) * 3
	RunState.test_round_index = round_index
	RunState.test_room_index = room_index
	RunState.test_difficulty = difficulty
	difficulty_value_label.text = "난이도(effective_difficulty) = 방%d + (라운드%d-1)x3 = %d" % [
		room_index, round_index, difficulty
	]


## 실제 RunState 반영 로직 — @onready 노드를 전혀 참조하지 않는 순수한 부분이라
## dice_test.gd가 씬 트리 없이(스크립트 .new()만으로) 직접 호출해 "결과가 실제로
## 바뀌는가"를 검증할 수 있다(F-3 원칙). character_id/chosen_starting_skill_id는
## reset_run() 호출 전후로 백업/복원해 "실제 플레이의 다음 런 시작 스킬 선택"이 테스트
## 전투로 조용히 바뀌지 않게 한다(클래스 주석 참고).
## growth(비어있으면 적용 안 함 — reset_run()이 만든 캐릭터 기본 구성 그대로 둠,
## 기존 H-2 테스트와의 하위 호환)와 extra_skill_flags(SkillPool.grant()로 하나씩
## 부여)는 H-3 신규 매개변수 — 둘 다 기본값이 있어 H-2 시절 호출부(dice_test.gd의
## _check_h2_test_battle_setup())는 그대로 동작한다.
func _apply_start_selection(character_id: String, skill_id: String, monster_id: String, round_index: int, room_index: int, growth: Dictionary = {}, extra_skill_flags: Array = []) -> void:
	var backup_chosen := RunState.chosen_starting_skill_id
	RunState.chosen_starting_skill_id = skill_id
	RunState.reset_run(character_id)
	RunState.chosen_starting_skill_id = backup_chosen
	RunState.test_battle = true
	RunState.test_monster_id = monster_id
	RunState.test_round_index = round_index
	RunState.test_room_index = room_index
	RunState.test_difficulty = room_index + (round_index - 1) * 3
	_apply_growth(growth)
	for flag in extra_skill_flags:
		SkillPool.grant(flag)


## "주머니 구성 적용은 reset_run() 이후 한 곳에서만"(INBOX.md H-3 원문) — 호출부는
## 항상 _apply_start_selection()을 거치므로 여기 한 곳만 보면 된다. 캐릭터 기믹
## (min_max_only 등)은 reset_run()이 이미 "기본 구성(D4x기본개수)" 기준으로
## 적용해뒀는데, growth가 개수/면 개수를 바꾸면 그 적용이 낡은 모양에 묶여버리므로
## 주머니를 새로 만든 뒤 RunState._apply_character_gimmick()을 다시 불러 새 모양에
## 맞게 재적용한다.
func _apply_growth(growth: Dictionary) -> void:
	if growth.is_empty():
		return
	var sides: int = growth.get("sides", 4)
	var attack_count: int = growth.get("attack_count", RunState.player_attack_bag.count)
	var defense_count: int = growth.get("defense_count", RunState.player_defense_bag.count)
	RunState.player_attack_bag = DiceBag.new(sides, attack_count)
	RunState.player_defense_bag = DiceBag.new(sides, defense_count)
	RunState._apply_character_gimmick()
	RunState.gold = growth.get("gold", RunState.gold)
	var pip_value: int = int(ceil(sides / 2.0))
	var pips: Array[int] = []
	for i in int(growth.get("pip_count", 0)):
		pips.append(pip_value)
	RunState.pip_inventory = pips
	var dies: Array[int] = []
	for i in int(growth.get("die_count", 0)):
		dies.append(sides)
	RunState.die_inventory = dies


func _on_start_pressed() -> void:
	_sync_growth_to_run_state()
	var growth := {
		"attack_count": int(_attack_count_spin.value),
		"defense_count": int(_defense_count_spin.value),
		"sides": GROWTH_SIDES_OPTIONS[_sides_option.selected],
		"gold": int(_gold_spin.value),
		"pip_count": int(_pip_spin.value),
		"die_count": int(_die_spin.value),
	}
	_apply_start_selection(
		_selected_character_id, _selected_skill_id, _selected_monster_id,
		int(round_spin.value), int(room_spin.value), growth, _selected_skill_flags.duplicate()
	)
	get_tree().change_scene_to_file("res://code/scenes/combat_test.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/character_select.tscn")


## QA 전용: 숫자 키 입력 → "전투 시작" 버튼까지 실제로 눌리는 경로 확인(다른 화면들의
## _debug_press_shortcut_* 패턴과 동일한 이유).
func _debug_press_shortcut_1() -> void:
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_1
	_unhandled_input(key)


## QA 전용: "고블린 왕"(보스)을 라운드3/방4로 골라 전투 시작까지 한 번에 재현 —
## 설정 화면에서 보스 테스트 전투를 켜는 전체 경로를 스크린샷으로 확인하기 위함.
func _debug_start_boss_test_battle() -> void:
	_on_monster_selected("goblin_king")
	round_spin.value = 3
	room_spin.value = 4
	_on_start_pressed()


## QA 전용: H-3로 화면이 길어져 ScrollContainer가 생겼으므로, 아래쪽(몬스터 목록/
## 난이도/전투 시작 버튼)이 겹침 없이 보이는지 확인하려면 스크롤을 맨 아래로 내린
## 상태의 캡처가 필요하다.
func _debug_scroll_to_bottom() -> void:
	var scroll: ScrollContainer = $MainScroll
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## QA 전용: [대형 기획 9] I-3 — 해적을 선택하고 "보유 스킬" 섹션(새 "일제 사격"/
## "일제 사격+" 체크박스가 자동으로 뜨는지)이 보이도록 스크롤을 맨 아래로 내린다.
## _debug_scroll_to_bottom()과 같은 이유로 0-arity QA 래퍼로 분리.
func _debug_select_pirate_scroll_bottom() -> void:
	_on_character_selected("pirate")
	_debug_scroll_to_bottom()
