class_name MonsterCatalog
extends RefCounted
## 몬스터 계열(패밀리) + 몬스터 카탈로그 데이터 (INBOX.md [대형 기획 6] G-1, 2026-10-07).
##
## 사람이 이미 설계해둔 몬스터 대개편(계열 4종 + 일반/정예/보스 대형 풀 + 정예 방)의
## 첫 조각 — "데이터 표"만 먼저 만들고 **전투 동작은 바꾸지 않는다**. 기존
## `combat_test.gd`의 `MONSTER_PROFILES`(5종)를 그대로 옮겨왔을 뿐, dice_gimmick
## 적용 로직(`_monster_config_for_room()` 등)은 손대지 않았다 — 결과가 전과
## 완전히 같아야 한다(`dice_test.gd`의 기존 몬스터 스케일링 검증이 그대로 PASS해야 함).
##
## FAMILIES: 계열 4종(id -> {name, description}). `family_icon.gd`(FamilyIcon)가
## 이 id를 category로 받아 전용 도형을 그린다. 사용자 지시 원문의 예시를 그대로 따름:
## - "humanoid"(인간형): 방어/장비 계열 (예: 고블린 = 방어 관련 무언가를 함)
## - "amorphous"(부정형): 플레이어 주사위를 직접 건드리는 계열 (예: 슬라임/유령)
## - "beast"(야수형): 공격/폭딜 계열
## - "undead"(언데드형): 흡수/부활/지속 효과 계열
## 5번째 계열은 만들지 않는다(필요해지면 나중에, INBOX.md 원문 지시).
##
## MONSTERS: 몬스터 1종당 1개 Dictionary.
## - "id": 고유 id. 아트 리소스 경로에도 재사용(ART-1c, `res://resources/monsters/<id>/`).
##   기존 5종은 아트 스레드가 이미 쓰고 있는 이름(slime/goblin/skeleton/orc/dark_knight)을
##   그대로 맞춤.
## - "name"/"color"/"personality": 기존 MONSTER_PROFILES와 동일한 의미.
## - "family": 위 FAMILIES의 키.
## - "tier": "normal" | "elite" | "boss". 지금은 전부 "normal" — G-7(정예 8종)/
##   G-8(보스 6종)이 각각 "elite"/"boss" 몬스터를 이 배열에 추가한다.
## - "skills": 스킬 id(+파라미터) 목록 — `monster_skills.gd`(`MonsterSkills`)가 읽는
##   필드. 지금은 각 원소가 {"id": <기존 dice_gimmick 문자열>}뿐이고(기믹 없는 슬라임은
##   빈 배열), 실제 적용은 여전히 `combat_test.gd`가 `gimmick_of()`로 skills[0].id를
##   꺼내 기존 "dice_gimmick" 코드 경로에 그대로 넘기는 다리 역할만 한다. G-3(2026-10-07)
##   으로 `MonsterSkills`에 인간형 "armor"(파라미터 "amount")/"guard_up"/"counter"
##   (파라미터 "amount") + 부정형 "sticky"/"seal"/"dull"/"numb"(파라미터 없음) 7종이
##   추가됐지만, G-5(일반 몬스터 20종)가 몬스터 데이터를 채우기 전까지는 이 배열에
##   실제로 쓰는 몬스터가 없다 — 지금 5종은 전부 기존 4종(anger_stack/fixed_value/
##   min_max_only/steady_guard) 그대로.
## - "hp_mult": 등급별/개체별 HP 배율. 기존 5종은 전부 1.0(동작 변경 없음). G-5(2026-10-07)
##   부터 `combat_test.gd`의 `_monster_config_for_room()`이 `max_hp = round((10 + room*3) *
##   hp_mult)`로 실제 반영한다(기존 1.0짜리는 결과가 그대로라 동작 보존, 신규 몬스터 중
##   "좀비"만 1.4로 체력이 더 높다).
## - "atk_dice_delta"/"def_dice_delta": 몬스터별 공격/방어 다이스 "개수" 보정(기본 0,
##   없으면 0). G-5 원문이 일부 몬스터에 붙인 "공격 다이스 +1"/"방어 낮음" 같은 수치
##   메모를 스킬 프리미티브가 아니라 이 필드로 표현한다(`_monster_config_for_room()`의
##   attack_count/defense_count 계산에 더해지고 최소 1개로 클램프됨). 기존 5종은 전부
##   0(동작 보존).
##
## G-5(2026-10-07) 범위/의도적 보류: INBOX.md 원문은 "고블린"을 anger_stack 대신
## armor(1)로, "슬라임"을 기믹 없음 대신 sticky로 재배정하길 원했지만(같은 계열은 비슷한
## 스타일), 이 재배정은 `dice_test.gd`에 room0/room1 기믹을 하드코딩한 회귀 테스트가
## 여러 곳 있고 실제 던전 순환(`legacy_cycle_monster()`)에도 바로 영향을 준다. G-6이
## 어차피 이 순환 로직 자체를 "런 몬스터 계획"으로 통째로 교체할 예정이라, 기존 5종의
## 재배정은 그때 테스트와 함께 한 번에 다시 쓰는 게 더 안전하다고 판단해 이번 이터레이션은
## **신규 15종 추가만** 하고 기존 5종(슬라임/고블린/해골 전사/오크/다크 나이트)의 skills/
## family/tier는 전혀 건드리지 않았다(다크 나이트는 G-7에서 정예로 재배정될 예정이라 이미
## G-5의 "일반 20종" 목록 자체에서 빠져 있음 — INBOX.md 원문 그대로).

const FAMILIES := {
	"humanoid": {"name": "인간형", "description": "방어/장비 중심 — 몬스터 자신의 방어를 강화한다"},
	"amorphous": {"name": "부정형", "description": "플레이어 주사위를 직접 건드린다"},
	"beast": {"name": "야수형", "description": "공격/폭딜 중심 — 몬스터 자신의 공격을 강화한다"},
	"undead": {"name": "언데드형", "description": "흡수/부활/지속 효과 중심"},
}

const MONSTERS := [
	{
		"id": "slime", "name": "슬라임", "family": "amorphous", "tier": "normal",
		"color": Color(0.35, 0.85, 0.4), "skills": [], "hp_mult": 1.0,
		"personality": "무기력하고 단순함",
	},
	{
		"id": "goblin", "name": "고블린", "family": "humanoid", "tier": "normal",
		"color": Color(0.75, 0.55, 0.25), "skills": [{"id": "anger_stack"}], "hp_mult": 1.0,
		"personality": "성급하고 화를 잘 냄",
	},
	{
		"id": "skeleton", "name": "해골 전사", "family": "undead", "tier": "normal",
		"color": Color(0.85, 0.85, 0.8), "skills": [{"id": "fixed_value"}], "hp_mult": 1.0,
		"personality": "감정 없이 명령대로만 움직이는 병사, 늘 같은 힘으로 정확하게 타격",
	},
	{
		"id": "orc", "name": "오크", "family": "beast", "tier": "normal",
		"color": Color(0.3, 0.55, 0.3), "skills": [{"id": "min_max_only"}], "hp_mult": 1.0,
		"personality": "힘만 믿고 저돌적으로 날뛰는 성격, 전부 아니면 전무",
	},
	{
		"id": "dark_knight", "name": "다크 나이트", "family": "humanoid", "tier": "normal",
		"color": Color(0.55, 0.25, 0.75), "skills": [{"id": "steady_guard"}], "hp_mult": 1.0,
		"personality": "차갑고 노련하며 방어에서 흔들리지 않는 기사",
	},
	# G-5(2026-10-07) 신규 15종 — INBOX.md [대형 기획 6] G-5 표 그대로(수치는 전부 잠정값,
	# F-4 시뮬로 조정 예정). 계열당 기존 2~3종 + 신규로 정확히 5종씩이 되도록 채움.
	{
		"id": "armored_goblin", "name": "아머 고블린", "family": "humanoid", "tier": "normal",
		"color": Color(0.6, 0.45, 0.2), "skills": [{"id": "armor", "amount": 2}], "hp_mult": 1.0,
		"personality": "묵직한 철판을 두르고 묵묵히 버티는 고블린",
	},
	{
		"id": "shield_goblin", "name": "방패 고블린", "family": "humanoid", "tier": "normal",
		"color": Color(0.68, 0.5, 0.28), "skills": [{"id": "guard_up"}], "hp_mult": 1.0,
		"personality": "체력이 떨어질수록 방패를 더 단단히 그러쥐는 고블린",
	},
	{
		"id": "bandit", "name": "산적", "family": "humanoid", "tier": "normal",
		"color": Color(0.5, 0.35, 0.2), "skills": [{"id": "counter", "amount": 1}], "hp_mult": 1.0,
		"personality": "방심한 공격을 그대로 되받아치는 데 능숙한 산적",
	},
	{
		"id": "guard_soldier", "name": "경비병", "family": "humanoid", "tier": "normal",
		"color": Color(0.45, 0.45, 0.55), "skills": [{"id": "steady_guard"}], "hp_mult": 1.0,
		"personality": "정해진 자리를 흔들림 없이 지키는 병사",
	},
	{
		"id": "poison_slime", "name": "독 슬라임", "family": "amorphous", "tier": "normal",
		"color": Color(0.45, 0.75, 0.2), "skills": [{"id": "sticky"}], "atk_dice_delta": 1,
		"hp_mult": 1.0, "personality": "끈적한 독액으로 상대의 움직임을 둔하게 만드는 슬라임",
	},
	{
		"id": "ghost", "name": "유령", "family": "amorphous", "tier": "normal",
		"color": Color(0.75, 0.8, 0.85), "skills": [{"id": "seal"}], "hp_mult": 1.0,
		"personality": "가장 약한 손놀림을 그대로 봉인해버리는 유령",
	},
	{
		"id": "shadow", "name": "그림자", "family": "amorphous", "tier": "normal",
		"color": Color(0.2, 0.2, 0.25), "skills": [{"id": "dull"}], "hp_mult": 1.0,
		"personality": "날카로운 기세를 슬그머니 무디게 만드는 그림자",
	},
	{
		"id": "mist", "name": "안개", "family": "amorphous", "tier": "normal",
		"color": Color(0.8, 0.85, 0.85), "skills": [{"id": "numb"}], "hp_mult": 1.0,
		"personality": "손끝의 감각을 흐려놓는 자욱한 안개",
	},
	{
		"id": "wolf", "name": "늑대", "family": "beast", "tier": "normal",
		"color": Color(0.45, 0.45, 0.5), "skills": [{"id": "pounce", "amount": 3}], "hp_mult": 1.0,
		"personality": "싸움이 시작되는 순간 가장 거칠게 달려드는 늑대",
	},
	{
		"id": "mad_dog", "name": "광견", "family": "beast", "tier": "normal",
		"color": Color(0.55, 0.4, 0.3), "skills": [{"id": "anger_stack"}], "hp_mult": 1.0,
		"personality": "조금만 거슬려도 이성을 잃고 날뛰는 개",
	},
	{
		"id": "boar", "name": "멧돼지", "family": "beast", "tier": "normal",
		"color": Color(0.4, 0.28, 0.18), "skills": [{"id": "bloodlust"}], "hp_mult": 1.0,
		"personality": "피를 흘릴수록 더 거세게 돌진하는 멧돼지",
	},
	{
		"id": "dire_spider", "name": "독거미", "family": "beast", "tier": "normal",
		"color": Color(0.3, 0.15, 0.35), "skills": [{"id": "pounce", "amount": 2}],
		"def_dice_delta": -1, "hp_mult": 1.0,
		"personality": "방어는 허술해도 첫 기습만큼은 치명적인 거미",
	},
	{
		"id": "ghoul", "name": "구울", "family": "undead", "tier": "normal",
		"color": Color(0.5, 0.55, 0.35), "skills": [{"id": "drain"}], "hp_mult": 1.0,
		"personality": "할퀸 상처에서 생기를 빨아들여 되살아나는 구울",
	},
	{
		"id": "zombie", "name": "좀비", "family": "undead", "tier": "normal",
		"color": Color(0.45, 0.5, 0.4), "skills": [{"id": "chill"}], "hp_mult": 1.4,
		"personality": "둔하지만 쉽게 쓰러지지 않는, 서늘한 기운을 내뿜는 좀비",
	},
	{
		"id": "skeleton_archer", "name": "해골 궁수", "family": "undead", "tier": "normal",
		"color": Color(0.8, 0.75, 0.6), "skills": [], "atk_dice_delta": 1, "def_dice_delta": -1,
		"hp_mult": 1.0, "personality": "방어는 포기하고 화살 공세에만 집중하는 해골",
	},
	{
		"id": "wraith_soldier", "name": "망령 병사", "family": "undead", "tier": "normal",
		"color": Color(0.4, 0.45, 0.5), "skills": [{"id": "drain"}], "atk_dice_delta": -1,
		"hp_mult": 1.0, "personality": "약한 공격으로도 꾸준히 생명력을 갈취하는 병사",
	},
]

## [대형 기획 6] G-5(2026-10-07): 기존 던전 진행(`combat_test.gd`의 `_monster_config_for_room()`)은
## 아직 "20종 풀에서 뽑는" 로직(G-6 몫)이 없다 — 그 전까지는 room_index를 이 5개 id로만
## 순환시켜(기존 MONSTERS.size()==5였을 때와 완전히 동일한 순서) MONSTERS 배열이 20개로
## 늘어나도 실제 플레이/기존 회귀 테스트(dice_test.gd)가 전혀 영향받지 않게 한다.
const LEGACY_ROOM_CYCLE_IDS := ["slime", "goblin", "skeleton", "orc", "dark_knight"]


## id로 몬스터 하나를 찾는다(없으면 빈 Dictionary). G-5 QA 훅(`GAME_QA_MONSTER_ID`)과
## legacy_cycle_monster()가 공유하는 조회 헬퍼.
static func get_by_id(id: String) -> Dictionary:
	for m in MONSTERS:
		if m.get("id", "") == id:
			return m
	return {}


## room_index를 LEGACY_ROOM_CYCLE_IDS(기존 5종, 기존과 동일한 순서)로 순환시켜 몬스터를
## 고른다 — `_monster_config_for_room()`이 쓰던 `MONSTERS[room_index % MONSTERS.size()]`를
## 그대로 대체하는 호환 함수(MONSTERS가 20개로 늘어나도 결과가 바뀌지 않게).
static func legacy_cycle_monster(room_index: int) -> Dictionary:
	var id: String = LEGACY_ROOM_CYCLE_IDS[room_index % LEGACY_ROOM_CYCLE_IDS.size()]
	return get_by_id(id)


static func family_ids() -> Array:
	return FAMILIES.keys()


## 몬스터 dict에서 기존 코드가 쓰던 "dice_gimmick" 문자열을 뽑아낸다(skills[0].id,
## skills가 비어 있으면 빈 문자열) — `_monster_config_for_room()`이 그대로 호환되게
## 하는 다리 역할. skills 배열 자체는 G-2 이후 2개 이상(정예)/3개 이상(보스)으로
## 늘어날 수 있지만, 이 함수는 "기존 단일 기믹 호환" 용도라 항상 0번째만 본다.
static func gimmick_of(monster: Dictionary) -> String:
	var skills: Array = monster.get("skills", [])
	if skills.is_empty():
		return ""
	return skills[0].get("id", "")
