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
## - "skills": 스킬 id(+파라미터) 목록 — G-2에서 생길 `monster_skills.gd` 프레임워크가
##   읽을 미래형 필드. 지금은 각 원소가 {"id": <기존 dice_gimmick 문자열>}뿐이고(기믹
##   없는 슬라임은 빈 배열), 실제 적용은 여전히 `combat_test.gd`가 `gimmick_of()`로
##   skills[0].id를 꺼내 기존 "dice_gimmick" 코드 경로에 그대로 넘기는 다리 역할만 한다.
## - "hp_mult": 등급별 HP 배율. 지금은 전부 1.0(동작 변경 없음) — G-7(정예 1.5)에서
##   쓰일 자리를 미리 만들어 둠(보스는 기존 "마지막 방 HP x2" 공식을 그대로 유지하고
##   이 필드와는 아직 연동하지 않음, G-8에서 결정).

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
]


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
