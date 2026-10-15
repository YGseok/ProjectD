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
##
## [대형 기획 13] M-1(2026-10-14): bg_color를 투명으로 바꿨다 — Godot은 포커스 상태의
## 버튼을 그릴 때 normal/hover 등 기존 스타일 위에 이 "focus" 스타일을 겹쳐 그리므로
## (교체가 아니라 오버레이), 예전처럼 불투명한 회색 배경을 쓰면 UIKit.style_primary_
## button()처럼 버튼마다 다른 배경색을 준 커스텀 스타일이 포커스 상태에서 전부 같은
## 회색으로 덮여버린다(주 행동 버튼이 포커스되는 순간 보조 버튼과 구분이 안 되던 버그,
## M-1 첫 스크린샷에서 발견). 테두리만으로도 "눈에 띄는 하이라이트"(K-1 원문 요구)는
## 충분히 성립한다.
static func focus_style(accent: Color = ACCENT_DEFAULT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	return style


## 컨트롤 하나를 포커스 가능하게 만들고(FOCUS_ALL) 포커스 스타일을 덮어쓴다. normal/hover/
## pressed 등 기존 스타일은 그대로 유지 — "focus" 테마 슬롯만 추가한다.
static func make_focusable(control: Control, accent: Color = ACCENT_DEFAULT) -> void:
	control.focus_mode = Control.FOCUS_ALL
	control.add_theme_stylebox_override("focus", focus_style(accent))


## buttons를 "한 줄" 순서로 보고 각 요소에 FOCUS_ALL + 포커스 스타일을 적용하고,
## horizontal이면 좌/우, 아니면 위/아래 focus_neighbor_*를 순서대로 이어 방향키 이동이
## 목록 순서와 일치하게 한다. wrap=true면 마지막 다음은 처음으로, 처음 이전은 마지막으로
## 돌아 포커스가 밖으로 못 나간다. trap=true면 체인에 안 쓰는 반대쪽 축(예: horizontal이면
## 위/아래)도 "자기 자신"으로 묶어, Godot의 기본 동작(해당 방향의 focus_neighbor가
## 비어 있으면 화면 좌표 기준으로 가장 가까운 다른 포커스 가능 컨트롤을 자동으로 찾는 것)이
## 오버레이 패널 뒤에 깔린 화면의 버튼으로 새 버리는 것을 막는다 — customize_panel/
## achievement_panel처럼 "포커스가 패널 안에 갇혀야" 하는 곳에서 wrap과 함께 켠다(K-1
## 요구사항). null이거나 해제된(freed) 요소는 건너뛴다. get_path_to()가 성립하려면 두
## 요소가 같은 트리(공통 부모) 아래에 있어야 한다 — 실제 씬에서는 항상 그렇고, 테스트는
## 임시 부모 Node 하나에 자식으로 넣어두면 된다.
## buttons는 일부러 Array(비타입)로 받는다 — [대형 기획 12] L-1부터 Button이 아닌
## Control(캐릭터 카드 패널, CharacterCardPanel)도 체인에 들어오므로, 호출하는 쪽이
## Array[Button]이든 Array[Control]이든 그대로 넘길 수 있게 열어둔다(런타임에 각 요소가
## 실제로 Control인지는 valid 배열에 append할 때 엔진이 보장).
static func chain_linear(buttons: Array, horizontal: bool, wrap: bool = false, trap: bool = false, accent: Color = ACCENT_DEFAULT) -> void:
	var valid: Array[Control] = []
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


## 목록에서 "보이고 활성화된" 첫 요소에 포커스를 준다. 화면 진입/재구성 시 호출 — 첫
## 방향키 입력 전에 아무 것도 포커스돼 있지 않으면 방향키가 아무 효과도 없기 때문에
## (Godot은 "현재 포커스" 기준으로 다음 포커스를 찾으므로) 반드시 필요하다. "disabled"는
## BaseButton(Button 등)에만 있는 속성이라, CharacterCardPanel처럼 Button이 아닌 Control도
## 체인에 들어올 수 있는 [대형 기획 12] L-1부터는 `is BaseButton`으로 먼저 확인한다.
static func grab_first_focus(buttons: Array) -> void:
	for b in buttons:
		if b == null or not is_instance_valid(b):
			continue
		var ctrl: Control = b
		if not ctrl.visible:
			continue
		if ctrl is BaseButton and (ctrl as BaseButton).disabled:
			continue
		ctrl.grab_focus()
		return


## [대형 기획 14] N-1 "주 행동 키" 규칙: 화면 진입/상태 전환 시 "포커스가 없거나
## 애매하면" 그 화면의 주 행동 버튼(스타일상 강조된 버튼, 예: UIKit.style_primary_
## button으로 칠한 버튼)에 기본 포커스가 가 있어야 한다. 대부분의 화면은 fallback_list
## 안에 그 주 행동 버튼을 우연히 가장 먼저 넣어둬서 grab_first_focus()만으로도 이미
## 맞았지만(dungeon_map의 "전투 입장", event/story_event의 "계속"), 전수 감사
## (docs/UI_REVIEW.md "N-1" 절)에서 shop.gd는 리스트 순서상 상점 품목 버튼이 먼저라
## "던전으로 돌아가기"(주 행동으로 스타일링된 버튼)가 아니라 첫 품목 버튼에 기본
## 포커스가 가던 불일치를 찾았다. primary가 보이고 활성화돼 있으면 그쪽에 바로
## 포커스를 주고, 아니면(아직 안 보이거나 비활성화된 상태) 기존처럼 fallback_list에서
## 첫 유효한 컨트롤로 폴백한다 — "리스트 순서가 우연히 주 행동과 일치"하는 데
## 의존하지 않고 모든 화면이 명시적으로 이 규칙을 지키게 한다.
static func grab_default_focus(primary: Control, fallback_list: Array) -> void:
	if primary != null and is_instance_valid(primary) and primary.visible:
		if not (primary is BaseButton and (primary as BaseButton).disabled):
			primary.grab_focus()
			return
	grab_first_focus(fallback_list)
