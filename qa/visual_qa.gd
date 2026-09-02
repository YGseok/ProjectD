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
##      - 우선순위 2: res://scenes/<name>/<name>.tscn (폴더당 씬 1개 컨벤션)
##      - 우선순위 3: res://scenes/<name>.tscn (평면 컨벤션)
##   2. GAME_QA_FRAME 번째 프레임까지 기다린다 (기본 60, 로딩/애니메이션 안정화 목적).
##   3. 뷰포트를 이미지로 캡처해 PNG로 저장한다.
##      - GAME_QA_OUT 이 지정되면 그 경로(res:// 또는 절대경로)에 저장.
##      - 없으면 res://qa_out/<GAME_START>.png 에 저장.
##   4. 창을 닫는다 (get_tree().quit()).
##
## 환경변수 목록:
##   GAME_START       (필수, QA 모드 트리거) 예: dungeon
##   GAME_START_PATH  (선택) 씬 경로를 컨벤션 대신 직접 지정. 예: res://scenes/dungeon/dungeon.tscn
##   GAME_QA_FRAME    (선택, 기본 60) 몇 프레임 후에 캡처할지
##   GAME_QA_OUT      (선택) 출력 PNG 경로. 예: res://qa_out/dungeon.png 또는 절대경로
##   GAME_QA_CALL     (선택) 캡처 직전에 현재 씬 루트에서 인자 없이 호출할 메서드 이름.
##                    클릭을 흉내낼 수 없는 자동 QA에서, 다단계 UI(예: 보상 화면의
##                    하위 선택 화면)를 직접 함수 호출로 열어서 스크린샷으로 확인할 때 씀.

var _qa_active := false
var _target_frame := 60
var _frame_count := 0
var _output_path := ""
var _scene_name := ""
var _qa_call := ""


func _ready() -> void:
	_scene_name = OS.get_environment("GAME_START")
	if _scene_name.is_empty():
		# QA 모드가 아님 -> 평상시 게임 실행. 아무것도 하지 않는다.
		return

	_qa_active = true

	var frame_env := OS.get_environment("GAME_QA_FRAME")
	if not frame_env.is_empty() and frame_env.is_valid_int():
		_target_frame = frame_env.to_int()

	var explicit_path := OS.get_environment("GAME_START_PATH")
	var scene_path := explicit_path
	if scene_path.is_empty():
		scene_path = "res://scenes/%s/%s.tscn" % [_scene_name, _scene_name]
		if not ResourceLoader.exists(scene_path):
			scene_path = "res://scenes/%s.tscn" % _scene_name

	if not ResourceLoader.exists(scene_path):
		push_error("[VisualQA] GAME_START='%s' 에 해당하는 씬을 찾을 수 없습니다. 시도한 경로: %s (GAME_START_PATH로 직접 지정 가능)" % [_scene_name, scene_path])
		get_tree().quit(1)
		return

	_output_path = OS.get_environment("GAME_QA_OUT")
	if _output_path.is_empty():
		_output_path = "res://qa_out/%s.png" % _scene_name

	_qa_call = OS.get_environment("GAME_QA_CALL")

	# 엔진이 메인 씬을 트리에 추가하는 도중이라 change_scene_to_file을 즉시 호출하면
	# "Parent node is busy adding/removing children" 에러가 난다. 한 프레임 넘겨서 호출한다.
	await get_tree().process_frame

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[VisualQA] 씬 전환 실패: %s (err=%s)" % [scene_path, err])
		get_tree().quit(1)
		return

	print("[VisualQA] scene='%s' frame=%d out='%s'" % [scene_path, _target_frame, _output_path])
	set_process(true)


func _process(_delta: float) -> void:
	if not _qa_active:
		return
	_frame_count += 1
	if _frame_count >= _target_frame:
		set_process(false)
		_capture_and_quit()


func _capture_and_quit() -> void:
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


func _resolve_absolute_path(path: String) -> String:
	if path.begins_with("res://"):
		return ProjectSettings.globalize_path(path)
	return path
