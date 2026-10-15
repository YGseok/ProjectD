extends Node
## 시각 QA 하네스.
##
## project.godot 의 Autoload 로 등록해서 사용한다 (이름 권장: VisualQA).
## 평상시(사람이 직접 게임을 실행할 때)에는 GAME_START 환경변수가 비어 있으므로
## 아무 동작도 하지 않고 즉시 빠진다. 정상 플레이에는 전혀 영향을 주지 않는다.
##
## 동작 방식 (GAME_START 가 설정된 경우에만):
##   1. GAME_START 값으로 씬을 찾아 로드한다.
##      - 우선순위 1: GAME_START_PATH 환경변수 (전체 res:// 경로를 직접 지정)
##      - 우선순위 2: res://code/scenes/<name>/<name>.tscn (폴더당 씬 1개 컨벤션)
##      - 우선순위 3: res://code/scenes/<name>.tscn (평면 컨벤션)
##   2. GAME_QA_FRAME 번째 프레임까지 기다린다 (기본 60, 로딩/애니메이션 안정화 목적).
##   3. 뷰포트를 이미지로 캡처해 PNG로 저장한다.
##      - GAME_QA_OUT 이 지정되면 그 경로(res:// 또는 절대경로)에 저장.
##      - 없으면 res://qa_out/<GAME_START>.png 에 저장.
##   4. 창을 닫는다 (get_tree().quit()).
##
## 환경변수 목록:
##   GAME_START       (필수, QA 모드 트리거) 예: dungeon
##   GAME_START_PATH  (선택) 씬 경로를 컨벤션 대신 직접 지정. 예: res://code/scenes/dungeon/dungeon.tscn
##   GAME_QA_FRAME    (선택, 기본 60) 몇 프레임 후에 캡처할지
##   GAME_QA_OUT      (선택) 출력 PNG 경로. 예: res://qa_out/dungeon.png 또는 절대경로
##   GAME_QA_CALL     (선택) 캡처 직전에 현재 씬 루트에서 인자 없이 호출할 메서드 이름.
##                    클릭을 흉내낼 수 없는 자동 QA에서, 다단계 UI(예: 보상 화면의
##                    하위 선택 화면)를 직접 함수 호출로 열어서 스크린샷으로 확인할 때 씀.
##   GAME_QA_CLICK_PATH (선택) 캡처 직전에 실제로 "클릭"을 흉내낼 Control 노드의 경로
##                    (현재 씬 루트 기준 NodePath 문자열, 예: "CustomizeToggleButton").
##                    GAME_QA_CALL(메서드를 코드로 직접 호출)과 달리, 이건 그 노드의
##                    화면 좌표 중앙에 실제 InputEventMouseButton(press+release)을
##                    Input.parse_input_event()로 주입한다 — Godot의 실제 입력 파이프라인
##                    (뷰포트 피킹, mouse_filter, z-order상 다른 UI가 클릭을 가로채는지 등)을
##                    그대로 통과하므로, "버튼 연결 로직은 맞는데 실제 클릭 시점에만 다른
##                    문제가 있을 수 있다"는 의심을 검증할 때 GAME_QA_CALL보다 신뢰도가 높다.
##                    노드를 못 찾거나 Control이 아니면 에러를 출력하고 클릭 없이 진행한다.
##   GAME_QA_CLICK_WAIT_FRAMES (선택, 기본 20) 클릭 주입 후 그 결과(버튼 pressed 시그널 ->
##                    연결된 콜백 -> UI 변화)가 반영될 때까지 기다리는 프레임 수.
##   GAME_QA_SETTLE   (선택, "1"/"true"면 켜짐) GAME_QA_FRAME에 도달해도, 현재 씬이
##                    `_qa_is_settled() -> bool` 메서드를 갖고 있으면(예: combat_test.gd —
##                    물리 다이스가 아직 구르는 중인지 판단) 그 값이 true가 될 때까지
##                    캡처를 미룬다. 물리 시뮬레이션은 멈추는 시점이 실행마다 달라
##                    "고정 프레임"만으로는 다이스가 한창 구르는 중간 순간을 찍을 수
##                    있는 문제(STATUS.md 알려진 이슈)를 줄이기 위함. 씬에 그 메서드가
##                    없으면 기존과 동일하게 GAME_QA_FRAME에서 바로 캡처한다(하위 호환).
##   GAME_QA_SETTLE_MAX_FRAMES (선택, 기본 240) GAME_QA_SETTLE로 기다리는 최대 추가
##                    프레임 수. 끝내 정지 판정을 못 받아도 이 프레임을 넘기면 안전장치로
##                    강제 캡처한다(무한 대기 방지).

var _qa_active := false
var _target_frame := 60
var _frame_count := 0
var _output_path := ""
var _scene_name := ""
var _qa_call := ""
var _qa_settle_enabled := false
var _qa_settle_max_extra_frames := 240
var _settle_extra_elapsed := 0
var _qa_click_path := ""
var _qa_click_wait_frames := 20

## [대형 기획 14] N-1 — "실제 InputEventKey 시퀀스로 한 판 풀 시뮬레이션"용 플래그.
## GAME_QA_KEY_RUN=1이면 스크린샷 캡처 대신 _run_key_sequence_playthrough()가
## 캐릭터 선택 -> 던전 맵 -> 전투 승리 -> 보상 -> 다음 방 흐름을 실제
## Input.parse_input_event()로 (마우스 이벤트 없이) 진행해보고, 매 단계의 포커스/
## 상태 전환을 로그로 남긴다. 이 모드는 VisualQA가 current_scene이 아닌 Autoload라서
## (code/qa/visual_qa.gd 상단 주석 참고) 실제 change_scene_to_file()로 화면이
## 여러 번 바뀌어도 이 스크립트 자신은 안 사라진다는 점을 이용한다 — dice_test.gd
## 안에서 같은 걸 하면 dice_test 자신이 current_scene이라 그 즉시 자기 자신이
## 교체돼버려(테스트 하네스 전체가 날아감) 불가능했던 것과 대조적이다.
var _qa_key_run_enabled := false


func _ready() -> void:
	_scene_name = OS.get_environment("GAME_START")
	if _scene_name.is_empty():
		# QA 모드가 아님 -> 평상시 게임 실행. 아무것도 하지 않는다.
		return

	_qa_active = true

	# 사람이 PC를 쓰는 동안 창이 포그라운드로 튀어나와 화면을 가리지 않도록,
	# QA 모드일 때만 창을 화면 밖으로 옮긴다. 완전 headless는 이 프로젝트의
	# SubViewport 3D 렌더링이 깨질 위험이 있어(GPU 컨텍스트 없음) 쓰지 않는다 —
	# 대신 실제 창은 유지하되 보이지 않는 좌표로 옮겨 렌더링은 정상 동작시킨다.
	get_window().position = Vector2i(-4000, -4000)

	var frame_env := OS.get_environment("GAME_QA_FRAME")
	if not frame_env.is_empty() and frame_env.is_valid_int():
		_target_frame = frame_env.to_int()

	var explicit_path := OS.get_environment("GAME_START_PATH")
	var scene_path := explicit_path
	if scene_path.is_empty():
		scene_path = "res://code/scenes/%s/%s.tscn" % [_scene_name, _scene_name]
		if not ResourceLoader.exists(scene_path):
			scene_path = "res://code/scenes/%s.tscn" % _scene_name

	if not ResourceLoader.exists(scene_path):
		push_error("[VisualQA] GAME_START='%s' 에 해당하는 씬을 찾을 수 없습니다. 시도한 경로: %s (GAME_START_PATH로 직접 지정 가능)" % [_scene_name, scene_path])
		get_tree().quit(1)
		return

	_output_path = OS.get_environment("GAME_QA_OUT")
	if _output_path.is_empty():
		_output_path = "res://qa_out/%s.png" % _scene_name

	_qa_call = OS.get_environment("GAME_QA_CALL")

	var settle_env := OS.get_environment("GAME_QA_SETTLE").to_lower()
	_qa_settle_enabled = settle_env == "1" or settle_env == "true"
	var settle_max_env := OS.get_environment("GAME_QA_SETTLE_MAX_FRAMES")
	if not settle_max_env.is_empty() and settle_max_env.is_valid_int():
		_qa_settle_max_extra_frames = settle_max_env.to_int()

	_qa_click_path = OS.get_environment("GAME_QA_CLICK_PATH")
	var click_wait_env := OS.get_environment("GAME_QA_CLICK_WAIT_FRAMES")
	if not click_wait_env.is_empty() and click_wait_env.is_valid_int():
		_qa_click_wait_frames = click_wait_env.to_int()

	_qa_key_run_enabled = OS.get_environment("GAME_QA_KEY_RUN") == "1"

	# 엔진이 메인 씬을 트리에 추가하는 도중이라 change_scene_to_file을 즉시 호출하면
	# "Parent node is busy adding/removing children" 에러가 난다. 한 프레임 넘겨서 호출한다.
	await get_tree().process_frame

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[VisualQA] 씬 전환 실패: %s (err=%s)" % [scene_path, err])
		get_tree().quit(1)
		return

	if _qa_key_run_enabled:
		# [대형 기획 14] N-1 — 노드에 _process()가 정의돼 있으면 Godot은 set_process(true)를
		# 명시적으로 부르지 않아도 기본적으로 매 프레임 그걸 호출한다. 이 모드에서는 그
		# 기존 "프레임 세서 캡처" 루프(_process() 아래)가 전혀 필요 없는데도 끄지 않고
		# 두면, GAME_QA_FRAME(기본 60)에 도달하는 순간 _capture_and_quit()이 끼어들어
		# get_tree().quit()을 불러버려 한창 진행 중이던 플레이스루 코루틴을 중간에
		# 죽인다(실제로 처음 돌려봤을 때 "combat_test 전환" 로그 직후 뜬금없이
		# "saved: character_select.png"가 찍히며 멈춘 것으로 발견). 명시적으로 꺼둔다.
		set_process(false)
		print("[VisualQA] key-sequence playthrough mode (scene='%s')" % scene_path)
		_run_key_sequence_playthrough()
		return

	print("[VisualQA] scene='%s' frame=%d out='%s'" % [scene_path, _target_frame, _output_path])
	set_process(true)


func _process(_delta: float) -> void:
	if not _qa_active or _qa_key_run_enabled:
		return
	_frame_count += 1
	if _frame_count < _target_frame:
		return
	if _qa_settle_enabled and not _is_current_scene_settled() \
			and _settle_extra_elapsed < _qa_settle_max_extra_frames:
		_settle_extra_elapsed += 1
		return
	if _qa_settle_enabled:
		print("[VisualQA] settle wait: +%d frame(s) 대기 후 캡처 (settled=%s)" \
			% [_settle_extra_elapsed, str(_is_current_scene_settled())])
	set_process(false)
	_capture_and_quit()


## GAME_QA_SETTLE 모드에서 폴링하는 헬퍼. 현재 씬이 `_qa_is_settled()`를 구현하지
## 않으면(대부분의 씬) 항상 true를 반환해 기존 동작(GAME_QA_FRAME에서 바로 캡처)과
## 동일하게 움직인다 — 이 훅을 구현한 씬(예: combat_test.gd)에서만 실제로 대기한다.
func _is_current_scene_settled() -> bool:
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("_qa_is_settled"):
		return true
	return scene.call("_qa_is_settled")


func _capture_and_quit() -> void:
	if not _qa_click_path.is_empty():
		_simulate_click(_qa_click_path)
		for _i in _qa_click_wait_frames:
			await get_tree().process_frame

	if not _qa_call.is_empty():
		var scene := get_tree().current_scene
		if scene != null and scene.has_method(_qa_call):
			scene.call(_qa_call)
			await get_tree().process_frame
		else:
			push_error("[VisualQA] GAME_QA_CALL='%s' 메서드를 현재 씬에서 찾을 수 없습니다." % _qa_call)

	# 마지막 프레임이 실제로 그려진 뒤에 캡처하기 위해 한 프레임 더 대기한다.
	await RenderingServer.frame_post_draw

	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_error("[VisualQA] 뷰포트 이미지를 가져오지 못했습니다.")
		get_tree().quit(1)
		return

	var abs_path := _resolve_absolute_path(_output_path)
	var dir_path := abs_path.get_base_dir()
	var dir_err := DirAccess.make_dir_recursive_absolute(dir_path)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("[VisualQA] 출력 디렉토리 생성 실패: %s (err=%s)" % [dir_path, dir_err])
		get_tree().quit(1)
		return

	var save_err := img.save_png(abs_path)
	if save_err != OK:
		push_error("[VisualQA] PNG 저장 실패: %s (err=%s)" % [abs_path, save_err])
		get_tree().quit(1)
		return

	print("[VisualQA] saved: %s" % abs_path)
	get_tree().quit(0)


## GAME_QA_CLICK_PATH 처리. 실제 Godot 입력 파이프라인(뷰포트 피킹, mouse_filter,
## z-order상 다른 UI가 클릭을 가로채는지 등)을 그대로 거치는 진짜 마우스 클릭을
## 흉내낸다 — GAME_QA_CALL(메서드 직접 호출)과 달리 "버튼을 실제로 눌렀을 때만
## 재현되는 문제"를 잡아낼 수 있다.
func _simulate_click(node_path: String) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		push_error("[VisualQA] GAME_QA_CLICK_PATH: 현재 씬이 없습니다.")
		return
	var target := scene.get_node_or_null(node_path)
	if target == null:
		push_error("[VisualQA] GAME_QA_CLICK_PATH='%s' 노드를 찾을 수 없습니다." % node_path)
		return
	if not (target is Control):
		push_error("[VisualQA] GAME_QA_CLICK_PATH='%s' 는 Control이 아닙니다 (클릭 불가)." % node_path)
		return

	var ctrl: Control = target
	var center := ctrl.get_global_rect().get_center()

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	press.global_position = center
	Input.parse_input_event(press)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	release.global_position = center
	Input.parse_input_event(release)

	print("[VisualQA] simulated click: node='%s' at %s" % [node_path, str(center)])


func _resolve_absolute_path(path: String) -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path


## ---------------------------------------------------------------------------
## [대형 기획 14] N-1 — 실제 InputEventKey 시퀀스로 "캐릭터 선택 -> 던전 맵 ->
## 전투 승리 -> 보상 -> 다음 방"을 마우스 이벤트 없이 2개 방까지 실제로 진행해보는
## 헤드리스 플레이스루. GAME_QA_KEY_RUN=1 + GAME_START=character_select로 실행된다
## (scripts/qa_shot.sh의 9번째 인자 "1").
##
## 왜 dice_test.gd 안에 넣지 않았는가: dice_test 자신이 그 실행의 current_scene이라,
## 어느 화면의 버튼이든 change_scene_to_file()을 실제로 한 번만 호출해도 dice_test
## 자신이 교체돼(SceneTree.current_scene은 전역에 하나뿐) 테스트 하네스 전체가
## 그 자리에서 사라진다 — 이후 수천 개의 다른 검증이 전혀 실행되지 않는 참사가 된다.
## 이 autoload(VisualQA)는 current_scene이 아니라 트리 최상위에 별도로 떠 있는
## 노드라서 그 영향을 받지 않고, 실제 씬 전환을 몇 번이든 그대로 관찰할 수 있다
## (이 파일 상단 클래스 주석의 "엔진이 메인 씬을 바꿔도 이 스크립트는 안 사라진다"는
## 전제 그대로).
##
## 결정론을 위해 "견습 모험가"(기믹 없음, D4x3/D4x3)로 0번째 방(공격 2D4/방어 1D4
## 몬스터, DESIGN.md "시작 몬스터" 참고)과 1번째 방(같은 공식으로 아주 약간 더 강할
## 뿐인 몬스터)을 상대한다 — 기대 공격합(7.5) > 몬스터 기대 방어합(2.5)이고 몬스터
## 기대 공격합(5) < 플레이어 기대 방어합(7.5)이라 사실상 항상 이긴다(물리 다이스
## RNG 자체를 강제하지 않고 실제 굴림 그대로 두되, 승률을 거의 100%로 만드는 매치업을
## 고른 것 — "진짜로 이겨야" 보상/다음 방 전환까지 실제로 검증되므로).
var _key_run_ok := true
var _key_run_log: Array[String] = []


func _krlog(ok: bool, text: String) -> void:
	_key_run_ok = _key_run_ok and ok
	var tag := "OK" if ok else "FAIL"
	var line := "[KeyRun] [%s] %s" % [tag, text]
	_key_run_log.append(line)
	print(line)


## 실제 키보드 키 하나를 engine Input 파이프라인에 press+release 둘 다 주입한다.
## ui_accept/ui_left/ui_right/ui_up/ui_down은 Godot 기본 InputMap이 각각
## Enter·Kp Enter·Space / 방향키에 매핑돼 있어(project.godot에 별도 [input] 재정의
## 없음, DESIGN.md "조작" 절), keycode만 설정하면 그대로 해당 ui_* 액션으로 해석된다.
## **release도 반드시 보내야 한다** — dice_test.gd의 기존 QA 훅들(Esc 등)은
## press만으로도 충분했지만(_unhandled_input에서 직접 pressed만 검사), 실제
## BaseButton(Button)은 press에서 "누르는 중" 상태로만 들어가고 release에서야
## pressed 시그널을 실제로 emit한다(마우스 클릭과 같은 press-then-release 모델) —
## 이 함수를 처음 press만 보내는 걸로 만들었다가 "던전 시작" 버튼이 실제로 눌리지
## 않는 걸 이 테스트를 실행해보고서야 발견했다(2026-10-15, 첫 실행 로그 참고).
func _send_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)


## 매 프레임 포커스를 확인하면서 최대 max_presses번 key를 눌러 target에 포커스가
## 도달하는지 본다(정확한 체인 길이를 하드코딩하지 않아 레이아웃이 조금 바뀌어도
## 깨지지 않는다 — "도달 가능한가"라는 N-1의 질문 자체를 그대로 테스트한다).
func _press_until_focused(target: Control, keycode: Key, max_presses: int) -> bool:
	var viewport := get_viewport()
	for _i in max_presses:
		if viewport.gui_get_focus_owner() == target:
			return true
		_send_key(keycode)
		await get_tree().process_frame
	return viewport.gui_get_focus_owner() == target


## battle_over(그리고 승리라면 보상 UI, 패배라면 next_button)까지 실제 물리 전투가
## 끝나길 기다린다. 다이스 물리 정지 대기(여러 교환)가 몇 초씩 걸리고, 이 QA 창은
## 화면 밖(-4000,-4000)에 떠서 포커스가 없는 채로 돌아가 실제 fps가 60보다 낮게
## 나오는 경우가 있어(1200프레임=20초 가정으로는 실제로 타임아웃됨, player_hp=19
## monster_hp=2까지는 진행된 상태였음 — 거의 끝나가고 있었을 뿐) 넉넉한 타임아웃을
## 둔다.
func _wait_for_battle_result(combat: Node, max_frames: int = 4800) -> bool:
	for i in max_frames:
		if combat.battle_over:
			var reward_ready: bool = combat.player_won and combat._reward_action_buttons.size() > 0
			var lose_ready: bool = not combat.player_won and combat.next_button.visible
			if reward_ready or lose_ready:
				print("[KeyRun][debug] battle resolved at frame %d: player_won=%s player_hp=%s monster_hp=%s" % [
					i, combat.player_won, str(combat.get("player_hp")), str(combat.get("monster_hp"))])
				return true
		await get_tree().process_frame
	print("[KeyRun][debug] battle TIMED OUT after %d frames: battle_over=%s player_won=%s player_hp=%s monster_hp=%s" % [
		max_frames, combat.battle_over, combat.player_won, str(combat.get("player_hp")), str(combat.get("monster_hp"))])
	return false


func _run_key_sequence_playthrough() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var cs = get_tree().current_scene
	if cs == null or not cs.has_method("_debug_select_berserker"):
		_krlog(false, "캐릭터 선택 씬을 못 찾음(current_scene=%s) — GAME_START=character_select로 실행했는지 확인" % str(cs))
		_finish_key_run()
		return

	var viewport := get_viewport()

	# 1단계: 기본 포커스가 첫 카드(견습 모험가)인지 확인 — 화면 진입 시 아무 것도
	# 고르지 않은 상태에서도 방향키가 바로 먹혀야 한다는 "주 행동 키" 규칙의 일부.
	var novice_card: Control = cs._card_panels.get("novice")
	_krlog(viewport.gui_get_focus_owner() == novice_card,
		"character_select 진입 시 기본 포커스 = 첫 카드(견습 모험가)")

	# 2단계: [대형 기획 14] N-1 전수 감사에서 고친 버그 재확인 — 카드에서 오른쪽
	# 화살표로 "시작 스킬 슬롯"(이전에는 마우스로만 닿을 수 있었음)에 실제로
	# 도달하는지, 거기서 다시 왼쪽/위/아래로 카드로 돌아오는지.
	_send_key(KEY_RIGHT)
	await get_tree().process_frame
	var slot0: Control = cs._starting_skill_slot_buttons[0] if cs._starting_skill_slot_buttons.size() > 0 else null
	_krlog(slot0 != null and viewport.gui_get_focus_owner() == slot0,
		"카드에서 -> (오른쪽) 시작 스킬 슬롯[0]에 실제로 도달")
	_send_key(KEY_LEFT)
	await get_tree().process_frame
	_krlog(viewport.gui_get_focus_owner() == novice_card,
		"시작 스킬 슬롯에서 <- (왼쪽) 다시 카드로 복귀")

	# 3단계: 스페이스로 견습 모험가를 확정 선택(이미 기본 선택이지만, "포커스+스페이스
	# 확정"이라는 실제 활성화 경로 자체를 검증 — character_card_panel.gd._gui_input()의
	# ui_accept 분기).
	_send_key(KEY_SPACE)
	await get_tree().process_frame
	_krlog(cs._selected_id == "novice", "스페이스로 카드 확정 -> _selected_id=%s(기대 novice)" % cs._selected_id)

	# 4단계: 아래 방향키로 "던전 시작" 버튼까지 실제 도달 후 스페이스로 런 시작.
	var reached_start: bool = await _press_until_focused(cs.start_button, KEY_DOWN, 20)
	_krlog(reached_start, "카드 목록에서 아래 방향키로 \"던전 시작\" 버튼에 도달")
	_send_key(KEY_SPACE)
	for _i in 15:
		await get_tree().process_frame

	var dm = get_tree().current_scene
	_krlog(dm != null and dm.has_method("_on_combat_button_pressed"),
		"\"던전 시작\" 확정 -> dungeon_map 씬으로 실제 전환됨")
	if dm == null or not dm.has_method("_on_combat_button_pressed"):
		_finish_key_run()
		return
	_krlog(RunState.character_id == "novice" and RunState.rooms_cleared == 0,
		"RunState 실제 반영 — character_id=%s(기대 novice) rooms_cleared=%d(기대 0)" % [RunState.character_id, RunState.rooms_cleared])

	# 5~7단계: 방 2개(0번째/1번째)를 "전투 입장 -> 자동 전투 승리 -> 보상 선택 ->
	# 다음" 순으로 실제로 돌며, 매번 RunState.rooms_cleared가 실제로 증가하는지까지
	# 확인한다(플래그만이 아니라 "계산 결과"를 본다는 세션 규칙 반영).
	for room_idx in range(2):
		dm = get_tree().current_scene
		var viewport2 := get_viewport()
		_krlog(viewport2.gui_get_focus_owner() == dm.enter_combat_button,
			"dungeon_map(방 %d) 진입 시 기본 포커스 = 주 행동(전투 입장)" % room_idx)
		var rooms_before: int = RunState.rooms_cleared
		_send_key(KEY_SPACE)
		for _i in 15:
			await get_tree().process_frame

		var combat = get_tree().current_scene
		_krlog(combat != null and combat.has_method("_qa_is_settled"),
			"전투 입장 확정 -> combat_test 씬으로 실제 전환됨 (방 %d)" % room_idx)
		if combat == null or not combat.has_method("_qa_is_settled"):
			_finish_key_run()
			return

		var battle_ok: bool = await _wait_for_battle_result(combat)
		_krlog(battle_ok and combat.player_won,
			"전투가 실제 물리 굴림으로 자동 승리까지 끝남 (방 %d, player_won=%s)" % [room_idx, combat.player_won])
		if not battle_ok:
			_finish_key_run()
			return

		if combat.player_won:
			var first_reward: Button = combat._reward_action_buttons[0] if combat._reward_action_buttons.size() > 0 else null
			_krlog(first_reward != null and get_viewport().gui_get_focus_owner() == first_reward,
				"승리 보상 화면 기본 포커스 = 첫 보상 행동 버튼 (방 %d)" % room_idx)
			_send_key(KEY_SPACE)
			await get_tree().process_frame
			var reached_next: bool = await _press_until_focused(combat.next_button, KEY_DOWN, 10)
			_krlog(reached_next, "보상 선택 후 \"다음\" 버튼에 방향키로 도달 (방 %d)" % room_idx)
			_send_key(KEY_SPACE)
		else:
			_send_key(KEY_SPACE)
		for _i in 15:
			await get_tree().process_frame

		dm = get_tree().current_scene
		_krlog(dm != null and dm.has_method("_on_combat_button_pressed"),
			"\"다음\" 확정 -> dungeon_map으로 실제 복귀 (방 %d)" % room_idx)
		_krlog(RunState.rooms_cleared == rooms_before + 1,
			"RunState.rooms_cleared 실제 증가 — %d -> %d (방 %d)" % [rooms_before, RunState.rooms_cleared, room_idx])

	_finish_key_run()


func _finish_key_run() -> void:
	print("[VisualQA] key-sequence playthrough %s (%d개 중 %s)" % [
		"PASS" if _key_run_ok else "FAIL",
		_key_run_log.size(),
		"전부 OK" if _key_run_ok else "일부 FAIL",
	])
	get_tree().quit(0 if _key_run_ok else 1)
