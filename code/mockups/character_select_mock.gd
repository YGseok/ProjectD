extends Node2D
## [대형 기획 17] S-0 시안 — 캐릭터 선택 화면 개편안(S-1/S-2/S-3). 실제 게임 흐름에
## 연결되지 않은 정적 시안 — 고정 예시 데이터(견습 모험가, 시작 스킬 3종)만 쓴다.
## 비교 대상은 docs/design/MOCKUP_REVIEW.md, "전" 캡처는 qa_out/mockups/
## character_select_before.png(실제 character_select.tscn).
##
## 반영한 기준(docs/design/VISUAL_STANDARD.md):
## - S-1.1/.2: 스킬 카드 안에 아이콘을 슬롯에 맞추고(6절 비율 유지), 한 줄 효과 요약 추가.
## - S-1.3: "(하나만 선택)" 문구 제거, 선택된 카드를 눌린 상태(두꺼운 accent 테두리+배경
##   틴트)로 표현.
## - S-1.4: 잠긴 카드에 자물쇠 + 해금 조건 문구, 포커스 제외(focus_mode=FOCUS_NONE).
## - S-2/S-6: 상단 버튼을 장식 이미지 스킨 대신(현재 스킨은 VISUAL_STANDARD.md 2절
##   실측에서 글자-장식 대비 문제가 확인됨) 절차적 플랫 스타일로 — "더 차분한 UI 키트"
##   방향을 새 아트 없이 미리 보여주는 근사치(MockupCommon.FLAT_SKIN_DIR, 실제 교체는
##   아트 발주 후).
## - S-3: 단계 표시(① → ② → ③) 제거, 하단 상태 메시지 바로 대체.

const CHARACTER_ID := "novice"
const SELECTED_SKILL_ID := "start_expand"

var _key_overlay: KeyOverlay


func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	add_child(bg)
	CharacterTheme.apply_background(self, CHARACTER_ID)

	var palette := CharacterTheme.ui_palette(CHARACTER_ID)

	var title := Label.new()
	title.text = "캐릭터 선택"
	title.position = Vector2(40, 24)
	title.add_theme_font_size_override("font_size", 24)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	add_child(title)

	_build_top_buttons(palette)
	_build_roster_list(palette)
	_build_portrait()
	_build_detail_panel(palette)
	_build_status_bar()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _build_top_buttons(palette: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(760, 24)
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	for label_text in ["몬스터 도감", "업적", "테스트 전투"]:
		var btn := Button.new()
		btn.text = label_text
		btn.custom_minimum_size = Vector2(0, 32)
		UIKit.style_secondary_button(btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
		row.add_child(btn)


func _build_roster_list(palette: Dictionary) -> void:
	var body := UIKit.make_section(self, "", CHARACTER_ID, Vector2(40, 72), MockupCommon.FLAT_SKIN_DIR)
	body.get_parent().custom_minimum_size = Vector2(240, 600)
	body.get_parent().size = Vector2(240, 600)
	var roster := ["novice", "berserker", "guardian", "enchantress"]
	for cid in roster:
		var profile := CharacterProfiles.get_profile(cid)
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		var selected: bool = cid == CHARACTER_ID
		style.bg_color = palette["accent"].darkened(0.6) if selected else Color(0.14, 0.14, 0.17)
		style.set_border_width_all(2 if selected else 1)
		style.border_color = palette["accent"] if selected else Color(0.3, 0.3, 0.34)
		style.set_corner_radius_all(6)
		style.content_margin_left = 10
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size = Vector2(216, 44)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		row.add_child(hbox)
		var thumb_tex := CharacterArt.load_face_thumb(cid)
		MockupCommon.make_ratio_safe_icon(hbox, thumb_tex, Vector2(32, 32), palette["primary"])
		var name_label := Label.new()
		name_label.text = String(profile.get("name", cid))
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95) if selected else Color(0.8, 0.8, 0.8))
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(name_label)
		body.add_child(row)


func _build_portrait() -> void:
	var face_tex := CharacterArt.load_face(CHARACTER_ID, "neutral")
	MockupCommon.make_ratio_safe_icon(self, face_tex, Vector2(380, 500)).position = Vector2(340, 110)


func _build_detail_panel(palette: Dictionary) -> void:
	var panel_x := 760.0
	var name_label := Label.new()
	name_label.text = CharacterProfiles.get_profile(CHARACTER_ID).get("name", CHARACTER_ID)
	name_label.position = Vector2(panel_x, 72)
	name_label.add_theme_font_size_override("font_size", 20)
	CharacterTheme.apply_label(name_label, CHARACTER_ID, true)
	add_child(name_label)

	var section := UIKit.make_section(self, "시작 스킬", CHARACTER_ID, Vector2(panel_x, 110), MockupCommon.FLAT_SKIN_DIR)
	var section_panel: Control = section.get_parent()
	section_panel.custom_minimum_size = Vector2(480, 320)
	section_panel.size = Vector2(480, 320)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)

	_build_skill_card(row, "start_expand", "확장", "합계 8+ → 다이스 전체 +1", "start_wall", true, false)
	_build_skill_card(row, "start_lean", "정예", "합계 7- → 다이스 전체 +1", "start_lean", false, false)
	_build_skill_card(row, "start_wealth", "황금손", "골드 30당 공격 +1(최대+2)", "start_wealth", false, true)


## selected: 눌린(선택된) 상태(S-1.3) — 두꺼운 accent 테두리 + 배경 틴트, "(하나만
## 선택)" 문구 없이 카드 자체의 상태만으로 전달.
## locked: 잠금(S-1.4) — 자물쇠 아이콘 + 해금 조건 문구, 포커스에서 제외.
func _build_skill_card(parent: Node, skill_id: String, display_name: String, summary: String, motif_skill_id: String, selected: bool, locked: bool) -> void:
	var palette := CharacterTheme.ui_palette(CHARACTER_ID)
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = palette["accent"].darkened(0.55)
		style.set_border_width_all(4)
		style.border_color = palette["accent"]
	elif locked:
		style.bg_color = Color(0.08, 0.08, 0.09)
		style.set_border_width_all(1)
		style.border_color = Color(0.3, 0.3, 0.32)
	else:
		style.bg_color = Color(0.14, 0.14, 0.17)
		style.set_border_width_all(1)
		style.border_color = Color(0.4, 0.4, 0.44)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(140, 180)
	if locked:
		card.focus_mode = Control.FOCUS_NONE  # S-1.4: 잠긱 카드는 키보드 포커스에서 제외
	parent.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# S-1.1: 아이콘을 48x48 정사각 슬롯 안에 비율 유지로(칸 밖으로 안 터짐).
	var icon_slot := CenterContainer.new()
	icon_slot.custom_minimum_size = Vector2(0, 52)
	vbox.add_child(icon_slot)
	var icon := SkillIcon.new()
	icon.motif = SkillPool.icon_motif_for(motif_skill_id)
	icon.skill_id = motif_skill_id
	icon.custom_minimum_size = Vector2(44, 44)
	icon.modulate = Color(0.45, 0.45, 0.47) if locked else Color(1, 1, 1)
	icon_slot.add_child(icon)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.52) if locked else Color(0.95, 0.95, 0.95))
	vbox.add_child(name_label)

	if locked:
		var lock_row := HBoxContainer.new()
		lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(lock_row)
		var lock := LockIcon.new()
		lock.custom_minimum_size = Vector2(16, 16)
		lock_row.add_child(lock)
		var req := SkillPool.unlock_requirement(CHARACTER_ID, 2)
		var cond_label := Label.new()
		cond_label.text = String(req.get("text", ""))
		cond_label.add_theme_font_size_override("font_size", 11)
		cond_label.add_theme_color_override("font_color", Color(0.82, 0.68, 0.3))
		cond_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		cond_label.custom_minimum_size = Vector2(120, 0)
		cond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(cond_label)
	else:
		# S-1.2: 카드 안에 한 줄 효과 요약(기존엔 선택된 카드 아래에만 전체 문장으로 있었음).
		var summary_label := Label.new()
		summary_label.text = summary
		summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		summary_label.custom_minimum_size = Vector2(120, 0)
		summary_label.add_theme_font_size_override("font_size", 12)
		summary_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.8))
		vbox.add_child(summary_label)


func _build_status_bar() -> void:
	# S-3: "① 캐릭터 → ② 시작 스킬 → ③ 던전 입장" 단계 표시 대신, 지금 상태를 바로 설명.
	MockupCommon.make_status_bar(self, "시작 스킬 \"확장\"을 선택했습니다 — 스페이스/Enter로 던전에 입장하세요.", Rect2(40, 664, 1200, 40))


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(40, 72, 240, 600), "number": 1, "label": "캐릭터 목록(위/아래 순환)"},
		{"rect": Rect2(760, 150, 480, 280), "number": 2, "label": "시작 스킬 3슬롯(좌/우)"},
		{"rect": Rect2(760, 24, 300, 32), "number": 3, "label": "상단 보조 버튼(좌/우)"},
		{"rect": Rect2(540, 664, 200, 40), "number": 4, "label": "던전 입장"},
	])
