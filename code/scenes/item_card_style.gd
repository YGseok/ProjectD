class_name ItemCardStyle
extends RefCounted
## 다이스 개조 아이템(DiceItemPool/EventItemPool이 쓰는 공통 딕셔너리 형식: name/
## description/kind/...) 하나를 "카드"처럼 보여주는 공용 카드 패널.
##
## INBOX.md 피드백(2026-09-01) "전투 이후, 강화 카드를 선택한다"가 지금까지
## 이름+설명 라벨과 버튼이 화면에 그냥 나열되는 목록 형태로만 구현되어 있었다
## (STATUS.md 다음 할 일 큐에 "시각적으로 카드처럼 보이지 않는다"는 간극으로 남아있던
## 부분). 전투 승리 보상(combat_test.gd)/상점(shop.gd)/특수 이벤트(event.gd) 세 화면이
## 전부 같은 아이템 딕셔너리 형식을 보여주므로, 카드 틀(제목/설명/가격 등 보조 문구/
## 버튼을 담을 영역)을 여기 한 곳에 모아 공유한다. 실제 버튼 생성·연결은 각 화면이
## 기존처럼 담당하고(적용 대상 주머니·골드 소모 등 화면마다 다른 로직이라), 이 헬퍼는
## 그 버튼들을 넣을 카드 틀만 만들어 반환한다.
##
## build_card()는 결과 다이스가 확정적인 아이템(add_die/upgrade_die)이면 카드 안에
## 그 다이스 면 모양(ShapeDieChip) 미리보기도 자동으로 넣는다 — 아래
## _build_result_die_preview() 참고. 대상 주머니에 따라 결과가 달라지는 아이템
## (boost_weak_face/uniform_faces)은 build_effect_preview(item, bag)를 각 화면이
## 버튼 옆에 개별로 붙여야 한다 — 아래 참고.

const CARD_BG := Color(0.13, 0.12, 0.17, 0.97)
const CARD_BORDER := Color(0.55, 0.45, 0.25)
const TITLE_COLOR := Color(0.95, 0.85, 0.55)
const DESC_COLOR := Color(0.82, 0.82, 0.82)
const EXTRA_COLOR := Color(1.0, 0.85, 0.35)
const PREVIEW_CHIP_SIZE := 16.0


## item: DiceItemPool/EventItemPool 아이템 딕셔너리 (최소 "name"/"description" 필요).
## extra_label_text: 제목 밑에 작게 덧붙일 보조 문구(예: 상점의 "20 골드"). 빈 문자열이면
## 생략.
## 반환값의 "card"를 add_child()로 씬에 붙이고 position/size를 지정한 뒤,
## "button_row"에 버튼을 add_child()로 추가하면 카드 안에 세로로 쌓인다(VBoxContainer라
## 폭은 카드에 맞춰 자동으로 늘어남, 버튼 높이는 각자 custom_minimum_size로 지정할 것).
static func build_card(item: Dictionary, extra_label_text: String = "") -> Dictionary:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_color = CARD_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var title := Label.new()
	title.text = item["name"]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	if extra_label_text != "":
		var extra := Label.new()
		extra.text = extra_label_text
		extra.add_theme_font_size_override("font_size", 14)
		extra.add_theme_color_override("font_color", EXTRA_COLOR)
		vbox.add_child(extra)

	var desc := Label.new()
	desc.text = item["description"]
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", DESC_COLOR)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(desc)

	var preview := _build_result_die_preview(item)
	if preview:
		vbox.add_child(preview)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var button_row := VBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	vbox.add_child(button_row)

	return {"card": card, "vbox": vbox, "button_row": button_row}


## "완성하면 어떤 주사위가 될지 예상할 수 있게" (INBOX.md 2026-09-02)를 아이템 카드에도
## 반영한다. add_die/upgrade_die 종류는 결과 다이스의 면 개수(sides/new_sides)가 이미
## 아이템 딕셔너리에 고정돼 있어(주머니 상태와 무관하게 결과가 항상 동일), 그 면 개수의
## ShapeDieChip(전투 중 다이스 결과 표시와 같은 모양/칩 스타일)을 1..N 값으로 나열해
## "이 아이템을 쓰면 이런 모양의 다이스가 생긴다"를 미리 보여줄 수 있다.
## boost_weak_face/uniform_faces는 적용 대상 다이스가 그 시점의 주머니 상태(어느 면이
## 가장 낮은가 등)에 따라 정해져 카드 생성 시점엔 결과를 확정할 수 없으므로 미리보기를
## 만들지 않는다(null 반환) — 이런 아이템은 기존처럼 설명 텍스트만으로 안내한다.
static func _build_result_die_preview(item: Dictionary) -> Control:
	var sides: int
	match item.get("kind", ""):
		"add_die":
			sides = item["sides"]
		"upgrade_die":
			sides = item["new_sides"]
		_:
			return null

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 3)
	flow.add_theme_constant_override("v_separation", 3)
	var shape_sides := ShapeDieChip.shape_sides_for_dice_sides(sides)
	for face in range(1, sides + 1):
		flow.add_child(_make_preview_chip(shape_sides, face))
	return flow


static func _make_preview_chip(shape_sides: int, value: int) -> Control:
	var chip := ShapeDieChip.new()
	chip.custom_minimum_size = Vector2(PREVIEW_CHIP_SIZE, PREVIEW_CHIP_SIZE)
	chip.size = Vector2(PREVIEW_CHIP_SIZE, PREVIEW_CHIP_SIZE)
	chip.shape_sides = shape_sides
	chip.value = value
	return chip


## boost_weak_face/uniform_faces용 버튼 옆 미리보기. `_build_result_die_preview()`와
## 달리 카드 생성 시점이 아니라 "이 버튼(공격 주머니 / 방어 주머니)을 누르면"이 정해진
## 시점에 호출한다 — bag이 정해지면 DiceItemPool.preview_effect()의 결과가 완전히
## 결정적이기 때문(그 시점 주머니 상태를 그대로 읽어 계산, RNG 없음). 항상 고정
## 크기(칩 1~2개 + 짧은 텍스트)로만 구성해, 대상 다이스의 면 개수가 커져도(D12/D20 등)
## 카드 레이아웃이 깨지지 않게 한다. 미리보기가 없으면(add_die/upgrade_die 등) null.
static func build_effect_preview(item: Dictionary, bag: DiceBag) -> Control:
	var info = DiceItemPool.preview_effect(item, bag)
	if info == null:
		return null

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var shape_sides: int = info["shape_sides"]

	match item.get("kind", ""):
		"boost_weak_face":
			row.add_child(_make_preview_chip(shape_sides, info["before"]))
			var arrow := Label.new()
			arrow.text = "→"
			arrow.add_theme_font_size_override("font_size", 12)
			arrow.add_theme_color_override("font_color", DESC_COLOR)
			row.add_child(arrow)
			row.add_child(_make_preview_chip(shape_sides, info["after"]))
		"uniform_faces":
			row.add_child(_make_preview_chip(shape_sides, info["value"]))
			var label := Label.new()
			label.text = "x%d" % int(info["face_count"])
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", DESC_COLOR)
			row.add_child(label)
		_:
			return null
	return row
