class_name CustomizePanel
extends Control
## 어디서든 열 수 있는 "다이스 눈금 커스터마이징"(= 정비) 오버레이.
##
## [대형 기획 15] Q-5(16)(2026-10-17)로 UX를 통째로 재설계했다. INBOX.md 피드백
## "UX가 난해하고 줄글이라 현학적이고 지루하다"를 반영해, 기존 "눈금 선택 화면 ->
## 다이스 선택 화면 -> 면 선택 화면(그 즉시 적용)" 3단계 순차 네비게이션을 **한
## 화면**으로 합쳤다:
##   1단계) 화면 위쪽 "보유 눈금" 줄에서 눈금 하나를 고른다(다시 누르면 선택 해제).
##   2단계) 그 아래 "공격/방어 주머니"에서 다이스 면을 하나 고른다(눈금을 고르기 전엔
##          비활성화) — 면은 ShapeDieChip으로 그 다이스의 실제 모양(삼각/사각/오각)을
##          그린다(INBOX.md 원문 "shape_die_chip, 면 배열로 보여준다").
##   3단계) 면까지 고르면 화면 아래에 "미리보기"(적용 전 -> 적용 후, 바뀐 면 강조)가
##          뜨고 "적용"/"취소" 버튼이 나타난다. **이 시점까지는 아무것도 바뀌지
##          않는다** — "적용"을 눌러야 실제 교환이 일어나고, "취소"는 면 선택만 지운다
##          (눈금 선택은 유지돼 다른 면을 바로 다시 고를 수 있음).
## 세 단계가 전부 한 화면에 있어 방향키로 위/아래 훑으며 셀프 서비스로 조작할 수 있고,
## 글 설명은 한 줄짜리 진행 안내(_step_caption())뿐이다. 교환 규칙 자체(_exchange_pip,
## 값 상한 클램프)는 전혀 바뀌지 않았다 — 이 패널이 호출하는 시점과 보여주는 방식만
## 바뀌었을 뿐이다.
##
## "여분 다이스"(다이스 승급, 면 개수 자체를 바꾸는 별도 기능)는 이번 재설계 대상이
## 아니다(INBOX 원문이 "눈금 -> 면" 교환만 지목) — 기존 3단계 화면(_show_die_
## inventory_picker -> _show_die_target_picker)을 그대로 유지한다.
##
## 하위 호환: dungeon_map.gd의 QA 훅과 dice_test.gd 회귀 테스트가 예전 메서드 이름
## (_show_die_picker/_show_face_picker/_on_face_chosen)을 직접 호출한다. 전부
## 유지하되, _show_die_picker/_show_face_picker는 이제 "그 상태로 선택값을 맞춰두고
## 통합 화면을 다시 그리는" 얇은 shim이고, _on_face_chosen은 여전히 "즉시 적용"
## 동작(미리보기 없이 한 번에 선택->적용, QA/디버그 전용 지름길)을 그대로 수행한다.
##
## combat_test.gd의 승리 보상 화면에 있던 자체 커스터마이징 구현은 예전에 이미
## 제거됐고, 그 화면의 "커스터마이징" 버튼은 여전히 이 공용 오버레이를 그대로 연다.
##
## [대형 기획 15] Q-5(15): 이 패널을 여는 진입점(dungeon_map.gd의 "정비" 버튼)은 더는
## 방 선택지 목록에 있지 않다 — 헤더의 고정 버튼으로 분리됐다(dungeon_map.gd 참고).
##
## 별도 .tscn 없이 스크립트 하나로 완결된 Control이다(deck_panel.gd와 같은 패턴) —
## 아무 씬에나 Control 노드 하나 만들고 이 스크립트만 붙이면 동작한다.

## 패널이 닫힐 때 발생한다. combat_test.gd처럼 "패널을 닫으면 원래 화면 흐름으로
## 돌아가야 하는" 문맥에서 이 시그널로 복귀 시점을 알 수 있다.
signal closed

var _ui: Array[Node] = []

## [Q-5(16) 후속 — 셀프 피드백으로 발견한 버그 수정] 통합 화면이 "미리보기+적용/취소"
## 단계까지 펼쳐지면(특히 공격/방어 주머니가 DiceBag.MAX_DICE=6에 가까워질수록) 내용
## 높이가 화면(720px)을 넘어서 "닫기" 버튼과 프레임 하단이 뷰포트 밖으로 잘려 보이지도
## 눌리지도 않게 된다(실제 1280x720 캡처로 확인된 버그 — qa_out/q5_preview.png).
##
## 처음에는 DeckPanel(M-1)처럼 ScrollContainer를 썼으나, 이 패널(그리고 이 패널을
## 매다는 dungeon_map.tscn 등)의 씬 루트가 전부 Node2D라 ScrollContainer가
## NOTIFICATION_SORT_CHILDREN에서 자기 크기를 다시 계산할 때 뷰포트 기준으로
## 엉뚱한 배율(실측 2560x1440 — 1280x720의 정확히 2배, HiDPI 스케일로 추정)을
## 얻어버려 스크롤 계산이 신뢰할 수 없었다(dungeon_map.gd의 디버그 훅으로 직접
## 확인). 그래서 Container 레이아웃에 전혀 기대지 않는 수동 방식으로 바꿨다 —
## _clip(clip_contents=true인 평범한 Control, size를 직접 고정 지정)이 보이는
## 영역을 자르고, 그 안의 _content_root(마찬가지로 평범한 Control)를
## position.y만 움직여서 "스크롤"을 흉내낸다. 기존 절대좌표(Vector2(200, y) 등)
## 계산은 전혀 바꾸지 않는다(_content_root가 기본적으로 (0,0)에 있으므로 좌표계가
## 그대로 유지됨).
var _clip: Control
var _content_root: Control
var _scroll_offset := 0.0
var _content_height := SCREEN_SIZE.y

## _add_preview_section()이 매번 새로 만드는 "적용" 버튼 참조 — _show_pip_picker()가
## 이번 redraw의 기본 포커스를 고르는 데 쓴다(위 _clip 주석 참고). 미리보기가 없는
## redraw에서는 _add_preview_section 자체가 호출되지 않아 이전 값이 남을 수 있으므로,
## _show_pip_picker()가 매번 호출 전에 null로 리셋한다.
var _preview_apply_button: Button = null

## _on_face_chosen()(QA/디버그 전용 "즉시 적용" 지름길)의 이중 실행 방지 플래그.
## 같은 프레임 안에 같은 호출이 두 번 들어와도(예: 더블클릭을 흉내낸 테스트) 두 번째
## 호출은 이미 비워진 _pending_face/_selected_pip_index를 그대로 다시 바라보게
## 만들어 안전해지지만, _on_face_chosen은 bag/die_index/face_index/pip_index를
## 호출부가 직접 넘기는 "bound 인자" 방식이라(통합 화면의 버튼처럼 멤버 상태를
## 다시 읽는 게 아님) 인자 자체는 두 번째 호출에도 똑같이 유효해 보여 그대로
## _exchange_pip()을 다시 실행할 수 있다(이터레이션 48과 같은 클래스의 버그) — 이
## 플래그로 한 번만 실행되게 막는다.
var _face_chosen_locked := false

## _show_die_target_picker()가 만든 다이스 슬롯 버튼의 이중 실행 방지 플래그.
## _face_chosen_locked과 같은 이유 — 새 단계가 열릴 때마다 풀린다.
var _die_chosen_locked := false

## [Q-5(16) 신규] 지금 선택된 "보유 눈금" 인덱스. -1 = 아무것도 선택 안 됨(1단계).
var _selected_pip_index := -1

## [Q-5(16) 신규] 2단계에서 고른 교환 대상 면. 비어 있으면({}) 아직 면을 안 골랐거나
## 막 취소된 상태 — {"bag": DiceBag, "die_index": int, "face_index": int}.
var _pending_face: Dictionary = {}

## "이 면이 바뀔 예정"(미리보기의 적용 전 쪽, 주황) / "적용하면 이 값이 됨"(적용 후
## 쪽, 녹색) 강조색. FaceChipStyle의 "최댓값" 금색과 겹치지 않도록 다른 색을 쓴다.
const PENDING_HIGHLIGHT := Color(0.95, 0.55, 0.15)
const PENDING_HIGHLIGHT_BORDER := Color(0.35, 0.18, 0.0)
const APPLIED_HIGHLIGHT := Color(0.4, 0.95, 0.5)
const APPLIED_HIGHLIGHT_BORDER := Color(0.05, 0.4, 0.12)


## 이 패널(과 dungeon_map.tscn/combat_test.tscn 등 이 패널을 매다는 모든 씬)의 루트가
## Node2D라서, Control의 FULL_RECT 앵커가 "부모의 Control 크기"를 전혀 얻지 못해
## set_anchors_preset(FULL_RECT) 만으로는 size가 영원히 (0,0)으로 남는다(Node2D는
## Control이 아니라서 앵커 계산의 기준이 될 수 없고, 이 트리 구조에서는 뷰포트
## 크기로 대체되지도 않았다 — 셀프 피드백으로 ensure_control_visible()의 스크롤
## 계산이 완전히 틀어지는 것을 보고 실측 디버그 출력(panel.size=(0,0))으로 확인한
## 실제 버그). 이 프로젝트는 1280x720 고정 해상도를 이미 전제하므로(다른 QA
## 검증들도 이 값을 그대로 하드코딩) 앵커에 의존하지 않고 size를 직접 지정한다.
const SCREEN_SIZE := Vector2(1280.0, 720.0)


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = SCREEN_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP

	_clip = Control.new()
	_clip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_clip.size = SCREEN_SIZE
	_clip.clip_contents = true
	add_child(_clip)

	_content_root = Control.new()
	_content_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_clip.add_child(_content_root)


## 오버레이를 열고 선택 상태를 초기화한 뒤 통합 화면을 그린다.
##
## move_to_front(): 이 패널을 부르는 화면(dungeon_map 등)이 _ready() 이후에 자신의
## 자식 노드를 더 추가하면 그 노드들이 씬 트리에서 이 패널보다 뒤에 와서 더 나중에
## (= 위에) 그려진다 — 열릴 때마다 자신을 부모의 맨 마지막 자식으로 옮겨 항상 최상단에
## 오도록 보장한다(INBOX.md 2026-09-14 "던전 맵 커스터마이징 팝업을 띄웠는데, 전투 방
## 입장 보상 아이콘이 팝업 창을 뚫고 나온다"의 재발 방지).
func open() -> void:
	_selected_pip_index = -1
	_pending_face = {}
	move_to_front()
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
	# 화면이 바뀔 때마다(통합 화면 <-> 다이스 인벤토리 화면 등) 스크롤을 맨 위로
	# 되돌린다 — 각 _show_*_picker()가 그린 뒤 _chain_step_focus()가 다시 기본
	# 포커스를 잡으면서 필요하면 알맞은 위치로 다시 스크롤한다.
	_scroll_offset = 0.0
	if _content_root != null:
		_content_root.position = Vector2.ZERO


## Esc로 패널을 닫는다(K-1 — 오버레이 패널 공통 규칙, achievement_panel.gd와 같은 패턴).
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return
	var viewport := get_viewport()
	close()
	if viewport != null:
		viewport.set_input_as_handled()


## 이번 화면에 보이는 버튼들을 포커스가 안에 갇히는 방향키 체인(위/아래, wrap+trap)으로
## 묶고 기본 포커스를 준다. 각 _show_*_picker()가 자신의 버튼을 다 그린 뒤 마지막에
## 호출한다. preferred가 주어지고 buttons 안에 있으면 그 버튼에 포커스를 주고(그렇지
## 않으면 첫 버튼).
##
## [셀프 피드백 수정] 공격/방어 주머니가 많이 찬 후반 런에는 미리보기 단계까지 포함한
## 전체 내용이 720px를 넘어 "닫기" 버튼이 화면 밖에 묻힐 수 있다(실제 캡처
## qa_out/q5_preview.png로 발견). 각 버튼의 focus_entered에 _ensure_step_button_visible()
## 을 직접 연결해 포커스가 어디로 이동하든 그 버튼이 보이는 위치까지 수동으로
## 스크롤(_content_root.position.y 이동)시킨다 — ScrollContainer.follow_focus/
## ensure_control_visible() 둘 다 이 씬 구조(Node2D 루트 아래 Control, 모두 절대좌표
## 배치)에서는 자기 크기를 엉뚱하게 계산해 못 믿는다(dungeon_map.gd 디버그 훅으로
## scroll.size가 실제 화면의 2배(2560x1440)로 나오는 것을 직접 확인, 위 _clip 주석
## 참고) — 그래서 Container 레이아웃에 의존하지 않는 수동 clip+position 방식을 쓴다.
func _chain_step_focus(buttons: Array[Button], preferred: Button = null) -> void:
	# K-3: 포커스 강조색도 현재 캐릭터 accent로(K-1의 ACCENT_DEFAULT 대신).
	FocusNav.chain_linear(buttons, false, true, true, CharacterTheme.ui_palette(RunState.character_id)["accent"])
	for b in buttons:
		b.focus_entered.connect(_ensure_step_button_visible.bind(b))
	if preferred != null and buttons.has(preferred):
		preferred.grab_focus()
	else:
		FocusNav.grab_first_focus(buttons)


## btn이 화면(_clip.size.y, 보통 720px) 안에 들어오도록 _scroll_offset을 조정하고
## _content_root.position.y에 반영한다 — btn이 아래로 넘치면 그 아래가 보이게,
## 위로 넘치면(스크롤된 상태에서 포커스가 위로 돌아올 때) 그 위가 보이게.
func _ensure_step_button_visible(btn: Button) -> void:
	if _clip == null or not is_instance_valid(btn):
		return
	var viewport_height := _clip.size.y
	var btn_top := btn.position.y
	var btn_bottom := btn_top + btn.size.y
	if btn_bottom - _scroll_offset > viewport_height:
		_scroll_offset = btn_bottom - viewport_height
	elif btn_top - _scroll_offset < 0.0:
		_scroll_offset = btn_top
	_scroll_offset = clamp(_scroll_offset, 0.0, max(0.0, _content_height - viewport_height))
	_content_root.position.y = -_scroll_offset


## subtitle_text가 있으면 제목 아래에 회색 안내 문구를 한 줄 더 붙인다. Q-5(16)부터는
## 통합 화면(_show_pip_picker)이 줄글 대신 _step_caption() 한 줄만 쓰므로 subtitle_text
## 없이 부르고, 다이스 승급 화면(_show_die_inventory_picker 등, 이번 재설계 대상 아님)만
## 여전히 이 매개변수를 쓴다.
func _add_frame(title_text: String, height: float = 420.0, subtitle_text: String = "") -> void:
	# L-3(2026-10-14, [대형 기획 12] K-3 후속): 평범한 검정 ColorRect였던 틀을
	# Panel(테두리 있음)로 바꿔 CharacterTheme.apply()로 캐릭터 색 테두리를 입힌다
	# (내부 배경색 0,0,0,0.9는 그대로 유지 — 가독성 핵심 영역이라 대비를 해치지 않음).
	var bg := Panel.new()
	# [대형 기획 13] M-5a(2026-10-15): resources/ui/panel/overlay_{base,accent}.png가
	# 있으면 그 이미지 스킨을, 없으면 기존 StyleBoxFlat 절차적 테두리로 폴백.
	var skin_applied := UIKit.apply_panel_skin(bg, "overlay", RunState.character_id)
	if not skin_applied:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0, 0, 0, 0.9)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(8)
		bg.add_theme_stylebox_override("panel", frame_style)
	bg.position = Vector2(140, 120)
	bg.size = Vector2(1000, height)
	_content_root.add_child(bg)
	_ui.append(bg)
	if not skin_applied:
		CharacterTheme.apply(bg, RunState.character_id, false)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(170, 140)
	title.size = Vector2(940, 30)
	CharacterTheme.apply_label(title, RunState.character_id)
	_content_root.add_child(title)
	_ui.append(title)

	if subtitle_text != "":
		var subtitle := Label.new()
		# autowrap_mode를 text/size보다 먼저 설정해야 한다 — Label의 minimum_size는
		# autowrap이 꺼진 상태(기본값)에서는 줄바꿈 없는 전체 텍스트 폭 그대로라, size를
		# 먼저 지정하면 Control이 "size는 최소 minimum_size 이상"이라는 제약 때문에 그
		# 큰 값으로 즉시 클램프해버린다. 그 뒤에 autowrap_mode를 켜도 이미 커진 size는
		# 저절로 줄어들지 않아 텍스트가 프레임 밖으로 흘러넘친다(실제로 겪은 버그).
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
		subtitle.text = subtitle_text
		subtitle.position = Vector2(170, 172)
		subtitle.size = Vector2(940, 46)
		subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.72))
		_content_root.add_child(subtitle)
		_ui.append(subtitle)


## ================= 통합 화면 (Q-5(16) 재설계 — "정비") =================

## 지금 선택 상태에 맞는 한 줄 진행 안내(INBOX 원문 "단계 안내는 한 줄 이하").
func _step_caption() -> String:
	if _selected_pip_index == -1:
		return "① 눈금 선택 → ② 면 선택 → ③ 적용 — 아래 보유 눈금 중 하나를 고르세요."
	elif _pending_face.is_empty():
		return "① 눈금 선택 → ② 면 선택 → ③ 적용 — 공격/방어 주머니에서 바꿀 면을 고르세요."
	else:
		return "① 눈금 선택 → ② 면 선택 → ③ 적용 — 미리보기를 확인하고 적용하거나 취소하세요."


## 유일한 화면 — 보유 눈금(1단계) / 공격·방어 주머니 면 선택(2단계) / 미리보기+적용·취소
## (3단계, 면을 고른 뒤에만) 를 전부 한 화면에 그린다.
##
## 내용물(pending)을 먼저 전부 만들어 배열에 모아두기만 하고, 그 높이를 계산해
## _add_frame()을 먼저 부른 "다음"에 add_child()한다 — 내용이 나중에 그려지는
## 프레임(반투명 배경)보다 트리 순서상 앞에 있으면 그 밑에 깔려 안 보인다(기존
## customize_panel.gd가 겪었던 버그, pending 패턴으로 방지).
func _show_pip_picker() -> void:
	_clear_ui()
	_preview_apply_button = null
	var pending: Array[Node] = []
	var step_buttons: Array[Button] = []

	var y := 226.0

	var step_label := Label.new()
	step_label.text = _step_caption()
	step_label.position = Vector2(200, y)
	step_label.size = Vector2(880, 22)
	step_label.add_theme_font_size_override("font_size", 14)
	step_label.add_theme_color_override("font_color", CharacterTheme.ui_palette(RunState.character_id)["accent"])
	pending.append(step_label)
	y += 32.0

	y = _add_pip_row(y, pending, step_buttons)
	y += 18.0

	var col_y := y
	var bottom_a := _add_dice_column(RunState.player_attack_bag, "공격", Vector2(200, col_y), pending, step_buttons)
	var bottom_d := _add_dice_column(RunState.player_defense_bag, "방어", Vector2(650, col_y), pending, step_buttons)
	y = max(bottom_a, bottom_d) + 8.0

	if not _pending_face.is_empty():
		y = _add_preview_section(y, pending, step_buttons)
		y += 16.0

	y = _add_die_inventory_row(y, pending, step_buttons)
	y += 10.0

	_add_frame("정비 — 다이스 개조", max(300.0, y - 120.0 + 60.0))

	for node in pending:
		_content_root.add_child(node)
		_ui.append(node)

	var close_btn := Button.new()
	close_btn.text = "닫기"
	close_btn.position = Vector2(200, y)
	close_btn.size = Vector2(160, 40)
	close_btn.pressed.connect(close)
	UIKit.style_secondary_button(close_btn, RunState.character_id)
	_content_root.add_child(close_btn)
	_ui.append(close_btn)
	step_buttons.append(close_btn)
	_chain_step_focus(step_buttons, _preview_apply_button)
	# [셀프 피드백 수정] 공격/방어 주머니가 많이 찰수록(최대 MAX_DICE=6개) 미리보기
	# 단계까지 포함한 전체 내용이 화면(720px)보다 커질 수 있다 — 수동 스크롤 범위
	# 클램프에 쓸 내용 전체 높이(닫기 버튼 하단 + 여백)를 기록해둔다.
	_content_height = y + 40.0 + 60.0


## 1단계: 보유 눈금을 "아이템 칩"(ShapeDieChip, 정사각 — INBOX 원문 "보유 눈금을
## 아이템처럼 보여준다")으로 나열한다. 누르면 선택/선택 해제(토글) — 선택된 칩은 캐릭터
## accent색 굵은 테두리로 강조된다.
func _add_pip_row(y: float, pending: Array[Node], step_buttons: Array[Button]) -> float:
	var label := Label.new()
	label.text = "보유 눈금 (%d개)" % RunState.pip_inventory.size()
	label.position = Vector2(200, y)
	label.size = Vector2(400, 22)
	pending.append(label)
	y += 26.0

	if RunState.pip_inventory.is_empty():
		var hint := Label.new()
		hint.text = "전투 승리 보상으로 눈금을 얻으면 여기 쌓입니다."
		hint.position = Vector2(200, y)
		hint.size = Vector2(880, 20)
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.62))
		pending.append(hint)
		y += 34.0
	else:
		var chip_size := 48.0
		var gap := 10.0
		var px := 200.0
		for i in RunState.pip_inventory.size():
			var value: int = RunState.pip_inventory[i]
			var selected := i == _selected_pip_index
			var btn := _make_value_chip_button(value, 4, chip_size, false, selected, true)
			btn.position = Vector2(px, y)
			btn.pressed.connect(_on_pip_chip_pressed.bind(i))
			pending.append(btn)
			step_buttons.append(btn)

			px += chip_size + gap
			if px > 1080.0:
				px = 200.0
				y += chip_size + gap
		y += chip_size + gap
	return y


func _on_pip_chip_pressed(index: int) -> void:
	_selected_pip_index = -1 if _selected_pip_index == index else index
	_pending_face = {}
	_show_pip_picker()


## 2단계: 공격/방어 주머니 한 쪽을 "면 선택 가능한" 칩 열로 그린다 — ShapeDieChip이
## 그 다이스의 실제 면 모양(삼각/사각/오각)과 값을 보여준다(INBOX 원문 "shape_die_chip,
## 면 배열로 보여준다"). 눈금을 아직 선택하지 않았으면(_selected_pip_index == -1)
## 전부 비활성화한다 — 순서(눈금 -> 면)를 강제.
func _add_dice_column(bag: DiceBag, label_prefix: String, origin: Vector2, pending: Array[Node], step_buttons: Array[Button]) -> float:
	var header := Label.new()
	header.text = "%s 주머니" % label_prefix
	header.position = origin
	header.size = Vector2(420, 20)
	pending.append(header)

	var chip_size := 36.0
	var gap := 4.0
	var wrap_x := origin.x + 420.0
	var y := origin.y + 24.0
	var enabled := _selected_pip_index != -1

	for i in bag.dice.size():
		var faces: PackedInt32Array = bag.dice[i]
		var row_label := Label.new()
		row_label.text = "%s%d" % [label_prefix, i + 1]
		row_label.position = Vector2(origin.x, y + (chip_size - 14.0) / 2.0)
		row_label.size = Vector2(44, 16)
		row_label.add_theme_font_size_override("font_size", 12)
		pending.append(row_label)

		var chip_x := origin.x + 48.0
		var sides := faces.size()
		var shape_sides := ShapeDieChip.shape_sides_for_dice_sides(sides)
		for fi in sides:
			var v: int = faces[fi]
			var is_pending: bool = not _pending_face.is_empty() \
				and _pending_face["bag"] == bag and _pending_face["die_index"] == i and _pending_face["face_index"] == fi
			var btn := _make_value_chip_button(v, shape_sides, chip_size, v == sides, is_pending, enabled)
			btn.position = Vector2(chip_x, y)
			btn.pressed.connect(_on_face_button_pressed.bind(bag, i, fi))
			pending.append(btn)
			step_buttons.append(btn)

			chip_x += chip_size + gap
			if chip_x > wrap_x:
				chip_x = origin.x + 48.0
				y += chip_size + gap
		y += chip_size + 8.0

	return y


func _on_face_button_pressed(bag: DiceBag, die_index: int, face_index: int) -> void:
	if _selected_pip_index == -1:
		return
	if not _pending_face.is_empty() and _pending_face["bag"] == bag \
			and _pending_face["die_index"] == die_index and _pending_face["face_index"] == face_index:
		_pending_face = {}
	else:
		_pending_face = {"bag": bag, "die_index": die_index, "face_index": face_index}
	_show_pip_picker()


## 3단계: 선택된 눈금 -> 면 교환의 적용 전/후 비교. 바뀔 면은 주황(PENDING_HIGHLIGHT),
## 적용 후 값은 녹색(APPLIED_HIGHLIGHT)으로 강조한다(INBOX 원문 "바뀐 면 강조"). 아직
## _exchange_pip()을 호출하지 않은 순수 미리보기 계산이라, 여기 표시되는 "적용 후" 값은
## _exchange_pip()이 실제로 만드는 값과 항상 같은 공식(min(pip_value, sides))을 쓴다.
func _add_preview_section(y: float, pending: Array[Node], step_buttons: Array[Button]) -> float:
	var bag: DiceBag = _pending_face["bag"]
	var die_index: int = _pending_face["die_index"]
	var face_index: int = _pending_face["face_index"]
	var pip_value: int = RunState.pip_inventory[_selected_pip_index]
	var faces: PackedInt32Array = bag.dice[die_index]
	var sides := faces.size()
	var applied_value: int = min(pip_value, sides)
	var shape_sides := ShapeDieChip.shape_sides_for_dice_sides(sides)
	var chip_size := 42.0
	var gap := 4.0

	var header := Label.new()
	header.text = "미리보기 — 적용하면 아래처럼 바뀝니다 (눈금 [%d] 사용)" % pip_value
	header.position = Vector2(200, y)
	header.size = Vector2(880, 20)
	pending.append(header)
	y += 26.0

	var x := 200.0
	for fi in sides:
		var chip := _make_preview_chip(faces[fi], shape_sides, chip_size, fi == face_index, faces[fi] == sides, false)
		chip.position = Vector2(x, y)
		pending.append(chip)
		x += chip_size + gap

	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 28)
	arrow.position = Vector2(x + 4.0, y - 4.0)
	arrow.size = Vector2(36, chip_size)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pending.append(arrow)
	x += 44.0

	for fi in sides:
		var after_value: int = applied_value if fi == face_index else faces[fi]
		var chip2 := _make_preview_chip(after_value, shape_sides, chip_size, fi == face_index, after_value == sides, true)
		chip2.position = Vector2(x, y)
		pending.append(chip2)
		x += chip_size + gap
	y += chip_size + 14.0

	var apply_btn := Button.new()
	apply_btn.text = "적용"
	apply_btn.position = Vector2(200, y)
	apply_btn.size = Vector2(140, 42)
	apply_btn.pressed.connect(_confirm_exchange)
	UIKit.style_primary_button(apply_btn, RunState.character_id)
	pending.append(apply_btn)
	step_buttons.append(apply_btn)
	_preview_apply_button = apply_btn

	var cancel_btn := Button.new()
	cancel_btn.text = "취소"
	cancel_btn.position = Vector2(356, y)
	cancel_btn.size = Vector2(140, 42)
	cancel_btn.pressed.connect(_cancel_pending)
	UIKit.style_secondary_button(cancel_btn, RunState.character_id)
	pending.append(cancel_btn)
	step_buttons.append(cancel_btn)

	y += 42.0
	return y


## 미리보기 칩 하나(비클릭) — changed면 적용 전/후 강조색, 아니면 기존 "최댓값" 금색
## 강조 또는 평범한 색. ShapeDieChip은 클릭 불가 Control이라 그대로 pending에 넣는다.
func _make_preview_chip(value: int, shape_sides: int, size: float, changed: bool, is_max: bool, is_after: bool) -> ShapeDieChip:
	var chip := ShapeDieChip.new()
	chip.custom_minimum_size = Vector2(size, size)
	chip.size = Vector2(size, size)
	chip.shape_sides = shape_sides
	chip.value = value
	if changed:
		chip.fill_color = APPLIED_HIGHLIGHT if is_after else PENDING_HIGHLIGHT
		chip.border_color = APPLIED_HIGHLIGHT_BORDER if is_after else PENDING_HIGHLIGHT_BORDER
	elif is_max:
		chip.fill_color = FaceChipStyle.MAX_FACE_BG_COLOR
		chip.border_color = FaceChipStyle.MAX_FACE_BORDER_COLOR
	return chip


func _confirm_exchange() -> void:
	if _pending_face.is_empty() or _selected_pip_index == -1:
		return
	_exchange_pip(_pending_face["bag"], _pending_face["die_index"], _pending_face["face_index"], _selected_pip_index)
	_selected_pip_index = -1
	_pending_face = {}
	_show_pip_picker()


func _cancel_pending() -> void:
	_pending_face = {}
	_show_pip_picker()


## 눈금/다이스 면을 "실제 모양"(ShapeDieChip 재사용)으로 보여주는 클릭 가능한 칩.
## 눈금은 shape_sides=4(정사각 "아이템" 칩)로, 다이스 면은 그 다이스의 실제 면 모양으로
## 그린다. selected면 캐릭터 accent색 굵은 테두리로 강조하고, enabled=false면 비활성화
## (클릭 불가 + 흐린 색)한다.
func _make_value_chip_button(value: int, shape_sides: int, size: float, is_max: bool, selected: bool, enabled: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(size, size)
	btn.size = Vector2(size, size)
	btn.disabled = not enabled
	btn.flat = false

	var accent: Color = CharacterTheme.ui_palette(RunState.character_id)["accent"]
	var base_bg := Color(0.18, 0.17, 0.2, 0.95)
	var border := accent if selected else (FaceChipStyle.MAX_FACE_BORDER_COLOR if is_max else Color(0.42, 0.42, 0.46))

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_bg
	normal.set_border_width_all(4 if selected else 2)
	normal.border_color = border
	normal.set_corner_radius_all(int(size * 0.12))
	var hover := normal.duplicate()
	hover.bg_color = base_bg.lightened(0.1)
	var pressed_style := normal.duplicate()
	pressed_style.bg_color = base_bg.darkened(0.1)
	var disabled_style := normal.duplicate()
	disabled_style.bg_color = Color(0.1, 0.1, 0.11, 0.7)
	disabled_style.border_color = Color(0.3, 0.3, 0.32)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	var chip := ShapeDieChip.new()
	chip.custom_minimum_size = Vector2(size, size)
	chip.size = Vector2(size, size)
	chip.position = Vector2.ZERO
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.shape_sides = shape_sides
	chip.value = value
	if is_max and not selected:
		chip.fill_color = FaceChipStyle.MAX_FACE_BG_COLOR
		chip.border_color = FaceChipStyle.MAX_FACE_BORDER_COLOR
	elif not enabled:
		chip.fill_color = Color(0.45, 0.42, 0.38)
		chip.font_color = Color(0.75, 0.72, 0.68)
	btn.add_child(chip)
	return btn


## 여분 다이스(다이스 승급, 면 개수 교체 — 눈금 교환과 별개 기능, 이번 재설계 대상
## 아님)를 고르면 기존 3단계 화면(_show_die_target_picker)으로 들어간다.
func _add_die_inventory_row(y: float, pending: Array[Node], step_buttons: Array[Button]) -> float:
	var label := Label.new()
	label.text = "여분 다이스 (%d개) — 면 개수 자체를 바꾸고 싶다면" % RunState.die_inventory.size()
	label.position = Vector2(200, y)
	label.size = Vector2(700, 22)
	pending.append(label)
	y += 26.0

	if RunState.die_inventory.is_empty():
		var hint := Label.new()
		hint.text = "다이스 승급 아이템을 얻으면 여기 쌓입니다."
		hint.position = Vector2(200, y)
		hint.size = Vector2(880, 20)
		hint.add_theme_font_size_override("font_size", 12)
		hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.62))
		pending.append(hint)
		y += 34.0
	else:
		var dx := 200.0
		for i in RunState.die_inventory.size():
			var sides: int = RunState.die_inventory[i]
			var dbtn := Button.new()
			dbtn.text = "D%d" % sides
			dbtn.position = Vector2(dx, y)
			FaceChipStyle.style_button(dbtn, 44.0, false, false)
			dbtn.pressed.connect(_show_die_target_picker.bind(i))
			pending.append(dbtn)
			step_buttons.append(dbtn)

			dx += 54.0
			if dx > 1080.0:
				dx = 200.0
				y += 54.0
		y += 54.0
	return y


## ================= 하위 호환 shim (dungeon_map.gd QA 훅 / dice_test.gd) =================

## 예전 "2단계(다이스 선택) 화면"의 자리를 대신한다 — 이제 별도 화면이 아니라 통합
## 화면에서 pip_index를 선택한 상태로 만들 뿐이다. 호출부(QA 훅/테스트)는 "그 지점까지
## 진행된 상태"만 필요로 해서 동작은 동일하게 유지된다.
func _show_die_picker(pip_index: int) -> void:
	_selected_pip_index = pip_index
	_pending_face = {}
	_show_pip_picker()


## 예전 "3단계(면 선택) 화면"의 자리를 대신한다 — 이제 통합 화면에서 pip_index를
## 선택하고 지정한 다이스의 0번째 면을 미리 선택해 미리보기까지 보이는 상태로 만든다.
func _show_face_picker(bag: DiceBag, die_index: int, pip_index: int) -> void:
	_selected_pip_index = pip_index
	var faces: PackedInt32Array = bag.dice[die_index]
	_pending_face = {"bag": bag, "die_index": die_index, "face_index": 0} if faces.size() > 0 else {}
	_show_pip_picker()


## QA/디버그 전용 "즉시 적용" 지름길 — 미리보기 화면 없이 선택 즉시
## _exchange_pip()을 실행한다(기존 동작 그대로 유지, _debug_verify_pip_swap()/
## dice_test.gd의 이중 실행 방지 검증이 직접 호출). 같은 프레임 안에 같은 인자로
## 두 번 불려도(더블클릭 가정) 두 번째는 _face_chosen_locked로 막는다.
func _on_face_chosen(bag: DiceBag, die_index: int, face_index: int, pip_index: int) -> void:
	if _face_chosen_locked:
		return
	_face_chosen_locked = true
	_exchange_pip(bag, die_index, face_index, pip_index)
	_selected_pip_index = -1
	_pending_face = {}
	_show_pip_picker()


## QA 전용 — 자동 스크린샷은 클릭을 흉내낼 수 없으므로 곧장 "미리보기까지 열린" 상태를
## 만들어 화면을 확인하기 위함. 인벤토리가 비어있으면(정상 플레이라면 승리 전엔 항상 빈
## 상태) 확인용 임시 눈금을 하나 넣어준다.
func debug_open_face_picker() -> void:
	if RunState.pip_inventory.is_empty():
		RunState.pip_inventory.append(4)
	open()
	_show_face_picker(RunState.player_attack_bag, 0, RunState.pip_inventory.size() - 1)


## ================= 다이스 인벤토리 흐름 (변경 없음) =================

## 다이스 인벤토리 흐름 1단계: RunState.die_inventory(다이스 승급 아이템 획득으로 쌓인
## "새 다이스의 면 개수" 목록)에서 교체에 쓸 다이스 하나를 고른다. 통합 화면의 "여분
## 다이스" 행에서 들어온다.
func _show_die_inventory_picker() -> void:
	_clear_ui()
	var step_buttons: Array[Button] = []

	var chip_size := 70.0
	var gap := 14.0
	var y := 236.0
	var x := 200.0

	if RunState.die_inventory.is_empty():
		_add_frame(
			"커스터마이징 — 인벤토리에 다이스가 없습니다",
			260.0,
			"다이스는 상점/특수 이벤트/전투 승리 보상의 \"다이스 승급\" 아이템을 얻으면 여기 쌓입니다. 얻고 나면 여기서 원하는 다이스와 맞바꿀 수 있습니다."
		)
		var msg := Label.new()
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD
		msg.text = "지금은 맞바꿀 수 있는 다이스가 없어 다음 단계로 진행할 수 없습니다."
		msg.position = Vector2(200, y)
		msg.size = Vector2(880, 40)
		_content_root.add_child(msg)
		_ui.append(msg)
		y += 60.0
	else:
		var pending: Array[Node] = []
		for i in RunState.die_inventory.size():
			var sides: int = RunState.die_inventory[i]
			var btn := Button.new()
			btn.text = "D%d" % sides
			btn.position = Vector2(x, y)
			FaceChipStyle.style_button(btn, chip_size, false, false)
			btn.pressed.connect(_show_die_target_picker.bind(i))
			pending.append(btn)
			step_buttons.append(btn)

			x += chip_size + gap
			if x > 1000.0:
				x = 200.0
				y += chip_size + gap
		y += chip_size + 24.0
		# 프레임(반투명 배경)이 위 버튼들보다 먼저 그려져야 버튼이 그 위에 보인다.
		_add_frame(
			"커스터마이징 — 사용할 다이스를 고르세요",
			max(260.0, y - 120.0),
			"보유 다이스 %d개 중 주머니에 넣을 것을 하나 고르세요. 다음 단계에서 어느 다이스와 맞바꿀지 정합니다." % RunState.die_inventory.size()
		)
		for node in pending:
			_content_root.add_child(node)
			_ui.append(node)

	var back_btn := Button.new()
	back_btn.text = "뒤로"
	back_btn.position = Vector2(200, y)
	back_btn.size = Vector2(160, 40)
	back_btn.pressed.connect(_show_pip_picker)
	UIKit.style_secondary_button(back_btn, RunState.character_id)
	_content_root.add_child(back_btn)
	_ui.append(back_btn)
	step_buttons.append(back_btn)
	_chain_step_focus(step_buttons)
	_content_height = y + 40.0 + 60.0


## 다이스 인벤토리 흐름 2단계: 고른 다이스를 넣을 자리(공격/방어 주머니 중 하나의
## 다이스 슬롯)를 고르면 즉시 교환된다. 기존 다이스보다 면 개수가 작거나 같은 자리는
## "실제로는 승급이 아니게" 되므로 비활성화해 의도치 않은 다운그레이드를 막는다.
func _show_die_target_picker(inv_index: int) -> void:
	_clear_ui()
	_die_chosen_locked = false
	var step_buttons: Array[Button] = []
	var new_sides: int = RunState.die_inventory[inv_index]
	_add_frame(
		"커스터마이징 — D%d을(를) 넣을 다이스를 고르세요" % new_sides,
		460.0,
		"아래 목록은 공격/방어 주머니의 다이스별 현재 면 개수입니다. 고르면 그 자리가 D%d로 바뀌고, 원래 있던 다이스는 인벤토리로 돌아갑니다(면 개수가 이미 D%d 이상인 자리는 승급이 아니므로 고를 수 없습니다)." % [new_sides, new_sides]
	)

	var y := 226.0
	y = _add_die_target_rows("공격", RunState.player_attack_bag, y, inv_index, new_sides, step_buttons)
	y = _add_die_target_rows("방어", RunState.player_defense_bag, y, inv_index, new_sides, step_buttons)

	if not _has_upgrade_target(new_sides):
		var note := Label.new()
		note.text = "지금은 D%d보다 작은 자리가 없어 승급할 곳이 없습니다. 다른 눈금/다이스를 먼저 써보거나 나중에 다시 시도하세요." % new_sides
		note.autowrap_mode = TextServer.AUTOWRAP_WORD
		note.position = Vector2(200, y)
		note.size = Vector2(880, 40)
		note.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
		_content_root.add_child(note)
		_ui.append(note)
		y += 50.0

	var back_btn := Button.new()
	back_btn.text = "뒤로"
	back_btn.position = Vector2(200, y + 10)
	back_btn.size = Vector2(160, 40)
	back_btn.pressed.connect(_show_pip_picker)
	UIKit.style_secondary_button(back_btn, RunState.character_id)
	_content_root.add_child(back_btn)
	_ui.append(back_btn)
	step_buttons.append(back_btn)
	_chain_step_focus(step_buttons)
	_content_height = y + 50.0 + 60.0


## 공격/방어 주머니 어느 쪽이든 new_sides보다 면 개수가 작은 다이스가 하나라도
## 있는지 확인한다 — 없으면 이번 인벤토리 다이스는 지금 둘 곳이 없다는 뜻이라
## 안내 문구를 보여준다(버튼이 전부 비활성화된 채 아무 설명 없이 남는 것을 방지).
func _has_upgrade_target(new_sides: int) -> bool:
	for faces in RunState.player_attack_bag.dice:
		if faces.size() < new_sides:
			return true
	for faces in RunState.player_defense_bag.dice:
		if faces.size() < new_sides:
			return true
	return false


func _add_die_target_rows(bag_label: String, bag: DiceBag, y: float, inv_index: int, new_sides: int, out_buttons: Array[Button]) -> float:
	for i in bag.dice.size():
		var faces: PackedInt32Array = bag.dice[i]
		var is_upgrade := faces.size() < new_sides
		var btn := Button.new()
		btn.text = "%s %d — D%d%s" % [bag_label, i + 1, faces.size(), "" if is_upgrade else " (승급 아님)"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.disabled = not is_upgrade
		btn.position = Vector2(200, y)
		btn.size = Vector2(1080 - 200, 46)
		btn.pressed.connect(_on_die_target_chosen.bind(bag, i, inv_index))
		UIKit.style_secondary_button(btn, RunState.character_id)
		_content_root.add_child(btn)
		_ui.append(btn)
		out_buttons.append(btn)
		y += 54.0
	return y


## 인벤토리의 다이스와 주머니 슬롯을 맞바꾼다. 밀려난 기존 다이스는 면 개수만
## RunState.die_inventory로 돌아온다(면 값 자체는 표준으로 리셋되지만, 예전 자동교체도
## 같은 리셋을 했으므로 새로운 손해는 아니다). _exchange_pip과 대칭 구조.
func _exchange_die(bag: DiceBag, die_index: int, inv_index: int) -> void:
	var new_sides: int = RunState.die_inventory[inv_index]
	var old_sides: int = bag.dice[die_index].size()
	bag.replace_die(die_index, new_sides)
	RunState.die_inventory.remove_at(inv_index)
	RunState.die_inventory.append(old_sides)


func _on_die_target_chosen(bag: DiceBag, die_index: int, inv_index: int) -> void:
	if _die_chosen_locked:
		return
	_die_chosen_locked = true
	_exchange_die(bag, die_index, inv_index)
	_show_die_inventory_picker()


## 2단계/3단계 눈금<->면 교환의 핵심 로직. RunState.pip_inventory/bag만 건드리는 순수
## 로직이라(@onready UI 노드 없음) dice_test.gd가 add_child 없이 직접 호출해 검증할 수
## 있다. 밀려난 기존 면 값은 인벤토리로 돌아오므로(사라지지 않음), applied_value는
## min(pip_value, 그 다이스의 면 개수)로 클램프된다(값 상한 규칙 유지).
func _exchange_pip(bag: DiceBag, die_index: int, face_index: int, pip_index: int) -> void:
	var faces: PackedInt32Array = bag.dice[die_index]
	var sides := faces.size()
	var pip_value: int = RunState.pip_inventory[pip_index]
	var old_value: int = faces[face_index]
	var applied_value: int = min(pip_value, sides)
	bag.set_face_value(die_index, face_index, applied_value)
	RunState.pip_inventory.remove_at(pip_index)
	RunState.pip_inventory.append(old_value)


## QA 전용 — debug_open_face_picker()와 같은 목적, 다이스 인벤토리 흐름의 2단계
## (교체할 자리 선택) 화면을 확인하기 위함. 인벤토리가 비어있으면 확인용 D6 하나를
## 넣어준다.
func debug_open_die_target_picker() -> void:
	if RunState.die_inventory.is_empty():
		RunState.die_inventory.append(6)
	open()
	_show_die_target_picker(RunState.die_inventory.size() - 1)
