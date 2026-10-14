extends Node
## 캐릭터별 스킬 도감 발견 기록 ([대형 기획 12] L-2(a), INBOX.md 2026-10-14).
##
## AchievementManager(achievement_manager.gd)와 같은 패턴(Autoload + user:// JSON
## 영구 저장)을 그대로 따른다 — "이 캐릭터로 이 스킬을 한 번이라도 봤다"는 사실은
## RunState.reset_run()으로 매 런 초기화되면 안 되고, 게임을 껐다 켜도 유지돼야 한다.
##
## 기록 시점(INBOX.md L-2 원문 4가지): 스킬이 선택지로 화면에 표시된 순간, 획득한
## 순간, 시작 스킬로 고른 순간, 캐릭터 선택 화면에서 잠금 미리보기로 상세를 본 순간.
## 네 시점 모두 "실제로 표시되거나 얻은" 사건이므로, 호출부(event.gd의
## _show_skill_offer, character_select.gd의 _rebuild_starting_skill_slots/
## _on_starting_skill_locked_preview)가 그 시점에 mark_discovered()를 직접 부르는
## 방식으로 통일했다 — SkillPool.grant()/RunState.reset_run() 안에 넣지 않은 이유:
## reset_run()이 시작 스킬을 SkillPool.grant()로 부여하는 시점에는
## RunState.test_battle이 아직 false로 리셋된 상태다(reset_run() 자신이 그 필드를
## 맨 먼저 초기화하고, 테스트 전투 설정 화면인 test_battle_setup.gd._apply_start_
## selection()은 reset_run() 호출이 끝난 "다음" 줄에서야 test_battle=true를 세팅함).
## 그래서 "테스트 전투에서는 기록하지 않는다" 가드를 grant()/reset_run() 안에 두면
## 바로 이 순서 때문에 뚫린다 — 대신 "실제 캐릭터 선택 화면/이벤트 화면에서 사용자가
## 보거나 고른" 지점에서만 mark_discovered()를 부르므로, 그 화면들을 거치지 않는
## test_battle_setup.gd(완전히 별도 UI)는 자연히 제외된다.

const SAVE_PATH := "user://skill_codex.json"

## character_id -> Array[String](그 캐릭터로 발견한 skill_id들). Dictionary/Array
## 둘 다 삽입 순서를 유지하므로 저장/로드 왕복에 문제 없다.
var _discovered: Dictionary = {}


func _ready() -> void:
	_load()


## character_id로 skill_id를 발견 기록에 추가한다. 테스트 전투 중(RunState.test_battle)
## 에는 절대 기록하지 않는다(업적/진행도와 같은 원칙, INBOX.md 명시) — 호출부가 이미
## test_battle_setup.gd를 거치지 않는 화면에서만 부르므로 이 가드는 주로 방어적
## 안전장치다. character_id/skill_id가 비어있으면 아무 일도 하지 않는다.
func mark_discovered(character_id: String, skill_id: String) -> void:
	if RunState.test_battle or character_id == "" or skill_id == "":
		return
	var list: Array = _discovered.get(character_id, [])
	if list.has(skill_id):
		return
	list.append(skill_id)
	_discovered[character_id] = list
	_save()


func is_discovered(character_id: String, skill_id: String) -> bool:
	var list: Array = _discovered.get(character_id, [])
	return list.has(skill_id)


## 그 캐릭터로 발견한 skill_id 전체 목록(복사본)을 반환한다.
func discovered_ids_for(character_id: String) -> Array:
	var list: Array = _discovered.get(character_id, [])
	return list.duplicate()


func discovered_count_for(character_id: String) -> int:
	var list: Array = _discovered.get(character_id, [])
	return list.size()


func _load() -> void:
	_discovered = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		_discovered = parsed


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SkillCodex: 저장 실패 (%s)" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(_discovered))
	f.close()


## QA 전용: 저장 파일과 메모리 상태를 초기화해 스크린샷/테스트를 결정적으로 만든다
## (AchievementManager._debug_reset_for_qa()와 동일한 패턴). 실제 플레이 코드 경로에서는
## 호출되지 않는다.
func _debug_reset_for_qa() -> void:
	_discovered = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
