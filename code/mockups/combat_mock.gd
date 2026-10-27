extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28, 1단계 와이어프레임 반려 후) — 전투 화면 개편
## 시안(S-7b 중심, S-2/S-6).
##
## 1단계 반려 사유: 배경·캐릭터/몬스터 초상·다이스 스테이지·공격/방어 다이스 줄·몬스터
## 정보가 전부 빠지고 전투 기록 패널(가짜 로그 텍스트)만 화면을 채웠다.
## 재작업: code/scenes/combat_test.tscn을 그대로 instantiate()한다 — 배경/HUD/포트레이트/
## 3D 다이스 스테이지는 실제 씬이 _ready()에서 전부 정상적으로 그리므로 손댈 필요가 없고,
## S-7b가 지적한 "전투 기록 패널이 화면 밖으로 삐져나감" 문제만 패치한다.

const RealScene := preload("res://code/scenes/combat_test.tscn")

var _real: Node
var _key_overlay: KeyOverlay


func _ready() -> void:
	_real = RealScene.instantiate()
	add_child(_real)
	await get_tree().process_frame

	_patch_log_panel()
	_patch_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


## GAME_QA_SETTLE(다이스 물리 정지 대기)이 이 래퍼(=current_scene)에서 훅을 찾으므로,
## 실제 combat_test 인스턴스의 _qa_is_settled()로 그대로 넘긴다 — 없으면 combat_test.gd가
## 그 메서드를 아직 구현 안 했다는 뜻이라 항상 true(= 바로 캡처, 기존 하위 호환과 동일).
func _qa_is_settled() -> bool:
	if _real != null and _real.has_method("_qa_is_settled"):
		return _real.call("_qa_is_settled")
	return true


## QA 전용 forwarding — qa_shot.sh의 4번째 인자(qa_call)로 실제 씬의 0-arity 디버그
## 훅(예: _debug_show_reward_after_last_exchange)을 그대로 호출하고 싶을 때 쓴다.
## visual_qa.gd가 scene.call(method)를 "current_scene"(=이 래퍼)에 거므로, 없는
## 메서드면 실제 인스턴스로 그대로 전달한다.
func _debug_show_reward_after_last_exchange() -> void:
	if _real != null and _real.has_method("_debug_show_reward_after_last_exchange"):
		_real.call("_debug_show_reward_after_last_exchange")


## S-7b: "전투 기록" 패널이 y=572(배경/초상/다이스 스테이지 아래 — 그대로 둠)에서
## 시작해 높이 무제한이라 로그가 쌓이면 하단이 화면(720) 밖으로 나간다
## (combat_test.gd:1655~1657 확인됨). **위치는 건드리지 않는다**(x/y를 옮기면 배경
## 원화·초상·다이스 스테이지를 덮어버린다 — 1단계 반려 사유를 반복하게 됨). 대신
## log_label(실제 전투 로그 텍스트, 가짜 데이터 아님)을 고정 높이 ScrollContainer로
## 감싸 내용이 넘쳐도 패널 전체 높이가 더 이상 안 늘어나게 한다 — 화면 바닥(720)까지
## 쓸 수 있는 여유(720-572=148, 안쪽 여백 16을 뺀 132) 안에 패널이 들어온다.
func _patch_log_panel() -> void:
	var log_panel: Control = _real.get("_log_panel")
	var log_label: Control = _real.get("log_label")
	if log_panel == null or log_label == null:
		return

	var body: Node = log_panel.get_child(0) if log_panel.get_child_count() > 0 else null
	if body == null:
		return

	var log_parent := log_label.get_parent()
	if log_parent != null:
		log_parent.remove_child(log_label)

	var scroll := ScrollContainer.new()
	# title(~20) + divider(~2) + player_status_label(~18) + scroll(90) + 안쪽 여백(16)
	# ≈ 146 — 572+146=718, 화면(720) 안에 들어온다.
	scroll.custom_minimum_size = Vector2(0, 90)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	log_label.custom_minimum_size = Vector2(960, 0)
	scroll.add_child(log_label)


## S-2/S-6: 토글/행동 버튼 장식 방향 — 다른 화면(MOCKUP_REVIEW.md 9절)과 같은 결정을
## 따르므로 여기서는 고정으로 "더 나은 쪽"(B안, 플랫)을 적용한다(character_select/
## monster_codex만 A/B 둘 다 비교용으로 찍는다 — 지시 (3)).
func _patch_buttons() -> void:
	var cid := RunState.character_id
	var secondary_names := ["skill_codex_button", "customize_toggle_button", "deck_toggle_button", "test_retry_button", "test_back_button"]
	for n in secondary_names:
		var b: Button = _real.get(n)
		if b != null:
			MockupCommon.restyle_button(b, cid, false, "B")
	var next_btn: Button = _real.get("next_button")
	if next_btn != null:
		MockupCommon.restyle_button(next_btn, cid, true, "B")


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(140, 560, 1000, 48), "number": 1, "label": "행동 버튼 줄(좌/우, 전투는 자동 진행)"},
	])
