class_name SkillPool
extends RefCounted
## "캐릭터 스킬 부여 이벤트" 후보 목록 (INBOX.md [미니 기획 C] 1~2단계, 2026-09-16).
##
## 스킬은 "이번 런 동안 유지되는 영구 버프 플래그"로 취급한다(전투 시스템을 새로
## 만들지 않기 위함, DESIGN.md 미니 기획 C-2). 획득한 스킬 id는 RunState.skill_flags에
## 문자열로 쌓이고, 여기서는 후보 정의 + 뽑기/부여만 담당한다.
##
## item dict 형식을 EventItemPool.ITEMS와 비슷하게(name/description) 맞춰서
## code/scenes/item_card_style.gd(ItemCardStyle)의 카드 UI를 그대로 재사용할 수 있게
## 했다(INBOX.md [미니 기획 C]-5 "기존 카드 UI를 재사용할 수 있으면 재사용" 반영) —
## "kind"/"grade" 필드가 없어도 build_card()는 다이스 미리보기 없이/기본 등급 배지로
## 정상 동작한다.
##
## [미니 기획 C]-3(공용 스킬 2종의 구체적인 수치)이 이미 INBOX.md에 확정돼 있어 그
## 이름/설명을 그대로 옮겨 적었다. 다만 **이 스킬들의 실제 전투 보너스 적용
## (combat_test.gd가 RunState.skill_flags를 읽어 반영하는 부분)은 아직 구현하지
## 않았다** — 이번 이터레이션 범위는 "후보 정의 + 획득 구조 + RunState.skill_flags
## 배열"까지이고, 실제 효과 배선은 다음 이터레이션이 이어서 처리한다. 고유 스킬
## ([미니 기획 C]-4, 캐릭터 기믹과 시너지)은 아직 후보에 없음 — 공용 스킬 구조가
## 실제로 잘 동작하는 걸 먼저 확인한 뒤 추가한다(세션 지침 "한 이터레이션에 전부
## 하지 말 것" 반영).
const SKILLS: Array[Dictionary] = [
	{
		"id": "deep_breath",
		"name": "심호흡",
		"description": "매 전투 첫 방어턴에 방어 다이스 결과값이 +1 된다 (상한: 각 다이스 면 개수). 효과 적용은 다음 이터레이션에서 구현 예정.",
	},
	{
		"id": "spare_die",
		"name": "여분",
		"description": "매 전투 시작 시 공격 다이스 1개를 추가로 굴려, 더 높은 값을 채택한다 (이번 런 내내 유지). 효과 적용은 다음 이터레이션에서 구현 예정.",
	},
]


## RunState.skill_flags에 이미 있는 id는 후보에서 제외한다(같은 스킬을 중복 획득할
## 수 없으므로 — 두 번째 카드도 항상 새로운 선택지여야 함). 남은 후보 중 최대 n개를
## 무작위로(중복 없이) 반환한다. 후보가 하나도 없으면 빈 배열을 돌려주고, event.gd는
## 이 경우 스킬 이벤트 대신 기존 아이템 이벤트로 대체한다.
static func available_choices(n: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for skill in SKILLS:
		if not RunState.skill_flags.has(skill["id"]):
			pool.append(skill)
	pool.shuffle()
	return pool.slice(0, min(n, pool.size()))


## skill_id를 RunState.skill_flags에 추가한다. 이미 보유 중이면 아무 일도 하지
## 않는다(배열이라 append만 하면 중복이 생길 수 있어 다이스/눈금 인벤토리와 달리
## 명시적으로 has() 가드가 필요함 — 스킬은 "개수"가 아니라 "보유 여부"만 의미가 있음).
static func grant(skill_id: String) -> void:
	if not RunState.skill_flags.has(skill_id):
		RunState.skill_flags.append(skill_id)
