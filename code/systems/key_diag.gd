extends CanvasLayer
## 입력 진단 표시(임시) — 2026-10-27.
##
## 사용자가 "방향키가 게임에 안 먹는다"고 계속 보고하지만, 실제 OS 키 입력을 보내는
## 하네스(scripts/qa_key_os_harness.ps1)와 창을 클릭한 뒤 방향키를 보내는 재현에서는
## 모두 정상이었다. 사용자 환경에서만 막히는 원인(에디터 내장 게임 창에서 키가 에디터로
## 가는지, 창이 OS 포커스를 못 받는지 등)을 사용자 화면에서 바로 알 수 있도록, 화면
## 왼쪽 아래에 작은 진단 줄을 띄운다.
##   - "창 포커스"가 계속 "아니오"이면 게임 창이 키보드 포커스를 못 받는 것이다
##     (에디터 내장 창이면 게임 화면을 한 번 클릭해야 한다).
##   - 키를 눌렀는데 "마지막 키"가 안 바뀌면 키 입력 자체가 게임에 도착하지 않는 것이다.
##   - "마지막 키"는 바뀌는데 선택이 안 움직이면 게임 안의 포커스 이동 문제다.
## F10으로 숨기거나 다시 보인다. QA 캡처 실행(GAME_START/GAME_QA_FRAME 환경변수가
## 있는 경우)에는 화면이 오염되지 않도록 처음부터 숨긴다. 원인이 확정되면 제거한다.

var _label: Label
var _last_key := "없음 (키를 눌러 보세요)"
var _key_count := 0
var _click_count := 0
var _accum := 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.72)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(8, 696)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	panel.add_child(_label)
	add_child(panel)
	if OS.has_environment("GAME_START") or OS.has_environment("GAME_QA_FRAME"):
		visible = false
	_refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10:
			visible = not visible
			return
		_key_count += 1
		_last_key = "%s (코드 %d)" % [OS.get_keycode_string(event.keycode), event.keycode]
		_refresh()
	elif event is InputEventMouseButton and event.pressed:
		_click_count += 1
		_refresh()


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 0.25:
		_accum = 0.0
		_refresh()


func _refresh() -> void:
	if _label == null or not visible:
		return
	var win := get_window()
	var focus_text := "예" if (win != null and win.has_focus()) else "아니오"
	var owner: Control = null
	if get_viewport() != null:
		owner = get_viewport().gui_get_focus_owner()
	var owner_text: String = str(owner.name) if owner != null else "없음"
	_label.text = "입력 진단(F10 숨김) | 창 포커스: %s | 마지막 키: %s | 키 %d회, 클릭 %d회 | 선택된 칸: %s" % [
		focus_text, _last_key, _key_count, _click_count, owner_text]
