class_name CustomizePanel
extends Control
## 어디서든 열 수 있는 "다이스 눈금 커스터마이징" 오버레이.
##
## 지금까지 커스터마이징(다이스 선택 -> 면 선택 -> 값 선택, 값 교체 방식 — 상한은
## 그 다이스의 면 개수)은 combat_test.gd 안에 전투 승리 보상 화면의 일부로만 있어서
## 승리 직후 그 순간에만 접근 가능했다. INBOX.md 피드백(2026-09-03) "선택지 등에서
## 내 덱을 항상 볼 수 있고, 커스터마이징도 가능해야할 것 같다"의 "커스터마이징도
## 가능해야" 부분(STATUS.md 큐 0번 "어디서든 덱 열람 + 커스터마이징")을 반영해,
## 같은 로직을 combat_test.gd 밖으로 꺼내 어느 화면에서든 붙여 쓸 수 있는 독립
## 오버레이로 만들었다. 값 교체 규칙과 시각 스타일(FaceChipStyle)은 combat_test.gd의
## 커스터마이징과 완전히 동일 — 여기서는 "어디서든 열 수 있다"는 접근성만 새로 추가.
##
## combat_test.gd의 승리 보상 커스터마이징(_show_customize_picker 등)은 그대로
## 남겨뒀다. 보상 화면은 "다이스 아이템 2종 중 선택 + 커스터마이징"이 한 화면 안에
## 공존해야 하는 문맥이라, 이 범용 오버레이로 억지로 통합하면 오히려 두 문맥(보상 선택
## 흐름 vs 언제든 여닫는 오버레이)이 뒤섞여 복잡해질 것으로 판단해 분리 상태를 유지함.
##
## 이번 이터레이션에서는 dungeon_map.tscn에만 진입점(버튼)을 붙였다. shop/event/
## story_event 화면에도 같은 방식으로 붙일 수 있지만(스크립트 하나로 완결된 노드라
## deck_panel.gd처럼 씬마다 붙이기만 하면 됨), 한 이터레이션에 너무 많이 바꾸지
## 않기 위해 다음으로 미뤘다 (docs/STATUS.md 다음 할 일 큐 참고).
##
## 별도 .tscn 없이 스크립트 하나로 완결된 Control이다 (deck_panel.gd/shape_die_chip.gd와
## 같은 패턴) — 아무 씬에나 Control 노드 하나 만들고 이 스크립트만 붙이면 동작한다.

var _ui: Array[Node] = []


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## 오버레이를 열고 1단계(다이스 선택)부터 시작한다.
func open() -> void:
	visible = true
	_show_die_picker()


func close() -> void:
	_clear_ui()
	visible = false


func _clear_ui() -> void:
	for node in _ui:
		node.queue_free()
	_ui.clear()


func _add_frame(title_text: String, height: float = 420.0) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.position = Vector2(140, 120)
	bg.size = Vector2(1000, height)
	add_child(bg)
	_ui.append(bg)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(170, 140)
	title.size = Vector2(940, 30)
	add_child(title)
	_ui.append(title)


## 1단계: 공격/방어 주머니의 다이스 중 하나를 고른다.
func _show_die_picker() -> void:
	_clear_ui()
	_add_frame("커스터마이징: 강화할 다이스를 고르세요")

	var y := 190.0
	y = _add_die_rows("공격", RunState.player_attack_bag, y)
	y = _add_die_rows("방어", RunState.player_defense_bag, y)

	var close_btn := Button.new()
	close_btn.text = "닫기"
	close_btn.position = Vector2(200, y + 10)
	close_btn.size = Vector2(160, 40)
	close_btn.pressed.connect(close)
	add_child(close_btn)
	_ui.append(close_btn)


func _add_die_rows(bag_label: String, bag: DiceBag, y: float) -> float:
	for i in bag.dice.size():
		var faces: PackedInt32Array = bag.dice[i]
		var btn := Button.new()
		btn.text = "%s %d" % [bag_label, i + 1]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("h_separation", 0)
		btn.position = Vector2(200, y)
		btn.size = Vector2(1080 - 200, 46)
		btn.pressed.connect(_show_face_picker.bind(bag, i))
		add_child(btn)
		_ui.append(btn)

		var chip_x := 270.0
		var chip_size := 32.0
		var max_value := faces.size()
		for v in faces:
			var chip := FaceChipStyle.make_chip(v, chip_size, false, v == max_value)
			chip.position = Vector2(chip_x, y + (46 - chip_size) / 2.0)
			add_child(chip)
			_ui.append(chip)
			chip_x += chip_size + 6.0
		y += 54.0
	return y


## 2단계: 고른 다이스의 면 하나를 고른다 (값은 3단계에서 정한다).
func _show_face_picker(bag: DiceBag, die_index: int) -> void:
	_clear_ui()
	_add_frame("강화할 면을 고르세요 (전체 면 구성)", 480.0)

	var faces: PackedInt32Array = bag.dice[die_index]
	var max_value := faces.size()
	var chip_size := 80.0
	var gap := 16.0
	var y := 210.0
	var x := 200.0
	for fi in faces.size():
		var caption := Label.new()
		caption.text = "면 %d" % (fi + 1)
		caption.position = Vector2(x, y - 26)
		caption.size = Vector2(chip_size, 22)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(caption)
		_ui.append(caption)

		var btn := Button.new()
		btn.text = str(faces[fi])
		btn.position = Vector2(x, y)
		FaceChipStyle.style_button(btn, chip_size, false, faces[fi] == max_value)
		btn.pressed.connect(_show_value_picker.bind(bag, die_index, fi))
		add_child(btn)
		_ui.append(btn)

		x += chip_size + gap
		if x > 1000.0:
			x = 200.0
			y += chip_size + 46.0

	var back_btn := Button.new()
	back_btn.text = "뒤로"
	back_btn.position = Vector2(200, y + chip_size + 24)
	back_btn.size = Vector2(160, 40)
	back_btn.pressed.connect(_show_die_picker)
	add_child(back_btn)
	_ui.append(back_btn)


## 3단계: 고른 면에 넣을 값을 1..(면 개수) 범위에서 직접 고른다 (교체 방식 — 더하는
## 것이 아님, 상한은 그 다이스의 면 개수). combat_test.gd의 커스터마이징과 동일한 규칙.
func _show_value_picker(bag: DiceBag, die_index: int, face_index: int) -> void:
	_clear_ui()
	var faces: PackedInt32Array = bag.dice[die_index]
	var max_value: int = faces.size()
	_add_frame("면 %d에 넣을 값을 고르세요 (현재값 %d, 최대 %d)" % [face_index + 1, faces[face_index], max_value], 480.0)

	var chip_size := 70.0
	var gap := 14.0
	var y := 210.0
	var x := 200.0
	for value in range(1, max_value + 1):
		var is_current := value == faces[face_index]
		if is_current:
			var tag := Label.new()
			tag.text = "현재"
			tag.position = Vector2(x, y - 24)
			tag.size = Vector2(chip_size, 20)
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(tag)
			_ui.append(tag)

		var btn := Button.new()
		btn.text = str(value)
		btn.disabled = is_current
		btn.position = Vector2(x, y)
		FaceChipStyle.style_button(btn, chip_size, is_current, value == max_value)
		btn.pressed.connect(_on_value_chosen.bind(bag, die_index, face_index, value))
		add_child(btn)
		_ui.append(btn)

		x += chip_size + gap
		if x > 1000.0:
			x = 200.0
			y += chip_size + 40.0

	var back_btn := Button.new()
	back_btn.text = "뒤로"
	back_btn.position = Vector2(200, y + chip_size + 24)
	back_btn.size = Vector2(160, 40)
	back_btn.pressed.connect(_show_face_picker.bind(bag, die_index))
	add_child(back_btn)
	_ui.append(back_btn)


## 값을 바로 적용하고 1단계(다이스 선택)로 돌아간다 — combat_test.gd의 보상 화면
## 흐름과 달리 여기서는 "적용 후 닫힘"이 아니라 "적용 후 계속 다른 다이스도 만질 수
## 있음"이 자연스럽다고 판단함 (전투 승리라는 1회성 이벤트가 아니라 언제든 열 수 있는
## 화면이므로, 여러 다이스를 연달아 만지고 싶을 수 있음).
func _on_value_chosen(bag: DiceBag, die_index: int, face_index: int, value: int) -> void:
	bag.set_face_value(die_index, face_index, value)
	_show_die_picker()
