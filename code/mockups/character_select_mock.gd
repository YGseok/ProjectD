extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28, 1단계 와이어프레임 반려 후) — 캐릭터 선택
## 개편 시안.
##
## 1단계 반려 사유: 처음부터 새로 그려서 캐릭터 8명 중 4명/능력치/고유 능력/스킬 도감
## 버튼/던전 입장 버튼이 모두 빠지고 전신 원화가 뒤에 거대하게 잘려 깔렸다.
## 재작업: code/scenes/character_select.tscn을 그대로 instantiate()해 자식으로 붙이고,
## 그 실제 노드 트리 위에서 VISUAL_STANDARD.md가 요구하는 자리만 고친다 — 실제 씬
## 파일은 전혀 건드리지 않는다. "전"과 같은 데이터(8명 로스터, 실제 선택된 캐릭터의
## 진짜 능력치/원화/시작 스킬)가 "후"에도 그대로 남는다.
##
## MOCKUP_VARIANT 환경변수("A" 또는 "B", 기본 "A")로 상단 버튼 장식 방향을 고른다
## (docs/design/MOCKUP_REVIEW.md 1절 "공통 결정 질문" — A=스킨 유지+글자 보강,
## B=장식 없는 얇은 테두리). qa_shot.sh로 캡처할 때 `MOCKUP_VARIANT=B`를 미리
## export해두면(env 명령은 명시된 변수만 덮어쓰고 나머지는 부모 셸에서 상속하므로)
## 그대로 전달된다 — GAME_START_PATH를 쓰는 것과 같은 트릭.

const RealScene := preload("res://code/scenes/character_select.tscn")
## character_select.gd의 STARTING_SKILL_SLOT_WIDTH와 같은 값(실제 씬 상수를 그대로
## 베낄 수 없어 복사 — 슬롯 폭이 바뀌면 같이 맞춰야 함, 레이아웃 폭 기준값일 뿐이라
## 1~2px 어긋나도 치명적이지 않음).
const SLOT_WIDTH := 115.0

var _real: Node
var _variant: String
var _key_overlay: KeyOverlay


func _ready() -> void:
	_variant = OS.get_environment("MOCKUP_VARIANT")
	if _variant != "B":
		_variant = "A"

	_real = RealScene.instantiate()
	add_child(_real)
	# 실제 씬의 _ready()가 카드/상세 패널/시작 스킬 슬롯을 전부 그릴 시간을 한 프레임 준다.
	await get_tree().process_frame

	_patch_step_indicator_and_status_bar()
	_patch_skill_section_title()
	_patch_skill_slots()
	_patch_header_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


## GAME_QA_SETTLE 등 QA 훅이 current_scene(=이 래퍼)에서 메서드를 찾으므로, 실제 화면이
## 구현한 훅이 있으면 그대로 넘겨준다(이 화면은 물리 없음 — 항상 true).
func _qa_is_settled() -> bool:
	return true


## S-3: "① 캐릭터 → ② 시작 스킬 → ③ 던전 입장" 단계 표시를 숨기고, 그 자리(비게 된
## y=66~92 띠, StepIndicatorLabel이 쓰던 바로 그 영역)를 상태 메시지 바로 재사용한다.
## VISUAL_STANDARD.md 7-2 규격의 "하단 고정, 하단에 다른 고정 UI가 있으면 상단 고정으로
## 예외"가 정확히 이 화면 사례다 — 하단(y=680~716)은 이미 "던전 입장" 주 행동이 차지함.
func _patch_step_indicator_and_status_bar() -> void:
	var step_label: Control = _real.get_node_or_null("StepIndicatorLabel")
	if step_label != null:
		step_label.visible = false
	MockupCommon.make_status_bar(
		self,
		"방향키로 캐릭터와 시작 스킬을 고르세요 · 스페이스/Enter로 확정 · 아래 \"던전 입장\"으로 시작합니다.",
		Rect2(340, 66, 920, 34))


## S-1.3: "시작 스킬 (하나만 선택)" 문구 제거 — 선택 상태는 이미 실제 코드
## (_starting_skill_slot_style())가 금테로 표시하고 있어 그대로 둔다(새로 만들 필요 없음).
func _patch_skill_section_title() -> void:
	var title := MockupCommon.find_label_with_text(_real, "시작 스킬 (하나만 선택)")
	if title is Label:
		(title as Label).text = "시작 스킬"


## S-1.1(아이콘 슬롯 밖으로 안 터지게)/S-1.2(한 줄 효과 요약)/S-1.4(잠긴 카드 조건 문구
## 상시 노출 + 포커스 제외). _rarity_tag_by_skill_id가 skill_id -> 등급 태그 Label을
## 주므로, 그 Label의 부모 체인(icon_area -> content -> button)을 거슬러 올라가면
## skill_id와 버튼을 함께 얻을 수 있다(슬롯 버튼 목록을 따로 들고 있을 필요 없음).
func _patch_skill_slots() -> void:
	var tag_by_id: Dictionary = _real.get("_rarity_tag_by_skill_id")
	if tag_by_id == null:
		return
	for skill_id in tag_by_id.keys():
		var rarity_tag: Node = tag_by_id[skill_id]
		if rarity_tag == null or not is_instance_valid(rarity_tag):
			continue
		var icon_area: Control = rarity_tag.get_parent()
		if icon_area == null:
			continue
		# S-1.1: 슬롯 칸보다 아이콘/장식이 커도 칸 밖으로 안 터지게 클리핑(본 구현 때는
		# UIKit.draw_icon_keep_aspect()로 "여백 맞춤"으로 바꿀 자리 — 지금은 안전망).
		icon_area.clip_contents = true

		var content: Control = icon_area.get_parent()
		if content == null:
			continue
		var button: Control = content.get_parent()
		if button == null or not (button is Button):
			continue

		var locked := false
		for c in icon_area.get_children():
			if c is LockIcon:
				locked = true
				break

		if locked:
			# S-1.4: 기존엔 tooltip(호버해야만 보임)로만 있던 해금 조건을 카드 안에
			# 상시 보이는 문구로 추가하고, 잠긴 슬롯은 키보드 포커스에서 뺀다.
			(button as Button).focus_mode = Control.FOCUS_NONE
			var cond_label := Label.new()
			cond_label.text = (button as Button).tooltip_text
			cond_label.add_theme_font_size_override("font_size", 11)
			cond_label.add_theme_color_override("font_color", Color(0.82, 0.68, 0.3))
			cond_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			cond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cond_label.custom_minimum_size = Vector2(SLOT_WIDTH, 0)
			content.add_child(cond_label)
		else:
			# S-1.2: 선택된 카드 아래에만 있던 전체 문장 대신, 카드마다 실제 SkillPool
			# description(가공/요약 없이 원문)을 한 줄로 잘라 보여준다.
			var skill: Dictionary = SkillPool.find_skill(skill_id)
			var desc: String = String(skill.get("description", ""))
			if desc != "":
				var summary_label := Label.new()
				summary_label.text = desc
				summary_label.clip_text = true
				summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				summary_label.add_theme_font_size_override("font_size", 11)
				summary_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
				content.add_child(summary_label)

		# 한 줄(또는 잠긴 카드는 여러 줄) 요약을 더했으니, 카드 높이가 그 내용을 실제로
		# 담을 만큼 커지지 않으면 글자가 카드 밖으로 흘러나온다(_test_cs_crop.png에서
		# 직접 확인한 문제) — Button은 추가한 자식만큼 자동으로 커지지 않으므로 실측
		# 높이로 직접 늘린다.
		var needed_height: float = content.get_combined_minimum_size().y + 16.0
		if needed_height > button.custom_minimum_size.y:
			button.custom_minimum_size = Vector2(button.custom_minimum_size.x, needed_height)
			button.size = button.custom_minimum_size


## S-2/S-6: 아직 던전에 들어가지 않은 화면이라(DESIGN.md "플레이어블 캐릭터" K-3)
## 상단 공용 버튼은 중립색을 유지하는 기존 결정을 그대로 두고, 장식 방향(A/B)만 바꾼다.
func _patch_header_buttons() -> void:
	var buttons := [
		_real.get("monster_codex_button"),
		_real.get("achievement_button"),
		_real.get("test_battle_button"),
		_real.get("_skill_codex_button"),
	]
	for b in buttons:
		if b is Button:
			MockupCommon.restyle_button(b as Button, RunState.character_id, false, _variant, FocusNav.ACCENT_DEFAULT)
	# "던전 입장"은 K-3 원칙의 유일한 예외로 캐릭터 퍼스널 컬러를 쓰므로(primary) 따로.
	var start_btn: Button = _real.get("start_button")
	if start_btn != null:
		MockupCommon.restyle_button(start_btn, _real.get("_selected_id"), true, _variant)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(20, 100, 300, 580), "number": 1, "label": "캐릭터 목록(위/아래 순환, 밖으로 안 샘)"},
		{"rect": Rect2(340, 100, 920, 580), "number": 2, "label": "상세 패널 — 시작 스킬 3슬롯(좌/우)"},
		{"rect": Rect2(880, 24, 360, 68), "number": 3, "label": "상단 보조 버튼(좌/우)"},
		{"rect": Rect2(470, 680, 340, 36), "number": 4, "label": "던전 입장"},
	])
