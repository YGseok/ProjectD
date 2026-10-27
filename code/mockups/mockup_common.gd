class_name MockupCommon
extends RefCounted
## [대형 기획 17] S-0 1단계 — 8개 화면 시안(code/mockups/*.gd)이 공유하는 헬퍼.
##
## docs/design/VISUAL_STANDARD.md가 정한 기준(상태 메시지 바 규격 7절, 키 경로 표시)을
## 시안에서 실제로 구현해보기 위한 것 — 아직 실제 게임 화면(code/scenes/)에는 적용하지
## 않는다(본 구현은 사용자 확정 후). UIKit/CharacterTheme와 같은 설계(순수 정적 함수).

## S-6("더 얇고 차분한 UI 키트") 방향을 새 아트 없이 미리 보여주기 위한 트릭 — 존재하지
## 않는 base_dir을 UIKit.style_*/make_section 등에 넘기면 이미지 스킨 로드가 전부
## 실패해(파일 없음) 기존 절차적 StyleBoxFlat 폴백으로 떨어진다("있으면 쓰고 없으면
## 절차적" 설계를 역이용). 실제 "차분한 키트"가 아트로 납품되면 이 경로는 빼고 새
## base_dir로 교체한다 — 지금은 "장식을 낮추면 이렇게 보인다"의 근사치.
const FLAT_SKIN_DIR := "res://mockups/_no_skin/"

const STATUS_BAR_BG := Color(0.33, 0.24, 0.07, 0.96)
const STATUS_BAR_BORDER := Color(0.85, 0.65, 0.25)
const STATUS_BAR_TEXT := Color(1.0, 0.95, 0.85)
## STATUS_BAR_TEXT vs STATUS_BAR_BG 대비비 — code/qa/pixel_contrast.gd --rgb로 사전 확인:
## 1.0,0.95,0.85 vs 0.33,0.24,0.07 == 9.22:1 (VISUAL_STANDARD.md 2절 기준 4.5:1 통과,
## code/qa/pixel_contrast.gd --rgb로 실측).


## VISUAL_STANDARD.md 7-2 규격의 "상태 메시지 바" — 화면 하단(기본) 고정, 조건 미충족
## 동안만 보이는 걸 전제로 호출부가 visible을 토글한다(이 함수는 만들기만).
static func make_status_bar(parent: Node, text: String, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = STATUS_BAR_BG
	style.border_color = STATUS_BAR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.position = rect.position
	panel.size = rect.size
	parent.add_child(panel)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", STATUS_BAR_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


## 1순위/2순위/3순위 표(VISUAL_STANDARD.md 3절) — 시안 코너에 작게 "이 화면의 1순위가
## 무엇인지" 범례를 달아, 리뷰어가 "1순위가 먼저 읽히는가"를 바로 비교할 수 있게 한다.
## 실제 게임 화면에는 넣지 않을 디버그 성격의 범례(시안 전용) — 그래서 작고 흐리게.
static func make_priority_tag(parent: Node, position: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 3)
	parent.add_child(label)


## S-7 아이콘 비율 원칙(VISUAL_STANDARD.md 6절) 시연용 — 정사각 슬롯 안에 원본 비율
## 유지(TextureRect의 STRETCH_KEEP_ASPECT_CENTERED + EXPAND_IGNORE_SIZE 조합이 정확히
## 이 동작이라 새 그리기 코드 없이 그대로 재사용). 텍스처가 없으면 ColorRect 플레이스홀더.
static func make_ratio_safe_icon(parent: Node, tex: Texture2D, slot: Vector2, fallback_color: Color = Color(0.5, 0.5, 0.55)) -> Control:
	if tex != null:
		var rect := TextureRect.new()
		rect.texture = tex
		rect.custom_minimum_size = slot
		rect.size = slot
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(rect)
		return rect
	var ph := ColorRect.new()
	ph.color = fallback_color
	ph.custom_minimum_size = slot
	ph.size = slot
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(ph)
	return ph
