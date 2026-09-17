class_name SkillPool
extends RefCounted
## "캐릭터 스킬 부여 이벤트" 후보 목록 (INBOX.md [미니 기획 C], 2026-09-16).
##
## 스킬은 "이번 런 동안 유지되는 영구 버프 플래그"로 취급한다(전투 시스템을 새로
## 만들지 않기 위함, DESIGN.md 미니 기획 C-2). 획득한 스킬 id는 RunState.skill_flags에
## 문자열로 쌓이고, 여기서는 후보 정의 + 뽑기/부여만 담당한다. 실제 전투 보너스는
## code/scenes/combat_test.gd가 RunState.skill_flags를 읽어 _do_exchange()에서 적용한다
## ([미니 기획 C]-3/4, 2026-09-16에 배선 완료 — 아래 SKILLS/UNIQUE_SKILLS의 description은
## 더 이상 "구현 예정"이 아니라 실제 동작을 그대로 서술한다).
##
## item dict 형식을 EventItemPool.ITEMS와 비슷하게(name/description) 맞춰서
## code/scenes/item_card_style.gd(ItemCardStyle)의 카드 UI를 그대로 재사용할 수 있게
## 했다(INBOX.md [미니 기획 C]-5 "기존 카드 UI를 재사용할 수 있으면 재사용" 반영) —
## "kind"/"grade" 필드가 없어도 build_card()는 다이스 미리보기 없이/기본 등급 배지로
## 정상 동작한다.
const SKILLS: Array[Dictionary] = [
	{
		"id": "deep_breath",
		"name": "심호흡",
		"description": "매 전투 첫 방어턴에 방어 다이스 결과값이 +1 된다 (상한: 각 다이스 면 개수).",
	},
	{
		"id": "spare_die",
		"name": "여분",
		"description": "매 공격턴 여분 다이스를 하나 더 굴려, 가장 낮은 공격 다이스 값을 그보다 높으면 대체한다 (이번 런 내내 유지).",
	},
]

## 고유 스킬([미니 기획 C]-4) — 캐릭터 기믹과 시너지가 있는 스킬로, "character_id"가
## 일치하는 캐릭터에게만 후보로 제시된다. 처음엔 광전사(min_max_only) 전용 1종만 구현
## (INBOX.md "나머지 4캐릭터 전용 스킬은 이 하나가 실제로 잘 동작/체감되는 걸 확인한
## 뒤에 같은 패턴으로 이어서 추가" 지시 반영 — 한 번에 5개를 다 만들지 않음). 부정적인
## 후속 피드백 없이 남은 항목으로만 큐에 남아있어, 2026-09-16 다음 이터레이션이 같은
## 패턴 그대로 두 번째(수호자)를 추가했다.
##
## "frenzy_deepen"(광기 심화): 광전사는 원래 "explosive_stack" 기믹이 없지만(자기
## 기믹은 min_max_only), 이 스킬을 획득하면 combat_test.gd가 explosive_stack 캐릭터와
## 동일한 스택 추적 파이프라인을 광전사에게도 열어준다 — min_max_only라 공격 다이스가
## 최댓값을 보여줄 확률이 이미 표준 다이스보다 높으므로(중간값이 없어 최소/최댓값
## 둘 중 하나) 스택이 잘 쌓이는 시너지가 생긴다(INBOX.md 예시 그대로). 스택 3회 도달
## 시의 보너스 턴은 명목상 폭발병과 같은 "1D20 굴림"이지만, 광기 심화는 한 단계 더
## 나아가 1D20을 두 번 굴려 더 높은 값을 채택한다(combat_test.gd의 player_frenzy_active
## 분기 참고).
##
## "guard_deepen"(수호 심화): frenzy_deepen과 완전히 대칭 구조(공격 대신 방어) —
## 수호자는 원래 "guard_stack" 기믹이 없지만(자기 기믹은 fixed_defense_die, 방어
## 다이스 하나가 항상 고정값), 이 스킬을 획득하면 방패병과 동일한 수호 스택 파이프라인이
## 열린다. 수호자는 방어 다이스 하나가 안 굴려지는 대신 나머지가 표준 확률이라
## frenzy_deepen만큼 스택이 잘 쌓이는 직접적 시너지는 없지만, "방어 몰빵" 컨셉에 맞게
## 방어 다이스 개수 자체가 많아(D4x4) 최댓값을 볼 기회 자체는 늘어난다. 보너스 턴은
## 1D20 한 번이 아니라 두 번 굴려 더 높은 값을 채택(combat_test.gd의
## player_guard_deepen_active 분기 참고).
##
## "chain_explosion"(연쇄 폭발): 폭발병(explosive) 전용. frenzy_deepen/guard_deepen과
## 달리 폭발병은 이미 자기 기믹으로 explosive_stack 파이프라인을 갖고 있어("없던
## 파이프라인을 열어준다"는 패턴을 그대로 못 씀, STATUS.md 큐 17 참고) — 대신 그
## 파이프라인 자체를 강화하는 방향으로, 폭발 스택 임계치를 3에서 2로 낮춰 보너스
## 공격턴(1D20)을 더 자주 받게 한다(combat_test.gd의 player_chain_explosion_active /
## _player_explosive_threshold() 참고). 큐 17이 예시로 든 "스택 임계치를 3→2로
## 낮추는 스킬" 방향을 그대로 채택.
##
## "chain_guard"(연쇄 방어): 방패병(shieldbearer) 전용, chain_explosion과 완전히 대칭
## 구조(공격 대신 방어). 방패병은 이미 자기 기믹으로 guard_stack 파이프라인을 갖고
## 있어 같은 이유로 "없던 파이프라인을 열어준다" 패턴을 못 쓴다 — 수호 스택 임계치를
## 3에서 2로 낮춰 보너스 방어턴(1D20)을 더 자주 받게 한다(combat_test.gd의
## player_chain_guard_active / _player_guard_threshold() 참고). chain_explosion처럼
## 보너스 턴 자체는 강화하지 않고(1D20 한 번 그대로) 임계치만 낮춘다 — 광기/수호
## 심화 두 스킬이 이미 "두 번 굴려 채택" 강화를 쓰고 있어 같은 축을 또 건드리면
## 과할 수 있기 때문(STATUS.md 큐 17 참고).
##
## "versatile_surge"(임기응변): 견습 모험가(novice) 전용, 나머지 4캐릭터의 마지막
## 빈자리(INBOX.md 2026-09-17 기획자 결정). 견습 모험가는 기믹이 아예 없는 "만능형"
## 캐릭터라 한쪽에 몰빵하는 대신, frenzy_deepen/guard_deepen의 "없던 파이프라인을
## 열어준다" 패턴을 공격+방어 양쪽에 동시에 적용한다 — explosive_stack과 guard_stack
## 파이프라인이 함께 열리고, 둘 다 기존 기본 임계치(EXPLOSIVE_STACK_THRESHOLD/
## GUARD_STACK_THRESHOLD, 둘 다 3)와 기본 보너스(1D20 한 번 굴림)를 그대로 쓴다 —
## frenzy_deepen/guard_deepen의 "두 번 굴려 채택" 강화나 chain_explosion/chain_guard의
## "임계치 2로 낮춤" 강화는 넣지 않는다(한 캐릭터가 공격+방어 두 축을 동시에 얻는
## 것 자체가 이미 다른 4종 대비 강력하므로, 축마다의 강화까지 겹치면 과할 수 있음 —
## "넓지만 얕게"가 견습 모험가의 정체성, combat_test.gd의 player_versatile_active
## 분기 참고).
const UNIQUE_SKILLS: Array[Dictionary] = [
	{
		"id": "frenzy_deepen",
		"name": "광기 심화",
		"description": "폭발 스택이 3에 도달하면 보너스 공격턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (광전사 전용).",
		"character_id": "berserker",
	},
	{
		"id": "guard_deepen",
		"name": "수호 심화",
		"description": "수호 스택이 3에 도달하면 보너스 방어턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (수호자 전용).",
		"character_id": "guardian",
	},
	{
		"id": "chain_explosion",
		"name": "연쇄 폭발",
		"description": "폭발 스택 임계치가 3에서 2로 낮아져 보너스 공격턴을 더 자주 받는다 (폭발병 전용).",
		"character_id": "explosive",
	},
	{
		"id": "chain_guard",
		"name": "연쇄 방어",
		"description": "수호 스택 임계치가 3에서 2로 낮아져 보너스 방어턴을 더 자주 받는다 (방패병 전용).",
		"character_id": "shieldbearer",
	},
	{
		"id": "versatile_surge",
		"name": "임기응변",
		"description": "공격/방어 다이스가 각각 최댓값을 보일 때마다 해당 스택이 함께 쌓인다. 공격은 3스택에서 보너스 공격턴을, 방어는 3스택에서 보너스 방어턴을 각각 1D20으로 얻는다 (견습 모험가 전용).",
		"character_id": "novice",
	},
]


## 스킬 강화판([미니 기획 D], 2026-09-17) — 기존 7종 스킬(SKILLS 2종 + UNIQUE_SKILLS
## 5종) 각각의 "+" 버전. 새 메커니즘을 만들지 않고 "기존 메커니즘을 한 단계 더 강하게"만
## 한다(기획자 결정 원문). "upgrades" 필드가 base 스킬 id를 가리킨다 — 이 필드로
## available_upgrade_choices()가 "base를 보유했는데 +는 아직 없는" 후보를 찾는다.
## character_id 필드는 UNIQUE_SKILLS 계열 강화에만 있고(공용 스킬 강화는 캐릭터 무관),
## item dict 형식은 SKILLS/UNIQUE_SKILLS와 동일해 ItemCardStyle 카드 UI를 그대로 재사용한다.
##
## 실제 전투 효과 배선([미니 기획 D]-4)은 아직 없음 — 이번 이터레이션은 데이터 정의(1번)와
## 후보 뽑기(2번)까지만, combat_test.gd 배선은 다음 이터레이션들이 나눠서 이어간다.
const UPGRADE_SKILLS: Array[Dictionary] = [
	{
		"id": "deep_breath_plus",
		"name": "심호흡+",
		"description": "방어 다이스 +1 보정이 첫 방어턴뿐 아니라 매 방어턴마다 적용된다 (상한: 각 다이스 면 개수).",
		"upgrades": "deep_breath",
	},
	{
		"id": "spare_die_plus",
		"name": "여분+",
		"description": "여분 다이스를 1개가 아니라 2개 굴려, 그 중 더 높은 값으로 가장 낮은 공격 다이스를 대체한다.",
		"upgrades": "spare_die",
	},
	{
		"id": "frenzy_deepen_plus",
		"name": "광기 심화+",
		"description": "폭발 스택이 3에 도달하면 보너스 공격턴이 1D20을 세 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (광전사 전용).",
		"upgrades": "frenzy_deepen",
		"character_id": "berserker",
	},
	{
		"id": "guard_deepen_plus",
		"name": "수호 심화+",
		"description": "수호 스택이 3에 도달하면 보너스 방어턴이 1D20을 세 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (수호자 전용).",
		"upgrades": "guard_deepen",
		"character_id": "guardian",
	},
	{
		"id": "chain_explosion_plus",
		"name": "연쇄 폭발+",
		"description": "폭발 스택 임계치는 2 그대로, 보너스 공격턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (폭발병 전용).",
		"upgrades": "chain_explosion",
		"character_id": "explosive",
	},
	{
		"id": "chain_guard_plus",
		"name": "연쇄 방어+",
		"description": "수호 스택 임계치는 2 그대로, 보너스 방어턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (방패병 전용).",
		"upgrades": "chain_guard",
		"character_id": "shieldbearer",
	},
	{
		"id": "versatile_surge_plus",
		"name": "임기응변+",
		"description": "공격/방어 스택 임계치가 3에서 2로 낮아져 보너스 턴을 더 자주 받는다 (견습 모험가 전용).",
		"upgrades": "versatile_surge",
		"character_id": "novice",
	},
]


## 캐릭터별 "시작 스킬" 후보([미니 기획 E], INBOX.md 2026-09-17 기획자 결정) — 런
## "시작 시점"에 캐릭터 선택 화면에서 미리 확정 선택하는 로드아웃. SKILLS/UNIQUE_SKILLS
## (런 중 무작위 이벤트로 얻는 스킬)와는 완전히 다른 레이어라 별도 상수로 분리했다(기획자
## 결정 2번 "이 스킬들은 런 중 이벤트로는 절대 나오지 않는다"). 전부 이미 있는
## DiceBag.apply_flat_bonus(values, 1)("심호흡"과 동일한 "결과값 +1, 상한은 면 개수" 헬퍼)를
## 조건부로 호출하는 방식으로 통일해 새 다이스 연산을 만들지 않는다 — 실제 전투 배선은
## combat_test.gd가 아직 담당하지 않음(이번 조각은 데이터 정의만, [미니 기획 E]-4가 이어감).
##
## "character_ids": 여러 캐릭터가 같은 원형을 공유할 수 있어 Array[String]로 표시한다.
## starting_skills_for_character()가 이 배열을 필터링해 "그 캐릭터가 고를 수 있는 시작
## 스킬 목록"을 만드는데, STARTING_SKILLS 안에서의 등장 순서가 곧 슬롯 순서다(슬롯 0=항상
## 해금, 슬롯 1=AchievementManager.is_unlocked("clear_"+character_id) 해금 시에만 — UI
## 배선은 [미니 기획 E]-3이 담당). 예: 견습 모험가는 start_expand -> start_lean 순으로
## 등장해 슬롯 0="확장", 슬롯 1="정예"가 된다.
const STARTING_SKILLS: Array[Dictionary] = [
	{
		"id": "start_aggro",
		"name": "맹공",
		"description": "공격 다이스 개수가 방어 다이스 개수보다 많으면, 공격 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["berserker", "explosive"],
	},
	{
		"id": "start_wall",
		"name": "철벽",
		"description": "방어 다이스 개수가 공격 다이스 개수보다 많으면, 방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["guardian", "shieldbearer"],
	},
	{
		"id": "start_expand",
		"name": "확장",
		"description": "공격+방어 다이스 합계가 8개 이상이면, 공격/방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["novice", "explosive"],
	},
	{
		"id": "start_lean",
		"name": "정예",
		"description": "공격+방어 다이스 합계가 6개 이하로 유지되면, 공격/방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["novice", "shieldbearer"],
	},
	{
		"id": "start_hoard",
		"name": "수집가",
		"description": "보유한 눈금 인벤토리가 5개 이상이면, 공격 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["berserker"],
	},
	{
		"id": "start_ironclad",
		"name": "강철 방비",
		"description": "철제 재질(D12/D20) 다이스를 1개 이상 보유하면, 방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["guardian"],
	},
]


## character_id가 STARTING_SKILLS의 "character_ids"에 포함된 항목만, 배열 등장 순서
## 그대로 필터링해 반환한다(순서가 곧 슬롯 순서 — 위 주석 참고). 해당 캐릭터의 원형이
## 하나도 없으면 빈 배열을 반환한다.
static func starting_skills_for_character(character_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill in STARTING_SKILLS:
		if skill["character_ids"].has(character_id):
			result.append(skill)
	return result


## RunState.skill_flags에 이미 있는 id는 후보에서 제외한다(같은 스킬을 중복 획득할
## 수 없으므로 — 두 번째 카드도 항상 새로운 선택지여야 함). 공용 스킬(SKILLS)에 더해
## character_id가 주어지고 UNIQUE_SKILLS 중 해당 캐릭터 전용 스킬이 있으면 후보 풀에
## 함께 섞는다(character_id를 생략하면 기존처럼 공용 스킬만 나온다 — 호출부 호환 유지).
## 남은 후보 중 최대 n개를 무작위로(중복 없이) 반환한다. 후보가 하나도 없으면 빈 배열을
## 돌려주고, event.gd는 이 경우 스킬 이벤트 대신 기존 아이템 이벤트로 대체한다.
static func available_choices(n: int, character_id: String = "") -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for skill in SKILLS:
		if not RunState.skill_flags.has(skill["id"]):
			pool.append(skill)
	if character_id != "":
		for skill in UNIQUE_SKILLS:
			if skill.get("character_id", "") == character_id and not RunState.skill_flags.has(skill["id"]):
				pool.append(skill)
	pool.shuffle()
	return pool.slice(0, min(n, pool.size()))


## skill_id를 RunState.skill_flags에 추가한다. 이미 보유 중이면 아무 일도 하지
## 않는다(배열이라 append만 하면 중복이 생길 수 있어 다이스/눈금 인벤토리와 달리
## 명시적으로 has() 가드가 필요함 — 스킬은 "개수"가 아니라 "보유 여부"만 의미가 있음).
static func grant(skill_id: String) -> void:
	if not RunState.skill_flags.has(skill_id):
		RunState.skill_flags.append(skill_id)


## 강화 후보 뽑기([미니 기획 D]-2). UPGRADE_SKILLS 중 base 스킬("upgrades" 필드)을
## RunState.skill_flags가 이미 갖고 있고, "+"id 자신은 아직 없는 것만 후보로 삼는다
## (base가 없으면 애초에 강화할 대상이 없고, +를 이미 가졌으면 중복 강화가 되므로 둘 다
## 제외). character_id가 있는 항목(UNIQUE_SKILLS 계열 강화)은 인자로 받은 character_id와
## 일치할 때만 후보에 포함 — 공용 스킬 강화(character_id 없음)는 캐릭터 무관하게 항상 후보.
## available_choices()와 같은 패턴으로 남은 후보 중 최대 n개를 무작위 반환, 후보가 없으면
## 빈 배열(event.gd는 이 경우 기존 아이템/스킬 이벤트로 대체해야 함).
static func available_upgrade_choices(n: int, character_id: String = "") -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for skill in UPGRADE_SKILLS:
		if not RunState.skill_flags.has(skill["upgrades"]):
			continue
		if RunState.skill_flags.has(skill["id"]):
			continue
		var required_character: String = skill.get("character_id", "")
		if required_character != "" and required_character != character_id:
			continue
		pool.append(skill)
	pool.shuffle()
	return pool.slice(0, min(n, pool.size()))


## base_id(강화 전 스킬 id)를 받아 UPGRADE_SKILLS에서 대응하는 "+"id를 찾아 grant()로
## skill_flags에 추가한다(중복 방지는 grant()가 그대로 처리). 대응하는 강화판이 없으면
## 아무 일도 하지 않는다.
static func grant_upgrade(base_id: String) -> void:
	for skill in UPGRADE_SKILLS:
		if skill["upgrades"] == base_id:
			grant(skill["id"])
			return
