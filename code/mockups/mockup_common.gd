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


## ---------------------------------------------------------------------------
## [대형 기획 17] S-0 재작업(2026-10-28, 반려 후 재시도) — 아래부터는 "실제 씬을
## 인스턴스화한 뒤 패치"하는 새 접근을 위한 공용 헬퍼. 1단계(최초 시도)는 화면을
## 처음부터 다시 그려 고정 예시 데이터만 보여줬는데, 감독 검수에서 "내용 대부분이
## 빠진 와이어프레임"으로 반려됐다 — 실제 캐릭터 8명, 능력치, 배경 원화, 던전 입장
## 버튼 등이 전부 사라져 있었다. 재작업은 code/scenes/의 실제 .tscn을 그대로
## instantiate()해 자식으로 붙이고, 그 노드 트리를 찾아가 VISUAL_STANDARD.md가 요구하는
## 자리만 고친다 — 실제 씬 파일(code/scenes/*.tscn/.gd)은 전혀 수정하지 않는다.
## ---------------------------------------------------------------------------

## 노드 트리를 재귀로 훑어 predicate(node)가 true인 노드를 전부 out에 모은다. 커스텀
## class_name(SkillIcon/FamilyIcon/RewardIcon 등)은 get_class()로 못 찾으므로(엔진
## 기본 클래스만 돌려줌), 호출부가 `func(n): return n is SkillIcon` 같은 Callable로
## 직접 타입을 검사한다.
static func find_nodes(root: Node, predicate: Callable, out: Array) -> void:
	if predicate.call(root):
		out.append(root)
	for child in root.get_children():
		find_nodes(child, predicate, out)


## 텍스트가 target과 정확히 일치하는 첫 Label(또는 RichTextLabel의 text)을 찾는다 —
## "하나만 선택" 같은 문구를 하드코딩 경로 없이 지우거나 바꿀 때 쓴다.
static func find_label_with_text(root: Node, target: String) -> Node:
	if (root is Label and (root as Label).text == target) \
			or (root is RichTextLabel and (root as RichTextLabel).text == target):
		return root
	for child in root.get_children():
		var found := find_label_with_text(child, target)
		if found != null:
			return found
	return null


## S-2/S-6 장식 방향 A/B안 — 실제 화면에 이미 떠 있는 버튼(스킨까지 이미 입혀진 상태)을
## 그 자리에서 다시 스킨한다. A안: 기존 이미지 스킨은 그대로 두고 글자 쪽만 고친다
## (외곽선+배경 패드로 대비 보강, VISUAL_STANDARD.md 2절 "선택지 (b)"). B안: 장식
## 자체를 낮춘 얇은 테두리 플랫 버튼(FLAT_SKIN_DIR 트릭, 1단계 시안과 동일한 근사).
static func restyle_button(btn: Button, character_id: String, primary: bool, variant: String, tint: Color = Color(0, 0, 0, 0)) -> void:
	if variant == "B":
		if primary:
			UIKit.style_primary_button(btn, character_id, tint, FLAT_SKIN_DIR)
		else:
			UIKit.style_secondary_button(btn, character_id, tint, FLAT_SKIN_DIR)
		return
	# A안: 스킨 유지 + 글자 자체를 더 또렷하게(외곽선 + 살짝 큰 폰트) — 장식 텍스처의
	# 밝기 편차 때문에 글자가 묻히는 문제(VISUAL_STANDARD.md 2절 실측)를 글자 쪽
	# 보강으로 상쇄한다.
	if primary:
		UIKit.style_primary_button(btn, character_id, tint)
	else:
		UIKit.style_secondary_button(btn, character_id, tint)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	btn.add_theme_constant_override("outline_size", 3)
	var cur_size: int = btn.get_theme_font_size("font_size")
	btn.add_theme_font_size_override("font_size", max(cur_size, 15))


## S-7 아이콘 비율 패치 — 이미 트리에 붙어 있는 RewardIcon/FamilyIcon(Control+_draw(),
## TextureRect가 아니라 늘림 방지 옵션이 없음, VISUAL_STANDARD.md 6-2 원인 설명)이
## HBoxContainer의 기본 SIZE_FILL 때문에 세로로 늘어나는 것을 막는다 — 컨테이너가 강제로
## 늘리지 못하게 SHRINK_CENTER로 고정(본 구현 때 UIKit.draw_icon_keep_aspect()로 갈아낄
## 자리를 이 패치가 근사).
static func fix_icon_aspect(icon: Control) -> void:
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
