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
##
## 보유 스킬 목록(2026-09-28): [미니 기획 D]-6("선택, 급하지 않음"이라 미착수로 남아있던
## 항목, STATUS.md 큐 16 참고) — RunState.skill_flags(런 시작 스킬 + 이벤트로 얻은
## 공용/고유 스킬 + "+" 강화판, 전부 문자열 id로만 쌓이던 것)를 이름으로 풀어 캐릭터
## 섹션 아래에 나열한다. 지금까지는 스킬을 얻어도 이 패널/캐릭터 선택 화면 어디에도
## "지금 뭘 갖고 있는지" 모아서 보여주는 곳이 없었다.

const CHIP_SIZE := 22.0
const CHIP_GAP := 4.0
## [대형 기획 13] M-1: 얼굴 썸네일 한 변 — character_select.gd의 좌측 목록과 같은
## 패턴(FACE_THUMB_SIZE/PORTRAIT_SCALE_COMPACT)을 재사용하되 패널 폭(260px 전후)에
## 맞춰 조금 더 작게 잡았다.
const FACE_THUMB_SIZE := 40.0
const PORTRAIT_SCALE_COMPACT := 0.17

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
	# K-3(캐릭터 퍼스널 컬러): 이 패널은 dungeon_map/shop/event/story_event에 상시,
	# combat_test에 토글로 떠 있어 "런 시작 이후 모든 화면의 주요 패널 테두리"를 한
	# 지점에서 통일하기에 가장 효율적인 자리다 — 실제 색 적용은 캐릭터가 바뀔 때마다
	# _rebuild()가 담당(이 _ready() 시점의 border_color는 _rebuild()가 바로 덮어씀).

	# [대형 기획 13] M-1: 보유 스킬이 많이 쌓이면(런 후반) 6섹션 총합이 이 패널의 고정
	# 높이(화면마다 다르지만 dungeon_map 기준 550px)를 넘을 수 있다 — 전엔 그냥 화면
	# 밖으로 잘렸다(INBOX M-1이 명시적으로 금지하는 "화면 밖으로 잘림"). ScrollContainer로
	# 감싸 넘치면 스크롤되게 한다(character_select 좌측 카드 목록의 ART-1a와 같은 해법).
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_vbox = VBoxContainer.new()
	# 구역(섹션)마다 독립된 테두리 패널(UIKit.make_section)로 바뀌면서 패널 자체의
	# 여백이 섹션 사이 간격 역할을 겸하므로, 이전처럼 별도 _add_spacer() 노드 없이
	# VBox separation만으로 충분하다.
	_vbox.add_theme_constant_override("separation", 6)
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_vbox)
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
	return "%s#%s#%s#%s#%d#%d" % [
		RunState.character_id, _bag_signature(RunState.player_attack_bag), _bag_signature(RunState.player_defense_bag),
		",".join(RunState.skill_flags), RunState.pip_inventory.size(), RunState.die_inventory.size(),
	]


func _bag_signature(bag: DiceBag) -> String:
	var s := ""
	for faces in bag.dice:
		s += "["
		for v in faces:
			s += str(v) + ","
		s += "]"
	return s


func _rebuild() -> void:
	# K-3: 패널 테두리를 현재 캐릭터의 primary 색으로 다시 칠한다(캐릭터가 바뀔 때만
	# 실제로 값이 변함, _process()가 이미 character_id를 서명에 포함해 이때만 _rebuild()
	# 호출함).
	CharacterTheme.apply(self, RunState.character_id, false)
	for c in _vbox.get_children():
		c.queue_free()
	var cid := RunState.character_id
	_add_character_section(cid)
	_add_skills_section(cid)
	_add_bag_section("공격 주머니", RunState.player_attack_bag, cid)
	_add_bag_section("방어 주머니", RunState.player_defense_bag, cid)
	# [대형 기획 13] M-1: 기존 4섹션이 이 패널(dungeon_map 기준 550px 높이)을 다 채우지
	# 못해 아래쪽이 통째로 빈 공간이었다(INBOX M-1 비평 "빈 공간이 없게 배치"). 이벤트
	# 주사위/인벤토리는 지금까지 DeckPanel 어디에도 없던 실제 정보라 장식용 여백 대신
	# 유의미한 내용으로 채운다 — 섹션을 따로 쪼개면 테두리/패딩만 늘어 공간을 더 먹으므로
	# (오히려 "빈 공간" 문제를 키움) 한 섹션에 묶는다.
	_add_misc_section(cid)


## [대형 기획 13] M-1: 캐릭터 얼굴 썸네일 + 이름 + 설명(기믹 포함)을 구역 패널 하나로
## 묶는다(INBOX M-1 원문 "캐릭터 얼굴+이름"). 얼굴 이미지 우선순위는 character_select
## 좌측 목록과 같은 규칙(CharacterArt.load_face_thumb() — face_neutral.png ->
## full.png 크롭 -> 도형 플레이스홀더)이라 두 화면의 얼굴이 항상 일치한다.
## 스킬(기믹) 유형 아이콘(SkillIcon)은 이름 옆에 그대로 유지해 어떤 계열의 기믹인지
## 짐작 가능하게 한다(INBOX.md 2026-09-14 "캐릭터 스킬에 아이콘을 추가한다").
func _add_character_section(cid: String) -> void:
	var profile := CharacterProfiles.get_profile(cid)
	var body := UIKit.make_section(_vbox, "", cid)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	body.add_child(hbox)

	var portrait_holder := Control.new()
	portrait_holder.custom_minimum_size = Vector2(FACE_THUMB_SIZE, FACE_THUMB_SIZE)
	var thumb := CharacterArt.load_face_thumb(cid)
	if thumb != null:
		var thumb_rect := TextureRect.new()
		thumb_rect.texture = thumb
		thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait_holder.add_child(thumb_rect)
	else:
		var portrait := CharacterPortraitPlaceholder.new()
		portrait.scale = Vector2(PORTRAIT_SCALE_COMPACT, PORTRAIT_SCALE_COMPACT)
		portrait.position = Vector2(FACE_THUMB_SIZE / 2.0, FACE_THUMB_SIZE / 2.0 + 2.7)
		portrait.set_palette(profile["hair_color"], profile["dress_color"])
		portrait_holder.add_child(portrait)
	hbox.add_child(portrait_holder)

	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 2)
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	var skill_icon := SkillIcon.new()
	skill_icon.custom_minimum_size = Vector2(16, 16)
	skill_icon.category = String(profile.get("gimmick", ""))
	title_row.add_child(skill_icon)

	var title := Label.new()
	title.text = String(profile.get("name", ""))
	title.add_theme_font_size_override("font_size", 16)
	# K-3: 이름 글자색도 테두리와 같은 캐릭터 accent로 — 패널 전체가 "이 캐릭터의 색"
	# 이라는 인상을 제목에서부터 준다.
	title.add_theme_color_override("font_color", CharacterTheme.ui_palette(cid)["accent"])
	title_row.add_child(title)
	name_vbox.add_child(title_row)

	var desc := Label.new()
	desc.text = String(profile.get("desc", ""))
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_vbox.add_child(desc)


## STATUS.md 큐 16([미니 기획 D]-6, "선택, 급하지 않음"으로 미착수 남아있던 항목) —
## RunState.skill_flags에 쌓인 스킬(런 시작 스킬 + 이벤트로 얻은 공용/고유 스킬 +
## "+" 강화판, 전부 같은 배열에 문자열 id로만 저장됨)을 이름으로 풀어 목록으로 보여준다.
## SkillPool.find_skill()이 SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS 네
## 상수를 전부 뒤져 이름을 찾아주므로, 이 패널은 어느 스킬이 어느 상수 출신인지 몰라도
## 된다 — 새 스킬 종류가 늘어도 이 코드는 그대로 유지됨. 새 위젯을 만들지 않고 캐릭터
## 섹션과 같은 Label 나열 패턴을 재사용했다.
func _add_skills_section(cid: String) -> void:
	var body := UIKit.make_section(_vbox, "보유 스킬", cid)

	if RunState.skill_flags.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(없음)"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		body.add_child(empty_label)
		return

	for skill_id in RunState.skill_flags:
		var skill := SkillPool.find_skill(skill_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		# K-4b: 효과 모티프 아이콘(SkillPool.icon_motif_for) — 전투 중(토글)/비전투
		# 4개 화면 전부 이 패널을 공유하므로 여기 한 곳만 고치면 "전투 중 보유 스킬
		# 표시"와 "덱 패널" 양쪽 요구를 함께 충족한다.
		var motif := SkillPool.icon_motif_for(skill_id)
		if motif != "":
			var skill_icon := SkillIcon.new()
			skill_icon.custom_minimum_size = Vector2(14, 14)
			skill_icon.motif = motif
			skill_icon.skill_id = skill_id
			row.add_child(skill_icon)
		var skill_label := Label.new()
		skill_label.text = "· %s" % String(skill.get("name", skill_id))
		skill_label.add_theme_font_size_override("font_size", 12)
		skill_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		row.add_child(skill_label)
		body.add_child(row)


## 이벤트 주사위(RunState.event_die_sides) + 눈금/다이스 인벤토리 — 둘 다 지금까지
## character_select 상세 패널/CustomizePanel을 열어야만 보이던 정보라, 던전 진행
## 화면에서도 상시 볼 수 있게 한 섹션에 함께 넣는다(각각 섹션을 쪼개면 테두리/패딩만
## 늘어 "빈 공간" 문제를 오히려 키우므로 묶음).
func _add_misc_section(cid: String) -> void:
	var body := UIKit.make_section(_vbox, "기타 정보", cid)

	var die_row := HBoxContainer.new()
	die_row.add_theme_constant_override("separation", 8)
	body.add_child(die_row)
	var sample := EventDieVisual.new()
	sample.custom_minimum_size = Vector2(24, 24)
	sample.value = 1
	die_row.add_child(sample)
	var die_label := Label.new()
	die_label.text = "이벤트 주사위 D%d" % RunState.event_die_sides
	die_label.add_theme_font_size_override("font_size", 12)
	die_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	die_row.add_child(die_label)

	var inv_row := HBoxContainer.new()
	inv_row.add_theme_constant_override("separation", 16)
	body.add_child(inv_row)
	inv_row.add_child(_make_inventory_chip("pip", "눈금 %d개" % RunState.pip_inventory.size()))
	inv_row.add_child(_make_inventory_chip("dice", "다이스 %d개" % RunState.die_inventory.size()))


func _make_inventory_chip(category: String, text: String) -> Control:
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 5)
	var icon := RewardIcon.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.category = category
	pair.add_child(icon)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	pair.add_child(label)
	return pair


func _add_bag_section(title_text: String, bag: DiceBag, cid: String) -> void:
	var body := UIKit.make_section(_vbox, title_text, cid)
	for faces in bag.dice:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", CHIP_GAP)
		for v in faces:
			row.add_child(_make_chip(v))
		body.add_child(row)


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
