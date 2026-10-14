class_name CharacterCardPanel
extends PanelContainer
## 캐릭터 선택 화면의 카드 패널 자체를 클릭/스페이스로 선택 가능하게 만드는 컨트롤.
##
## INBOX.md 2026-10-14 [대형 기획 12] L-1 — 기존에는 카드마다 별도 "선택" 버튼이 있었는데,
## 이제 카드 패널 전체가 클릭 영역이자 포커스 대상이다. PanelContainer는 BaseButton이
## 아니라 pressed 시그널이 없으므로, 좌클릭과 ui_accept(스페이스/Enter) 둘 다 _gui_input()
## 에서 직접 감지해 공용 "activated" 시그널로 통일한다. 포커스 이동 자체(방향키)는
## FocusNav.make_focusable()이 focus_mode=FOCUS_ALL + focus 테두리 StyleBox만 적용하고
## 엔진의 기본 포커스 탐색에 맡긴다 — 여기서는 "포커스를 받은 뒤 확정하는 것"만 담당한다.

signal activated


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## 좌클릭(InputEventMouseButton) 또는 ui_accept(스페이스/Enter) 둘 다 같은 activated로
## 통일한다 — 호출하는 쪽(character_select.gd)은 선택 로직을 한 곳에만 연결하면 된다.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		activated.emit()
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		activated.emit()


## 마우스오버 피드백(INBOX.md 원문 "hover 시 살짝 밝아지는 피드백") — 선택 강조(테두리
## 색/두께)는 character_select.gd의 _refresh_selection_highlight()가 "panel" StyleBox로
## 별도 관리하므로, 여기서는 modulate만 건드려 서로 간섭하지 않는다.
func _on_mouse_entered() -> void:
	modulate = Color(1.12, 1.12, 1.12)


func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1)
