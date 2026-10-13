class_name FocusNav
## 방향키 이동 + 스페이스/Enter 확정(Godot 기본 ui_left/right/up/down/ui_accept) 기반
## 포커스 내비게이션 공용 유틸리티.
##
## INBOX.md 2026-10-13 [대형 기획 11] K-1 — 기존 숫자 단축키(keyboard_shortcuts.gd의
## KeyboardShortcuts, 이번에 완전히 대체되어 삭제됨)를 "방향키로 이동, 스페이스(Enter)로
## 확정, Esc로 닫기/뒤로" 방식으로 바꾼다. Button은 기본적으로 focus_mode=FOCUS_ALL이고
## BaseButton이 포커스 상태에서 ui_accept를 받으면 스스로 pressed를 발생시키므로(Godot
## 엔진 기본 동작), 이 유틸은 "방향키가 시각적 순서와 일치하게 focus_neighbor_*를 명시적으로
## 연결"하고 "포커스가 눈에 보이게 StyleBox를 덮어쓰는" 두 가지만 담당한다 — 버튼 활성화
## 자체는 엔진에 맡기고 새로 구현하지 않는다(KeyboardShortcuts.try_press처럼 pressed를
## 직접 emit하는 코드가 없음 — 자동 geometry 기반 포커스 탐색에 맡기면 테스트 환경(뷰포트
## 레이아웃 미확정)에서 결과가 불안정하므로, 명시적 체인만 믿을 수 있는 경로로 쓴다).
##
## 씬 상태를 전혀 갖지 않는 정적 함수만 제공해 dice_test.gd가 인스턴스화 없이 검증할 수
## 있다(다른 systems/*.gd, keyboard_shortcuts.gd와 같은 설계).

const ACCENT_DEFAULT := Color(0.3, 0.85, 0.95)


## 포커스를 받았을 때 보이는 테두리 스타일. K-3(캐릭터 퍼스널 컬러)에서 accent를 캐릭터
## 색으로 넘길 수 있도록 매개변수화해뒀다 — 지금은 전부 기본값(밝은 청록)을 쓴다.
static func focus_style(accent: Color = ACCENT_DEFAULT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.22, 0.26, 0.95)
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	return style


## 컨트롤 하나를 포커스 가능하게 만들고(FOCUS_ALL) 포커스 스타일을 덮어쓴다. normal/hover/
## pressed 등 기존 스타일은 그대로 유지 — "focus" 테마 슬롯만 추가한다.
static func make_focusable(control: Control, accent: Color = ACCENT_DEFAULT) -> void:
	control.focus_mode = Control.FOCUS_ALL
	control.add_theme_stylebox_override("focus", focus_style(accent))


## buttons를 "한 줄" 순서로 보고 각 버튼에 FOCUS_ALL + 포커스 스타일을 적용하고,
## horizontal이면 좌/우, 아니면 위/아래 focus_neighbor_*를 순서대로 이어 방향키 이동이
## 목록 순서와 일치하게 한다. wrap=true면 마지막 다음은 처음으로, 처음 이전은 마지막으로
## 돌아 포커스가 밖으로 못 나간다. trap=true면 체인에 안 쓰는 반대쪽 축(예: horizontal이면
## 위/아래)도 "자기 자신"으로 묶어, Godot의 기본 동작(해당 방향의 focus_neighbor가
## 비어 있으면 화면 좌표 기준으로 가장 가까운 다른 포커스 가능 컨트롤을 자동으로 찾는 것)이
## 오버레이 패널 뒤에 깔린 화면의 버튼으로 새 버리는 것을 막는다 — customize_panel/
## achievement_panel처럼 "포커스가 패널 안에 갇혀야" 하는 곳에서 wrap과 함께 켠다(K-1
## 요구사항). null이거나 해제된(freed) 버튼은 건너뛴다. get_path_to()가 성립하려면 두
## 버튼이 같은 트리(공통 부모) 아래에 있어야 한다 — 실제 씬에서는 항상 그렇고, 테스트는
## 임시 부모 Node 하나에 버튼들을 자식으로 넣어두면 된다.
static func chain_linear(buttons: Array[Button], horizontal: bool, wrap: bool = false, trap: bool = false, accent: Color = ACCENT_DEFAULT) -> void:
	var valid: Array[Button] = []
	for b in buttons:
		if b != null and is_instance_valid(b):
			valid.append(b)
	var n := valid.size()
	for i in n:
		make_focusable(valid[i], accent)
		var prev_path := NodePath()
		var next_path := NodePath()
		if i > 0:
			prev_path = valid[i].get_path_to(valid[i - 1])
		elif wrap:
			# n==1이면 valid[n - 1] == valid[i] 자기 자신 — "자기 자신에게 자기 자신"으로
			# 묶여도 안전하다(포커스가 그대로 머무를 뿐 밖으로 못 나간다는 wrap의 목적과
			# 일치, achievement_panel.gd처럼 버튼이 하나뿐인 패널에서도 트랩이 성립해야 함).
			prev_path = valid[i].get_path_to(valid[n - 1])
		if i < n - 1:
			next_path = valid[i].get_path_to(valid[i + 1])
		elif wrap:
			next_path = valid[i].get_path_to(valid[0])
		if horizontal:
			valid[i].focus_neighbor_left = prev_path
			valid[i].focus_neighbor_right = next_path
			if trap:
				var self_path := valid[i].get_path_to(valid[i])
				valid[i].focus_neighbor_top = self_path
				valid[i].focus_neighbor_bottom = self_path
		else:
			valid[i].focus_neighbor_top = prev_path
			valid[i].focus_neighbor_bottom = next_path
			if trap:
				var self_path2 := valid[i].get_path_to(valid[i])
				valid[i].focus_neighbor_left = self_path2
				valid[i].focus_neighbor_right = self_path2


## 목록에서 "보이고 활성화된" 첫 버튼에 포커스를 준다. 화면 진입/재구성 시 호출 — 첫
## 방향키 입력 전에 아무 것도 포커스돼 있지 않으면 방향키가 아무 효과도 없기 때문에
## (Godot은 "현재 포커스" 기준으로 다음 포커스를 찾으므로) 반드시 필요하다.
static func grab_first_focus(buttons: Array[Button]) -> void:
	for b in buttons:
		if b != null and is_instance_valid(b) and b.visible and not b.disabled:
			b.grab_focus()
			return
