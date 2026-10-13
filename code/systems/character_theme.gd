class_name CharacterTheme
extends RefCounted
## INBOX.md 2026-10-13 [대형 기획 11] K-3 — 캐릭터 프로필의 hair_color/dress_color를
## 화면 전반의 UI 팔레트로 쓰기 위한 순수 유틸리티. K-1(FocusNav)/K-2(character_select
## 상세 패널)가 지금껏 고정값(FocusNav.ACCENT_DEFAULT, 회색 테두리)을 썼던 자리에
## 캐릭터별 색을 꽂을 수 있도록, "원색을 보정해 실전 배색(배경/테두리/강조/글자)으로
## 쓸 수 있는 4색 팔레트"를 만들어 돌려준다.
##
## 원색을 그대로 패널 배경에 쓰면(예: 해적의 밝은 터콰이즈 dress_color) 글자 대비가
## 무너지므로(INBOX.md 원문이 명시한 우려), panel_bg는 항상 HSV value를 낮게 눌러
## 어둡게 만들고(명도만 낮추고 색조는 유지 — "그 캐릭터 색이 배경에 희미하게 스며든
## 느낌"), accent/primary는 반대로 채도/명도를 끌어올려 어두운 배경 위에서 또렷하게
## 보이는 테두리/포커스 색으로 쓴다. text는 near-white 고정값이지만, panel_bg를 항상
## 어둡게 누른 덕에 8종 전부 대비비 4.5:1을 넉넉히 넘는다(계산은 relative_luminance/
## contrast_ratio로 테스트에서 직접 검증 가능하게 공개 함수로 뺐다 — WCAG 2.0 공식).
##
## 씬 상태를 전혀 갖지 않는 정적 함수만 제공해 dice_test.gd가 인스턴스화 없이
## 검증할 수 있다(FocusNav/CharacterProfiles와 같은 설계).

## 캐릭터가 없는 컨텍스트(아직 한 번도 RunState.reset_run()이 안 불린 경우는
## 실제로는 없지만 character_id가 ""로 들어오는 방어적 상황, 테스트 등) 또는
## 테스트 전용 화면이 중립을 원할 때 쓰는 기본 팔레트 — K-1이 쓰던 기존 고정값과
## 동일한 색으로, 이번 변경 전과 시각적으로 달라지지 않게 맞췄다.
const NEUTRAL_PRIMARY := Color(0.32, 0.32, 0.37)
const NEUTRAL_ACCENT := Color(0.3, 0.85, 0.95)
const NEUTRAL_PANEL_BG := Color(0.1, 0.1, 0.13, 0.92)
const NEUTRAL_TEXT := Color(0.85, 0.85, 0.85)

## WCAG 2.0 "4.5:1 이상"(본문 텍스트 AA 기준) — INBOX.md K-3 원문이 명시한 수치.
const MIN_TEXT_CONTRAST := 4.5

## panel_bg를 누를 명도(HSV value) — 어떤 원색이 들어와도 항상 이 값까지 어둡게
## 만든다(밝은 원색이 배경으로 그대로 쓰이는 것을 막는 핵심 장치).
const PANEL_BG_VALUE := 0.09
## accent/primary를 끌어올릴 최소 채도/명도 — 어두운 배경 위에서 흐릿해지는 색(예:
## 주술사의 거의 무채색에 가까운 어두운 보라)도 테두리로는 또렷이 보이게 한다.
const ACCENT_MIN_SATURATION := 0.55
const ACCENT_MIN_VALUE := 0.75
const PRIMARY_MIN_VALUE := 0.45
const PRIMARY_MAX_VALUE := 0.65


## sRGB 채널 하나를 WCAG 상대 휘도 계산용 선형값으로 변환.
static func _linearize(channel: float) -> float:
	if channel <= 0.03928:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)


## WCAG 2.0 relative luminance (0=검정, 1=흰색).
static func relative_luminance(c: Color) -> float:
	return 0.2126 * _linearize(c.r) + 0.7152 * _linearize(c.g) + 0.0722 * _linearize(c.b)


## WCAG 2.0 contrast ratio (1.0~21.0) — 두 색의 순서는 결과에 영향 없음.
static func contrast_ratio(c1: Color, c2: Color) -> float:
	var l1 := relative_luminance(c1)
	var l2 := relative_luminance(c2)
	var lighter: float = max(l1, l2)
	var darker: float = min(l1, l2)
	return (lighter + 0.05) / (darker + 0.05)


## 글자색 text가 배경 bg 위에서 MIN_TEXT_CONTRAST를 만족하지 못하면, text를 배경보다
## 밝은 방향으로 점점 밝혀가며(lightened) 만족하는 색을 찾는다 — panel_bg가 항상
## PANEL_BG_VALUE(0.09)로 어둡게 눌려있어 실전에서는 거의 항상 1회 안에 통과하지만,
## 팔레트 구성이 바뀌어도 대비가 깨지지 않도록 방어적으로 둔다.
static func _ensure_text_contrast(text: Color, bg: Color) -> Color:
	var result := text
	var guard := 0
	while contrast_ratio(result, bg) < MIN_TEXT_CONTRAST and guard < 20:
		result = result.lightened(0.05)
		guard += 1
	return result


## character_id -> {primary, accent, panel_bg, text} 4색 팔레트.
## - accent: hair_color/dress_color 중 더 선명한(채도×명도가 큰) 쪽을 골라 채도/명도를
##   끌어올린 색 — 포커스 테두리(FocusNav)·강조용.
## - primary: 같은 원색을 accent보다 차분하게(명도를 중간 구간으로) 눌러 평상시 패널
##   테두리/제목에 쓴다.
## - panel_bg: dress_color의 색조만 가져와 명도를 PANEL_BG_VALUE까지 어둡게 누른 배경색
##   (원색이 밝아도 배경으로 쓰면 항상 어두움이 보장됨).
## - text: near-white 고정값, panel_bg 대비 MIN_TEXT_CONTRAST(4.5) 미달 시 자동 보정.
## character_id가 빈 문자열이거나 CharacterProfiles에 없으면 NEUTRAL_* 그대로 반환.
static func ui_palette(character_id: String) -> Dictionary:
	if character_id == "":
		return {
			"primary": NEUTRAL_PRIMARY,
			"accent": NEUTRAL_ACCENT,
			"panel_bg": NEUTRAL_PANEL_BG,
			"text": NEUTRAL_TEXT,
		}
	var profile := CharacterProfiles.get_profile(character_id)
	var hair: Color = profile.get("hair_color", NEUTRAL_ACCENT)
	var dress: Color = profile.get("dress_color", NEUTRAL_PRIMARY)
	var base: Color = hair if (hair.s * hair.v) >= (dress.s * dress.v) else dress

	var accent := Color.from_hsv(base.h, max(base.s, ACCENT_MIN_SATURATION), max(base.v, ACCENT_MIN_VALUE))
	var primary := Color.from_hsv(base.h, max(base.s, 0.35), clamp(base.v, PRIMARY_MIN_VALUE, PRIMARY_MAX_VALUE))
	var panel_bg := Color.from_hsv(dress.h, clamp(dress.s * 0.5, 0.0, 0.4), PANEL_BG_VALUE, NEUTRAL_PANEL_BG.a)
	var text := _ensure_text_contrast(NEUTRAL_TEXT, panel_bg)

	return {"primary": primary, "accent": accent, "panel_bg": panel_bg, "text": text}


## panel(PanelContainer/Panel 등 "panel" 테마 슬롯을 쓰는 Control)의 테두리 색을
## character_id 팔레트 기준으로 덮어쓰는 한 줄 헬퍼(INBOX.md 원문 "화면별 하드코딩이
## 아니라 공용 헬퍼로 — 새 화면이 생겨도 한 줄로 적용되게"). 기존에 "panel" 스타일
## override가 있으면 그것을 복제해 border_color만 바꾸고(배경/여백/모서리 반경 등
## 나머지 스타일은 그대로 유지), 없으면 panel_bg/테두리 1px/모서리 6px로 새로 만든다.
## use_accent=true면 accent(더 밝은, 포커스/강조용)를, false(기본)면 primary(평상시
## 테두리용)를 쓴다.
static func apply(panel: Control, character_id: String, use_accent: bool = false) -> void:
	var palette := ui_palette(character_id)
	var color: Color = palette["accent"] if use_accent else palette["primary"]
	var existing := panel.get_theme_stylebox("panel")
	var style: StyleBoxFlat
	if existing is StyleBoxFlat:
		style = (existing as StyleBoxFlat).duplicate()
	else:
		style = StyleBoxFlat.new()
		style.bg_color = palette["panel_bg"]
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
	style.border_color = color
	panel.add_theme_stylebox_override("panel", style)
