class_name StatusMessageBar
extends Control
## [대형 기획 17] S-0/S-3(2026-10-28) 공용 컴포넌트 — "① 캐릭터 → ② 시작 스킬 →
## ③ 던전 입장" 같은 단계 표시 대신 쓰는 상태 메시지 바. 화면 안의 고정된 위치(보통
## 하단, 하단에 다른 고정 버튼이 있으면 상단 — VISUAL_STANDARD.md 7-2)에 두고, 지금
## 해야 할 일이 있을 때만 보이게 한다(set_message의 show_it 인자). 색/레이아웃은
## code/mockups/mockup_common.gd의 make_status_bar() 시안을 그대로 옮긴 것 — 대비
## 9.22:1 실측(code/qa/pixel_contrast.gd --rgb)으로 이미 확인됨.
##
## 호출부는 이 노드를 화면 .tscn에 Control로 배치(offset_left/top/right/bottom으로
## 자리를 고정 — 다른 요소를 가리지 않도록 빈 공간을 직접 확보)하고, 코드에서
## set_message(text, show_it)만 부르면 된다. CharacterTheme/FocusNav와 달리 이 바는
## 캐릭터 퍼스널 컬러를 따르지 않는다(경고/안내용 호박색 고정 — 어떤 캐릭터 색과도
## 항상 대비가 보장돼야 하기 때문).

const BAR_BG := Color(0.33, 0.24, 0.07, 0.96)
const BAR_BORDER := Color(0.85, 0.65, 0.25)
const BAR_TEXT := Color(1.0, 0.95, 0.85)

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = BAR_BG
	style.border_color = BAR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", BAR_TEXT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_label)


## text를 보여준다. show_it=false면(조건이 이미 충족돼 더 보여줄 안내가 없으면)
## 바 전체를 숨긴다 — 자리(offset)는 호출부가 .tscn에서 이미 비워뒀으므로, 숨겨도
## 다른 요소가 그 자리로 이동하거나 겹치지 않는다(고정 좌표 레이아웃 전제).
func set_message(text: String, show_it: bool = true) -> void:
	_label.text = text
	visible = show_it
