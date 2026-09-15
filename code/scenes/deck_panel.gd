class_name DeckPanel
extends PanelContainer
## 화면 한쪽에 상시 떠 있는 "내 덱 보기" 패널 (view-only).
## INBOX.md 피드백(2026-09-03): "내 공격 덱과 방어 덱이 어떤 눈금을 보유한 주사위들인지
## 항상 떠있으면 좋겠다 (전투 중에도, 선택지 중에도)".
##
## STATUS.md 큐 0번 권고("공용 패널을 한 번에 다 하지 말고 '보기 전용 패널 추가'부터
## 작게 시작할 것")를 반영해, 이번 이터레이션에서는 상호작용(커스터마이징) 없이
## 공격/방어 주머니 구성을 보여주기만 한다. 여러 씬(dungeon_map/shop/event/
## story_event)에 그대로 붙여 쓸 수 있도록 스크립트 하나로 완결된 Control이며
## 별도 .tscn이 필요 없다 (shape_die_chip.gd와 같은 패턴).
##
## combat_test.tscn은 화면이 이미 다이스 뷰포트/초상화/로그로 꽉 차 있어 이 패널을
## 넣을 여유 공간이 없다 — 다음 이터레이션에서 레이아웃을 다시 짜야 함 (docs/STATUS.md
## 참고).
##
## 캐릭터 정보 섹션(2026-09-15): INBOX.md 2026-09-14 "캐릭터 정보 및 보유 스킬을
## 상시 볼 수 있도록 한다"를 반영. 이 패널이 이미 "전투 제외 화면에서는 상시 표시,
## 전투 중에는 토글 한 번으로 열람"이라는 정확히 요청된 동작을 하고 있어(위 문서 참고),
## 새 버튼/패널을 따로 만들지 않고 덱 정보 위에 캐릭터 이름+설명(기믹 포함) 한 섹션만
## 추가했다 — 새 레이아웃 공간을 확보할 필요가 없어 5개 화면(dungeon_map/shop/event/
## story_event/combat_test) 모두에 자동으로 반영됨. "보유 스킬"은 현재
## character_profiles.gd의 gimmick 설명 텍스트가 유일한 캐릭터별 능력이라 그걸
## 그대로 보여준다 — 이벤트로 얻는 별도 "고유 스킬" 시스템 자체는 아직 없음(DESIGN.md
## "고유 스킬(이벤트로 획득)은 아직 없음" 참고, 다음 할 일 큐 "캐릭터 스킬 이벤트 신설").

const CHIP_SIZE := 20.0
const CHIP_GAP := 3.0
const SECTION_GAP := 10.0

var _vbox: VBoxContainer
var _last_signature := ""


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.4)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 4)
	add_child(_vbox)
	_rebuild()


## 커스터마이징/아이템 적용 등으로 RunState의 다이스 구성이 바뀔 수 있으므로, 매
## 프레임 내용을 문자열 서명으로 비교해 실제로 바뀐 경우에만 다시 그린다 (모든
## 호출부에 "덱이 바뀌면 패널도 갱신해라" 배선을 일일이 추가하지 않아도 되게 하기
## 위함 — 다이스 개수가 많아야 수십 개 수준이라 매 프레임 비교 비용은 무시할 만함).
func _process(_delta: float) -> void:
	var sig := _signature()
	if sig != _last_signature:
		_last_signature = sig
		_rebuild()


func _signature() -> String:
	return "%s#%s#%s" % [RunState.character_id, _bag_signature(RunState.player_attack_bag), _bag_signature(RunState.player_defense_bag)]


func _bag_signature(bag: DiceBag) -> String:
	var s := ""
	for faces in bag.dice:
		s += "["
		for v in faces:
			s += str(v) + ","
		s += "]"
	return s


func _rebuild() -> void:
	for c in _vbox.get_children():
		c.queue_free()
	_add_character_section()
	_add_spacer()
	_add_section("공격 주머니", RunState.player_attack_bag)
	_add_spacer()
	_add_section("방어 주머니", RunState.player_defense_bag)


## 캐릭터 이름 + 설명(기믹 포함)을 덱 정보 위에 보여준다. character_profiles.gd의
## desc 필드는 캐릭터 선택 화면에서 쓰는 것과 동일한 텍스트를 그대로 재사용 — 별도
## "요약본"을 새로 만들지 않아 두 화면의 설명이 어긋날 일이 없다.
## 스킬(기믹) 유형 아이콘(SkillIcon, 2026-09-15 신규)을 이름 왼쪽에 붙여, 이 패널만
## 봐도 캐릭터 선택 화면의 상세 패널과 같은 시각적 언어로 어떤 계열의 기믹인지
## 짐작 가능하게 한다(INBOX.md 2026-09-14 "캐릭터 스킬에 아이콘을 추가한다").
func _add_character_section() -> void:
	var profile := CharacterProfiles.get_profile(RunState.character_id)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	var skill_icon := SkillIcon.new()
	skill_icon.custom_minimum_size = Vector2(18, 18)
	skill_icon.category = String(profile.get("gimmick", ""))
	title_row.add_child(skill_icon)

	var title := Label.new()
	title.text = "캐릭터: %s" % profile.get("name", "")
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	title_row.add_child(title)
	_vbox.add_child(title_row)

	var desc := Label.new()
	desc.text = String(profile.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_vbox.add_child(desc)


func _add_section(title_text: String, bag: DiceBag) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_vbox.add_child(title)
	for faces in bag.dice:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", CHIP_GAP)
		for v in faces:
			row.add_child(_make_chip(v))
		_vbox.add_child(row)


func _make_chip(value: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(CHIP_SIZE, CHIP_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.88, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.15, 0.12, 0.08)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = str(value)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))
	panel.add_child(label)
	return panel


func _add_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, SECTION_GAP)
	_vbox.add_child(spacer)
