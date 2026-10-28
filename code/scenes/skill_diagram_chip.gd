class_name SkillDiagramChip
extends Control
## [대형 기획 15] Q-7(b)(2026-10-17) 신규 — SkillDiagram이 그리는 "기호" 1개
## (SkillPool.diagram_for()의 diagram 배열 원소 1개)를 전담하는 최소 Control.
##
## 렌더 분기는 기호 type별 함수 테이블(_RENDERERS)로만 하고 스킬 id로는 절대
## 분기하지 않는다(INBOX.md "렌더 분기는 기호 종류별 함수 테이블(스킬 id 하드코딩
## 금지)" 요구). 새 symbol type이 SkillPool.DIAGRAM_SYMBOL_TYPES에 추가되면 이
## 테이블에 항목을 추가해야 하고, 빠뜨리면 _draw_unknown_symbol()(물음표 배지)로
## 눈에 보이게 떨어진다(조용히 숨지 않음 — K-4a 모티프 누락 처리와 같은 원칙).
##
## 색맹 고려(INBOX.md "색만으로 구분 금지: 모양 포함") — 텍스트 라벨은 전부
## TEXT_COLOR(밝은 중성색, 다크 배경 대비 WCAG AA 통과 보장)로 통일해 색 구분에
## 기대지 않고, 대신 아이콘 자체의 "모양"으로 구분한다: 공격=칼끝 삼각형,
## 방어=방패 오각형, 이벤트=육각형, 폭발 스택=별모양, 수호 스택=겹겹의 방패,
## 저글링/맞바꾸기=교차 화살표, 주기=시계판 — SkillIcon이 이미 쓰는 같은 어휘를
## 재사용해 게임 전체에서 "방패=방어" 학습이 일관되게 한다.
##
## resources/ui/icon/*.png(attack/defense/hp/gold/pip/dice)가 있으면 UIKit.icon_texture()
## 로 그 실루엣을 칠해 쓰고, 없으면(또는 그 아이콘 세트에 없는 모양 — event/material/
## stack/swap/cycle/reroll 등) 절차적 도형으로 그린다(SkillIcon과 같은 "파일 우선,
## 없으면 draw_*" 원칙).

const SIZE_LARGE := 0
const SIZE_SMALL := 1
## Q-7(c)(2026-10-17) 신규 — SkillDetailPopup처럼 화면 전체를 덮는 큰 오버레이에서 쓰는
## 세 번째 크기. 감독 피드백("LARGE 칩이 30px 안팎이라 카드/팝업에서 눈에 안 띈다")에
## 따라 이번 조각에서 LARGE 자체도 44px 이상으로 키우고, 팝업만 그보다 한 단계 더 큰
## 56px 이상을 쓴다.
const SIZE_POPUP := 2

const CHIP_HEIGHT := {SIZE_LARGE: 44.0, SIZE_SMALL: 20.0, SIZE_POPUP: 56.0}
const ICON_PX := {SIZE_LARGE: 26.0, SIZE_SMALL: 13.0, SIZE_POPUP: 34.0}
const FONT_PX := {SIZE_LARGE: 15, SIZE_SMALL: 9, SIZE_POPUP: 18}
const PAD := {SIZE_LARGE: 5.0, SIZE_SMALL: 2.0, SIZE_POPUP: 6.0}

const COLOR_ATTACK := Color(0.92, 0.4, 0.18)
const COLOR_DEFENSE := Color(0.32, 0.58, 0.88)
const COLOR_EVENT := Color(0.68, 0.52, 0.88)
const COLOR_GOLD := Color(0.95, 0.82, 0.3)
const COLOR_CONDITION := Color(0.6, 0.78, 0.95)
const COLOR_REROLL := Color(0.3, 0.78, 0.58)
const COLOR_SWAP := Color(0.92, 0.78, 0.2)
const COLOR_CYCLE := Color(0.2, 0.68, 0.64)
const COLOR_STACK_ATTACK := Color(0.95, 0.58, 0.18)
const COLOR_STACK_DEFENSE := Color(0.62, 0.66, 0.72)
## 모든 텍스트 라벨 공용색 — CHIP_BG 대비 WCAG AA(4.5:1) 이상을 항상 보장하기
## 위해 "텍스트는 전부 이 색 하나"로 고정한다(대비 책임을 색상 수만큼 분산시키지
## 않음, dice_test.gd의 Q-7b 대비 검증 참고).
const TEXT_COLOR := Color(0.92, 0.92, 0.95)
const CHIP_BG := Color(0.16, 0.16, 0.2, 0.85)

var symbol: Dictionary = {}
var size_variant: int = SIZE_LARGE

var _font: Font = null


func setup(symbol_value: Dictionary, size_variant_value: int) -> void:
	symbol = symbol_value
	size_variant = size_variant_value
	if _font == null:
		_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var computed := _compute_size()
	custom_minimum_size = computed
	size = computed
	queue_redraw()


## 기호 종류별 함수 테이블. type -> 이 스크립트의 메서드 이름(0-인자).
const _RENDERERS := {
	"die": "_draw_die_symbol",
	"compare": "_draw_compare_symbol",
	"condition": "_draw_condition_symbol",
	"arrow": "_draw_arrow_symbol",
	"value": "_draw_value_symbol",
	"duration": "_draw_duration_symbol",
	"reroll": "_draw_reroll_symbol",
	"stack": "_draw_stack_symbol",
	"swap": "_draw_swap_symbol",
	"cycle": "_draw_cycle_symbol",
	"gold": "_draw_gold_symbol",
}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), CHIP_BG, true)
	var type: String = symbol.get("type", "")
	var method: String = _RENDERERS.get(type, "")
	if method != "" and has_method(method):
		call(method)
	else:
		_draw_unknown_symbol()


## 테스트(dice_test.gd)와 _draw()가 "지금 상태에서 어느 함수 테이블 분기를 타는지"를
## 속성이 아니라 계산 결과로 같이 검증할 수 있게 노출(SkillIcon.render_source()와
## 같은 패턴 — 단일 진실 소스).
func render_method() -> String:
	var type: String = symbol.get("type", "")
	return _RENDERERS.get(type, "")


func _compute_size() -> Vector2:
	var h: float = CHIP_HEIGHT[size_variant]
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var fsize: int = FONT_PX[size_variant]
	var type: String = symbol.get("type", "")
	match type:
		"die":
			return Vector2(icon_px + pad * 2.0, h)
		"compare":
			var op_w := _text_width(symbol.get("op", ">"), fsize) + pad
			return Vector2(pad * 4.0 + icon_px * 2.0 + op_w, h)
		"condition":
			var ctext := _condition_label()
			var cw := icon_px + pad * 2.0
			if ctext != "":
				cw += _text_width(ctext, fsize) + pad
			return Vector2(cw, h)
		"arrow":
			return Vector2(pad * 2.0 + icon_px * 1.2, h)
		"value":
			return Vector2(pad * 3.0 + _text_width(_value_text(), fsize), h)
		"duration":
			return Vector2(pad * 3.0 + _text_width(_duration_text(), fsize), h)
		"reroll", "stack", "swap", "cycle":
			var stext := _side_label_text()
			return Vector2(pad * 3.0 + icon_px + _text_width(stext, fsize), h)
		"gold":
			var gw := icon_px + pad * 2.0
			var amount = symbol.get("amount", null)
			if amount != null:
				gw += _text_width(_gold_amount_text(amount), fsize) + pad
			return Vector2(gw, h)
		_:
			return Vector2(icon_px + pad * 2.0, h)


## ---------------------------------------------------------------------------
## 텍스트 생성 — _compute_size()와 _draw_*_symbol() 양쪽이 같은 함수를 불러써야
## 크기와 실제 그림이 어긋나지 않는다(단일 진실 소스).
## ---------------------------------------------------------------------------

func _value_text() -> String:
	var op: String = symbol.get("op", "+")
	match op:
		"+":
			var amount: int = int(symbol.get("amount", 1))
			var s := ("+%d" % amount) if amount >= 0 else str(amount)
			if symbol.has("max"):
				s += "(≤%s)" % str(symbol.get("max"))
			return s
		"×":
			return "×%d" % int(symbol.get("amount", 2))
		"max":
			return "MAX"
		"half":
			return "½"
		"full":
			return "FULL"
		_:
			return op.to_upper()


func _duration_text() -> String:
	match symbol.get("kind", "every_turn"):
		"every_turn":
			return "매턴"
		"first_turn":
			return "1ST"
		"once":
			return "1회"
		_:
			return String(symbol.get("kind", ""))


func _side_label_text() -> String:
	match symbol.get("type", ""):
		"reroll":
			return "×%d" % int(symbol.get("count", 1))
		"stack":
			return "/%d" % int(symbol.get("threshold", 3))
		"swap":
			return "×%d" % int(symbol.get("count", 1))
		"cycle":
			return "%d턴" % int(symbol.get("turns", 2))
		_:
			return ""


func _gold_amount_text(amount) -> String:
	var v: int = int(amount)
	return ("+%d" % v) if v >= 0 else str(v)


func _condition_label() -> String:
	var kind: String = symbol.get("kind", "")
	var op: String = symbol.get("op", "")
	var value = symbol.get("value", null)
	match kind:
		"first_turn":
			return "첫턴"
		"hp_half":
			return "½HP"
		"round_change":
			return "라운드"
		"perfect_block":
			return "완전방어"
		"overguard":
			return "초과방어"
		"dice_cap":
			return "가득"
		"material":
			return "재질"
		"gold":
			return ("%d마다" % int(value)) if value != null else "골드"
		"dice_total", "pip_inventory", "dice_type_count":
			return ("%s%s" % [op, str(value)]) if value != null else kind
		_:
			return kind


func _condition_icon_name() -> String:
	match symbol.get("kind", ""):
		"hp_half":
			return "hp"
		"gold":
			return "gold"
		"pip_inventory":
			return "pip"
		"dice_total", "dice_cap", "dice_type_count":
			return "dice"
		_:
			return ""


func _text_width(text: String, fsize: int) -> float:
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x


## ---------------------------------------------------------------------------
## 기호 종류별 그리기
## ---------------------------------------------------------------------------

func _die_rect() -> Rect2:
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	return Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px))


func _draw_die_symbol() -> void:
	var target: String = symbol.get("target", "attack")
	var rect := _die_rect()
	match target:
		"attack":
			_draw_die_icon(rect, "attack", COLOR_ATTACK)
		"defense":
			_draw_die_icon(rect, "defense", COLOR_DEFENSE)
		"event":
			_draw_hexagon_shape(rect, COLOR_EVENT)
		_:
			_draw_split_diamond_shape(rect, COLOR_ATTACK, COLOR_DEFENSE)
	var count: int = int(symbol.get("count", 1))
	if count > 1:
		_draw_count_badge(rect, count)


func _draw_compare_symbol() -> void:
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var h := size.y
	var fsize: int = FONT_PX[size_variant]
	var left_target: String = symbol.get("left", "attack")
	var right_target: String = symbol.get("right", "defense")
	var op: String = symbol.get("op", ">")
	var op_w := _text_width(op, fsize) + pad
	var left_rect := Rect2(Vector2(pad, (h - icon_px) * 0.5), Vector2(icon_px, icon_px))
	var op_rect := Rect2(Vector2(pad * 2.0 + icon_px, 0.0), Vector2(op_w, h))
	var right_rect := Rect2(Vector2(pad * 3.0 + icon_px + op_w, (h - icon_px) * 0.5), Vector2(icon_px, icon_px))
	_draw_die_icon(left_rect, left_target, COLOR_ATTACK if left_target == "attack" else COLOR_DEFENSE)
	_draw_centered_text(op_rect, op, fsize, TEXT_COLOR)
	_draw_die_icon(right_rect, right_target, COLOR_ATTACK if right_target == "attack" else COLOR_DEFENSE)


func _draw_condition_symbol() -> void:
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var rect := Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px))
	var icon_name := _condition_icon_name()
	if icon_name != "":
		_draw_die_icon(rect, icon_name, COLOR_CONDITION)
	else:
		match symbol.get("kind", ""):
			"material":
				_draw_diamond_shape(rect, COLOR_CONDITION)
			"first_turn":
				_draw_numeral_badge(rect, "1", COLOR_CONDITION)
			"round_change":
				_draw_clock_shape(rect, COLOR_CYCLE)
			"perfect_block":
				_draw_die_icon(rect, "defense", COLOR_CONDITION)
			"overguard":
				_draw_die_icon(rect, "defense", COLOR_CONDITION)
			_:
				_draw_numeral_badge(rect, "?", COLOR_CONDITION)
	var text := _condition_label()
	if text != "":
		var text_rect := Rect2(Vector2(rect.position.x + icon_px + pad, 0.0), Vector2(max(size.x - icon_px - pad * 3.0, 0.0), size.y))
		_draw_left_text(text_rect, text, FONT_PX[size_variant], TEXT_COLOR)


func _draw_arrow_symbol() -> void:
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var art := _load_diagram_shape_art("arrow", TEXT_COLOR)
	if art != null:
		draw_texture_rect(art, Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px)), false)
		return
	var y := size.y * 0.5
	var line_end: float = pad + icon_px * 0.9
	draw_line(Vector2(pad, y), Vector2(line_end, y), TEXT_COLOR, 2.0)
	var head := PackedVector2Array([
		Vector2(line_end, y - icon_px * 0.22),
		Vector2(line_end, y + icon_px * 0.22),
		Vector2(line_end + icon_px * 0.3, y),
	])
	draw_colored_polygon(head, TEXT_COLOR)


func _draw_value_symbol() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect.grow(-1.0), Color(0.3, 0.27, 0.12, 0.9), true)
	_draw_centered_text(rect, _value_text(), FONT_PX[size_variant], TEXT_COLOR)
	if bool(symbol.get("ignore_defense", false)):
		var badge_size: float = ICON_PX[size_variant] * 0.5
		var badge_rect := Rect2(rect.position + Vector2(rect.size.x - badge_size - 1.0, 1.0), Vector2(badge_size, badge_size))
		_draw_shield_shape(badge_rect, COLOR_DEFENSE.darkened(0.35))
		draw_line(badge_rect.position, badge_rect.position + badge_rect.size, Color(0.92, 0.25, 0.22), 1.6)


func _draw_duration_symbol() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	_draw_centered_text(rect, _duration_text(), FONT_PX[size_variant], TEXT_COLOR)


func _draw_reroll_symbol() -> void:
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var rect := Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px))
	_draw_reroll_shape(rect, COLOR_REROLL)
	var text_rect := Rect2(Vector2(rect.position.x + icon_px + pad, 0.0), Vector2(max(size.x - icon_px - pad * 3.0, 0.0), size.y))
	_draw_left_text(text_rect, _side_label_text(), FONT_PX[size_variant], TEXT_COLOR)


func _draw_stack_symbol() -> void:
	var target: String = symbol.get("target", "attack")
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var rect := Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px))
	var color := COLOR_STACK_ATTACK if target == "attack" else COLOR_STACK_DEFENSE
	if target == "attack":
		_draw_burst_shape(rect, color)
	else:
		_draw_layered_shield_shape(rect, color)
	var text_rect := Rect2(Vector2(rect.position.x + icon_px + pad, 0.0), Vector2(max(size.x - icon_px - pad * 3.0, 0.0), size.y))
	_draw_left_text(text_rect, _side_label_text(), FONT_PX[size_variant], TEXT_COLOR)


func _draw_swap_symbol() -> void:
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var rect := Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px))
	_draw_swap_shape(rect, COLOR_SWAP)
	var text_rect := Rect2(Vector2(rect.position.x + icon_px + pad, 0.0), Vector2(max(size.x - icon_px - pad * 3.0, 0.0), size.y))
	_draw_left_text(text_rect, _side_label_text(), FONT_PX[size_variant], TEXT_COLOR)


func _draw_cycle_symbol() -> void:
	var target: String = symbol.get("target", "attack")
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var rect := Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px))
	_draw_clock_shape(rect, COLOR_CYCLE)
	var text_rect := Rect2(Vector2(rect.position.x + icon_px + pad, 0.0), Vector2(max(size.x - icon_px - pad * 3.0, 0.0), size.y))
	_draw_left_text(text_rect, _side_label_text(), FONT_PX[size_variant], TEXT_COLOR)
	var dot_r: float = icon_px * 0.14
	var dot_color := COLOR_ATTACK if target == "attack" else COLOR_DEFENSE
	draw_circle(rect.position + rect.size - Vector2(dot_r, dot_r), dot_r, dot_color)


func _draw_gold_symbol() -> void:
	var icon_px: float = ICON_PX[size_variant]
	var pad: float = PAD[size_variant]
	var rect := Rect2(Vector2(pad, (size.y - icon_px) * 0.5), Vector2(icon_px, icon_px))
	_draw_die_icon(rect, "gold", COLOR_GOLD)
	var amount = symbol.get("amount", null)
	if amount != null:
		var text_rect := Rect2(Vector2(rect.position.x + icon_px + pad, 0.0), Vector2(max(size.x - icon_px - pad * 3.0, 0.0), size.y))
		_draw_left_text(text_rect, _gold_amount_text(amount), FONT_PX[size_variant], TEXT_COLOR)


func _draw_unknown_symbol() -> void:
	_draw_numeral_badge(Rect2(Vector2.ZERO, size), "?", COLOR_CONDITION)


## ---------------------------------------------------------------------------
## 아이콘 로딩 (파일 우선) / 절차적 폴백 도형 — SkillIcon과 같은 "있으면 쓰고 없으면
## draw_*" 원칙.
## ---------------------------------------------------------------------------

## [대형 기획 17] S-1.5(2026-10-28) — die/compare/condition/gold는 이미 _draw_die_icon()이
## resources/ui/icon/(여러 화면이 공유하는 기능 아이콘 세트)로 "있으면 아트, 없으면 도형"을
## 하고 있다. 그 세트에 없는 나머지 도식 전용 모양(이벤트 육각형/재질 마름모/재굴림/스택
## (공격·방어)/맞바꾸기/주기/화살표 — 11종 발주 목록은 docs/STATUS.md 참고)은 별도 폴더
## resources/ui/diagram/<shape>.png를 같은 원칙(흰 실루엣+알파를 symbol 색으로 틴트)으로
## 확인한다. 파일이 없으면(지금은 전부 이 상태) null을 돌려줘 호출부가 기존 절차적
## draw_*_shape()로 그대로 폴백한다.
static var _diagram_shape_art_cache: Dictionary = {}

func _load_diagram_shape_art(shape_name: String, tint: Color) -> Texture2D:
	var key := "%s|%s" % [shape_name, tint.to_html(true)]
	if _diagram_shape_art_cache.has(key):
		return _diagram_shape_art_cache[key]
	var path := "res://resources/ui/diagram/%s.png" % shape_name
	var tex: Texture2D = null
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			img.convert(Image.FORMAT_RGBA8)
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					img.set_pixel(x, y, Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a))
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_diagram_shape_art_cache[key] = tex
	return tex


func _draw_die_icon(rect: Rect2, icon_name: String, color: Color) -> void:
	var tex := UIKit.icon_texture(icon_name, color)
	if tex != null:
		draw_texture_rect(tex, rect, false)
		return
	match icon_name:
		"attack":
			_draw_sword_shape(rect, color)
		"defense":
			_draw_shield_shape(rect, color)
		"hp":
			_draw_heart_shape(rect, color)
		"gold":
			_draw_coin_shape(rect, color)
		"pip":
			_draw_dot_shape(rect, color)
		"dice":
			_draw_dice_shape(rect, color)
		_:
			draw_rect(rect, color, false, 1.5)


func _draw_sword_shape(rect: Rect2, color: Color) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	draw_rect(Rect2(x0 + w * 0.42, y0 + h * 0.46, w * 0.16, h * 0.4), color)
	var head := PackedVector2Array([
		Vector2(x0 + w * 0.5, y0 + h * 0.04),
		Vector2(x0 + w * 0.82, y0 + h * 0.5),
		Vector2(x0 + w * 0.18, y0 + h * 0.5),
	])
	draw_colored_polygon(head, color)


func _draw_shield_shape(rect: Rect2, color: Color) -> void:
	var x0 := rect.position.x
	var y0 := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	var pts := PackedVector2Array([
		Vector2(x0 + w * 0.5, y0 + h * 0.04),
		Vector2(x0 + w * 0.86, y0 + h * 0.2),
		Vector2(x0 + w * 0.86, y0 + h * 0.52),
		Vector2(x0 + w * 0.5, y0 + h * 0.96),
		Vector2(x0 + w * 0.14, y0 + h * 0.52),
		Vector2(x0 + w * 0.14, y0 + h * 0.2),
	])
	draw_colored_polygon(pts, color)


func _draw_hexagon_shape(rect: Rect2, color: Color) -> void:
	var art := _load_diagram_shape_art("event", color)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	var center := rect.get_center()
	var r: float = min(rect.size.x, rect.size.y) * 0.48
	var pts := PackedVector2Array()
	for i in range(6):
		var angle: float = TAU * i / 6.0 - PI / 2.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(pts, color)


func _draw_split_diamond_shape(rect: Rect2, color_a: Color, color_b: Color) -> void:
	var art := _load_diagram_shape_art("split", color_a)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	var x0 := rect.position.x
	var y0 := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	var left := PackedVector2Array([
		Vector2(x0 + w * 0.5, y0 + h * 0.04),
		Vector2(x0 + w * 0.5, y0 + h * 0.96),
		Vector2(x0 + w * 0.06, y0 + h * 0.5),
	])
	draw_colored_polygon(left, color_a)
	var right := PackedVector2Array([
		Vector2(x0 + w * 0.5, y0 + h * 0.04),
		Vector2(x0 + w * 0.5, y0 + h * 0.96),
		Vector2(x0 + w * 0.94, y0 + h * 0.5),
	])
	draw_colored_polygon(right, color_b)


func _draw_heart_shape(rect: Rect2, color: Color) -> void:
	var lobe_r := rect.size.x * 0.24
	draw_circle(rect.position + Vector2(rect.size.x * 0.32, rect.size.y * 0.38), lobe_r, color)
	draw_circle(rect.position + Vector2(rect.size.x * 0.68, rect.size.y * 0.38), lobe_r, color)
	var tip := PackedVector2Array([
		rect.position + Vector2(rect.size.x * 0.12, rect.size.y * 0.42),
		rect.position + Vector2(rect.size.x * 0.88, rect.size.y * 0.42),
		rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.92),
	])
	draw_colored_polygon(tip, color)


func _draw_coin_shape(rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	var r: float = min(rect.size.x, rect.size.y) * 0.44
	draw_circle(center, r, color)
	draw_arc(center, r * 0.6, 0.0, TAU, 12, color.darkened(0.35), 1.4)


func _draw_dot_shape(rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	var r: float = min(rect.size.x, rect.size.y) * 0.3
	var pts := PackedVector2Array([
		center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0),
	])
	draw_colored_polygon(pts, color)


func _draw_dice_shape(rect: Rect2, color: Color) -> void:
	var r := rect.grow(-rect.size.x * 0.08)
	draw_rect(r, color, false, 2.0)
	draw_circle(r.get_center(), r.size.x * 0.09, color)


func _draw_diamond_shape(rect: Rect2, color: Color) -> void:
	var art := _load_diagram_shape_art("material", color)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	var center := rect.get_center()
	var hw := rect.size.x * 0.4
	var hh := rect.size.y * 0.4
	var pts := PackedVector2Array([
		center + Vector2(0, -hh), center + Vector2(hw, 0), center + Vector2(0, hh), center + Vector2(-hw, 0),
	])
	draw_colored_polygon(pts, color)
	var pts_inner := PackedVector2Array([
		center + Vector2(0, -hh * 0.4), center + Vector2(hw * 0.4, 0), center + Vector2(0, hh * 0.4), center + Vector2(-hw * 0.4, 0),
	])
	draw_colored_polygon(pts_inner, color.lightened(0.3))


func _draw_numeral_badge(rect: Rect2, text: String, color: Color) -> void:
	draw_rect(rect, color.darkened(0.55), true)
	draw_rect(rect, color, false, 1.6)
	var fsize: int = max(int(rect.size.y * 0.55), 7)
	_draw_centered_text(rect, text, fsize, TEXT_COLOR)


func _draw_clock_shape(rect: Rect2, color: Color) -> void:
	var art := _load_diagram_shape_art("cycle", color)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	var center := rect.get_center()
	var r: float = min(rect.size.x, rect.size.y) * 0.42
	draw_arc(center, r, 0.0, TAU, 20, color, 2.0)
	draw_line(center, center + Vector2(0, -r * 0.6), color, 2.0)
	draw_line(center, center + Vector2(r * 0.5, 0), color, 2.0)


func _draw_reroll_shape(rect: Rect2, color: Color) -> void:
	var art := _load_diagram_shape_art("reroll", color)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	var center := rect.get_center()
	var r: float = min(rect.size.x, rect.size.y) * 0.4
	draw_arc(center, r, -PI * 0.1, PI * 1.5, 20, color, 2.2)
	var head_base: Vector2 = center + Vector2(cos(-PI * 0.1), sin(-PI * 0.1)) * r
	var head := PackedVector2Array([
		head_base + Vector2(0.0, -r * 0.28),
		head_base + Vector2(r * 0.32, r * 0.02),
		head_base + Vector2(-r * 0.05, r * 0.3),
	])
	draw_colored_polygon(head, color)


func _draw_burst_shape(rect: Rect2, color: Color) -> void:
	var art := _load_diagram_shape_art("stack_attack", color)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	var center := rect.get_center()
	var outer: float = min(rect.size.x, rect.size.y) * 0.46
	var inner: float = outer * 0.42
	var points := PackedVector2Array()
	var spikes := 7
	for i in range(spikes * 2):
		var r: float = outer if i % 2 == 0 else inner
		var a: float = TAU * i / (spikes * 2.0) - PI / 2.0
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color)


func _draw_layered_shield_shape(rect: Rect2, color: Color) -> void:
	var art := _load_diagram_shape_art("stack_defense", color)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	_draw_shield_shape(rect, color)
	var center := rect.get_center() - Vector2(0, rect.size.y * 0.08)
	var r: float = min(rect.size.x, rect.size.y) * 0.22
	draw_arc(center, r, PI * 0.15, PI * 0.85, 8, color.darkened(0.45), 1.6)


func _draw_swap_shape(rect: Rect2, color: Color) -> void:
	var art := _load_diagram_shape_art("swap", color)
	if art != null:
		draw_texture_rect(art, rect, false)
		return
	var x0 := rect.position.x
	var y0 := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	var top_y := y0 + h * 0.32
	var bottom_y := y0 + h * 0.68
	draw_line(Vector2(x0 + w * 0.14, top_y), Vector2(x0 + w * 0.72, top_y), color, 2.0)
	var top_head := PackedVector2Array([
		Vector2(x0 + w * 0.72, top_y - h * 0.12),
		Vector2(x0 + w * 0.72, top_y + h * 0.12),
		Vector2(x0 + w * 0.9, top_y),
	])
	draw_colored_polygon(top_head, color)
	draw_line(Vector2(x0 + w * 0.86, bottom_y), Vector2(x0 + w * 0.28, bottom_y), color.darkened(0.2), 2.0)
	var bottom_head := PackedVector2Array([
		Vector2(x0 + w * 0.28, bottom_y - h * 0.12),
		Vector2(x0 + w * 0.28, bottom_y + h * 0.12),
		Vector2(x0 + w * 0.1, bottom_y),
	])
	draw_colored_polygon(bottom_head, color.darkened(0.2))


func _draw_centered_text(rect: Rect2, text: String, fsize: int, color: Color) -> void:
	var text_w := _text_width(text, fsize)
	var x := rect.position.x + (rect.size.x - text_w) * 0.5
	var y := rect.position.y + rect.size.y * 0.5 + fsize * 0.35
	draw_string(_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, color)


func _draw_left_text(rect: Rect2, text: String, fsize: int, color: Color) -> void:
	var y := rect.position.y + rect.size.y * 0.5 + fsize * 0.35
	draw_string(_font, Vector2(rect.position.x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, color)


func _draw_count_badge(rect: Rect2, count: int) -> void:
	var badge_r: float = rect.size.x * 0.28
	var center := rect.position + rect.size - Vector2(badge_r * 0.8, badge_r * 0.8)
	draw_circle(center, badge_r, Color(0.08, 0.08, 0.1, 0.95))
	var fsize: int = max(FONT_PX[size_variant] - 3, 7)
	var text := "%d" % count
	var tw := _text_width(text, fsize)
	draw_string(_font, center - Vector2(tw * 0.5, -fsize * 0.32), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, TEXT_COLOR)
