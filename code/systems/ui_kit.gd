class_name UIKit
extends RefCounted
## INBOX.md 2026-10-14 [대형 기획 13] M-1 — 던전 선택~전투 화면들을 캐릭터 선택 화면
## (K-2/K-3) 수준의 "구역 패널, 위계가 분명한 버튼, 퍼스널 컬러"로 끌어올리기 위한 공용
## 헬퍼. character_select.gd의 `_make_section()` 패턴을 여러 화면에서 복붙하지 않도록
## 한 곳으로 뽑았다(INBOX M-3 "공용 컴포넌트/헬퍼로 만들어 K-3 CharacterTheme와 연결").
##
## CharacterTheme/FocusNav와 같은 설계: 씬 상태를 전혀 갖지 않는 정적 함수만 제공해
## dice_test.gd가 인스턴스화 없이 검증할 수 있다.
##
## [대형 기획 13] M-5(a)(2026-10-15) — ProjectD Art가 납품한 `resources/ui/` 이미지
## 스킨(패널 section/hud/card/overlay, 버튼 primary/secondary, HP 바)을 이 팩토리들이
## 우선 사용하도록 확장했다. 파일이 없으면 기존 절차적(StyleBoxFlat 등) 스타일로 조용히
## 폴백 — 호출부(화면 코드)는 전혀 안 바꿔도 된다. 패턴은 `skill_icon.gd`의
## `load_external_art()`와 같다(FileAccess.file_exists + Image.load, ResourceLoader
## 경유 안 함 — base_dir를 테스트에서 user://로 주입할 수 있어야 하기 때문).

const SECTION_BG := Color(0.1, 0.1, 0.13, 0.92)
const SECTION_BORDER_WIDTH := 1
const SECTION_CORNER := 8
## [대형 기획 13] M-3 — 감독 추가 비평(2026-10-14) "패널이 전부 얇은 테두리 사각형 +
## 어두운 단색이라 질감이 없다" 반영. 본격적인 질감/장식(그라데이션 텍스처, 코너 장식)은
## M-5 아트 스킨 납품으로 미루고, 코드로 값싸게 되는 미세한 그림자만 모든 구역 패널/
## HUD 바에 공통으로 입힌다 — StyleBoxFlat 내장 기능이라 성능/의존성 부담이 없다.
## (M-5a로 이미지 스킨이 있으면 이 그림자 로직 자체는 안 쓰임 — 폴백 전용.)
const SECTION_SHADOW_SIZE := 6
const SECTION_SHADOW_COLOR := Color(0, 0, 0, 0.35)
const SECTION_SHADOW_OFFSET := Vector2(0, 2)

const BUTTON_CORNER := 6
const PRIMARY_BUTTON_HEIGHT := 64.0
const SECONDARY_BUTTON_HEIGHT := 46.0

## 운영 경로. 테스트는 `base_dir` 매개변수로 user:// 임시 경로를 주입해 resources/를
## 건드리지 않고 "없음→있음→없음" 전환을 검증한다(skill_icon.gd의
## external_art_base_dir와 같은 패턴).
const SKIN_BASE_DIR := "res://resources/ui/"

## 패널 종류별 9-slice 마진(docs/art/ART_RESOURCES.md 3-6 표, 2026-10-15 최종값) —
## {"l":좌, "t":상, "r":우, "b":하}. 키가 이 네 가지 종류를 벗어나면 스킨 미지원으로
## 간주해 항상 폴백한다.
const PANEL_SKIN_SPECS := {
	"section": {"l": 24, "t": 24, "r": 24, "b": 24},
	"hud": {"l": 34, "t": 20, "r": 34, "b": 20},
	"card": {"l": 24, "t": 24, "r": 24, "b": 24},
	"overlay": {"l": 44, "t": 44, "r": 44, "b": 44},
}

## 버튼(128×48) 9-slice 마진 — primary/secondary 공통.
const BUTTON_SKIN_MARGIN := {"l": 28, "t": 16, "r": 28, "b": 16}

## HP 프레임(256×28) 9-slice 마진 + 프레임 안쪽 채움 홈 인셋(ART_RESOURCES.md UI200,
## "채움 위치 = 프레임 사각형에서 좌22/상11/우22/하10px" — 9-slice 마진과 다른 값이라
## 별도 상수로 둔다).
const HP_FRAME_SKIN_MARGIN := {"l": 32, "t": 10, "r": 32, "b": 10}
const HP_FILL_INSET := {"l": 22, "t": 11, "r": 22, "b": 10}

## 운영 경로(base_dir == SKIN_BASE_DIR)에서만 쓰는 캐시 — resources/ui/*.png는 실행 중
## 안 바뀌므로, 캐릭터/종류별로 한 번만 합성(base+accent 블렌딩)하면 된다. 테스트가 쓰는
## 임시 base_dir는 캐시를 타지 않아(아래 각 _cached_* 함수의 cache_enabled 분기)
## "없음→있음→없음" 전환이 항상 즉시 반영된다.
static var _panel_skin_cache: Dictionary = {}
static var _button_skin_cache: Dictionary = {}
static var _hp_frame_cache: Dictionary = {}


## ---------------------------------------------------------------------------
## 이미지 스킨 공용 유틸 (skill_icon.gd의 load_external_art()와 같은 패턴)
## ---------------------------------------------------------------------------

static func _load_skin_image(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return img


static func _texture_from_image(img: Image) -> Texture2D:
	img.generate_mipmaps()  # 밉맵 — 줄여서 그릴 때 계단 방지 (K-4c와 같은 이유)
	return ImageTexture.create_from_image(img)


## img의 RGB를 tint로 곱하고(알파는 유지) 제자리에서 바꾼다. "흰색+알파" accent 레이어를
## 캐릭터 퍼스널 컬러로 물들이는 용도.
static func _tint_rgb(img: Image, tint: Color) -> void:
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a))


## base_dir + "panel/<kind>_base.png"(+"_accent.png")를 읽어 accent를 character_id
## accent색으로 틴트해 base 위에 블렌딩한 뒤 하나의 텍스처로 굽는다(패널은 버튼과 달리
## "상태"가 없어 라이브 오버레이보다 미리 굽는 쪽이 훨씬 단순하고, 기존
## `body.get_parent() == panel` 가정도 그대로 유지된다). base 파일이 없으면 null.
static func _build_panel_skin_texture(kind: String, character_id: String, base_dir: String) -> Texture2D:
	var base_img := _load_skin_image(base_dir + "panel/" + kind + "_base.png")
	if base_img == null:
		return null
	base_img.convert(Image.FORMAT_RGBA8)
	var accent_img := _load_skin_image(base_dir + "panel/" + kind + "_accent.png")
	if accent_img != null:
		var palette := CharacterTheme.ui_palette(character_id)
		_tint_rgb(accent_img, palette["accent"])
		base_img.blend_rect(accent_img, Rect2i(Vector2i.ZERO, accent_img.get_size()), Vector2i.ZERO)
	return _texture_from_image(base_img)


static func _cached_panel_skin_texture(kind: String, character_id: String, base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	var key := "%s|%s" % [kind, character_id]
	if cache_enabled and _panel_skin_cache.has(key):
		return _panel_skin_cache[key]
	var tex := _build_panel_skin_texture(kind, character_id, base_dir)
	if cache_enabled:
		_panel_skin_cache[key] = tex
	return tex


## panel(PanelContainer/Panel 등 "panel" 테마 슬롯을 쓰는 Control)에 kind("section"/
## "hud"/"card"/"overlay") 이미지 스킨을 적용한다. base PNG가 없으면 아무것도 바꾸지
## 않고 false를 돌려준다 — 호출부가 기존 절차적(StyleBoxFlat) 스타일로 폴백해야 한다는
## 신호. 성공하면 true(이후 panel.add_theme_stylebox_override("panel", ...)를 다시
## 하면 이 스킨이 지워지므로 주의).
static func apply_panel_skin(panel: Control, kind: String, character_id: String, base_dir: String = SKIN_BASE_DIR) -> bool:
	if not PANEL_SKIN_SPECS.has(kind):
		return false
	var tex := _cached_panel_skin_texture(kind, character_id, base_dir)
	if tex == null:
		return false
	var specs: Dictionary = PANEL_SKIN_SPECS[kind]
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var style := StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = specs["l"]
	style.texture_margin_right = specs["r"]
	style.texture_margin_top = specs["t"]
	style.texture_margin_bottom = specs["b"]
	# content_margin은 기본값(-1)으로 남겨 texture_margin과 자동으로 같아지게 한다 —
	# PanelContainer 자식(body)이 9-slice 테두리만큼 자연히 인셋된다.
	panel.add_theme_stylebox_override("panel", style)
	return true


## ---------------------------------------------------------------------------
## 패널 팩토리
## ---------------------------------------------------------------------------

## 세로 구역 패널 — 테두리+배경 패널(panel_bg, primary 테두리) 안에 제목(선택)과
## 내용을 담을 VBoxContainer("body")를 만들어 parent에 붙이고 body를 돌려준다.
## title이 빈 문자열이면 제목 라벨 없이 틀만 만든다(헤더류 섹션에서 사용).
## resources/ui/panel/section_{base,accent}.png가 있으면 그 이미지 스킨을 쓰고,
## 없으면(기본 상태) 기존 StyleBoxFlat 절차적 스타일로 폴백한다(M-5a).
## icon_name(M-5b): title이 있을 때 제목 왼쪽에 작은 기능 아이콘(resources/ui/icon/
## <icon_name>.png, 흰 실루엣을 character_id accent로 착색)을 붙인다. 빈 문자열(기본값)이면
## 지금까지처럼 아이콘 없음 — 기존 호출부는 전혀 안 바꿔도 된다.
static func make_section(parent: Node, title: String, character_id: String, position: Vector2 = Vector2.ZERO, base_dir: String = SKIN_BASE_DIR, icon_name: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	var skin_applied := apply_panel_skin(panel, "section", character_id, base_dir)
	if not skin_applied:
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
	if not skin_applied:
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
		# [대형 기획 13] M-5(b) — 제목 줄 양옆에 deco/title_ornament_{left,right}가 있으면
		# 작은 장식을, icon_name이 주어지고 해당 icon/*.png가 있으면 기능 아이콘을 덧붙인다.
		# 둘 다 없으면 기존(제목 Label 하나만)과 완전히 동일하다.
		var title_row := HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 5)
		title_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		var left_orn := _make_title_ornament_rect("left", character_id, base_dir)
		if left_orn != null:
			title_row.add_child(left_orn)
		if icon_name != "":
			var icon_tex := icon_texture(icon_name, CharacterTheme.ui_palette(character_id)["accent"], base_dir)
			if icon_tex != null:
				var icon_rect := TextureRect.new()
				icon_rect.texture = icon_tex
				icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.custom_minimum_size = Vector2(16, 16)
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				title_row.add_child(icon_rect)
		var title_label := Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 13)
		CharacterTheme.apply_label(title_label, character_id, true)
		title_row.add_child(title_label)
		var right_orn := _make_title_ornament_rect("right", character_id, base_dir)
		if right_orn != null:
			title_row.add_child(right_orn)
		body.add_child(title_row)
		# 감독 추가 비평 "제목 줄 구분선" — 제목이 있는 패널만 제목과 본문 사이에 얇은
		# 가로선을 둬 둘을 시각적으로 분리한다(제목 없는 패널은 구분할 대상이 없어 생략).
		# deco/divider_{base,accent}.png가 있으면 그 이미지를, 없으면 기존 ColorRect 1px
		# 선으로 폴백한다(M-5b).
		body.add_child(_make_divider_control(character_id, base_dir))
	return body


## 가로 HUD 띠 — 상단에 라운드/진행도/골드 같은 칩을 나란히 두는 용도(제목 없음, 패딩만
## 얕게). make_section()과 같은 틀이지만 VBox 대신 HBox를 돌려준다.
## resources/ui/panel/hud_{base,accent}.png가 있으면 그 이미지 스킨을 쓴다(M-5a).
static func make_bar(parent: Node, character_id: String, position: Vector2 = Vector2.ZERO, base_dir: String = SKIN_BASE_DIR) -> HBoxContainer:
	var panel := PanelContainer.new()
	var skin_applied := apply_panel_skin(panel, "hud", character_id, base_dir)
	if not skin_applied:
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
	if not skin_applied:
		CharacterTheme.apply(panel, character_id, false)
	if position != Vector2.ZERO:
		panel.position = position

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)
	return hbox


## HUD 바 안에 들어가는 "아이콘(선택) + 큰 숫자/값 + 짧은 캡션" 한 묶음. icon이 null이면
## 아이콘 없이 텍스트만. 반환값은 {container, value_label, caption_label} — 호출부가
## 나중에 값만 바꿔 쓸 수 있게. resources/ui/deco/chip.png가 있으면 칩 배경으로 쓰고(M-5b,
## 캐릭터색 틴트 없는 단일 파일), 없으면 기존처럼 배경 없이 텍스트만(폴백).
static func make_stat_chip(parent: Node, icon: Control, value_text: String, caption_text: String, character_id: String, base_dir: String = SKIN_BASE_DIR) -> Dictionary:
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

	var chip_panel := PanelContainer.new()
	if apply_chip_skin(chip_panel, base_dir):
		chip_panel.add_child(vbox)
		parent.add_child(chip_panel)
		return {"container": chip_panel, "value_label": value_label, "caption_label": caption_label}
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
## 골라 돌려준다 — accent색이 밝든 어둡든 버튼 글자가 항상 읽히게 하기 위함. 이미지
## 스킨(M-5a)을 쓸 때도 그대로 적용된다 — primary 버튼은 면 전체가 accent 색이라
## 글자색 대비 처리가 특히 중요하다(INBOX M-5 원문).
static func contrasting_text_color(bg: Color) -> Color:
	var black := Color(0.06, 0.06, 0.08)
	var white := Color(0.96, 0.96, 0.96)
	if CharacterTheme.contrast_ratio(black, bg) >= CharacterTheme.contrast_ratio(white, bg):
		return black
	return white


## ---------------------------------------------------------------------------
## 버튼 이미지 스킨 (M-5a) — 패널과 달리 버튼은 normal/hover/pressed/disabled 4가지
## "상태"가 있어, 상태마다 base+accent를 미리 구워(baked) StyleBoxTexture 한 장으로
## 만든다(라이브 오버레이 child로는 상태 전환 시 자식 텍스처를 따로 갈아끼워야 해서
## 더 복잡해짐). "focus"(5번째 상태)는 FocusNav.focus_style()가 전담하는 별도
## 테마 슬롯이라 이 스킨 범위 밖 — 모든 포커스 가능 Control(버튼 아닌 것 포함)에
## 공통으로 쓰이는 범용 오버레이라 버튼 kind(primary/secondary)에 묶을 수 없다.
## ---------------------------------------------------------------------------

static func _button_skin_filenames(kind: String, state: String) -> Dictionary:
	if state == "disabled":
		return {"base": "%s_disabled_base.png" % kind, "accent": ""}
	return {"base": "%s_%s_base.png" % [kind, state], "accent": "%s_%s_accent.png" % [kind, state]}


static func _build_button_state_texture(kind: String, state: String, tint: Color, base_dir: String) -> Texture2D:
	var names := _button_skin_filenames(kind, state)
	var base_img := _load_skin_image(base_dir + "button/" + names["base"])
	if base_img == null:
		return null
	base_img.convert(Image.FORMAT_RGBA8)
	if names["accent"] != "":
		var accent_img := _load_skin_image(base_dir + "button/" + names["accent"])
		if accent_img != null:
			_tint_rgb(accent_img, tint)
			base_img.blend_rect(accent_img, Rect2i(Vector2i.ZERO, accent_img.get_size()), Vector2i.ZERO)
	return _texture_from_image(base_img)


static func _cached_button_state_texture(kind: String, state: String, tint: Color, base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	var key := "%s|%s|%s" % [kind, state, tint.to_html(true)]
	if cache_enabled and _button_skin_cache.has(key):
		return _button_skin_cache[key]
	var tex := _build_button_state_texture(kind, state, tint, base_dir)
	if cache_enabled:
		_button_skin_cache[key] = tex
	return tex


## kind("primary"/"secondary") + state("normal"/"hover"/"pressed"/"disabled")의 스킨
## StyleBoxTexture를 만들어 돌려준다. base 이미지가 그 상태에 없으면 null — 호출부가
## 그 상태만 기존 StyleBoxFlat으로 폴백해야 한다(INBOX M-5 "상태별로 폴백").
static func _button_state_stylebox(kind: String, state: String, tint: Color, base_dir: String) -> StyleBoxTexture:
	var tex := _cached_button_state_texture(kind, state, tint, base_dir)
	if tex == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = BUTTON_SKIN_MARGIN["l"]
	style.texture_margin_right = BUTTON_SKIN_MARGIN["r"]
	style.texture_margin_top = BUTTON_SKIN_MARGIN["t"]
	style.texture_margin_bottom = BUTTON_SKIN_MARGIN["b"]
	# content_margin을 texture_margin 기본값(상하 16)에 맡기면 버튼 최소 높이가
	# 48px+폰트로 커져, M-3이 고정 좌표(40px 높이 버튼 행)로 짜둔 기존 화면들에서
	# 아래 패널과 실제로 겹치는 회귀가 생긴다(M-5a 적용 직후 dice_test M-3 검증으로
	# 발견). texture_margin(9-slice 비늘림 구간, 순수 렌더링 값)과 content_margin
	# (레이아웃이 요구하는 최소 여백)은 Godot에서 원래 독립된 값 — 상하만 작게 줘
	# 기존 레이아웃 예산 안에 들어오게 한다(좌우는 28 그대로, 가로는 여유 있음).
	style.content_margin_left = BUTTON_SKIN_MARGIN["l"]
	style.content_margin_right = BUTTON_SKIN_MARGIN["r"]
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


## 주 행동 버튼(예: "전투 방 입장") — accent색을 꽉 채운 칠 버튼. 화면에서 가장 먼저
## 눈에 띄어야 하는 선택지 하나에만 쓴다. resources/ui/button/primary_*가 있으면 그
## 이미지 스킨(상태별 폴백 포함)을 쓰고, 없으면 기존 절차적 색 채움으로 폴백한다(M-5a).
static func style_primary_button(btn: Button, character_id: String, base_dir: String = SKIN_BASE_DIR) -> void:
	var palette := CharacterTheme.ui_palette(character_id)
	var accent: Color = palette["accent"]
	var text_color := contrasting_text_color(accent)
	var fallback_colors := {
		"normal": accent.darkened(0.12),
		"hover": accent,
		"pressed": accent.darkened(0.28),
		"disabled": accent.darkened(0.12).lerp(Color(0.2, 0.2, 0.22), 0.6),
	}
	var any_skin := false
	for state in fallback_colors.keys():
		var skin_style := _button_state_stylebox("primary", state, accent, base_dir)
		if skin_style != null:
			any_skin = true
			btn.add_theme_stylebox_override(state, skin_style)
		else:
			var style := StyleBoxFlat.new()
			style.bg_color = fallback_colors[state]
			style.set_corner_radius_all(BUTTON_CORNER)
			btn.add_theme_stylebox_override(state, style)
	if any_skin:
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color.darkened(0.3))
	btn.add_theme_font_size_override("font_size", 18)


## 보조 행동 버튼(상점/이벤트/커스터마이징 등) — 어두운 바탕 + primary색 얇은 테두리로
## 주 행동보다 한 단계 눌려 보이게 한다. tint가 주어지면(Color.a > 0) primary 대신 그
## 색을 테두리/배경 틴트로 쓴다(예: 정예 전투의 위험 색 강조). resources/ui/button/
## secondary_*가 있으면 그 이미지 스킨을 쓴다(M-5a, tint가 accent 대신 틴트색으로 쓰임).
static func style_secondary_button(btn: Button, character_id: String, tint: Color = Color(0, 0, 0, 0), base_dir: String = SKIN_BASE_DIR) -> void:
	var palette := CharacterTheme.ui_palette(character_id)
	var border: Color = tint if tint.a > 0.0 else palette["primary"]
	var base_bg: Color = Color(0.13, 0.13, 0.16) if tint.a <= 0.0 else Color(border.r, border.g, border.b).darkened(0.75)
	var fallback_colors := {
		"normal": base_bg,
		"hover": base_bg.lightened(0.12),
		"pressed": base_bg.darkened(0.15),
		"disabled": Color(0.1, 0.1, 0.12),
	}
	var any_skin := false
	for state in fallback_colors.keys():
		var skin_style := _button_state_stylebox("secondary", state, border, base_dir)
		if skin_style != null:
			any_skin = true
			btn.add_theme_stylebox_override(state, skin_style)
		else:
			var style := StyleBoxFlat.new()
			style.bg_color = fallback_colors[state]
			style.border_color = border
			style.set_border_width_all(2)
			style.set_corner_radius_all(BUTTON_CORNER)
			btn.add_theme_stylebox_override(state, style)
	if any_skin:
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	btn.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.52))
	btn.add_theme_font_size_override("font_size", 14)


## ---------------------------------------------------------------------------
## HP 바 이미지 스킨 (M-5a) — combat_test.gd의 _build_hp_bar()를 여기로 옮겨 다른
## 팩토리들과 같은 "파일 없으면 폴백" 규칙을 적용한다. 프레임(base+accent, 틴트 후
## 한 장으로 구움 — 패널과 같은 이유)과 채움(hp_fill.png, accent 없이 흰~회색
## 그라데이션 하나뿐 — 호출부가 비율에 따라 modulate로 녹/주황/빨강 착색)을 각각
## NinePatchRect로 그린다.
## ---------------------------------------------------------------------------

static func _build_hp_frame_texture(character_id: String, base_dir: String) -> Texture2D:
	var base_img := _load_skin_image(base_dir + "bar/hp_frame_base.png")
	if base_img == null:
		return null
	base_img.convert(Image.FORMAT_RGBA8)
	var accent_img := _load_skin_image(base_dir + "bar/hp_frame_accent.png")
	if accent_img != null:
		var palette := CharacterTheme.ui_palette(character_id)
		_tint_rgb(accent_img, palette["accent"])
		base_img.blend_rect(accent_img, Rect2i(Vector2i.ZERO, accent_img.get_size()), Vector2i.ZERO)
	return _texture_from_image(base_img)


static func _cached_hp_frame_texture(character_id: String, base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	if cache_enabled and _hp_frame_cache.has(character_id):
		return _hp_frame_cache[character_id]
	var tex := _build_hp_frame_texture(character_id, base_dir)
	if cache_enabled:
		_hp_frame_cache[character_id] = tex
	return tex


## holder(plain Control, parent에 이미 붙임)에 숫자 라벨만 공용으로 만들어 붙인다 —
## 스킨/폴백 양쪽 경로가 공유.
static func _make_hp_bar_label(holder: Control, width: float, height: float) -> Label:
	var label := Label.new()
	label.size = Vector2(width, height)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.98, 0.98, 0.98))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 3)
	holder.add_child(label)
	return label


## HP 바 하나(배경/프레임 + 채움 + 그 위에 겹친 숫자 Label)를 만들어 parent에 붙인다.
## resources/ui/bar/hp_frame_base.png가 있으면 이미지 프레임 + hp_fill.png 채움을,
## 없으면 기존 ColorRect 배경/채움으로 폴백한다. 반환값 {"fill", "label", "skinned",
## "fill_full_width"} — "fill"은 스킨이면 NinePatchRect, 폴백이면 ColorRect(둘 다
## .size.x로 비율을 줄이고, 색은 스킨이면 .modulate 폴백이면 .color로 칠한다 — 호출부가
## `fill is ColorRect`로 분기). "fill_full_width"는 hp=100%일 때의 채움 폭(스킨은
## 프레임 안쪽 홈만큼 width보다 작음) — 비율 계산의 기준값.
static func make_hp_bar(parent: Node, width: float, height: float, character_id: String, base_dir: String = SKIN_BASE_DIR) -> Dictionary:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(width, height)
	parent.add_child(holder)

	var frame_tex := _cached_hp_frame_texture(character_id, base_dir)
	if frame_tex == null:
		var bg := ColorRect.new()
		bg.color = Color(0.2, 0.07, 0.07)
		bg.size = Vector2(width, height)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(bg)

		var fill := ColorRect.new()
		fill.color = Color(0.35, 0.85, 0.35)
		fill.size = Vector2(width, height)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(fill)

		var label := _make_hp_bar_label(holder, width, height)
		return {"fill": fill, "label": label, "skinned": false, "fill_full_width": width}

	var frame := NinePatchRect.new()
	frame.texture = frame_tex
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.patch_margin_left = HP_FRAME_SKIN_MARGIN["l"]
	frame.patch_margin_right = HP_FRAME_SKIN_MARGIN["r"]
	frame.patch_margin_top = HP_FRAME_SKIN_MARGIN["t"]
	frame.patch_margin_bottom = HP_FRAME_SKIN_MARGIN["b"]
	frame.size = Vector2(width, height)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(frame)

	var fill_w: float = max(0.0, width - HP_FILL_INSET["l"] - HP_FILL_INSET["r"])
	var fill_h: float = max(0.0, height - HP_FILL_INSET["t"] - HP_FILL_INSET["b"])
	var fill: Control
	var fill_img := _load_skin_image(base_dir + "bar/hp_fill.png")
	if fill_img != null:
		var fill_patch := NinePatchRect.new()
		fill_patch.texture = _texture_from_image(fill_img)
		fill_patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		fill_patch.patch_margin_left = 2
		fill_patch.patch_margin_right = 2
		fill_patch.position = Vector2(HP_FILL_INSET["l"], HP_FILL_INSET["t"])
		fill_patch.size = Vector2(fill_w, fill_h)
		fill_patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill_patch.modulate = Color(0.35, 0.85, 0.35)
		holder.add_child(fill_patch)
		fill = fill_patch
	else:
		# 프레임은 있지만 채움 이미지가 없는 드문 경우 — 프레임 안쪽 홈에 맞춘 ColorRect로.
		var fill_rect := ColorRect.new()
		fill_rect.color = Color(0.35, 0.85, 0.35)
		fill_rect.position = Vector2(HP_FILL_INSET["l"], HP_FILL_INSET["t"])
		fill_rect.size = Vector2(fill_w, fill_h)
		fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(fill_rect)
		fill = fill_rect

	var label := _make_hp_bar_label(holder, width, height)
	return {"fill": fill, "label": label, "skinned": true, "fill_full_width": fill_w}


## ---------------------------------------------------------------------------
## [대형 기획 13] M-5(b)(2026-10-15) — 배지(turn/round/tier_*/codex_base)/장식(칩 배경/
## 구분선/제목 장식)/기능 아이콘 9종의 이미지 스킨. M-5(a)와 같은 "base+accent를 캐릭터
## accent로 틴트해 굽는다, 파일 없으면 폴백" 원칙을 그대로 따른다. icon/*.png(흰 실루엣)
## 만 예외 — base/accent 구분이 없는 단일 실루엣이라 호출부가 넘기는 임의의 tint색으로
## 직접 칠한다(캐릭터 accent일 수도, 범주 고유색(RewardIcon의 COLOR_GOLD 등)일 수도 있음).
## ---------------------------------------------------------------------------

static var _icon_texture_cache: Dictionary = {}


## resources/ui/icon/<name>.png(흰 실루엣+알파)를 tint색으로 칠해 돌려준다. 파일이 없으면
## null — 호출부(RewardIcon/LockIcon/FamilyIcon 등)가 기존 절차적 _draw()로 폴백해야
## 한다는 신호. tint가 캐릭터 accent가 아니라 호출부 고유색일 수 있어, 패널/버튼류와
## 달리 character_id가 아니라 tint Color 자체를 캐시 키로 쓴다.
static func icon_texture(name: String, tint: Color, base_dir: String = SKIN_BASE_DIR) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	var key := "%s|%s" % [name, tint.to_html(true)]
	if cache_enabled and _icon_texture_cache.has(key):
		return _icon_texture_cache[key]
	var img := _load_skin_image(base_dir + "icon/" + name + ".png")
	var tex: Texture2D = null
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
		_tint_rgb(img, tint)
		tex = _texture_from_image(img)
	if cache_enabled:
		_icon_texture_cache[key] = tex
	return tex


## ---------------------------------------------------------------------------
## 칩 배경 (deco/chip.png) — base/accent 구분 없는 단일 중립색 파일이라(ART_RESOURCES.md
## UI350 "좌우12, 상하10", accent 변형 없음) 캐릭터별 틴트 없이 그대로 쓴다.
## ---------------------------------------------------------------------------

static var _chip_texture_cache: Texture2D = null
static var _chip_texture_cache_dir: String = ""


static func _cached_chip_texture(base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	if cache_enabled and _chip_texture_cache_dir == base_dir and _chip_texture_cache != null:
		return _chip_texture_cache
	var img := _load_skin_image(base_dir + "deco/chip.png")
	var tex: Texture2D = null
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
		tex = _texture_from_image(img)
	if cache_enabled:
		_chip_texture_cache = tex
		_chip_texture_cache_dir = base_dir
	return tex


## panel(PanelContainer 등)에 칩 배경 스킨을 입힌다. 파일 없으면 false(호출부가 배경 없는
## 기존 모습으로 폴백).
static func apply_chip_skin(panel: Control, base_dir: String = SKIN_BASE_DIR) -> bool:
	var tex := _cached_chip_texture(base_dir)
	if tex == null:
		return false
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var style := StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = 12
	style.texture_margin_right = 12
	style.texture_margin_top = 10
	style.texture_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return true


## ---------------------------------------------------------------------------
## 섹션 제목 장식 (deco/title_ornament_{left,right}_{base,accent}) — base+accent 틴트 후
## 한 장으로 굽는 패턴(패널/HP 프레임과 동일). 캐릭터별로 다르므로 character_id를 캐시
## 키에 포함한다. 48×24 원본을 32×16 자리에 비율 유지로 축소해 13px 제목 글자 옆에
## 자연스럽게 들어오게 한다.
## ---------------------------------------------------------------------------

static var _title_ornament_cache: Dictionary = {}


static func _build_title_ornament_texture(side: String, character_id: String, base_dir: String) -> Texture2D:
	var base_img := _load_skin_image(base_dir + "deco/title_ornament_" + side + "_base.png")
	if base_img == null:
		return null
	base_img.convert(Image.FORMAT_RGBA8)
	var accent_img := _load_skin_image(base_dir + "deco/title_ornament_" + side + "_accent.png")
	if accent_img != null:
		var palette := CharacterTheme.ui_palette(character_id)
		_tint_rgb(accent_img, palette["accent"])
		base_img.blend_rect(accent_img, Rect2i(Vector2i.ZERO, accent_img.get_size()), Vector2i.ZERO)
	return _texture_from_image(base_img)


static func _cached_title_ornament_texture(side: String, character_id: String, base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	var key := "%s|%s" % [side, character_id]
	if cache_enabled and _title_ornament_cache.has(key):
		return _title_ornament_cache[key]
	var tex := _build_title_ornament_texture(side, character_id, base_dir)
	if cache_enabled:
		_title_ornament_cache[key] = tex
	return tex


static func _make_title_ornament_rect(side: String, character_id: String, base_dir: String) -> TextureRect:
	var tex := _cached_title_ornament_texture(side, character_id, base_dir)
	if tex == null:
		return null
	var rect := TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(32, 16)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## ---------------------------------------------------------------------------
## 구분선 (deco/divider_{base,accent}) — 원본은 512×16을 좌240/중앙 보석32/우240으로
## 디자인했지만(ART_RESOURCES.md UI351), 실제 쓰이는 패널 폭이 화면마다 달라 9-slice로
## "가운데만 고정, 양옆만 늘어남"을 표현하려면 영역을 잘라 붙이는 복잡한 처리가 필요하다.
## 이 선은 순수 장식(정보 전달 없음)이라 비용 대비 이득이 낮다고 판단해, 대신 전체
## 이미지를 폭에 맞춰 균일하게 늘리는 단순한 TextureRect(STRETCH_SCALE)로 근사한다 —
## 패널 폭이 디자인 폭(512)보다 많이 좁을 때만 가운데 보석이 약간 작아 보일 수 있다(사람
## 피드백으로 더 다듬을 수 있는 자리).
## ---------------------------------------------------------------------------

static var _divider_texture_cache: Dictionary = {}


static func _build_divider_texture(character_id: String, base_dir: String) -> Texture2D:
	var base_img := _load_skin_image(base_dir + "deco/divider_base.png")
	if base_img == null:
		return null
	base_img.convert(Image.FORMAT_RGBA8)
	var accent_img := _load_skin_image(base_dir + "deco/divider_accent.png")
	if accent_img != null:
		var palette := CharacterTheme.ui_palette(character_id)
		_tint_rgb(accent_img, palette["accent"])
		base_img.blend_rect(accent_img, Rect2i(Vector2i.ZERO, accent_img.get_size()), Vector2i.ZERO)
	return _texture_from_image(base_img)


static func _cached_divider_texture(character_id: String, base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	if cache_enabled and _divider_texture_cache.has(character_id):
		return _divider_texture_cache[character_id]
	var tex := _build_divider_texture(character_id, base_dir)
	if cache_enabled:
		_divider_texture_cache[character_id] = tex
	return tex


## 제목 줄 아래 구분선 Control 하나를 만들어 돌려준다(아직 parent에 안 붙임 — 호출부가
## body.add_child()). 이미지가 없으면 기존 ColorRect 1px 선(M-3 폴백)과 완전히 동일하다.
static func _make_divider_control(character_id: String, base_dir: String) -> Control:
	var tex := _cached_divider_texture(character_id, base_dir)
	if tex == null:
		var fallback := ColorRect.new()
		var palette := CharacterTheme.ui_palette(character_id)
		fallback.color = Color(palette["primary"].r, palette["primary"].g, palette["primary"].b, 0.3)
		fallback.custom_minimum_size = Vector2(0, 1)
		return fallback
	var rect := TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = Vector2(0, 16)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## ---------------------------------------------------------------------------
## 턴/라운드 배지 (badge/{turn,round}_{base,accent}) — 패널과 같은 "base+accent를 캐릭터
## accent로 틴트해 굽기" 패턴. 글자 길이가 상황마다 달라(예: "몬스터 공격턴 (내 방어턴)")
## 고정 크기 NinePatchRect 대신 PanelContainer+StyleBoxTexture로 만들어 내용에 맞춰
## 자연히 늘어나게 한다(M-5a 패널/버튼과 같은 이유).
## ---------------------------------------------------------------------------

const BADGE_SKIN_MARGINS := {
	"turn": {"l": 44, "t": 12, "r": 44, "b": 12},
	"round": {"l": 40, "t": 12, "r": 40, "b": 12},
}

static var _badge_skin_cache: Dictionary = {}


static func _build_badge_skin_texture(kind: String, character_id: String, base_dir: String) -> Texture2D:
	var base_img := _load_skin_image(base_dir + "badge/" + kind + "_base.png")
	if base_img == null:
		return null
	base_img.convert(Image.FORMAT_RGBA8)
	var accent_img := _load_skin_image(base_dir + "badge/" + kind + "_accent.png")
	if accent_img != null:
		var palette := CharacterTheme.ui_palette(character_id)
		_tint_rgb(accent_img, palette["accent"])
		base_img.blend_rect(accent_img, Rect2i(Vector2i.ZERO, accent_img.get_size()), Vector2i.ZERO)
	return _texture_from_image(base_img)


static func _cached_badge_skin_texture(kind: String, character_id: String, base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	var key := "%s|%s" % [kind, character_id]
	if cache_enabled and _badge_skin_cache.has(key):
		return _badge_skin_cache[key]
	var tex := _build_badge_skin_texture(kind, character_id, base_dir)
	if cache_enabled:
		_badge_skin_cache[key] = tex
	return tex


## panel에 kind("turn"/"round") 배지 스킨을 입힌다. 파일 없으면 false.
static func apply_badge_skin(panel: Control, kind: String, character_id: String, base_dir: String = SKIN_BASE_DIR) -> bool:
	if not BADGE_SKIN_MARGINS.has(kind):
		return false
	var tex := _cached_badge_skin_texture(kind, character_id, base_dir)
	if tex == null:
		return false
	var margins: Dictionary = BADGE_SKIN_MARGINS[kind]
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var style := StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = margins["l"]
	style.texture_margin_right = margins["r"]
	style.texture_margin_top = margins["t"]
	style.texture_margin_bottom = margins["b"]
	panel.add_theme_stylebox_override("panel", style)
	return true


## kind("turn"/"round") 배지 하나 — 배경 스킨이 있으면 PanelContainer(스킨)+Label, 없으면
## 기존처럼 배경 없는 Label 하나만(폴백, M-2/M-3 당시와 완전히 동일한 모습). 반환값
## {"control", "label", "skinned"} — 호출부가 label에 폰트 크기/색을 그대로 이어서 적용.
static func make_badge(parent: Node, kind: String, text: String, character_id: String, base_dir: String = SKIN_BASE_DIR) -> Dictionary:
	var panel := PanelContainer.new()
	if apply_badge_skin(panel, kind, character_id, base_dir):
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(label)
		parent.add_child(panel)
		return {"control": panel, "label": label, "skinned": true}
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	return {"control": label, "label": label, "skinned": false}


## ---------------------------------------------------------------------------
## 몬스터 티어 배지 (badge/tier_{normal,elite,boss}.png) — 64×64 풀컬러 완성 배지라
## 캐릭터색 틴트를 하지 않는다("늘리지 않음", ART_RESOURCES.md UI251~253). kind별로만
## 캐시(character_id 무관).
## ---------------------------------------------------------------------------

const TIER_BADGE_KINDS := ["normal", "elite", "boss"]

static var _tier_badge_cache: Dictionary = {}


## kind("normal"/"elite"/"boss")의 티어 배지 텍스처. 파일 없으면 null(호출부가 기존
## 색깔 텍스트 라벨로 폴백).
static func tier_badge_texture(kind: String, base_dir: String = SKIN_BASE_DIR) -> Texture2D:
	if not TIER_BADGE_KINDS.has(kind):
		return null
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	var key := "%s|%s" % [kind, base_dir]
	if cache_enabled and _tier_badge_cache.has(key):
		return _tier_badge_cache[key]
	var img := _load_skin_image(base_dir + "badge/tier_" + kind + ".png")
	var tex: Texture2D = null
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
		tex = _texture_from_image(img)
	if cache_enabled:
		_tier_badge_cache[key] = tex
	return tex


## ---------------------------------------------------------------------------
## 도감 상태 배지 (badge/codex_base.png) — 단일 밝은 회색 파일 하나를 상태색(보유/발견/
## 미발견)으로 그때그때 modulate한다(ART_RESOURCES.md UI255 "코드가 상태색으로
## modulate"). base+accent 합성이 필요 없어 원본 텍스처 자체를 한 번만 캐시하고,
## StyleBoxTexture.modulate_color로 상태색을 입힌다 — 틴트 베이킹보다 훨씬 가볍다.
## ---------------------------------------------------------------------------

const CODEX_BADGE_MARGINS := {"l": 18, "t": 8, "r": 18, "b": 8}

static var _codex_badge_texture_cache: Texture2D = null
static var _codex_badge_texture_cache_dir: String = ""


static func _cached_codex_badge_texture(base_dir: String) -> Texture2D:
	var cache_enabled: bool = base_dir == SKIN_BASE_DIR
	if cache_enabled and _codex_badge_texture_cache_dir == base_dir and _codex_badge_texture_cache != null:
		return _codex_badge_texture_cache
	var img := _load_skin_image(base_dir + "badge/codex_base.png")
	var tex: Texture2D = null
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
		tex = _texture_from_image(img)
	if cache_enabled:
		_codex_badge_texture_cache = tex
		_codex_badge_texture_cache_dir = base_dir
	return tex


## panel에 상태색 modulate가 적용된 codex 배지 스킨을 입힌다. 파일 없으면 false.
static func apply_codex_badge_skin(panel: Control, state_color: Color, base_dir: String = SKIN_BASE_DIR) -> bool:
	var tex := _cached_codex_badge_texture(base_dir)
	if tex == null:
		return false
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var style := StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = CODEX_BADGE_MARGINS["l"]
	style.texture_margin_right = CODEX_BADGE_MARGINS["r"]
	style.texture_margin_top = CODEX_BADGE_MARGINS["t"]
	style.texture_margin_bottom = CODEX_BADGE_MARGINS["b"]
	style.modulate_color = state_color
	panel.add_theme_stylebox_override("panel", style)
	return true


## 상태 배지 하나 — 스킨이 있으면 PanelContainer(상태색 modulate)+대비색 글자, 없으면
## 기존처럼 배경 없이 state_color 그대로의 글자색 Label 하나(폴백, L-2b 당시와 동일).
static func make_codex_badge(parent: Node, text: String, state_color: Color, base_dir: String = SKIN_BASE_DIR) -> Label:
	var panel := PanelContainer.new()
	if apply_codex_badge_skin(panel, state_color, base_dir):
		var label := Label.new()
		label.text = text
		label.add_theme_font_size_override("font_size", 11)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", contrasting_text_color(state_color))
		panel.add_child(label)
		parent.add_child(panel)
		return label
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", state_color)
	parent.add_child(label)
	return label
