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
## 상황 설명 문구("flavor" 필드, 2026-09-16) 전용 색 — 기계적 효과 설명(DESC_COLOR)과
## 구별되게 살짝 누런 양피지 톤을 준다. EventItemPool.ITEMS만 이 필드를 쓰므로
## DiceItemPool 기반 카드(상점/전투 보상)에는 아무 영향 없음.
const FLAVOR_COLOR := Color(0.72, 0.68, 0.55)
## INBOX.md 2026-09-14 "보상 팝업/상점 입장 시 설명 텍스트가 너무 길어 잘 안읽힌다.
## 이미지를 키우고 해당 이미지 위주로 설명해 직관성을 높인다" 반영 — 다이스 면 미리보기
## 칩을 키워서(16->24) 이미지가 카드의 시각적 중심이 되게 하고, 아래 desc 관련 상수들로
## 설명 텍스트는 보조 정보로 축소했다.
const PREVIEW_CHIP_SIZE := 30.0
# 구매 불가(골드 부족) 상태의 카드 색 — INBOX.md(2026-09-14) "골드 부족 버튼이 너무 많이
# 나온다. 선택 불가능한 품목은 패널 색상을 다르게 하여 비활성 상태임을 알려주는 게 좋을
# 듯" 반영. 버튼마다 "골드 부족" 텍스트를 반복하는 대신 카드 전체를 어둡게/채도 낮게
# 칠하고, 상단에 상태 배지 하나만 보여준다.
const CARD_BG_UNAFFORDABLE := Color(0.09, 0.09, 0.1, 0.97)
const CARD_BORDER_UNAFFORDABLE := Color(0.35, 0.32, 0.3)
const STATUS_BADGE_COLOR := Color(0.85, 0.4, 0.4)

# 보상 등급(S/A/B/C, INBOX.md 2026-09-14) 색상 — "녹색<파란색<보라색<노란색"으로 가치
# 상승을 표현하라는 지시를 그대로 반영. 등급별 실제 아이템 배정은 dice_item_pool.gd/
# event_item_pool.gd의 "grade" 필드 주석 참고(잠정값, 사람 피드백 필요).
const GRADE_COLORS := {
	"C": Color(0.45, 0.82, 0.45),
	"B": Color(0.45, 0.65, 0.95),
	"A": Color(0.72, 0.48, 0.95),
	"S": Color(0.95, 0.82, 0.25),
}
const DEFAULT_GRADE := "C"
const GRADE_BADGE_TEXT_COLOR := Color(0.08, 0.08, 0.08)


## item에 "grade" 필드가 없거나 알 수 없는 값이면 DEFAULT_GRADE(C) 색으로 폴백한다.
static func grade_color(grade: String) -> Color:
	return GRADE_COLORS.get(grade, GRADE_COLORS[DEFAULT_GRADE])


## item: DiceItemPool/EventItemPool 아이템 딕셔너리 (최소 "name"/"description" 필요).
## extra_label_text: 제목 밑에 작게 덧붙일 보조 문구(예: 상점의 "20 골드"). 빈 문자열이면
## 생략.
## unaffordable: true면 카드 배경/테두리를 어둡게 칠하고, 가격 라벨과 같은 줄에 "골드 부족"
## 배지를 붙인다(구매 가능 여부는 화면마다 골드 비교로 판정해 넘겨준다 — 이 헬퍼는 표시만
## 담당). 배지를 별도 줄로 추가하지 않는 이유는 카드 자연 높이가 늘어나 2행 그리드에서
## 아래 행 카드와 겹치기 때문 — 아래 구현 참고.
## 반환값의 "card"를 add_child()로 씬에 붙이고 position/size를 지정한 뒤,
## "button_row"에 버튼을 add_child()로 추가하면 카드 안에 세로로 쌓인다(VBoxContainer라
## 폭은 카드에 맞춰 자동으로 늘어남, 버튼 높이는 각자 custom_minimum_size로 지정할 것).
static func build_card(item: Dictionary, extra_label_text: String = "", unaffordable: bool = false) -> Dictionary:
	var grade: String = item.get("grade", DEFAULT_GRADE)
	var gcolor := grade_color(grade)

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG_UNAFFORDABLE if unaffordable else CARD_BG
	style.border_color = CARD_BORDER_UNAFFORDABLE if unaffordable else gcolor
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

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.add_child(_build_grade_badge(grade, gcolor))
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = item["name"]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", TITLE_COLOR if unaffordable else gcolor)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	# "골드 부족" 배지는 가격 라벨과 같은 줄(HBoxContainer)에 붙인다 — 별도 줄로 추가하면
	# 카드 자연 높이가 늘어나 2행 그리드에서 아래 행 카드와 겹치는 회귀가 생겼었다(이번
	# 이터레이션 중 실제로 발견해 이 방식으로 고침). 가격 표시가 없는 카드(extra_label_text
	# 빈 문자열)에서 unaffordable인 경우는 지금 없지만, 대비해 그 경우엔 배지만 있는 줄을
	# 만든다.
	if extra_label_text != "" or unaffordable:
		var extra_row := HBoxContainer.new()
		extra_row.add_theme_constant_override("separation", 10)
		if extra_label_text != "":
			var extra := Label.new()
			extra.text = extra_label_text
			extra.add_theme_font_size_override("font_size", 14)
			extra.add_theme_color_override("font_color", EXTRA_COLOR)
			extra_row.add_child(extra)
		if unaffordable:
			var status := Label.new()
			status.text = "골드 부족"
			status.add_theme_font_size_override("font_size", 14)
			status.add_theme_color_override("font_color", STATUS_BADGE_COLOR)
			extra_row.add_child(status)
		vbox.add_child(extra_row)

	# 상황 설명 문구(flavor) — 있으면 이미지/기계적 설명보다 먼저 보여준다("이 아이템을
	# 얻게 된 상황"이 가장 먼저 읽혀야 자연스러움). EventItemPool.ITEMS에만 있는 필드라
	# 없는 카드(DiceItemPool 기반)는 이 블록 전체를 건너뛴다.
	var flavor_text: String = item.get("flavor", "")
	if flavor_text != "":
		var flavor := Label.new()
		flavor.text = flavor_text
		flavor.add_theme_font_size_override("font_size", 12)
		flavor.add_theme_color_override("font_color", FLAVOR_COLOR)
		flavor.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(flavor)

	# 이미지(결과 다이스 미리보기)를 설명 텍스트보다 먼저 배치 — "이미지 위주로 보여주고
	# 설명은 보조 정보로" (INBOX.md 2026-09-14). 결과가 확정적인 아이템(add_die/
	# upgrade_die)만 이 미리보기가 있고, 나머지(boost_weak_face/uniform_faces)는 여기선
	# null이라 desc가 카드에서 가장 먼저 보이는 요소로 남는다 — 이 둘은 화면(shop.gd 등)이
	# 버튼 옆에 build_effect_preview()를 따로 붙인다.
	var preview := _build_result_die_preview(item)
	if preview:
		vbox.add_child(preview)

	var desc := Label.new()
	desc.text = item["description"]
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", DESC_COLOR)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(0, 22)
	vbox.add_child(desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var button_row := VBoxContainer.new()
	button_row.add_theme_constant_override("separation", 6)
	vbox.add_child(button_row)

	return {"card": card, "vbox": vbox, "button_row": button_row}


## 등급 배지(작은 색칠된 사각형 + 글자) — 카드 왼쪽 위, 타이틀 옆에 붙는다. 등급 색은
## 항상 진짜 등급을 그대로 보여준다(골드 부족으로 카드가 어두워져도 배지 자체는 원래
## 등급 색 유지 — "지금은 못 사도 이게 좋은 아이템인지"는 계속 알 수 있어야 하므로).
static func _build_grade_badge(grade: String, gcolor: Color) -> Control:
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = gcolor
	style.set_corner_radius_all(4)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = grade
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", GRADE_BADGE_TEXT_COLOR)
	badge.add_child(label)
	return badge


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
