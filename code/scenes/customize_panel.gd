class_name CustomizePanel
extends Control
## 어디서든 열 수 있는 "다이스 눈금 커스터마이징" 오버레이.
##
## INBOX.md 피드백(2026-09-03) "주사위 눈금 바꾸는 방법을 인지하기 어렵다. 인벤토리
## 창에 눈금이 쌓이고, 해당 눈금과 주사위 눈금이 교환되는 형태여야할 것 같다"를 반영해
## 상호작용 모델을 바꿨다. 기존에는 "다이스 선택 -> 면 선택 -> 1..면개수 범위에서 원하는
## 값을 자유롭게 골라 교체"였는데, 이제는:
##   1단계) RunState.pip_inventory(정수 "눈금" 목록, 전투 승리 보상으로 쌓임)에서 눈금
##          하나를 고른다
##   2단계) 적용할 다이스(공격/방어 주머니 중 하나)를 고른다
##   3단계) 그 다이스의 면 하나를 고른다 -> 그 즉시 교환이 일어난다: 골랐던 눈금이
##          그 면에 들어가고(단, 그 다이스의 면 개수를 넘는 값은 면 개수로 잘림 — 기존
##          "값 교체, 상한 있음" 규칙 유지), 원래 그 면에 있던 값은 다시 인벤토리로
##          돌아온다(사라지지 않음 — 교환이므로).
## 자유롭게 아무 값이나 고르던 것에서 "가진 눈금만 쓸 수 있다"는 자원 제약이 생겨서,
## "눈금을 어디서 얻고 어디에 쓰는지"가 명확해지는 것을 의도함 — 이게 "인지하기 쉬움"을
## 실제로 개선하는지는 사람이 플레이해보고 판단 필요.
##
## combat_test.gd의 승리 보상 화면에 있던 자체 커스터마이징 구현(다이스/면/값 선택
## 체인)은 이 상호작용 모델 통합을 계기로 제거하고, 그 화면의 "커스터마이징" 버튼도
## 이제 이 공용 오버레이를 그대로 연다(closed 시그널로 보상 화면 흐름에 복귀).
##
## 값 교체 규칙과 시각 스타일(FaceChipStyle)은 기존과 동일 — 여기서는 "무엇을 넣을
## 수 있는지"(자유 입력 -> 보유 눈금)만 바뀌었다.
##
## 별도 .tscn 없이 스크립트 하나로 완결된 Control이다 (deck_panel.gd/shape_die_chip.gd와
## 같은 패턴) — 아무 씬에나 Control 노드 하나 만들고 이 스크립트만 붙이면 동작한다.

## 패널이 닫힐 때 발생한다. combat_test.gd처럼 "패널을 닫으면 원래 화면 흐름으로
## 돌아가야 하는" 문맥에서 이 시그널로 복귀 시점을 알 수 있다.
signal closed

var _ui: Array[Node] = []


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## 오버레이를 열고 1단계(눈금 선택)부터 시작한다.
func open() -> void:
	visible = true
	_show_pip_picker()


func close() -> void:
	_clear_ui()
	visible = false
	closed.emit()


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


## 1단계: 인벤토리에 쌓인 눈금 중 하나를 고른다. 비어있으면 눈금을 얻는 방법을
## 안내하고 닫기만 가능하게 한다.
func _show_pip_picker() -> void:
	_clear_ui()

	var chip_size := 70.0
	var gap := 14.0
	var y := 200.0
	var x := 200.0

	if RunState.pip_inventory.is_empty():
		_add_frame("커스터마이징: 인벤토리에 눈금이 없습니다")
		var msg := Label.new()
		msg.text = "전투에서 승리하면 눈금을 얻습니다. 눈금을 다이스의 면과 맞바꿔 개조할 수 있습니다."
		msg.position = Vector2(200, y)
		msg.size = Vector2(880, 60)
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(msg)
		_ui.append(msg)
		y += 80.0
	else:
		for i in RunState.pip_inventory.size():
			var value: int = RunState.pip_inventory[i]
			var btn := Button.new()
			btn.text = str(value)
			btn.position = Vector2(x, y)
			FaceChipStyle.style_button(btn, chip_size, false, false)
			btn.pressed.connect(_show_die_picker.bind(i))
			add_child(btn)
			_ui.append(btn)

			x += chip_size + gap
			if x > 1000.0:
				x = 200.0
				y += chip_size + gap
		y += chip_size + 24.0
		_add_frame("커스터마이징: 맞바꿀 눈금을 고르세요", max(220.0, y - 120.0))

	var close_btn := Button.new()
	close_btn.text = "닫기"
	close_btn.position = Vector2(200, y)
	close_btn.size = Vector2(160, 40)
	close_btn.pressed.connect(close)
	add_child(close_btn)
	_ui.append(close_btn)


## 2단계: 고른 눈금을 적용할 다이스(공격/방어 주머니 중 하나)를 고른다.
func _show_die_picker(pip_index: int) -> void:
	_clear_ui()
	var pip_value: int = RunState.pip_inventory[pip_index]
	_add_frame("눈금 [%d]을(를) 넣을 다이스를 고르세요" % pip_value)

	var y := 190.0
	y = _add_die_rows("공격", RunState.player_attack_bag, y, pip_index)
	y = _add_die_rows("방어", RunState.player_defense_bag, y, pip_index)

	var back_btn := Button.new()
	back_btn.text = "뒤로"
	back_btn.position = Vector2(200, y + 10)
	back_btn.size = Vector2(160, 40)
	back_btn.pressed.connect(_show_pip_picker)
	add_child(back_btn)
	_ui.append(back_btn)


func _add_die_rows(bag_label: String, bag: DiceBag, y: float, pip_index: int) -> float:
	for i in bag.dice.size():
		var faces: PackedInt32Array = bag.dice[i]
		var btn := Button.new()
		btn.text = "%s %d" % [bag_label, i + 1]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("h_separation", 0)
		btn.position = Vector2(200, y)
		btn.size = Vector2(1080 - 200, 46)
		btn.pressed.connect(_show_face_picker.bind(bag, i, pip_index))
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


## 3단계: 고른 다이스의 면 하나를 고르면 그 즉시 눈금과 맞바꾼다.
func _show_face_picker(bag: DiceBag, die_index: int, pip_index: int) -> void:
	_clear_ui()
	var pip_value: int = RunState.pip_inventory[pip_index]
	var faces: PackedInt32Array = bag.dice[die_index]
	var sides := faces.size()
	var applied_value: int = min(pip_value, sides)
	_add_frame("맞바꿀 면을 고르세요 (눈금 [%d] -> 적용 시 %d)" % [pip_value, applied_value], 480.0)

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
		FaceChipStyle.style_button(btn, chip_size, false, faces[fi] == sides)
		btn.pressed.connect(_on_face_chosen.bind(bag, die_index, fi, pip_index))
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
	back_btn.pressed.connect(_show_die_picker.bind(pip_index))
	add_child(back_btn)
	_ui.append(back_btn)


## 눈금 <-> 면 값을 맞바꾸고 1단계(눈금 선택)로 돌아간다. 밀려난 기존 면 값은
## 인벤토리로 돌아오므로(사라지지 않음), 여러 다이스를 연달아 만지고 싶을 때도
## 항상 최소 1개 이상의 눈금(방금 밀려난 값)을 들고 계속 진행할 수 있다.
func _on_face_chosen(bag: DiceBag, die_index: int, face_index: int, pip_index: int) -> void:
	var faces: PackedInt32Array = bag.dice[die_index]
	var sides := faces.size()
	var pip_value: int = RunState.pip_inventory[pip_index]
	var old_value: int = faces[face_index]
	var applied_value: int = min(pip_value, sides)
	bag.set_face_value(die_index, face_index, applied_value)
	RunState.pip_inventory.remove_at(pip_index)
	RunState.pip_inventory.append(old_value)
	_show_pip_picker()


## QA 전용 — 자동 스크린샷은 클릭을 흉내낼 수 없으므로 곧장 3단계(면 선택)를 열어
## 화면을 확인하기 위함. 인벤토리가 비어있으면(정상 플레이라면 승리 전엔 항상 빈 상태)
## 확인용 임시 눈금을 하나 넣어준다.
func debug_open_face_picker() -> void:
	if RunState.pip_inventory.is_empty():
		RunState.pip_inventory.append(4)
	open()
	_show_face_picker(RunState.player_attack_bag, 0, RunState.pip_inventory.size() - 1)
