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
##
## 스킬 효과 도식 문법([대형 기획 15] Q-7(a), 2026-10-17, INBOX.md) — "글을 읽지
## 않아도 효과를 빠르게 안다"는 목표로, 모든 스킬 dict에 "diagram" 필드(Array[Dictionary])를
## 둔다. 렌더러(Q-7b, 아직 미구현)는 이 데이터만 읽어 그림을 그리고, 스킬 id별로 분기하는
## 하드코딩은 두지 않는다(INBOX.md "렌더 분기 하드코딩 금지" 명시).
##
## diagram은 "조건 칩... -> 효과 칩..." 순서의 배열이고, 배열의 원소 하나가 "기호" 1개로
## 취급된다(화살표도 포함) — 한 스킬당 MAX_DIAGRAM_SYMBOLS(=5)개까지만 허용한다(INBOX.md
## "한 도식당 기호 최대 4~5개"). 각 칩의 "type"은 DIAGRAM_SYMBOL_TYPES 11종 중 하나여야
## 한다:
##
## - "die"       {target: "attack"|"defense"|"event"|"dual", count?: int}
##               주사위 1개 — 대상 주머니(공격/방어/이벤트/양쪽)를 표시. count는 "몇 개에
##               적용되는가"(기본 1, 예: 매혹 심화는 2) — 기호 개수에는 포함 안 함.
## - "compare"   {left: "attack"|"defense", op: ">"|"="|">="|"<=", right: "attack"|"defense"}
##               두 주머니의 다이스 "개수" 비교 조건(예: 공격 개수 > 방어 개수).
## - "condition" {kind: String, op?: String, value?: Variant}
##               개수 비교 외의 발동 조건. kind 예: "first_turn"(첫 턴 한정),
##               "hp_half"(HP 절반 이하), "dice_total"(공+방 다이스 합계, op+value로
##               임계), "pip_inventory"(눈금 인벤토리 개수), "material"(특정 재질 보유),
##               "gold"(골드 임계치, N마다), "dice_cap"(주머니가 MAX_DICE로 꽉 찼을 때),
##               "dice_type_count"(면 개수 종류 수), "round_change"(라운드 전환 시점),
##               "perfect_block"(방어로 피해를 완전히 막음, 데미지 0 — Q-8(c) 신규).
## - "arrow"     {} — "그러면" / "조건 -> 효과" 구분자.
## - "value"     {amount?: int, op: "+"|"×"|"max"|"half"|"full", max?: int, ignore_defense?: bool}
##               수치 배지. op="max"는 "그 다이스를 면 최댓값으로 전환"(눈금을 올리는 게
##               아니라 결과만 고정), op="half"/"full"은 "공격 합계의 절반/전부"(해적
##               고정 피해 전용). max/ignore_defense는 상한·방어 무시 여부를 가리키는
##               부가 정보일 뿐 기호 개수에는 포함 안 함(렌더러가 보조 표시로만 씀).
## - "duration"  {kind: "first_turn"|"every_turn"|"once"}
##               비교·조건이 아니라 "언제 적용되는가"만 말할 때 쓴다(예: 매 턴, 1회).
## - "reroll"    {count: int} — 순환 화살표. count번 더 굴려 더 높은 값을 채택(advantage).
## - "stack"     {target: "attack"|"defense", threshold: int} — 스택이 threshold에
##               도달하면 보너스 턴이 열리는 캐릭터 기믹형 효과.
## - "swap"      {count: int} — 공격/방어 다이스를 count쌍 맞바꾼다.
## - "cycle"     {turns: int, target: "attack"|"defense"} — 주기형(쿨타임) 효과(N턴마다).
## - "gold"      {amount?: int} — 골드 변화.
##
## 도식으로 표현하기 어려운(설명이 복잡한) 스킬은 효과를 단순화하는 리디자인 후보로
## docs/STATUS.md에 적어야 하지만(diagram을 비워두지 않는다 — 검증 테스트가 빈 diagram을
## FAIL로 잡음), 이번 37종은 위 11개 기호로 전부 4~5개 이내로 표현 가능해 리디자인
## 후보가 없었다(docs/STATUS.md Q-7(a) 완료 기록 참고 — stack/swap/cycle 세 기호를
## 새로 추가해서 해결).
const DIAGRAM_SYMBOL_TYPES: Array[String] = [
	"die", "compare", "condition", "arrow", "value", "duration", "reroll",
	"stack", "swap", "cycle", "gold",
]
const MAX_DIAGRAM_SYMBOLS: int = 5

## 스킬 레어리티([대형 기획 15] Q-8(a), 2026-10-18, INBOX.md 원문 5). 아이템 보상
## 등급(ItemCardStyle.GRADE_COLORS의 S/A/B/C)과는 완전히 별개 축이다 — 아이템은
## "무엇을 얻는가"의 가치 등급이고, 스킬 레어리티는 "이 스킬이 얼마나 특별한가"를
## 나타낸다(INBOX.md "아이템 S/A/B/C 등급과 구분되는 스킬 전용 표시" 명시).
## 4단계: 일반 < 희귀 < 영웅 < 전설. 전설은 캐릭터별 3종씩(8명×3=24종, 한 런에 하나만
## 보유 가능)인데 규모상 한 이터레이션에 다 못 해 캐릭터 2명씩 쪼개 진행한다(INBOX.md
## 명시) — Q-8(c) 1/4(2026-10-19)로 견습 모험가(novice)/광전사(berserker) 6종, 2/4
## (2026-10-19)로 수호자(guardian)/폭발병(explosive) 6종이 들어왔다(총 12종). 나머지
## 4명(주술사/매혹사/곡예사/해적) 12종은 다음 이터레이션들(3/4~4/4) 몫 — LEGENDARY_SKILLS
## 배열이 비어있지 않은 뒤부터는 이 주석이 "진행 중" 표시다(완전히 끝나면 STATUS.md에
## 전체 24종 기록 후 이 주석도 정리).
const RARITY_COMMON := "common"
const RARITY_RARE := "rare"
const RARITY_EPIC := "epic"
const RARITY_LEGENDARY := "legendary"

## 등급 순서(낮음 -> 높음). 전수 검증 테스트가 "모든 스킬의 rarity가 이 배열 안에
## 있는지"로 유효성을 판정한다.
const RARITY_ORDER: Array[String] = [RARITY_COMMON, RARITY_RARE, RARITY_EPIC, RARITY_LEGENDARY]

## 등급 표시 텍스트("색만으로 구분 금지" — INBOX.md 명시, 아이콘 테두리색은 보조
## 신호일 뿐 이 텍스트가 항상 함께 그려진다).
const RARITY_LABELS: Dictionary = {
	RARITY_COMMON: "일반",
	RARITY_RARE: "희귀",
	RARITY_EPIC: "영웅",
	RARITY_LEGENDARY: "전설",
}

## 등급 색 — 아이템 등급 팔레트(초록<파란색<보라색<노란색, ItemCardStyle.GRADE_COLORS)와
## 겹치지 않는 별도 색상환(은회색 일반 -> 하늘색 희귀 -> 보라색 영웅 -> 주황색 전설)을
## 써서 두 등급 체계를 한눈에 구분할 수 있게 한다.
const RARITY_COLORS: Dictionary = {
	RARITY_COMMON: Color(0.72, 0.75, 0.78),
	RARITY_RARE: Color(0.3, 0.72, 0.95),
	RARITY_EPIC: Color(0.75, 0.38, 0.95),
	RARITY_LEGENDARY: Color(0.95, 0.55, 0.12),
}
const DEFAULT_RARITY := RARITY_COMMON

## 보상 풀 드롭 가중치(상대값 — weighted_pick()이 합으로 정규화하므로 100으로 맞출
## 필요 없음). INBOX.md "전설은 정예/보스 보상 또는 드문 확률" 중 "드문 확률" 쪽을
## 채택 — 등급이 높을수록 숫자가 작아져 뽑힐 확률이 낮다. 전설은 이번 조각에 후보가
## 0종이라 실제로 선택될 일이 없지만(available_choices()/available_upgrade_choices()가
## 여전히 SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS만 후보로 삼음), Q-8(c)가 전설 스킬을
## 추가했을 때 이 상수 하나만 쓰면 되도록 지금부터 자리를 비워둔다.
const RARITY_DROP_WEIGHTS: Dictionary = {
	RARITY_COMMON: 100.0,
	RARITY_RARE: 40.0,
	RARITY_EPIC: 12.0,
	RARITY_LEGENDARY: 3.0,
}

## skill_id -> rarity 전수표(ICON_MOTIFS와 같은 패턴 — 명시적 전수 표, 새 스킬을
## 추가하면서 깜빡 안 넣으면 dice_test.gd의 검증이 DEFAULT_RARITY로 조용히 묻히지
## 않고 FAIL로 잡아낸다). 배정 기준(기획자 결정, docs/STATUS.md Q-8(a) 완료 기록에
## 표로도 정리):
## - **일반**: SKILLS(공용 스킬 2종) + STARTING_SKILLS(캐릭터 시작 로드아웃, 고유 id
##   15종) 전부. 둘 다 "기본으로 주어지는" 스킬이라 레어리티 사다리의 바닥.
## - **희귀**: UNIQUE_SKILLS(캐릭터 전용 고유 스킬 9종) 전부. 공용/시작 스킬보다
##   희소하고(그 캐릭터를 플레이해야만 후보로 나옴) 캐릭터 기믹과 시너지가 있어
##   한 단계 위.
## - **영웅**: UPGRADE_SKILLS("+" 강화판 11종) 중 UNIQUE_SKILLS를 강화하는 9종 —
##   "강화판 = 베이스보다 한 등급 위" 원칙을 희귀 베이스에 적용한 결과.
## - UPGRADE_SKILLS 중 SKILLS(공용, 일반)를 강화하는 나머지 2종
##   (deep_breath_plus/spare_die_plus)은 같은 "한 등급 위" 원칙을 일반 베이스에
##   적용해 **희귀**가 된다(영웅이 아님 — 베이스 등급에 따라 강화 결과 등급도
##   달라진다).
## - **전설**: 이번 조각 0종(위 참고).
const SKILL_RARITY: Dictionary = {
	# SKILLS(공용 2종) — 일반.
	"deep_breath": RARITY_COMMON,
	"spare_die": RARITY_COMMON,
	# UNIQUE_SKILLS(캐릭터 전용 9종) — 희귀.
	"frenzy_deepen": RARITY_RARE,
	"guard_deepen": RARITY_RARE,
	"chain_explosion": RARITY_RARE,
	"chain_guard": RARITY_RARE,
	"versatile_surge": RARITY_RARE,
	"charm_amplify": RARITY_RARE,
	"juggle_encore": RARITY_RARE,
	"broadside": RARITY_RARE,
	"juggle_fortune": RARITY_RARE,
	# UPGRADE_SKILLS — 공용(일반) 베이스 강화 2종은 희귀(한 등급 위).
	"deep_breath_plus": RARITY_RARE,
	"spare_die_plus": RARITY_RARE,
	# UPGRADE_SKILLS — 고유(희귀) 베이스 강화 9종은 영웅(한 등급 위).
	"frenzy_deepen_plus": RARITY_EPIC,
	"guard_deepen_plus": RARITY_EPIC,
	"chain_explosion_plus": RARITY_EPIC,
	"chain_guard_plus": RARITY_EPIC,
	"versatile_surge_plus": RARITY_EPIC,
	"charm_amplify_plus": RARITY_EPIC,
	"juggle_encore_plus": RARITY_EPIC,
	"broadside_plus": RARITY_EPIC,
	"juggle_fortune_plus": RARITY_EPIC,
	# STARTING_SKILLS(시작 로드아웃, 고유 id 15종 — 해적 전용 중복 3행은 id가 같아
	# 자동으로 같은 값을 공유) — 전부 일반.
	"start_aggro": RARITY_COMMON,
	"start_wall": RARITY_COMMON,
	"start_expand": RARITY_COMMON,
	"start_lean": RARITY_COMMON,
	"start_hoard": RARITY_COMMON,
	"start_ironclad": RARITY_COMMON,
	"start_vanguard": RARITY_COMMON,
	"start_bulwark": RARITY_COMMON,
	"start_wealth": RARITY_COMMON,
	"start_overflow": RARITY_COMMON,
	"start_second_wind": RARITY_COMMON,
	"start_gambler": RARITY_COMMON,
	"start_sleight": RARITY_COMMON,
	"start_fortune": RARITY_COMMON,
	"start_diverse": RARITY_COMMON,
	# LEGENDARY_SKILLS(캐릭터별 3종, Q-8(c) 1/4 — novice/berserker 6종) — 전설.
	"legend_novice_harmony": RARITY_LEGENDARY,
	"legend_novice_rally": RARITY_LEGENDARY,
	"legend_novice_fateshuffle": RARITY_LEGENDARY,
	"legend_berserker_ragenuke": RARITY_LEGENDARY,
	"legend_berserker_bloodlust": RARITY_LEGENDARY,
	"legend_berserker_vengeance": RARITY_LEGENDARY,
	# LEGENDARY_SKILLS(Q-8(c) 2/4 — guardian/explosive 6종) — 전설.
	"legend_guardian_bulwark": RARITY_LEGENDARY,
	"legend_guardian_overguard": RARITY_LEGENDARY,
	"legend_guardian_bastion": RARITY_LEGENDARY,
	"legend_explosive_chainblast": RARITY_LEGENDARY,
	"legend_explosive_absolute": RARITY_LEGENDARY,
	"legend_explosive_lastblast": RARITY_LEGENDARY,
}


## skill_id -> rarity 조회. 등록되지 않은 id는 DEFAULT_RARITY(일반)로 폴백한다(단,
## SKILL_RARITY는 전수표라 정상적으로는 37종 전부 등록돼 있어야 함 — 폴백은 방어적
## 코드일 뿐 침묵 실패를 의도하지 않는다. dice_test.gd가 SKILLS/UNIQUE_SKILLS/
## UPGRADE_SKILLS/STARTING_SKILLS 전체 id가 SKILL_RARITY에 "명시적으로" 있는지
## 별도로 검증한다).
static func rarity_for(skill_id: String) -> String:
	return SKILL_RARITY.get(skill_id, DEFAULT_RARITY)


## rarity -> 표시 텍스트("일반"/"희귀"/"영웅"/"전설"). 알 수 없는 값은 DEFAULT_RARITY
## 텍스트로 폴백한다.
static func rarity_label(rarity: String) -> String:
	return RARITY_LABELS.get(rarity, RARITY_LABELS[DEFAULT_RARITY])


## rarity -> 표시 색. 알 수 없는 값은 DEFAULT_RARITY 색으로 폴백한다.
static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS[DEFAULT_RARITY])


## 레어리티 등급 표시 Control 하나(아이콘 테두리색 + 작은 텍스트 태그, INBOX.md
## "색만으로 구분 금지" 명시) — 카드 프레임/도감/상세 팝업/시작 스킬 슬롯 네 곳이
## 전부 이 하나를 공유해 색/모양/텍스트가 어긋나지 않게 한다. font_size만 호출부가
## 조정(카드/팝업은 크게, 좁은 슬롯은 작게).
static func build_rarity_badge(skill_id: String, font_size: int = 12) -> Dictionary:
	var rarity := rarity_for(skill_id)
	var color := rarity_color(rarity)

	var badge := PanelContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	badge.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = rarity_label(rarity)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", UIKit.contrasting_text_color(color))
	badge.add_child(label)

	return {"panel": badge, "label": label, "rarity": rarity, "color": color}


## "한 런에 전설 스킬은 하나만 보유 가능" 규칙([대형 기획 15] Q-8(c), INBOX.md 원문 5
## 명시) — skill_flags(RunState.skill_flags와 같은 형태의 문자열 배열)를 인자로 받는
## 순수 함수라 RunState를 직접 읽지 않으므로 dice_test.gd가 RNG/RunState 생성 없이 바로
## 호출해 "주어진 보유 목록이면 전설을 이미 가진 것으로 판정하는가"를 검증할 수 있다.
static func has_legendary(skill_flags: Array) -> bool:
	for id in skill_flags:
		if SKILL_RARITY.get(id, DEFAULT_RARITY) == RARITY_LEGENDARY:
			return true
	return false


## pool(스킬 dict 배열)에서 skill_flags가 이미 전설을 보유했다면 전설 등급 후보를 전부
## 제거한다(그 외 등급은 그대로 통과) — has_legendary()와 짝을 이루는 순수 함수.
## available_choices()가 weighted_pick() 추첨 "전"에 이 함수를 거쳐, "이미 전설을
## 가졌으면 다른 전설 후보가 보상/스킬 이벤트 선택지 풀에 전혀 나오지 않는다"는 규칙이
## 추첨 결과와 무관하게 항상 보장되게 한다(추첨 이후에 걸러내면 "후보 2장 중 1장이
## 전설이라 화면에 잠깐 보였다가 사라지는" 식의 버그가 생길 수 있어, 반드시 풀 구성
## 단계에서 제거해야 함).
static func filter_legendary_if_owned(pool: Array[Dictionary], skill_flags: Array) -> Array[Dictionary]:
	if not has_legendary(skill_flags):
		return pool
	var filtered: Array[Dictionary] = []
	for skill in pool:
		if rarity_for(skill["id"]) != RARITY_LEGENDARY:
			filtered.append(skill)
	return filtered


## 레어리티 가중치 기반 비복원 추출([대형 기획 15] Q-8(a) "보상 풀 가중치"). pool의
## 각 스킬을 rarity_for()로 조회한 RARITY_DROP_WEIGHTS 가중치에 비례해, 중복 없이
## 최대 n개를 뽑는다. rng를 호출부가 주입하는 순수 함수라(available_choices()처럼
## 전역 RNG에 기대지 않음) 같은 시드+같은 pool 순서면 항상 같은 결과를 재현한다 —
## 테스트가 결정적 시드로 재현 가능한지 요구하므로(INBOX.md) 이 분리가 핵심이다.
## 알고리즘: 매번 "남은 후보의 가중치 합"에서 난수를 하나 뽑아 누적 가중치 구간으로
## 후보를 고르고 제거하는 전형적인 가중치 비복원 추출(weighted sampling without
## replacement) — 한 번 뽑힌 스킬은 다음 추첨에서 제외되므로 같은 카드가 두 번
## 나오지 않는다.
static func weighted_pick(pool: Array[Dictionary], n: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var remaining: Array[Dictionary] = pool.duplicate()
	var result: Array[Dictionary] = []
	while remaining.size() > 0 and result.size() < n:
		var weights: Array[float] = []
		var total_weight := 0.0
		for skill in remaining:
			var w: float = RARITY_DROP_WEIGHTS.get(rarity_for(skill["id"]), RARITY_DROP_WEIGHTS[DEFAULT_RARITY])
			weights.append(w)
			total_weight += w
		var roll: float = rng.randf() * total_weight
		var cumulative := 0.0
		var picked_index := remaining.size() - 1
		for i in weights.size():
			cumulative += weights[i]
			if roll < cumulative:
				picked_index = i
				break
		result.append(remaining[picked_index])
		remaining.remove_at(picked_index)
	return result


const SKILLS: Array[Dictionary] = [
	{
		"id": "deep_breath",
		"name": "심호흡",
		"description": "매 전투 첫 방어턴에 방어 다이스 결과값이 +1 된다 (상한: 각 다이스 면 개수).",
		"diagram": [
			{"type": "condition", "kind": "first_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "spare_die",
		"name": "여분",
		"description": "매 공격턴 여분 다이스를 하나 더 굴려, 가장 낮은 공격 다이스 값을 그보다 높으면 대체한다 (이번 런 내내 유지).",
		"diagram": [
			{"type": "duration", "kind": "every_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "reroll", "count": 1},
		],
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
##
## "charm_amplify"(매혹 심화): 매혹사(enchantress) 전용, INBOX.md 2026-09-24
## [대형 기획 4]-D4가 예시로 든 그대로 — 자기 기믹 charm_flip이 매 턴 "가장 낮은
## 다이스 1개"만 최댓값으로 뒤집던 것을 "1개가 아니라 2개"로 늘린다. 새 메커니즘을
## 만들지 않고 DiceBag.apply_charm_flip()에 이미 있던 count 매개변수(기본값 1)를
## 그대로 재사용한다(combat_test.gd의 charm_flip 분기 참고).
##
## "juggle_encore"(곡예 앙코르): 곡예사(juggler) 전용. 자기 기믹 juggle_swap은
## "런 시작 시 1회"뿐이라 한 런 안에서는 고정이었는데(character_profiles.gd 주석
## 참고), 이 스킬은 INBOX.md 예시("juggle_swap을 라운드가 바뀔 때마다 재발동")
## 그대로 라운드 전환(RunState.advance_round(), 3라운드 중 1->2/2->3 전환 시점)마다
## DiceBag.swap_random_dice()를 한 번 더 호출해 공격/방어 다이스 무작위 1개씩을 다시
## 맞바꾼다 — 새 다이스 연산 없이 기존 헬퍼 재사용(run_state.gd의 advance_round() 참고).
##
## "broadside"(일제 사격): 해적(pirate) 전용, [대형 기획 9] I-3(2026-10-08). 자기 기믹
## cannon_volley("함포 일제사격", 3번째 공격턴마다 고정 피해)의 발동 주기를 3턴에서
## 2턴으로 단축한다 — 새 메커니즘 없이 기존 CANNON_VOLLEY_CYCLE을 스킬 보유 여부로
## 바꿔 끼우는 패턴(combat_test.gd의 player_broadside_active 분기, _cannon_volley_cycle()
## 참고). frenzy_deepen/chain_explosion과 달리 "스택"이 아니라 "주기"만 있어 공격/방어
## 분기 없이 공격 한 쪽만 건드린다.
##
## "juggle_fortune"(곡예 흥행): 곡예사(juggler) 전용, 2026-10-15 [대형 기획 14] N-5(a).
## INBOX.md "전용 스킬 및 강화에도 이벤트 계열 1쌍을 추가해 곡예사의 '이벤트 정체성'이
## 런 중간 성장에서도 이어지게(기존 juggle_encore는 유지)" 반영 — 곡예사는 이제
## juggle_encore(전투 기믹 재발동)와 juggle_fortune(이벤트 판정 보정) 두 고유 스킬을
## 함께 갖는다. "위험을 감수하기" 이벤트 주사위 굴림 결과에 +1 보정을 더한다(상한:
## 이벤트 주사위 면 개수 — 다른 다이스 보정 스킬들과 같은 상한 관례). event.gd의
## event_roll_bonus() 순수 함수로 구현(실제 굴림은 _on_risky_pressed()에서 적용).
const UNIQUE_SKILLS: Array[Dictionary] = [
	{
		"id": "frenzy_deepen",
		"name": "광기 심화",
		"description": "폭발 스택이 3에 도달하면 보너스 공격턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (광전사 전용).",
		"character_id": "berserker",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "reroll", "count": 2},
		],
	},
	{
		"id": "guard_deepen",
		"name": "수호 심화",
		"description": "수호 스택이 3에 도달하면 보너스 방어턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (수호자 전용).",
		"character_id": "guardian",
		"diagram": [
			{"type": "stack", "target": "defense", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "reroll", "count": 2},
		],
	},
	{
		"id": "chain_explosion",
		"name": "연쇄 폭발",
		"description": "폭발 스택 임계치가 3에서 2로 낮아져 보너스 공격턴을 더 자주 받는다 (폭발병 전용).",
		"character_id": "explosive",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 2},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
		],
	},
	{
		"id": "chain_guard",
		"name": "연쇄 방어",
		"description": "수호 스택 임계치가 3에서 2로 낮아져 보너스 방어턴을 더 자주 받는다 (방패병 전용).",
		"character_id": "shieldbearer",
		"diagram": [
			{"type": "stack", "target": "defense", "threshold": 2},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
		],
	},
	{
		"id": "versatile_surge",
		"name": "임기응변",
		"description": "공격/방어 다이스가 각각 최댓값을 보일 때마다 해당 스택이 함께 쌓인다. 공격은 3스택에서 보너스 공격턴을, 방어는 3스택에서 보너스 방어턴을 각각 1D20으로 얻는다 (견습 모험가 전용).",
		"character_id": "novice",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 3},
			{"type": "stack", "target": "defense", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "dual"},
		],
	},
	{
		"id": "charm_amplify",
		"name": "매혹 심화",
		"description": "charm_flip 효과가 그 턴 가장 낮은 다이스 1개가 아니라 2개에 적용된다 (매혹사 전용).",
		"character_id": "enchantress",
		"diagram": [
			{"type": "duration", "kind": "every_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "dual", "count": 2},
			{"type": "value", "op": "max"},
		],
	},
	{
		"id": "juggle_encore",
		"name": "곡예 앙코르",
		"description": "라운드가 바뀔 때마다 공격 다이스 무작위 1개와 방어 다이스 무작위 1개를 다시 맞바꾼다 (곡예사 전용).",
		"character_id": "juggler",
		"diagram": [
			{"type": "condition", "kind": "round_change"},
			{"type": "arrow"},
			{"type": "swap", "count": 1},
		],
	},
	{
		"id": "broadside",
		"name": "일제 사격",
		"description": "함포 일제사격 주기가 3턴에서 2턴으로 단축된다 (해적 전용).",
		"character_id": "pirate",
		"diagram": [
			{"type": "cycle", "turns": 2, "target": "attack"},
			{"type": "arrow"},
			{"type": "value", "op": "half", "ignore_defense": true},
		],
	},
	{
		"id": "juggle_fortune",
		"name": "곡예 흥행",
		"description": "'위험을 감수하기'에서 이벤트 주사위 굴림 결과에 +1 보정이 더해진다 (상한: 이벤트 주사위 면 개수, 곡예사 전용).",
		"character_id": "juggler",
		"diagram": [
			{"type": "die", "target": "event"},
			{"type": "arrow"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
]


## 전설 스킬([대형 기획 15] Q-8(c), INBOX.md 원문 5) — 캐릭터별 3종씩, "게임의 양상이
## 크게 바뀌는" 강력한 효과. UNIQUE_SKILLS와 같은 item dict 형식(character_id로 필터)이지만
## 완전히 별도 상수로 분리한 이유는 "한 런에 전설은 하나만"이라는 추가 규칙(위
## has_legendary()/filter_legendary_if_owned() 참고) 때문 — UNIQUE_SKILLS를 그대로
## 재사용하면서 이 규칙을 끼워 넣으면 "희귀 등급 고유 스킬은 전설 규칙과 무관"이라는
## 전제가 깨지기 쉬워, 전설만 별도 배열로 두고 available_choices()에서 두 배열을 합친
## 뒤 필터를 한 번만 태운다. 전부 UNIQUE_SKILLS처럼 "+" 강화판은 만들지 않는다(이미
## 최고 등급이라 "더 위"가 없음 — UPGRADE_SKILLS에 대응 행 없음).
##
## 1/4(이번 조각): 견습 모험가(novice)/광전사(berserker) 6종. 둘 다 "넓지만 얕게"(견습
## 모험가, 기믹 없음) / "극단형·공격 몰빵"(광전사, min_max_only) 정체성과 시너지를 갖도록
## 설계했다 — 나머지 6명(2/4~4/4)은 다음 이터레이션들이 이어간다.
##
## "legend_novice_harmony"(만물의 조화): 견습 모험가는 기믹이 없는 "만능형"이라 공격/
## 방어 어느 한쪽에 몰빵하지 않는 효과가 정체성에 맞는다 — 매 턴(공격/방어 모두) 그
## 턴에 굴린 다이스 중 가장 낮았던 값을 "그 턴 가장 높았던 값"으로 맞춘다. 기존
## "매혹 심화"(charm_amplify, DiceBag.apply_charm_flip)는 낮은 다이스를 "자기 자신의
## 면 최댓값"으로만 바꾸는데, 이 전설은 상한 없이 그 턴 실제로 나온 최고값을 그대로
## 쓴다(예: D4 세 개 중 하나가 1, 나머지가 3·4일 때 1이 4가 되는 건 charm_flip과 같지만,
## 공격 주머니에 더 큰 다이스가 섞여 있어 그 턴 최고값이 6이었다면 1도 6이 된다 —
## DESIGN.md가 예시로 든 "주사위 결과 합산 방식 변경"). combat_test.gd의
## _apply_harmonize_lowest()(순수 함수) 참고.
##
## "legend_novice_rally"(결의의 반격): 새 메커니즘(반격) — 방어로 몬스터 공격을 완전히
## 막으면(데미지 0) 그 방어 합계만큼 방어 무시 반격 피해를 몬스터에게 준다. "만능형"답게
## 공격이 아니라 방어 쪽 행동을 공격 기회로 바꿔주는 효과. combat_test.gd의
## _perfect_block_counter_damage() 참고.
##
## "legend_novice_fateshuffle"(운명의 뒤섞임): DESIGN.md가 예시로 든 "라운드마다 주머니
## 교체"를 문자 그대로 채택 — 라운드가 바뀔 때마다 공격/방어 다이스를(둘 중 적은 쪽
## 개수만큼) 전부 서로 맞바꾼다. 곡예사의 "곡예 앙코르"(juggle_encore, 매 라운드 1쌍만
## 교환)와 같은 DiceBag.swap_random_dice() 프리미티브를 재사용하지만, 전설답게 한
## 쌍이 아니라 보유한 전부를 섞는다 — run_state.gd의 _fateshuffle_swap_count() 참고.
##
## "legend_berserker_ragenuke"(광전 돌격): 광전사는 이미 explosive_stack(공격 최댓값
## 3회 누적 -> 보너스 공격턴 1D20)이 있다 — "광기 심화"(frenzy_deepen)가 그 보너스 턴을
## "1D20 두 번 굴려 최댓값"으로 강화했듯, 이 전설은 더 나아가 보너스 턴을 확률 없이
## 항상 최댓값(20)으로 고정한다(DESIGN.md "모든 공격 다이스가 한 면 값으로 고정" 예시를
## 폭발 스택 보너스 턴에 적용). combat_test.gd의 player_legend_ragenuke_active 분기 참고.
##
## "legend_berserker_bloodlust"(유혈광란): 광전사 자기 기믹(min_max_only)은 다이스가
## 중간값 없이 최솟값 아니면 최댓값만 나와 "최댓값이 뜨는 빈도"가 표준 다이스보다 높다 —
## 이 전설은 매 공격턴(보너스 턴 제외 불문) 최댓값을 보인 공격 다이스 1개당 방어 무시
## 고정 피해를 추가로 준다(DiceBag.count_max_rolls() 재사용, cannon_volley/broadside가
## 이미 쓰는 "방어 무시 고정 피해" 패턴 재사용). combat_test.gd의
## _bloodlust_bonus_damage() 참고.
##
## "legend_berserker_vengeance"(불굴의 보복): bloodlust와 완전히 대칭(공격 대신 방어) —
## 새 메커니즘(반격). 방어턴마다 최솟값을 보인 방어 다이스 1개당 방어 무시 반격 피해를
## 몬스터에게 준다(DiceBag.count_min_rolls(), 이번 조각에서 신규 추가). 하이리스크
## 하이리턴 정체성대로 "최악의 방어 굴림"도 보복의 재료로 쓴다. combat_test.gd의
## _vengeance_bonus_damage() 참고.
##
## 세 캐릭터(novice/berserker) 전부 "전설 스킬은 한 런에 하나만 가질 수 있다"는 안내
## 문장을 description 끝에 그대로 포함한다(INBOX.md "설명에도 적혀 있어야 함" 명시 —
## 등급 태그/도감/팝업/카드가 공통으로 description을 그려주는 자리이므로 문구를
## description에 두면 렌더 지점을 새로 만들지 않고 네 곳(카드/도감/팝업/시작 스킬
## 슬롯) 모두에 자동으로 나타난다).
const LEGENDARY_SKILLS: Array[Dictionary] = [
	{
		"id": "legend_novice_harmony",
		"name": "만물의 조화",
		"description": "매 턴(공격/방어 모두), 그 턴 가장 낮았던 다이스 결과값이 그 턴 가장 높았던 값으로 바뀐다 (자기 면 개수 상한 없음). 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "novice",
		"diagram": [
			{"type": "duration", "kind": "every_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "dual"},
			{"type": "value", "op": "max"},
		],
	},
	{
		"id": "legend_novice_rally",
		"name": "결의의 반격",
		"description": "방어로 피해를 완전히 막으면(데미지 0), 그 방어 합계만큼 몬스터에게 방어 무시 반격 피해를 준다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "novice",
		"diagram": [
			{"type": "condition", "kind": "perfect_block"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "op": "full", "ignore_defense": true},
		],
	},
	{
		"id": "legend_novice_fateshuffle",
		"name": "운명의 뒤섞임",
		"description": "라운드가 바뀔 때마다, 공격/방어 다이스를 보유한 개수만큼(적은 쪽 기준) 전부 서로 맞바꾼다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "novice",
		"diagram": [
			{"type": "condition", "kind": "round_change"},
			{"type": "arrow"},
			{"type": "swap", "count": 3},
		],
	},
	{
		"id": "legend_berserker_ragenuke",
		"name": "광전 돌격",
		"description": "폭발 스택이 3에 도달하면 보너스 공격턴이 확률 없이 항상 최댓값(20)으로 확정된다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "berserker",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "op": "max"},
		],
	},
	{
		"id": "legend_berserker_bloodlust",
		"name": "유혈광란",
		"description": "공격턴마다, 최댓값을 보인 공격 다이스 1개당 방어 무시 고정 피해 +2를 추가로 준다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "berserker",
		"diagram": [
			{"type": "die", "target": "attack"},
			{"type": "arrow"},
			{"type": "value", "amount": 2, "op": "+", "ignore_defense": true},
		],
	},
	{
		"id": "legend_berserker_vengeance",
		"name": "불굴의 보복",
		"description": "방어턴마다, 최솟값을 보인 방어 다이스 1개당 방어 무시 반격 피해 +2를 몬스터에게 준다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "berserker",
		"diagram": [
			{"type": "die", "target": "defense"},
			{"type": "arrow"},
			{"type": "value", "amount": 2, "op": "+", "ignore_defense": true},
		],
	},
	# 2/4(이번 조각): 수호자(guardian)/폭발병(explosive) 6종. 수호자는 "방어·반격
	# 특화"(fixed_defense_die, 방어 다이스 1개 항상 고정값) 정체성, 폭발병은 "폭발
	# 스택·한 방 특화"(explosive_stack, 공격 최댓값 3회 누적 -> 보너스 공격턴)
	# 정체성과 시너지를 갖도록 설계했다 — 나머지 2명(주술사/매혹사/곡예사/해적)은
	# 3/4~4/4가 이어간다.
	#
	# "legend_guardian_bulwark"(최후의 보루): 평소에는 기믹대로 방어 다이스 1개만
	# 고정값이지만, 플레이어 HP가 절반 이하로 떨어지면 그 턴 방어 다이스 "전부"가 각자의
	# 면 최댓값으로 고정된다(DESIGN.md가 전설 스킬 예시로 든 "다이스 규칙 변경"을 "위기
	# 상황에서"로 조건화) — 몬스터 "guard_up"(HP 절반 이하 -> 방어 +1) 조건을 재사용하되
	# 효과 강도를 극한까지 올렸다. DiceBag.apply_force_max()(이번 조각 신규, count_max_
	# rolls()와 같은 "다이스별 자기 면 최댓값" 계산 재사용) + combat_test.gd의
	# _is_hp_half_or_below() 참고.
	#
	# "legend_guardian_overguard"(반격의 벽): 새 메커니즘(반격) — "결의의 반격"(견습
	# 모험가 전설)과 달리 완전 방어(dmg==0)를 요구하지 않는다. 방어 합계가 몬스터 공격
	# 합계를 "초과"하기만 하면 그 초과분이 그대로 방어 무시 반격 피해가 된다(부족하면
	# 0) — 수호자는 방어 다이스가 많아(D4x4) 과잉 방어가 자주 나오는 체질이라 거의 매
	# 방어턴 조금씩 반격 피해가 쌓이는 "벽에 부딪히면 아프다" 정체성. combat_test.gd의
	# _overguard_counter_damage() 참고.
	#
	# "legend_guardian_bastion"(불굴의 벽): 자기 기믹(fixed_defense_die)의 고정 방어
	# 다이스 값 자체를 영구히 키운다 — 라운드가 바뀔 때마다(런 전체에서 최대 2회) 그
	# 값이 2씩 올라간다(상한: 그 다이스의 면 개수, 다이스 개조로 면 개수가 늘면 상한도
	# 함께 늘어남). 별도 상태 변수 없이 "고정값은 다이스 자체에 저장돼 있다"는 기존
	# 구조를 그대로 재활용한 "성장형" 전설 — run_state.gd의 advance_round()/
	# _bastion_fixed_value() 참고.
	#
	# "legend_explosive_chainblast"(연쇄 폭발의 고리): 폭발병은 이미 자기 기믹으로
	# explosive_stack 파이프라인을 갖고 있어(frenzy_deepen처럼 "없던 파이프라인을
	# 열어준다" 패턴을 못 씀) — 대신 보너스 공격턴을 소모해도 스택이 0으로 리셋되지
	# 않고 임계치만큼만 줄어, 초과분이 남아있으면 보너스 공격턴이 짧은 간격으로 연속
	# 발동할 수 있다("폭발이 폭발을 부른다"). combat_test.gd의
	# _update_explosive_chain_progress() 참고.
	#
	# "legend_explosive_absolute"(절대 폭발): 폭발 스택 보너스 공격턴(1D20)의 피해가
	# 몬스터 방어를 완전히 무시하게 만든다 — 막혔던 만큼(atk_total - dmg)을 방어 무시
	# 고정 피해로 그대로 돌려줘, cannon_volley/bloodlust가 쓰는 "방어 무시 고정 피해"
	# 패턴을 "보너스 턴 전체 피해"로 확장했다. combat_test.gd의
	# _absolute_detonation_bonus_damage() 참고.
	#
	# "legend_explosive_lastblast"(최후의 폭발): legend_guardian_bulwark와 대칭(수비
	# 대신 공격) — 플레이어 HP가 절반 이하이면 폭발 스택 진행과 무관하게 "모든" 공격턴이
	# 보너스 폭발턴(1D20)이 된다. 하이리스크 하이리턴 정체성을 벼랑 끝에서 극대화하는
	# "한 방 특화"의 정점. combat_test.gd의 _select_exchange_bags() 내
	# force_last_blast 분기 참고.
	#
	# 여섯 캐릭터(guardian/explosive) 전부 1/4과 동일하게 "전설 스킬은 한 런에 하나만
	# 가질 수 있다" 안내 문장을 description 끝에 포함한다.
	{
		"id": "legend_guardian_bulwark",
		"name": "최후의 보루",
		"description": "HP가 절반 이하일 때, 이번 방어 다이스 전부가 각자의 면 최댓값으로 고정된다 (평소에는 다이스 1개만 고정). 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "guardian",
		"diagram": [
			{"type": "condition", "kind": "hp_half"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "op": "max"},
		],
	},
	{
		"id": "legend_guardian_overguard",
		"name": "반격의 벽",
		"description": "방어 합계가 몬스터 공격 합계를 초과하면(완전 방어가 아니어도), 그 초과분만큼 몬스터에게 방어 무시 반격 피해를 준다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "guardian",
		"diagram": [
			{"type": "condition", "kind": "overguard"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "op": "full", "ignore_defense": true},
		],
	},
	{
		"id": "legend_guardian_bastion",
		"name": "불굴의 벽",
		"description": "라운드가 바뀔 때마다, 고정 방어 다이스 값이 2씩 영구히 오른다 (상한: 그 다이스의 면 개수). 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "guardian",
		"diagram": [
			{"type": "condition", "kind": "round_change"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "amount": 2, "op": "+"},
		],
	},
	{
		"id": "legend_explosive_chainblast",
		"name": "연쇄 폭발의 고리",
		"description": "폭발 스택이 임계치에 도달해 보너스 공격턴(1D20)을 써도 스택이 0으로 돌아가지 않고 임계치만큼만 줄어, 초과분이 남아있으면 보너스 공격턴이 연속으로 발동할 수 있다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "explosive",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
		],
	},
	{
		"id": "legend_explosive_absolute",
		"name": "절대 폭발",
		"description": "폭발 스택 보너스 공격턴(1D20)의 피해가 몬스터 방어를 완전히 무시한다 (막혔던 만큼을 방어 무시 피해로 그대로 돌려줌). 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "explosive",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "op": "full", "ignore_defense": true},
		],
	},
	{
		"id": "legend_explosive_lastblast",
		"name": "최후의 폭발",
		"description": "HP가 절반 이하이면, 폭발 스택 진행과 무관하게 모든 공격턴이 보너스 공격턴(1D20)이 된다. 전설 스킬은 한 런에 하나만 가질 수 있다.",
		"character_id": "explosive",
		"diagram": [
			{"type": "condition", "kind": "hp_half"},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
		],
	},
]


## 스킬 강화판([미니 기획 D], 2026-09-17; 2026-09-24 [대형 기획 4]-D4로 매혹사/곡예사
## 2종 추가돼 총 9종) — 기존 스킬(SKILLS 2종 + UNIQUE_SKILLS 7종) 각각의 "+" 버전. 새
## 메커니즘을 만들지 않고 "기존 메커니즘을 한 단계 더 강하게"만 한다(기획자 결정 원문).
## "upgrades" 필드가 base 스킬 id를 가리킨다 — 이 필드로 available_upgrade_choices()가
## "base를 보유했는데 +는 아직 없는" 후보를 찾는다. character_id 필드는 UNIQUE_SKILLS
## 계열 강화에만 있고(공용 스킬 강화는 캐릭터 무관), item dict 형식은 SKILLS/UNIQUE_SKILLS와
## 동일해 ItemCardStyle 카드 UI를 그대로 재사용한다.
const UPGRADE_SKILLS: Array[Dictionary] = [
	{
		"id": "deep_breath_plus",
		"name": "심호흡+",
		"description": "방어 다이스 +1 보정이 첫 방어턴뿐 아니라 매 방어턴마다 적용된다 (상한: 각 다이스 면 개수).",
		"upgrades": "deep_breath",
		"diagram": [
			{"type": "duration", "kind": "every_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "spare_die_plus",
		"name": "여분+",
		"description": "여분 다이스를 1개가 아니라 2개 굴려, 그 중 더 높은 값으로 가장 낮은 공격 다이스를 대체한다.",
		"upgrades": "spare_die",
		"diagram": [
			{"type": "duration", "kind": "every_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "reroll", "count": 2},
		],
	},
	{
		"id": "frenzy_deepen_plus",
		"name": "광기 심화+",
		"description": "폭발 스택이 3에 도달하면 보너스 공격턴이 1D20을 두 번이 아니라 세 번 굴려 더 높은 값을 채택한다 (광전사 전용).",
		"upgrades": "frenzy_deepen",
		"character_id": "berserker",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "reroll", "count": 3},
		],
	},
	{
		"id": "guard_deepen_plus",
		"name": "수호 심화+",
		"description": "수호 스택이 3에 도달하면 보너스 방어턴이 1D20을 두 번이 아니라 세 번 굴려 더 높은 값을 채택한다 (수호자 전용).",
		"upgrades": "guard_deepen",
		"character_id": "guardian",
		"diagram": [
			{"type": "stack", "target": "defense", "threshold": 3},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "reroll", "count": 3},
		],
	},
	{
		"id": "chain_explosion_plus",
		"name": "연쇄 폭발+",
		"description": "폭발 스택 임계치는 2 그대로, 보너스 공격턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (폭발병 전용).",
		"upgrades": "chain_explosion",
		"character_id": "explosive",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 2},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "reroll", "count": 2},
		],
	},
	{
		"id": "chain_guard_plus",
		"name": "연쇄 방어+",
		"description": "수호 스택 임계치는 2 그대로, 보너스 방어턴이 1D20을 두 번 굴려 더 높은 값을 채택하는 것으로 강화된다 (방패병 전용).",
		"upgrades": "chain_guard",
		"character_id": "shieldbearer",
		"diagram": [
			{"type": "stack", "target": "defense", "threshold": 2},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "reroll", "count": 2},
		],
	},
	{
		"id": "versatile_surge_plus",
		"name": "임기응변+",
		"description": "공격/방어 스택 임계치가 3에서 2로 낮아져 보너스 턴을 더 자주 받는다 (견습 모험가 전용).",
		"upgrades": "versatile_surge",
		"character_id": "novice",
		"diagram": [
			{"type": "stack", "target": "attack", "threshold": 2},
			{"type": "stack", "target": "defense", "threshold": 2},
			{"type": "arrow"},
			{"type": "die", "target": "dual"},
		],
	},
	{
		"id": "charm_amplify_plus",
		"name": "매혹 심화+",
		"description": "charm_flip 효과가 그 턴 가장 낮은 다이스 2개가 아니라 3개에 적용된다 (매혹사 전용).",
		"upgrades": "charm_amplify",
		"character_id": "enchantress",
		"diagram": [
			{"type": "duration", "kind": "every_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "dual", "count": 3},
			{"type": "value", "op": "max"},
		],
	},
	{
		"id": "juggle_encore_plus",
		"name": "곡예 앙코르+",
		"description": "라운드 전환 시 다이스 교환이 1번이 아니라 2번(서로 다른 무작위 다이스 쌍) 일어난다 (곡예사 전용).",
		"upgrades": "juggle_encore",
		"character_id": "juggler",
		"diagram": [
			{"type": "condition", "kind": "round_change"},
			{"type": "arrow"},
			{"type": "swap", "count": 2},
		],
	},
	{
		"id": "broadside_plus",
		"name": "일제 사격+",
		"description": "함포 일제사격 주기는 2턴 그대로, 고정 피해가 공격 합계의 절반이 아니라 전부로 강화된다 (해적 전용).",
		"upgrades": "broadside",
		"character_id": "pirate",
		"diagram": [
			{"type": "cycle", "turns": 2, "target": "attack"},
			{"type": "arrow"},
			{"type": "value", "op": "full", "ignore_defense": true},
		],
	},
	{
		"id": "juggle_fortune_plus",
		"name": "곡예 흥행+",
		"description": "이벤트 주사위 굴림 보정이 +1에서 +2로 강화된다 (상한은 그대로 이벤트 주사위 면 개수, 곡예사 전용).",
		"upgrades": "juggle_fortune",
		"character_id": "juggler",
		"diagram": [
			{"type": "die", "target": "event"},
			{"type": "arrow"},
			{"type": "value", "amount": 2, "op": "+"},
		],
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
## 스킬 목록"을 만드는데, STARTING_SKILLS 안에서의 등장 순서가 곧 슬롯 순서다. [대형
## 기획 5] F-2(a)부터 3단 해금 사다리다(슬롯 0=항상 해금 / 슬롯 1=해당 캐릭터로 첫
## 던전(라운드 1) 클리어, r1_<id> / 슬롯 2=해당 캐릭터로 최종 클리어, clear_<id> — 실제
## 판정은 unlock_requirement()/is_slot_requirement_met()이 슬롯 번호로 분기). 예: 견습
## 모험가는 start_expand -> start_lean -> start_wealth 순으로 등장해 슬롯 0="확장",
## 슬롯 1="정예", 슬롯 2="황금손"이 된다.
const STARTING_SKILLS: Array[Dictionary] = [
	{
		"id": "start_aggro",
		"name": "맹공",
		"description": "공격 다이스 개수가 방어 다이스 개수보다 많으면, 공격 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		# 2026-10-15 [대형 기획 14] N-5(a): 곡예사가 "이벤트 특화 클래스"로 재편되면서
		# 곡예사의 시작 스킬 사다리(전투 보너스형 3종)가 이벤트 테마로 교체됐다 — 이
		# 전투 스킬은 더는 곡예사 후보가 아니다(아래 start_hoard도 동일). 곡예사가
		# 유지하는 전투 보조 1종은 "잡화점"(start_diverse, 곡예사 전용 id)이다.
		"character_ids": ["berserker", "explosive"],
		"diagram": [
			{"type": "compare", "left": "attack", "op": ">", "right": "defense"},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_wall",
		"name": "철벽",
		"description": "방어 다이스 개수가 공격 다이스 개수보다 많으면, 방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["guardian", "shieldbearer"],
		"diagram": [
			{"type": "compare", "left": "defense", "op": ">", "right": "attack"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_expand",
		"name": "확장",
		"description": "공격+방어 다이스 합계가 8개 이상이면, 공격/방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["novice", "explosive", "enchantress"],
		"diagram": [
			{"type": "condition", "kind": "dice_total", "op": ">=", "value": 8},
			{"type": "arrow"},
			{"type": "die", "target": "dual"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_lean",
		"name": "정예",
		"description": "공격+방어 다이스 합계가 7개 이하로 유지되면, 공격/방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["novice", "shieldbearer", "enchantress"],
		"diagram": [
			{"type": "condition", "kind": "dice_total", "op": "<=", "value": 7},
			{"type": "arrow"},
			{"type": "die", "target": "dual"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_hoard",
		"name": "수집가",
		"description": "보유한 눈금 인벤토리가 5개 이상이면, 공격 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		# N-5(a): 곡예사 제외(위 start_aggro 주석 참고).
		"character_ids": ["berserker"],
		"diagram": [
			{"type": "condition", "kind": "pip_inventory", "op": ">=", "value": 5},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_ironclad",
		"name": "강철 방비",
		"description": "철제 재질(D12/D20) 다이스를 1개 이상 보유하면, 방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["guardian"],
		"diagram": [
			{"type": "condition", "kind": "material", "value": "steel"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_vanguard",
		"name": "선제",
		"description": "전투의 첫 공격턴 한 번만, 공격 다이스 결과값 전체가 +2 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["berserker"],
		"diagram": [
			{"type": "condition", "kind": "first_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "amount": 2, "op": "+"},
		],
	},
	{
		"id": "start_bulwark",
		"name": "대비",
		"description": "전투의 첫 방어턴 한 번만, 방어 다이스 결과값 전체가 +2 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["guardian"],
		"diagram": [
			{"type": "condition", "kind": "first_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "amount": 2, "op": "+"},
		],
	},
	{
		"id": "start_wealth",
		"name": "황금손",
		"description": "보유한 골드 30마다 공격 다이스 결과값 전체가 +1 된다 (최대 +2, 상한: 각 다이스 면 개수).",
		"character_ids": ["novice"],
		"diagram": [
			{"type": "condition", "kind": "gold", "value": 30},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "amount": 1, "op": "+", "max": 2},
		],
	},
	{
		"id": "start_overflow",
		"name": "과적",
		"description": "공격/방어 주머니 중 다이스 개수가 최대(6개)로 꽉 찬 쪽은 결과값 전체가 +1 된다 (두 쪽 다 꽉 차면 둘 다, 상한: 각 다이스 면 개수).",
		"character_ids": ["explosive"],
		"diagram": [
			{"type": "condition", "kind": "dice_cap", "value": 6},
			{"type": "arrow"},
			{"type": "die", "target": "dual"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_second_wind",
		"name": "오뚝이",
		"description": "전투 중 플레이어 HP가 최대 HP의 절반 이하이면, 방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["shieldbearer"],
		"diagram": [
			{"type": "condition", "kind": "hp_half"},
			{"type": "arrow"},
			{"type": "die", "target": "defense"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	{
		"id": "start_gambler",
		"name": "승부사",
		"description": "특수 이벤트 '위험을 감수하기'의 판정 DC가 1 낮아진다 (최저 DC 2).",
		"character_ids": ["enchantress"],
		"diagram": [
			{"type": "die", "target": "event"},
			{"type": "arrow"},
			{"type": "value", "amount": -1, "op": "+"},
		],
	},
	# 곡예사 이벤트 스킬 2종(N-5(a), 슬롯0/슬롯1) — "최소 2종을 이벤트 스킬로 교체,
	# 전투 보조 1종은 유지" 지시 반영. 아래 "잡화점"(기존 슬롯2, 전투 보조)은 그대로
	# 남겨 슬롯 순서가 눈속임(슬롯0) -> 한탕(슬롯1) -> 잡화점(슬롯2)이 되도록 이 두
	# 항목을 잡화점 바로 앞에 넣는다(STARTING_SKILLS 안에서의 등장 순서 = 슬롯 순서,
	# starting_skills_for_character() 주석 참고).
	{
		"id": "start_sleight",
		"name": "눈속임",
		"description": "특수 이벤트 '위험을 감수하기'의 판정 DC가 1 낮아진다 (최저 DC 2).",
		# "승부사"(start_gambler, 매혹사 전용)와 효과는 같지만 INBOX.md 지시대로
		# "매혹사와 공유하지 말고 구분"하기 위해 별도 id로 분리했다 — event.gd의
		# DC 계산이 두 id 중 하나만 있어도(or 조건) 동일하게 -1을 적용한다.
		"character_ids": ["juggler"],
		"diagram": [
			{"type": "die", "target": "event"},
			{"type": "arrow"},
			{"type": "value", "amount": -1, "op": "+"},
		],
	},
	{
		"id": "start_fortune",
		"name": "한탕",
		"description": "특수 이벤트 '위험을 감수하기'에서 성공하면 골드를 추가로 얻는다.",
		"character_ids": ["juggler"],
		"diagram": [
			{"type": "die", "target": "event"},
			{"type": "arrow"},
			{"type": "gold", "amount": 10},
		],
	},
	{
		"id": "start_diverse",
		"name": "잡화점",
		"description": "공격+방어 다이스 중 서로 다른 면 개수의 종류가 3종 이상이면, 공격/방어 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		# N-5(a): 곡예사가 유지하는 유일한 "전투 보조" 시작 스킬(슬롯2) — 눈속임/한탕과
		# 달리 전투 보너스형이라 그대로 남겨둔다.
		"character_ids": ["juggler"],
		"diagram": [
			{"type": "condition", "kind": "dice_type_count", "op": ">=", "value": 3},
			{"type": "arrow"},
			{"type": "die", "target": "dual"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
	# 해적([대형 기획 9] I-2, INBOX.md 2026-10-08 기획자 결정)은 슬롯 순서가
	# 선제->황금손->수집가인데, 이 세 id는 이미 berserker(수집가->선제 순)/novice(황금손이
	# 세 번째) 쪽 상대 순서로 전역 배열에 고정돼 있어 같은 dict row를 그대로 공유하면
	# 순서를 둘 다 만족시킬 수 없다(berserker는 start_hoard가 start_vanguard보다 앞에
	# 와야 하는데 해적은 반대 — starting_skills_for_character()가 전역 배열 등장 순서로
	# 슬롯을 매기므로 같은 두 엔트리로는 두 순서를 동시에 만족 불가). 그래서 berserker/
	# novice 쪽 엔트리는 그대로 두고, 해적 전용으로 id/name/description이 동일한 별도
	# row 3개를 새로 추가해 이 세 줄끼리의 상대 순서만으로 해적의 슬롯 순서를 만든다
	# (character_ids가 다른 엔트리라 berserker/novice 필터링에는 전혀 섞이지 않음,
	# find_skill()은 id로만 찾아 name/description이 같은 두 row 중 아무거나 찾아도
	# 결과가 같음).
	{
		"id": "start_vanguard",
		"name": "선제",
		"description": "전투의 첫 공격턴 한 번만, 공격 다이스 결과값 전체가 +2 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["pirate"],
		"diagram": [
			{"type": "condition", "kind": "first_turn"},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "amount": 2, "op": "+"},
		],
	},
	{
		"id": "start_wealth",
		"name": "황금손",
		"description": "보유한 골드 30마다 공격 다이스 결과값 전체가 +1 된다 (최대 +2, 상한: 각 다이스 면 개수).",
		"character_ids": ["pirate"],
		"diagram": [
			{"type": "condition", "kind": "gold", "value": 30},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "amount": 1, "op": "+", "max": 2},
		],
	},
	{
		"id": "start_hoard",
		"name": "수집가",
		"description": "보유한 눈금 인벤토리가 5개 이상이면, 공격 다이스 결과값 전체가 +1 된다 (상한: 각 다이스 면 개수).",
		"character_ids": ["pirate"],
		"diagram": [
			{"type": "condition", "kind": "pip_inventory", "op": ">=", "value": 5},
			{"type": "arrow"},
			{"type": "die", "target": "attack"},
			{"type": "value", "amount": 1, "op": "+"},
		],
	},
]


## 시작 스킬 슬롯의 해금 조건을 한 곳에서 만든다([대형 기획 5] F-1, INBOX.md 2026-10-06
## 기획자 결정). F-2(a)부터 3단 사다리(슬롯 0=항상 해금 / 슬롯 1=해당 캐릭터로 첫 던전
## (라운드 1) 클리어 / 슬롯 2=해당 캐릭터로 최종 클리어)다 — character_select.gd는 이
## 함수 하나만 참조하므로, 나중에 조건이 또 바뀌어도 여기만 고치면 된다.
## 반환: {"achievement_id": String(빈 문자열이면 "항상 해금"을 뜻함), "text": String}.
static func unlock_requirement(character_id: String, slot_index: int) -> Dictionary:
	var character_name: String = CharacterProfiles.get_profile(character_id).get("name", character_id)
	if slot_index <= 0:
		return {"achievement_id": "", "text": "기본 해금"}
	elif slot_index == 1:
		return {
			"achievement_id": "r1_" + character_id,
			"text": "%s(으)로 첫 던전(라운드 1)을 클리어하면 해금" % character_name,
		}
	else:
		return {
			"achievement_id": "clear_" + character_id,
			"text": "%s(으)로 최종 클리어(3라운드 전부)하면 해금" % character_name,
		}


## unlock_requirement()가 가리키는 업적이 실제로 해금됐는지 판정한다(AchievementManager
## 조회 + 마이그레이션 포함). 슬롯 1의 새 조건은 "r1_<id>"(라운드 1 클리어)지만, F-2(a) 전에
## 이미 "clear_<id>"(최종 클리어)를 해금해둔 기존 세이브는 그 자체로 라운드 1 클리어를
## 포함하므로 r1_<id>가 없어도 슬롯 1을 열어준다 — 이 "또는" 판정을 한 곳에만 둔다.
static func is_slot_requirement_met(character_id: String, slot_index: int) -> bool:
	var requirement := unlock_requirement(character_id, slot_index)
	var achievement_id: String = requirement.get("achievement_id", "")
	if achievement_id == "":
		return true
	if AchievementManager.is_unlocked(achievement_id):
		return true
	if slot_index == 1:
		return AchievementManager.is_unlocked("clear_" + character_id)
	return false


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
## 남은 후보 중 최대 n개를 레어리티 가중치(RARITY_DROP_WEIGHTS)에 비례해 무작위로
## (중복 없이) 반환한다([대형 기획 15] Q-8(a) "보상 풀 가중치" — 이전엔 pool.shuffle()
## 로 균등 추첨이었다. 효과/밸런스는 건드리지 않고 "어느 카드가 더 자주 보이는가"만
## 바뀐다). 후보가 하나도 없으면 빈 배열을 돌려주고, event.gd는 이 경우 스킬 이벤트
## 대신 기존 아이템 이벤트로 대체한다.
static func available_choices(n: int, character_id: String = "") -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for skill in SKILLS:
		if not RunState.skill_flags.has(skill["id"]):
			pool.append(skill)
	if character_id != "":
		for skill in UNIQUE_SKILLS:
			if skill.get("character_id", "") == character_id and not RunState.skill_flags.has(skill["id"]):
				pool.append(skill)
		for skill in LEGENDARY_SKILLS:
			if skill.get("character_id", "") == character_id and not RunState.skill_flags.has(skill["id"]):
				pool.append(skill)
	# Q-8(c) "한 런에 전설은 하나만" — weighted_pick() 추첨 전에 걸러낸다(위
	# filter_legendary_if_owned() 주석 참고).
	pool = filter_legendary_if_owned(pool, RunState.skill_flags)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return weighted_pick(pool, n, rng)


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
## available_choices()와 같은 패턴(Q-8(a)부터 레어리티 가중치 추첨)으로 남은 후보 중
## 최대 n개를 반환, 후보가 없으면 빈 배열(event.gd는 이 경우 기존 아이템/스킬 이벤트로
## 대체해야 함).
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
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return weighted_pick(pool, n, rng)


## base_id(강화 전 스킬 id)를 받아 UPGRADE_SKILLS에서 대응하는 "+"id를 찾아 grant()로
## skill_flags에 추가한다(중복 방지는 grant()가 그대로 처리). 대응하는 강화판이 없으면
## 아무 일도 하지 않는다.
static func grant_upgrade(base_id: String) -> void:
	for skill in UPGRADE_SKILLS:
		if skill["upgrades"] == base_id:
			grant(skill["id"])
			return


## 스킬 아이콘 모티프 분류표([대형 기획 11] K-4a, 2026-10-13). SkillIcon(skill_icon.gd)이
## category(캐릭터 고유 기믹 8종)와는 별개로 "스킬"(SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/
## STARTING_SKILLS) 쪽에 쓸 motif를 여기서 결정론적으로 조회한다. "효과" 기준으로 11종
## 모티프로 나눴다 — 시작 스킬 13종 중 9종이 "다이스 결과값 보정"류라 먼저 "무엇을
## 올리는가"(공격만/방어만/양쪽 다)로 나누고, 나머지(재굴림/스택형 보너스턴/다이스
## 전환·맞바꾸기/주기형 고정 피해/이벤트 판정 보정)를 효과 종류별로 묶었다. 트리거
## 조건(골드/인벤토리/재질/다이스 개수 등)은 모티프에 반영하지 않는다 — INBOX.md가
## "스킬의 실제 효과"로 분류하라고 명시했고, 조건이 달라도 최종 효과(예: "공격 다이스
## +1")가 같으면 같은 모티프를 공유해야 아이콘이 "효과를 한눈에 읽힌다"는 목적에
## 맞는다. 새 스킬을 추가하면서 이 표에 깜빡 안 넣으면 dice_test.gd의
## _check_k4a_skill_icon_motifs()가 빈 문자열을 잡아 FAIL로 알려준다(기본값/빈 아이콘
## fallback을 의도적으로 두지 않음).
const ICON_MOTIFS: Dictionary = {
	# 공격 다이스 결과값 보정만
	"start_aggro": "attack_boost",
	"start_hoard": "attack_boost",
	"start_vanguard": "attack_boost",
	"start_wealth": "attack_boost",
	# 방어 다이스 결과값 보정만
	"deep_breath": "defense_boost",
	"deep_breath_plus": "defense_boost",
	"start_wall": "defense_boost",
	"start_ironclad": "defense_boost",
	"start_bulwark": "defense_boost",
	"start_second_wind": "defense_boost",
	# 공격+방어 둘 다 보정
	"start_expand": "dual_boost",
	"start_lean": "dual_boost",
	"start_overflow": "dual_boost",
	"start_diverse": "dual_boost",
	# 여분 다이스로 대체(재굴림)
	"spare_die": "reroll",
	"spare_die_plus": "reroll",
	# 공격 스택 임계치 도달 -> 보너스 공격턴
	"frenzy_deepen": "burst_stack",
	"frenzy_deepen_plus": "burst_stack",
	"chain_explosion": "burst_stack",
	"chain_explosion_plus": "burst_stack",
	# 방어 스택 임계치 도달 -> 보너스 방어턴
	"guard_deepen": "guard_stack",
	"guard_deepen_plus": "guard_stack",
	"chain_guard": "guard_stack",
	"chain_guard_plus": "guard_stack",
	# 공격+방어 스택이 함께 열림(견습 모험가 전용)
	"versatile_surge": "dual_stack",
	"versatile_surge_plus": "dual_stack",
	# 다이스 값을 최댓값으로 전환
	"charm_amplify": "dice_flip",
	"charm_amplify_plus": "dice_flip",
	# 다이스 맞바꾸기
	"juggle_encore": "dice_swap",
	"juggle_encore_plus": "dice_swap",
	# 주기형(쿨타임) 고정 피해
	"broadside": "cycle_strike",
	"broadside_plus": "cycle_strike",
	# 전투 외 이벤트 판정 보정
	"start_gambler": "event_check",
	# N-5(a): 곡예사 이벤트 스킬 4종(시작 2종 + 전용/강화 1쌍) — 전부 "이벤트 판정
	# 보정"이라는 같은 효과 범주라 start_gambler와 모티프를 공유한다(ICON_MOTIFS
	# 주석의 "효과가 같으면 같은 모티프" 원칙).
	"start_sleight": "event_check",
	"start_fortune": "event_check",
	"juggle_fortune": "event_check",
	"juggle_fortune_plus": "event_check",
	# LEGENDARY_SKILLS(Q-8(c) 1/4, 2026-10-19) — "만물의 조화"는 매 턴 공격+방어 둘 다
	# 보정하는 효과라 기존 dual_boost를 그대로 공유(값 범위만 다르고 "효과 범주"는
	# 같음 — ICON_MOTIFS 주석의 "효과가 같으면 같은 모티프" 원칙). "운명의 뒤섞임"도
	# 다이스를 맞바꾸는 효과라 기존 dice_swap을 공유. 전설 전용 신규 모티프 3종
	# (legend_nuke/true_strike/counter_strike)은 아래에서 새로 추가 — 보너스 턴 확정
	# 최댓값/방어 무시 고정 피해/완전 방어 반격은 기존 11종 중 맞아떨어지는 범주가
	# 없어서 전설다운 시각 신호(SkillIcon.COLOR_LEGENDARY, 레어리티 색과 일치)를
	# 새로 만들었다.
	"legend_novice_harmony": "dual_boost",
	"legend_novice_rally": "counter_strike",
	"legend_novice_fateshuffle": "dice_swap",
	"legend_berserker_ragenuke": "legend_nuke",
	"legend_berserker_bloodlust": "true_strike",
	"legend_berserker_vengeance": "true_strike",
	# LEGENDARY_SKILLS(Q-8(c) 2/4, 2026-10-19) — guardian/explosive 6종. 1/4과 같은
	# "효과 범주가 같으면 기존 모티프를 공유" 원칙을 그대로 따라 신규 모티프를 추가하지
	# 않았다: "최후의 보루"(방어 다이스 전부를 자기 면 최댓값으로 전환)는 charm_amplify의
	# "값을 최댓값으로" 범주와 같아 dice_flip 공유. "반격의 벽"(방어턴에 반격 피해)은
	# "결의의 반격"과 같은 "방어턴 반격" 범주라 counter_strike 공유. "불굴의 벽"(방어
	# 다이스 결과값 영구 보정)은 "방어 다이스 결과값 보정" 범주라 defense_boost 공유.
	# "연쇄 폭발의 고리"/"최후의 폭발"(둘 다 최종 결과가 "이번 공격턴이 보너스 폭발턴이
	# 된다")은 burst_stack 공유(둘 다 발동 "조건"만 다르고 결과는 같음). "절대 폭발"
	# (보너스 폭발턴 피해가 방어 무시)은 유혈광란/불굴의 보복과 같은 "방어 무시 추가
	# 피해" 범주라 true_strike 공유.
	"legend_guardian_bulwark": "dice_flip",
	"legend_guardian_overguard": "counter_strike",
	"legend_guardian_bastion": "defense_boost",
	"legend_explosive_chainblast": "burst_stack",
	"legend_explosive_absolute": "true_strike",
	"legend_explosive_lastblast": "burst_stack",
}

## ICON_MOTIFS가 쓰는 값 전체(테스트/미리보기에서 전수 순회용). 여기 없는 문자열이
## skill_icon.gd에 들어오면 빈 원으로 떨어진다(_draw_motif()의 match 기본 분기).
## legend_nuke/true_strike/counter_strike 3종은 Q-8(c) 1/4(2026-10-19) 신규 — 전설
## 스킬 전용(SkillIcon.COLOR_LEGENDARY, RARITY_COLORS[RARITY_LEGENDARY]와 같은 색조).
const ICON_MOTIF_VALUES: Array[String] = [
	"attack_boost", "defense_boost", "dual_boost", "reroll", "burst_stack",
	"guard_stack", "dual_stack", "dice_flip", "dice_swap", "cycle_strike", "event_check",
	"legend_nuke", "true_strike", "counter_strike",
]


## skill_id -> icon_motif 조회. 등록되지 않은 id는 빈 문자열을 돌려준다(의도적으로
## fallback 모티프를 두지 않음 — 위 ICON_MOTIFS 주석 참고).
static func icon_motif_for(skill_id: String) -> String:
	return ICON_MOTIFS.get(skill_id, "")


## 캐릭터별 스킬 도감 전체 목록([대형 기획 12] L-2(a), INBOX.md 2026-10-14) — 그
## 캐릭터가 런에서 만날 수 있는 모든 스킬을 결정론적 순서(시작 스킬 -> 전용 -> 공용 ->
## 강화)로 모은다. "+"판은 base와 별개 항목으로 집계한다(INBOX.md 명시) — UPGRADE_SKILLS
## id가 이미 base와 다르므로("<base>_plus") 중복 걱정 없이 그대로 포함한다. 각 항목에
## "codex_source"(이 함수 전용 분류표 — SkillIcon.category(캐릭터 기믹 8종)와는 다른
## 개념) 필드를 덧붙여 도감 UI가 섹션을 나누거나 테스트가 분류를 검증할 수 있게 한다.
## 순수 함수(SkillPool의 다른 조회 함수들과 같은 스타일) — RunState/SkillCodex를 전혀
## 읽지 않으므로 몇 번을 불러도 항상 같은 결과를 돌려준다(발견/보유 여부는 호출부가
## SkillCodex.is_discovered()/RunState.skill_flags로 따로 합성).
static func codex_entries(character_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}

	for skill in starting_skills_for_character(character_id):
		if seen.has(skill["id"]):
			continue
		seen[skill["id"]] = true
		var entry: Dictionary = skill.duplicate()
		entry["codex_source"] = "starting"
		result.append(entry)

	for skill in UNIQUE_SKILLS:
		if skill.get("character_id", "") != character_id:
			continue
		if seen.has(skill["id"]):
			continue
		seen[skill["id"]] = true
		var entry: Dictionary = skill.duplicate()
		entry["codex_source"] = "unique"
		result.append(entry)

	# LEGENDARY_SKILLS(Q-8(c)) — UNIQUE_SKILLS 바로 다음(캐릭터 전용이라는 공통점이
	# UNIQUE_SKILLS와 더 가깝다) + SKILLS(공용)보다 앞에 둔다.
	for skill in LEGENDARY_SKILLS:
		if skill.get("character_id", "") != character_id:
			continue
		if seen.has(skill["id"]):
			continue
		seen[skill["id"]] = true
		var entry: Dictionary = skill.duplicate()
		entry["codex_source"] = "legendary"
		result.append(entry)

	for skill in SKILLS:
		if seen.has(skill["id"]):
			continue
		seen[skill["id"]] = true
		var entry: Dictionary = skill.duplicate()
		entry["codex_source"] = "common"
		result.append(entry)

	for skill in UPGRADE_SKILLS:
		var required_character: String = skill.get("character_id", "")
		if required_character != "" and required_character != character_id:
			continue
		if seen.has(skill["id"]):
			continue
		seen[skill["id"]] = true
		var entry: Dictionary = skill.duplicate()
		entry["codex_source"] = "upgrade"
		result.append(entry)

	return result


## skill_id로 네 상수(SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS) 전체를 찾아
## 이름/설명을 조회한다(DeckPanel "보유 스킬" 목록처럼 skill_flags에 쌓인 id만으로
## 화면에 표시할 이름이 필요한 곳에서 재사용). 못 찾으면 빈 Dictionary를 반환한다.
static func find_skill(skill_id: String) -> Dictionary:
	for skill in SKILLS:
		if skill["id"] == skill_id:
			return skill
	for skill in UNIQUE_SKILLS:
		if skill["id"] == skill_id:
			return skill
	for skill in LEGENDARY_SKILLS:
		if skill["id"] == skill_id:
			return skill
	for skill in UPGRADE_SKILLS:
		if skill["id"] == skill_id:
			return skill
	for skill in STARTING_SKILLS:
		if skill["id"] == skill_id:
			return skill
	return {}


## skill_id -> 효과 도식(diagram) 조회([대형 기획 15] Q-7(a)). find_skill()을 그대로
## 재사용하고, 해당 스킬에 "diagram" 필드가 없으면(이론상 없어야 함 — 전수 검증 테스트가
## 보장) 빈 배열을 돌려준다.
static func diagram_for(skill_id: String) -> Array:
	return find_skill(skill_id).get("diagram", [])
