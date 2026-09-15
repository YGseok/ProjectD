class_name KeyboardShortcuts
## 여러 화면에서 반복되는 "버튼에 숫자 단축키 배정" 패턴을 공유하는 순수 유틸리티.
##
## INBOX.md 2026-09-14: "키보드로도 조작이 되도록 키매핑 및 단축키를 추가한다" +
## "단축키가 필요한 버튼이면, 어떤 단축키를 눌러야하는지 버튼에도 표시한다"를 반영한
## 첫 조각 — 우선 "선택지 버튼 목록에 1~9 숫자 키를 순서대로 배정"하는 가장 흔한
## 패턴부터 커버한다(방향키 이동/포커스 방식 대신 숫자 직접 입력 방식을 택함 — 방
## 선택/아이템 선택/양자택일 등 대부분의 화면이 "버튼 목록 중 하나를 고른다" 형태라
## 순서 번호 하나로 충분하고, Tab 포커스 이동보다 한 번의 키 입력으로 끝나서 더 빠름).
## 씬 상태를 전혀 갖지 않는 정적 함수만 제공해 dice_test.gd가 인스턴스화 없이 그대로
## 검증할 수 있다 (다른 systems/*.gd 순수 유틸과 같은 패턴).

## "[숫자] " 접두어 패턴 — strip_hint()가 재적용 시 누적되지 않도록 기존 접두어를
## 지우는 데 쓴다.
static var _hint_regex: RegEx


static func _get_hint_regex() -> RegEx:
	if _hint_regex == null:
		_hint_regex = RegEx.new()
		_hint_regex.compile("^\\[\\d\\] ")
	return _hint_regex


## 텍스트 맨 앞에 이미 apply_hints()가 붙인 "[n] " 접두어가 있으면 지운 원본을 반환한다.
static func strip_hint(text: String) -> String:
	return _get_hint_regex().sub(text, "")


## 버튼 목록에 순서대로 "[1] ", "[2] ", ... 접두어를 붙인다. 같은 버튼에 다시 호출돼도
## (예: 화면이 다시 그려질 때마다 매번 부르는 경우) 접두어가 계속 쌓이지 않도록, 먼저
## 기존 접두어를 지운 뒤 새로 붙인다. 숫자 키는 1~9 한 자리만 쓰므로(더 큰 화면은 다른
## 조작 방식이 필요, 지금은 해당 화면 없음) 10번째부터는 접두어를 붙이지 않고 원본
## 텍스트만 남긴다 — 마우스 클릭은 항상 가능하므로 기능이 없어지는 것은 아니다.
static func apply_hints(buttons: Array[Button]) -> void:
	for i in buttons.size():
		var base_text := strip_hint(buttons[i].text)
		buttons[i].text = ("[%d] %s" % [i + 1, base_text]) if i < 9 else base_text


## InputEventKey가 숫자 1~9 키(메인 키보드 또는 넘패드) 눌림이면 0-based 인덱스를,
## 아니면 -1을 반환한다. 순수 함수라 실제 InputEventKey 없이도 dice_test.gd에서
## keycode/pressed/echo만 채운 인스턴스로 검증 가능하다.
static func digit_index(event: InputEvent) -> int:
	if not (event is InputEventKey):
		return -1
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return -1
	var keycode := key_event.keycode
	if keycode >= KEY_1 and keycode <= KEY_9:
		return keycode - KEY_1
	if keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		return keycode - KEY_KP_1
	return -1


## buttons[idx]가 존재하고, 화면에 보이고, 비활성화되지 않았을 때만 그 버튼의 pressed
## 시그널을 직접 발생시킨다 — 실제 마우스 클릭 이벤트를 흉내내는 대신 버튼이 클릭됐을
## 때와 완전히 같은 경로(연결된 콜백)를 타게 해서, 클릭과 단축키 사이에 동작이
## 어긋날 여지를 없앤다. 반환값 = 실제로 눌렀는지(호출부가 event를 소비할지 판단하거나,
## dice_test.gd가 가드 동작을 검증하는 데 씀).
static func try_press(buttons: Array[Button], idx: int) -> bool:
	if idx < 0 or idx >= buttons.size():
		return false
	var btn := buttons[idx]
	if btn == null or not is_instance_valid(btn) or not btn.visible or btn.disabled:
		return false
	btn.pressed.emit()
	return true
