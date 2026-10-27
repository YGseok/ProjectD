extends Node2D
## [대형 기획 17] S-0 시안 — 전투 화면 개편안(S-7b 중심, S-6). 고정 예시 데이터(플레이어
## HP 14/20, 몬스터 HP 6/10, 로그 8줄)만 쓰는 정적 시안.
##
## 반영한 기준:
## - S-7b: "전투 기록" 패널이 화면(720) 안에 완전히 들어오도록 높이를 고정하고,
##   내용이 넘치면 ScrollContainer로 내부 스크롤(기존은 높이 무제한 + 고정 y=572라
##   로그가 쌓이면 하단이 화면 밖으로 나갔음 — combat_test.gd:1655~1657 확인).
## - S-6: 장식을 FLAT_SKIN_DIR로 낮춤.

const CHARACTER_ID := "novice"

const SAMPLE_LOG := [
	"[보스전 진입] 라운드 3 최종 보스 — 타락한 기사단장이 나타났다.",
	"내 공격턴: 공격 합계 11 vs 몬스터 방어 합계 4 → 데미지 7",
	"몬스터 HP 10 → 3",
	"몬스터 공격턴: 몬스터 공격 합계 9 vs 내 방어 합계 6 → 데미지 3",
	"내 HP 20 → 17",
	"[상태] 폭발 스택 2/3 — 다음 최댓값 1회 더 필요",
	"내 공격턴: 공격 합계 8 vs 몬스터 방어 합계 5 → 데미지 3",
	"몬스터 HP 3 → 0 — 승리!",
]


var _key_overlay: KeyOverlay


func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	add_child(bg)
	CharacterTheme.apply_background(self, CHARACTER_ID)

	_build_hud()
	_build_log_panel()
	_build_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(140, 560, 440, 48), "number": 1, "label": "행동 버튼 줄(좌/우, 전투는 자동 진행)"},
	])


func _build_hud() -> void:
	var player_name := Label.new()
	player_name.text = "견습 모험가"
	player_name.position = Vector2(40, 20)
	player_name.add_theme_font_size_override("font_size", 16)
	CharacterTheme.apply_label(player_name, CHARACTER_ID, true)
	add_child(player_name)
	var player_hp := UIKit.make_hp_bar(self, 280, 24, CHARACTER_ID, MockupCommon.FLAT_SKIN_DIR)
	(player_hp["fill"] as Control).get_parent().position = Vector2(40, 48)
	player_hp["label"].text = "14 / 20"
	if player_hp["fill"] is ColorRect:
		(player_hp["fill"] as ColorRect).size.x = player_hp["fill_full_width"] * (14.0 / 20.0)

	var monster_name := Label.new()
	monster_name.text = "타락한 기사단장 (보스)"
	monster_name.position = Vector2(960, 20)
	monster_name.add_theme_font_size_override("font_size", 16)
	monster_name.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	add_child(monster_name)
	var monster_hp := UIKit.make_hp_bar(self, 280, 24, CHARACTER_ID, MockupCommon.FLAT_SKIN_DIR)
	(monster_hp["fill"] as Control).get_parent().position = Vector2(960, 48)
	monster_hp["label"].text = "6 / 10"
	if monster_hp["fill"] is ColorRect:
		(monster_hp["fill"] as ColorRect).size.x = monster_hp["fill_full_width"] * (6.0 / 10.0)


## S-7b 핵심 수정: y=100에서 시작해 높이를 440으로 고정(y=540에서 끝 — 하단 버튼 줄
## y=560 위에서 멈춤, 화면 끝 720을 넘지 않음). 내용은 ScrollContainer 안에 넣어
## 로그가 길어지면 패널 밖으로 삐져나가지 않고 안에서만 스크롤된다.
func _build_log_panel() -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.13, 0.92)
	style.set_border_width_all(1)
	style.border_color = CharacterTheme.ui_palette(CHARACTER_ID)["primary"]
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(140, 100)
	panel.size = Vector2(1000, 440)
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "전투 기록"
	title.add_theme_font_size_override("font_size", 13)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	vbox.add_child(title)
	var divider := ColorRect.new()
	divider.color = Color(0.4, 0.4, 0.44, 0.3)
	divider.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var log_box := VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 4)
	scroll.add_child(log_box)
	# 로그 8줄을 더 길게(실제 전투처럼 수십 줄까지 쌓일 수 있음을 보여주려고 반복)
	# — 스크롤이 실제로 필요한 상태를 재현.
	for repeat in 4:
		for line in SAMPLE_LOG:
			var label := Label.new()
			label.text = line
			label.add_theme_font_size_override("font_size", 13)
			label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			log_box.add_child(label)


func _build_buttons() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(140, 560)
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var next_btn := Button.new()
	next_btn.text = "다음"
	next_btn.custom_minimum_size = Vector2(140, 48)
	UIKit.style_primary_button(next_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	row.add_child(next_btn)
	for label_text in ["덱 보기", "정비"]:
		var btn := Button.new()
		btn.text = label_text
		btn.custom_minimum_size = Vector2(120, 48)
		UIKit.style_secondary_button(btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
		row.add_child(btn)
