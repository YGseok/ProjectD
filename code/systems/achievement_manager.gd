extends Node
## 업적 시스템 골격 (INBOX.md 2026-09-09 "[대형 기획 3] 업적 시스템 추가").
##
## 사용자가 30종 업적 아이디어를 한 번에 제안했지만, 최상위 세션 지침("업적 30종처럼
## 목록이 긴 항목은 시스템(저장/추적/UI) 먼저 만들고 업적 몇 개씩 나눠서 추가")에 따라
## 이번 이터레이션은 골격만 완성한다: 영구 저장(런/씬 전환과 무관하게 유지), 해금 판정
## API, 목록 조회 API. RunState는 새 런을 시작하면 reset_run()으로 초기화되지만, 업적은
## "게임을 껐다 켜도, 런을 몇 번을 다시 시작해도 유지"돼야 하므로 RunState가 아니라
## 별도 Autoload + user://achievements.json 저장을 쓴다.
##
## 이번에 실제로 등록한 업적은 서로 다른 3개의 후킹 지점(캐릭터 선택 화면 버튼 / 던전
## 맵의 런 완료 판정 / 전투 승리 판정)을 검증하기 위해 고른 3종뿐이다 (INBOX 제안 번호
## #25, #1, #6). 나머지 27종은 docs/STATUS.md 다음 할 일 큐에 남겨 다음 이터레이션들이
## 이어서 채운다 — 이 파일의 DEFINITIONS에 항목을 추가하고, 해당 조건이 되는 지점에서
## AchievementManager.unlock(id)만 호출하면 저장/UI 표시는 자동으로 따라온다.

const SAVE_PATH := "user://achievements.json"

## id -> {title, desc}. desc 끝의 "(INBOX #N)"은 INBOX.md가 제안했던 30종 목록의
## 원래 번호 — 나중에 나머지를 추가할 때 어떤 게 남았는지 추적하기 위해 남겨둔다.
const DEFINITIONS := {
	"first_run_start": {
		"title": "첫 발걸음",
		"desc": "던전을 처음 시작했다. (INBOX #25)",
	},
	"round1_clear": {
		"title": "던전 클리어",
		"desc": "첫 던전(라운드 1)을 클리어했다. (INBOX #1)",
	},
	"win_with_d20": {
		"title": "거인의 주사위",
		"desc": "D20 다이스를 보유한 채로 전투에서 승리했다. (INBOX #6)",
	},
}

## id -> 해금 시각(unix time, int). Dictionary 순서가 삽입 순서를 유지하므로 저장/로드
## 왕복에도 문제 없다.
var _unlocked: Dictionary = {}


func _ready() -> void:
	_load()


func is_unlocked(id: String) -> bool:
	return _unlocked.has(id)


## 업적을 해금한다. 이미 해금돼 있으면 아무 일도 하지 않고 false를 반환(중복 저장/알림
## 방지 — 같은 조건이 여러 번 참이 될 수 있는 호출부에서 매번 체크하지 않아도 되게 함).
## 새로 해금된 경우에만 true를 반환한다.
func unlock(id: String) -> bool:
	if not DEFINITIONS.has(id):
		push_warning("AchievementManager.unlock: 정의되지 않은 업적 id '%s'" % id)
		return false
	if _unlocked.has(id):
		return false
	_unlocked[id] = int(Time.get_unix_time_from_system())
	_save()
	return true


## 정의 순서대로 [{id, title, desc, unlocked}] 목록을 반환한다 — UI가 그대로 순회해서
## 그리면 된다.
func get_all_for_display() -> Array:
	var out: Array = []
	for id in DEFINITIONS.keys():
		var def: Dictionary = DEFINITIONS[id]
		out.append({
			"id": id,
			"title": def.title,
			"desc": def.desc,
			"unlocked": is_unlocked(id),
		})
	return out


func _load() -> void:
	_unlocked = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		_unlocked = parsed


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("AchievementManager: 저장 실패 (%s)" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(_unlocked))
	f.close()


## QA 전용: 저장 파일과 메모리 상태를 초기화해 스크린샷을 결정적으로 만든다(이전 QA
## 실행에서 남은 해금 상태가 다음 실행에 섞이지 않도록). 실제 플레이 코드 경로에서는
## 호출되지 않는다.
func _debug_reset_for_qa() -> void:
	_unlocked = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
