class_name UIKit
extends RefCounted
## INBOX.md 2026-10-14 [대형 기획 13] M-1 — 던전 선택~전투 화면들을 캐릭터 선택 화면
## (K-2/K-3) 수준의 "구역 패널, 위계가 분명한 버튼, 퍼스널 컬러"로 끌어올리기 위한 공용
## 헬퍼. character_select.gd의 `_make_section()` 패턴을 여러 화면에서 복붙하지 않도록
## 한 곳으로 뽑았다(INBOX M-3 "공용 컴포넌트/헬퍼로 만들어 K-3 CharacterTheme와 연결").
##
## CharacterTheme/FocusNav와 같은 설계: 씬 상태를 전혀 갖지 않는 정적 함수만 제공해
## dice_test.gd가 인스턴스화 없이 검증할 수 있다.

const SECTION_BG := Color(0.1, 0.1, 0.13, 0.92)
const SECTION_BORDER_WIDTH := 1
const SECTION_CORNER := 8
## [대형 기획 13] M-3 — 감독 추가 비평(2026-10-14) "패널이 전부 얇은 테두리 사각형 +
## 어두운 단색이라 질감이 없다" 반영. 본격적인 질감/장식(그라데이션 텍스처, 코너 장식)은
## M-5 아트 스킨 납품으로 미루고, 코드로 값싸게 되는 미세한 그림자만 모든 구역 패널/
## HUD 바에 공통으로 입힌다 — StyleBoxFlat 내장 기능이라 성능/의존성 부담이 없다.
const SECTION_SHADOW_SIZE := 6
const SECTION_SHADOW_COLOR := Color(0, 0, 0, 0.35)
const SECTION_SHADOW_OFFSET := Vector2(0, 2)

const BUTTON_CORNER := 6
const PRIMARY_BUTTON_HEIGHT := 64.0
const SECONDARY_BUTTON_HEIGHT := 46.0


## 세로 구역 패널 — 테두리+배경 패널(panel_bg, primary 테두리) 안에 제목(선택)과
## 내용을 담을 VBoxContainer("body")를 만들어 parent에 붙이고 body를 돌려준다.
## title이 빈 문자열이면 제목 라벨 없이 틀만 만든다(헤더류 섹션에서 사용).
static func make_section(parent: Node, title: String, character_id: String, position: Vector2 = Vector2.ZERO) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = SECTION_BG
	style.set_border_width_all(SECTION_BORDER_WIDTH)
	style.set_corner_radius_all(SECTION_CORNER)
	style.shadow_size = SECTION_SHADOW_SIZE
	style.shadow_color = SECTION_SHADOW_COLOR
	style.shadow_offset = SECTION_SHADOW_OFFSET
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	CharacterTheme.apply(panel, character_id, false)
	# parent가 Container면 자식 position은 parent의 sort 단계에서 덮어써지므로 무해하고,
	# parent가 평범한 Node(예: Node2D 씬 루트)면 이 position이 그대로 화면 좌표가 된다
	# (dungeon_map.gd 등 Control 트리 바깥에서 쓸 때 필요).
	if position != Vector2.ZERO:
		panel.position = position

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	panel.add_child(body)

	if title != "":
		var title_label := Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 13)
		CharacterTheme.apply_label(title_label, character_id, true)
		body.add_child(title_label)
		# 감독 추가 비평 "제목 줄 구분선" — 제목이 있는 패널만 제목과 본문 사이에 얇은
		# 가로선을 둬 둘을 시각적으로 분리한다(제목 없는 패널은 구분할 대상이 없어 생략).
		var divider := ColorRect.new()
		var palette := CharacterTheme.ui_palette(character_id)
		divider.color = Color(palette["primary"].r, palette["primary"].g, palette["primary"].b, 0.3)
		divider.custom_minimum_size = Vector2(0, 1)
		body.add_child(divider)
	return body


## 가로 HUD 띠 — 상단에 라운드/진행도/골드 같은 칩을 나란히 두는 용도(제목 없음, 패딩만
## 얕게). make_section()과 같은 틀이지만 VBox 대신 HBox를 돌려준다.
static func make_bar(parent: Node, character_id: String, position: Vector2 = Vector2.ZERO) -> HBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = SECTION_BG
	style.set_border_width_all(SECTION_BORDER_WIDTH)
	style.set_corner_radius_all(SECTION_CORNER)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	CharacterTheme.apply(panel, character_id, false)
	if position != Vector2.ZERO:
		panel.position = position

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)
	return hbox


## HUD 바 안에 들어가는 "아이콘(선택) + 큰 숫자/값 + 짧은 캡션" 한 묶음. icon이 null이면
## 아이콘 없이 텍스트만. 반환값은 {container, value_label, caption_label} — 호출부가
## 나중에 값만 바꿔 쓸 수 있게.
static func make_stat_chip(parent: Node, icon: Control, value_text: String, caption_text: String, character_id: String) -> Dictionary:
	var palette := CharacterTheme.ui_palette(character_id)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon != null:
		row.add_child(icon)
	var value_label := Label.new()
	value_label.text = value_text
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", palette["accent"])
	row.add_child(value_label)
	vbox.add_child(row)

	var caption_label := Label.new()
	caption_label.text = caption_text
	caption_label.add_theme_font_size_override("font_size", 11)
	caption_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.68))
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(caption_label)

	parent.add_child(vbox)
	return {"container": vbox, "value_label": value_label, "caption_label": caption_label}


## 런 전체 진행도를 점(dot) total개로 보여준다 — filled개는 채운 점(지난 방), current_index
## (있으면)는 테두리만 강조한 "지금" 점, 나머지는 빈 점. INBOX M-1 원문 "진행도는 진행
## 바나 칸"을 반영.
static func make_progress_dots(parent: Node, total: int, filled: int, current_index: int, character_id: String) -> Control:
	var palette := CharacterTheme.ui_palette(character_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in total:
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(16, 16)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		if i < filled:
			style.bg_color = palette["accent"]
			style.border_color = palette["accent"]
			style.set_border_width_all(0)
		elif i == current_index:
			style.bg_color = Color(0, 0, 0, 0)
			style.border_color = palette["accent"]
			style.set_border_width_all(2)
		else:
			style.bg_color = Color(0.25, 0.25, 0.28, 0.6)
			style.border_color = Color(0.4, 0.4, 0.44)
			style.set_border_width_all(1)
		dot.add_theme_stylebox_override("panel", style)
		row.add_child(dot)
	parent.add_child(row)
	return row


## bg 위에서 더 또렷하게 읽히는 쪽(검정/흰색 중)을 CharacterTheme의 대비비 계산으로
## 골라 돌려준다 — accent색이 밝든 어둡든 버튼 글자가 항상 읽히게 하기 위함.
static func contrasting_text_color(bg: Color) -> Color:
	var black := Color(0.06, 0.06, 0.08)
	var white := Color(0.96, 0.96, 0.96)
	if CharacterTheme.contrast_ratio(black, bg) >= CharacterTheme.contrast_ratio(white, bg):
		return black
	return white


## 주 행동 버튼(예: "전투 방 입장") — accent색을 꽉 채운 칠 버튼. 화면에서 가장 먼저
## 눈에 띄어야 하는 선택지 하나에만 쓴다.
static func style_primary_button(btn: Button, character_id: String) -> void:
	var palette := CharacterTheme.ui_palette(character_id)
	var accent: Color = palette["accent"]
	var text_color := contrasting_text_color(accent)
	var styles := {
		"normal": accent.darkened(0.12),
		"hover": accent,
		"pressed": accent.darkened(0.28),
		"disabled": accent.darkened(0.12).lerp(Color(0.2, 0.2, 0.22), 0.6),
	}
	for state in styles:
		var style := StyleBoxFlat.new()
		style.bg_color = styles[state]
		style.set_corner_radius_all(BUTTON_CORNER)
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color.darkened(0.3))
	btn.add_theme_font_size_override("font_size", 18)


## 보조 행동 버튼(상점/이벤트/커스터마이징 등) — 어두운 바탕 + primary색 얇은 테두리로
## 주 행동보다 한 단계 눌려 보이게 한다. tint가 주어지면(Color.a > 0) primary 대신 그
## 색을 테두리/배경 틴트로 쓴다(예: 정예 전투의 위험 색 강조).
static func style_secondary_button(btn: Button, character_id: String, tint: Color = Color(0, 0, 0, 0)) -> void:
	var palette := CharacterTheme.ui_palette(character_id)
	var border: Color = tint if tint.a > 0.0 else palette["primary"]
	var base_bg: Color = Color(0.13, 0.13, 0.16) if tint.a <= 0.0 else Color(border.r, border.g, border.b).darkened(0.75)
	var styles := {
		"normal": base_bg,
		"hover": base_bg.lightened(0.12),
		"pressed": base_bg.darkened(0.15),
		"disabled": Color(0.1, 0.1, 0.12),
	}
	for state in styles:
		var style := StyleBoxFlat.new()
		style.bg_color = styles[state]
		style.border_color = border
		style.set_border_width_all(2)
		style.set_corner_radius_all(BUTTON_CORNER)
		btn.add_theme_stylebox_override(state, style)
	btn.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.52))
	btn.add_theme_font_size_override("font_size", 14)
