class_name CharacterProfiles
extends RefCounted
## 플레이어블 캐릭터 정의 (INBOX.md [대형 기획 1] "플레이어블 캐릭터 4종 추가,
## 총 5종 중 선택 입장"의 첫 착수 조각).
##
## 아이디어 출처는 몬스터 다이스 특이 기믹(dice_bag.gd의 force_min_max_faces/
## force_fixed_value_for_die, combat_test.gd의 MONSTER_PROFILES와 같은 패턴) —
## "각 캐릭터가 전투에 들어갈 때 자기 다이스 풀에 특이 기믹 하나를 갖고 시작한다"는
## INBOX.md 방향을 그대로 따른다. 기믹은 RunState.reset_run()이 새 주머니를 만든
## 직후 한 번만 적용되고(몬스터와 동일한 "정적 적용" 방식), 이후 다이스 개조 아이템으로
## 주머니가 바뀌어도(add_die/replace_die 등) 재적용되지 않는다 — 시작 상태의 개성일
## 뿐, 게임 내내 강제되는 제약은 아니다.
##
## 이번 조각은 5종 중 4종 구현(기존 1 + 신규 3). INBOX.md가 예시로 든 세 성격
## (극단형/안정형/폭발형) 중 "폭발형"(분노 스택 — 몬스터 "고블린"처럼 매 턴 상태를
## 추적하고 턴 로직 자체를 바꿔야 함)은 combat_test.gd의 anger_stack 분기를 플레이어
## 공격턴에도 그대로 적용하는 방식(player_dice_gimmick/player_explosive_stacks/
## player_explosive_pending, combat_test.gd 참고)으로 이번에 완성함 — 이 배열의
## "gimmick" 필드만으로는 표현할 수 없어서(정적 다이스 개조가 아니라 매 턴 상태 추적이
## 필요) run_state.gd._apply_character_gimmick()의 match 문에는 걸리지 않고, 대신
## combat_test.gd가 CharacterProfiles.get_profile(RunState.character_id)를 직접 읽어
## "explosive_stack"일 때만 턴 로직에서 분기한다. 남은 1종(다섯 번째 컨셉)은 아직
## 미정 — docs/STATUS.md 다음 할 일 큐에 남겨둠. 캐릭터 5종 각각의 이름/컨셉/기믹
## 배정은 INBOX.md가 "AI가 제안해도 됨"이라고 허용한 것을 따름 — 사람이 다른
## 이름/배정을 원하면 이 배열만 고치면 됨.
##
## "gimmick" 필드 값:
##   ""              : 기믹 없음 (기존 "견습 모험가")
##   "min_max_only"  : 공격+방어 다이스 전부 DiceBag.force_min_max_faces() 적용
##                     (중간값 없음, 하이리스크/로우리스크 — 몬스터 "다크 나이트"와 같은 기믹)
##   "fixed_defense_die": 방어 다이스 중 0번째 하나만 DiceBag.force_fixed_value_for_die()로
##                     고정값(굴리지 않는 것과 동일 효과) — 예측 가능한 안정적 방어 한 조각
##   "explosive_stack": 정적 다이스 개조 없음(run_state.gd에서는 아무 일도 안 함) — 대신
##                     공격 다이스가 최댓값 면을 보여줄 때마다 combat_test.gd가 전투 중
##                     상태로 스택을 쌓고, 3스택에서 다음 공격 한 턴만 1D20으로 굴림
##                     (몬스터 "고블린"의 anger_stack과 같은 메커니즘, 플레이어 공격턴에 적용)
const PROFILES := [
	{
		"id": "novice",
		"name": "견습 모험가",
		"desc": "기본 캐릭터 (능력 차이 없음)",
		"gimmick": "",
		"hair_color": Color(0.78, 0.62, 0.86),
		"dress_color": Color(0.92, 0.55, 0.66),
	},
	{
		"id": "berserker",
		"name": "광전사",
		"desc": "극단형 — 공격/방어 다이스가 항상 최솟값 아니면 최댓값만 나옴 (중간값 없음, 하이리스크 하이리턴)",
		"gimmick": "min_max_only",
		"hair_color": Color(0.85, 0.25, 0.2),
		"dress_color": Color(0.35, 0.1, 0.1),
	},
	{
		"id": "guardian",
		"name": "수호자",
		"desc": "안정형 — 방어 다이스 하나가 항상 고정값으로만 나옴 (예측 가능한 안정적 방어)",
		"gimmick": "fixed_defense_die",
		"hair_color": Color(0.4, 0.55, 0.85),
		"dress_color": Color(0.25, 0.4, 0.55),
	},
	{
		"id": "explosive",
		"name": "폭발병",
		"desc": "폭발형 — 공격 다이스가 최댓값을 보여줄 때마다 폭발 스택이 쌓임 (3스택에서 다음 공격이 20면체 주사위로 터짐)",
		"gimmick": "explosive_stack",
		"hair_color": Color(0.95, 0.55, 0.15),
		"dress_color": Color(0.5, 0.18, 0.05),
	},
]


## id에 해당하는 프로필을 반환. 못 찾거나 빈 문자열이면 PROFILES[0](견습 모험가)로
## 폴백한다 — 기존 RunState.reset_run() 호출부(캐릭터 선택 없이 그냥 재시작하는
## 경로들)가 그대로 동작해야 하므로 항상 유효한 Dictionary를 반환해야 한다.
static func get_profile(id: String) -> Dictionary:
	for p in PROFILES:
		if p["id"] == id:
			return p
	return PROFILES[0]


## 방어 다이스 고정값 계산: 몬스터 "오크"(fixed_value)와 같은 공식(면 개수 평균 반올림)을
## 재사용해 D4 기준 3(=ceil(5/2))이 되도록 한다 — 새 밸런스 상수를 따로 만들지 않음.
static func fixed_defense_die_value(sides: int) -> int:
	return ceili((sides + 1) / 2.0)
