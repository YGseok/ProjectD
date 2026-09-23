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
## 처음 등록한 업적은 서로 다른 3개의 후킹 지점(캐릭터 선택 화면 버튼 / 던전
## 맵의 런 완료 판정 / 전투 승리 판정)을 검증하기 위해 고른 3종뿐이었다 (INBOX 제안 번호
## #25, #1, #6). 2026-09-09 (80)에 4종을 추가했다 — 원래 30종 목록에서 "골드 100
## 보유"/"오버킬"/"무결점 승리"/"기사회생" 계열로 STATUS.md가 예시로 들었던 항목들이지만,
## 원문 목록 자체가 보존돼 있지 않아 정확한 원래 번호는 알 수 없다(desc에 "(INBOX #N)"이
## 없는 항목은 이 사정을 뜻함). 나머지는 docs/STATUS.md 다음 할 일 큐에 남겨 다음
## 이터레이션들이 이어서 채운다 — 이 파일의 DEFINITIONS에 항목을 추가하고, 해당 조건이
## 되는 지점에서 AchievementManager.unlock(id)만 호출하면 저장/UI 표시는 자동으로
## 따라온다.

const SAVE_PATH := "user://achievements.json"

## id -> {title, desc, icon}. desc 끝의 "(INBOX #N)"은 INBOX.md가 제안했던 30종 목록의
## 원래 번호 — 나중에 나머지를 추가할 때 어떤 게 남았는지 추적하기 위해 남겨둔다.
## "icon"은 achievement_icon.gd(AchievementIcon)의 category 문자열(CATEGORIES 참고) —
## INBOX.md 2026-09-14 "업적에 유형별 아이콘을 추가한다"를 반영해 골드류는 "gold",
## 다이스류는 "dice" 식으로 업적의 "유형"에 맞춰 배정했다(개별 업적 전용 그림이 아니라
## 유형 공유 아이콘 — 요청 문구 "유형별 아이콘"을 그대로 따름).
const DEFINITIONS := {
	"first_run_start": {
		"title": "첫 발걸음",
		"desc": "던전을 처음 시작했다. (INBOX #25)",
		"icon": "start",
	},
	"round1_clear": {
		"title": "던전 클리어",
		"desc": "첫 던전(라운드 1)을 클리어했다. (INBOX #1)",
		"icon": "milestone",
	},
	"win_with_d20": {
		"title": "거인의 주사위",
		"desc": "D20 다이스를 보유한 채로 전투에서 승리했다. (INBOX #6)",
		"icon": "dice",
	},
	"gold_100": {
		"title": "부자",
		"desc": "골드를 한 번에 100 이상 보유했다.",
		"icon": "gold",
	},
	"flawless_win": {
		"title": "무결점 승리",
		"desc": "전투 중 단 한 대도 맞지 않고 승리했다.",
		"icon": "combat",
	},
	"comeback_win": {
		# 임계치(2)는 combat_test.gd의 COMEBACK_HP_THRESHOLD와 맞춰뒀다 (여기서 직접
		# 참조하지 않는 이유: DEFINITIONS가 const dict라 다른 스크립트의 preload 없이
		# 상수 참조가 어려움 — 값이 바뀌면 이 문구도 함께 고쳐야 한다).
		"title": "기사회생",
		"desc": "체력이 2 이하로 떨어진 채로 위기를 넘기고 승리했다.",
		"icon": "combat",
	},
	"overkill_win": {
		"title": "오버킬",
		"desc": "몬스터의 최대 체력 이상인 데미지를 한 방에 꽂아 넣어 승리했다.",
		"icon": "combat",
	},
	# 아래 3종은 combat_test.gd가 아니라 dungeon_map.gd의 _update_labels()에서 체크한다 —
	# 눈금/다이스 인벤토리와 주머니 캡은 특정 화면 하나에서만 바뀌는 게 아니라(상점/특수
	# 이벤트/전투 승리 보상 여러 곳에서 쌓임) 어느 화면으로 돌아오든 항상 들르는
	# 던전 맵에서 검사하는 게 "round1_clear"와 같은 패턴으로 더 안전하다.
	"pip_hoarder": {
		"title": "눈금 수집가",
		"desc": "눈금 인벤토리에 10개 이상을 동시에 보유했다.",
		"icon": "pip",
	},
	"die_hoarder": {
		"title": "다이스 수집가",
		"desc": "다이스 인벤토리에 5개 이상을 동시에 보유했다.",
		"icon": "dice",
	},
	"bag_maxed": {
		"title": "가득 찬 주머니",
		"desc": "공격 또는 방어 주머니를 최대 개수(6개)까지 채웠다.",
		"icon": "bag",
	},
	"shop_regular": {
		"title": "단골 손님",
		"desc": "한 런에서 상점을 3회 이상 이용했다.",
		"icon": "shop",
	},
	"material_collector": {
		"title": "재질 수집가",
		"desc": "플라스틱/나무/유리/철제 재질 다이스를 동시에 모두 보유했다.",
		"icon": "material",
	},
	# 아래 7종(라운드 2/최종 클리어 + 캐릭터별 첫 클리어)은 STATUS.md 큐 13이
	# "[대형 기획 1](5종 캐릭터)/[대형 기획 2](라운드·보스 구조)가 둘 다 완료돼 트리거
	# 지점이 갖춰졌다"고 정리한 항목 — combat_test.gd의 _apply_room_advance()가 보스를
	# 잡은 시점(advance_round()로 round_index가 바뀌기 전)에 직접 unlock한다. 이 작업 중
	# 기존 "round1_clear"가 실제로는 라운드 1이 아니라 "최종 라운드까지 전부 클리어"할
	# 때만 불렸던 버그(advance_round()가 매 라운드 즉시 rooms_cleared를 0으로 되돌려,
	# dungeon_map.gd의 RunState.is_run_complete() 기준 판정이 마지막 라운드 클리어와만
	# 겹쳤던 것)를 발견해 함께 고쳤다 — 아래 combat_test.gd 참고.
	"round2_clear": {
		"title": "라운드 2 클리어",
		"desc": "두 번째 라운드(던전)를 클리어했다.",
		"icon": "milestone",
	},
	"game_clear": {
		"title": "최종 승리",
		"desc": "3라운드 전부 클리어하고 최종 보스를 물리쳤다.",
		"icon": "milestone",
	},
	"clear_novice": {
		"title": "견습 모험가로 첫 클리어",
		"desc": "견습 모험가로 최종 클리어(3라운드 전부)에 성공했다.",
		"icon": "milestone",
	},
	"clear_berserker": {
		"title": "광전사로 첫 클리어",
		"desc": "광전사로 최종 클리어(3라운드 전부)에 성공했다.",
		"icon": "milestone",
	},
	"clear_guardian": {
		"title": "수호자로 첫 클리어",
		"desc": "수호자로 최종 클리어(3라운드 전부)에 성공했다.",
		"icon": "milestone",
	},
	"clear_explosive": {
		"title": "폭발병으로 첫 클리어",
		"desc": "폭발병으로 최종 클리어(3라운드 전부)에 성공했다.",
		"icon": "milestone",
	},
	"clear_shieldbearer": {
		"title": "침묵의 무녀로 첫 클리어",
		"desc": "침묵의 무녀로 최종 클리어(3라운드 전부)에 성공했다.",
		"icon": "milestone",
	},
	# 큐 13("업적 시스템 — 남은 항목 추가") 후속. 특수 이벤트의 "위험을 감수하기"
	# 판정(event.gd의 _resolve_risky)이 성공한 순간 바로 unlock — 새 RunState 카운터
	# 없이 이미 있는 성공/실패 분기 지점 하나만 후킹하면 되는 독립 항목이라 사람의
	# 원 목록(미보존) 없이도 추가 가능했다.
	"risk_taker": {
		"title": "위험을 감수한 자",
		"desc": "특수 이벤트에서 \"위험을 감수하기\"를 선택해 판정에 성공했다.",
		"icon": "dice",
	},
	# combat_test.gd의 패배 분기(player_hp <= 0)는 지금까지 유일하게 unlock() 호출이 하나도
	# 없던 결과 분기였다 — 승리 쪽엔 이미 5종(win_with_d20/flawless/comeback/overkill/
	# gold_100)이 달려 있는데 패배 쪽엔 아무 업적도 없어 대칭이 맞지 않았다. 새 RunState
	# 카운터 없이 이미 있는 분기 하나만 후킹하면 되는 독립 항목이라 risk_taker와 같은
	# 패턴으로 추가.
	"first_defeat": {
		"title": "패배도 경험이다",
		"desc": "던전에서 처음으로 패배(전멸)했다.",
		"icon": "combat",
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
			"icon": def.get("icon", "milestone"),
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
