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
]


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
