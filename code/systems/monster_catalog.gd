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
	# G-7(2026-10-07) 신규 정예 8종 — INBOX.md [대형 기획 6] G-7 표 그대로(스킬 2개씩,
	# hp_mult 1.5 + atk_dice_delta +1는 "정예 = 스킬 2개 + hp_mult 1.5 + 공격 다이스 +1"
	# 공통 공식, 수치는 전부 잠정값 — F-4 시뮬로 조정 예정). INBOX.md 원문은 인간형 정예
	# 하나를 "다크 나이트"(기존 일반 5종 중 하나, id="dark_knight")를 그대로 재배정해서
	# 쓰길 원했지만, `dice_test.gd`에 그 id로 `_monster_config_for_room(4)`(QA/테스트 전용
	# "레거시" 경로)의 결과 이름을 정확히 "다크 나이트 [철벽] [보스]"로 고정한 회귀
	# 검증이 있다(G-6 문서 주석 — 이 경로는 "동작 보존" 계약). tier를 "elite"로 바꾸면
	# 아래 "[정예]" 이름 태그가 자동으로 붙어(tier=="elite" 전부 공통) 그 경로의 결과
	# 문자열이 바뀌어버린다 — 기존 id는 전혀 손대지 않고, 같은 이름("다크 나이트")·같은
	# 1번째 스킬(steady_guard)을 쓰는 새 id("dark_knight_elite")를 따로 만들어 피했다
	# (이름이 같아도 id가 다르면 "같은 모습의 더 강한 개체"로 읽혀 자연스럽다 —
	# legacy_cycle_monster()의 "강화 " 접두어 재사용 패턴과 같은 맥락).
	{
		"id": "dark_knight_elite", "name": "다크 나이트", "family": "humanoid", "tier": "elite",
		"color": Color(0.55, 0.25, 0.75), "skills": [{"id": "steady_guard"}, {"id": "armor", "amount": 2}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "차갑고 노련하며 방어에서 흔들리지 않는 기사, 정예답게 갑주까지 두름",
	},
	{
		"id": "goblin_chief", "name": "고블린 족장", "family": "humanoid", "tier": "elite",
		"color": Color(0.78, 0.58, 0.22), "skills": [{"id": "armor", "amount": 2}, {"id": "counter", "amount": 1}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "방심한 공격을 되받아치면서도 든든한 갑주로 버티는 고블린 무리의 수장",
	},
	{
		"id": "gelatin_cube", "name": "젤라틴 큐브", "family": "amorphous", "tier": "elite",
		"color": Color(0.5, 0.82, 0.75), "skills": [{"id": "sticky"}, {"id": "dull"}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "거대한 반투명 덩어리가 날카로운 기세까지 통째로 둔화시켜 삼킨다",
	},
	{
		"id": "specter", "name": "망령", "family": "amorphous", "tier": "elite",
		"color": Color(0.55, 0.6, 0.68), "skills": [{"id": "seal"}, {"id": "numb"}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "가장 약한 손놀림도 가장 강한 손놀림도 가리지 않고 봉인해버리는 망령",
	},
	{
		"id": "orc_warrior", "name": "오크 투사", "family": "beast", "tier": "elite",
		"color": Color(0.22, 0.45, 0.22), "skills": [{"id": "min_max_only"}, {"id": "bloodlust"}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "전부 아니면 전무인 오크 중에서도 피를 볼수록 더 거세지는 역전의 투사",
	},
	{
		"id": "dark_wolf", "name": "암흑 늑대", "family": "beast", "tier": "elite",
		"color": Color(0.25, 0.25, 0.3), "skills": [{"id": "pounce", "amount": 3}, {"id": "anger_stack"}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "싸움이 시작되는 순간 가장 거칠게 달려들고, 거슬릴수록 더 날뛰는 어둠의 늑대",
	},
	{
		"id": "skeleton_knight", "name": "해골 기사", "family": "undead", "tier": "elite",
		"color": Color(0.7, 0.68, 0.58), "skills": [{"id": "fixed_value"}, {"id": "drain"}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "감정 없이 같은 힘으로 타격하면서도 할퀸 상처에서 생기를 빨아들이는 기사",
	},
	{
		"id": "lich_apprentice", "name": "리치 견습생", "family": "undead", "tier": "elite",
		"color": Color(0.45, 0.3, 0.55), "skills": [{"id": "revive"}, {"id": "chill"}],
		"atk_dice_delta": 1, "hp_mult": 1.5,
		"personality": "죽음을 두려워하지 않고 서늘한 기운으로 상대의 손끝마저 흐려놓는 견습생",
	},
	# G-8(2026-10-07) 신규 보스 6종(라운드당 2종, 등장은 run_seed로 라운드마다 결정 —
	# BOSS_ROSTER_BY_ROUND/build_monster_plan() 참고). "보스" 배율(공격+2/방어+1/HP x2)은
	# tier와 무관하게 _build_monster_config()의 is_boss 분기가 그대로 적용하므로, 여기
	# hp_mult/atk_dice_delta는 "보스 전용 추가 보정"이 필요한 경우만 기본값(1.0/0)이 아니다
	# (점액 군주만 정예 독슬라임과 같은 패턴으로 atk_dice_delta=1). "phase2_skills": 몬스터
	# HP가 최대 HP의 절반 이하가 되는 순간 전투당 1회 활성화되는 스킬 목록(skills와 같은
	# {"id":..., 파라미터...} 형태) — combat_test.gd의 `_maybe_activate_boss_phase2()`가
	# 이미 보유한 id면 파라미터만 덮어쓰고(고블린 왕의 "armor+2"처럼 기존 스킬을 강화),
	# 없는 id면 새로 추가한다(나머지 5종처럼 "새 스킬 1개 활성화"). 전부 1개짜리 배열이지만
	# 나중에 더 늘어날 수 있어 단일 Dictionary가 아니라 배열로 둔다.
	{
		# [대형 기획 10] J-2 6차 시도(2026-10-08) — R1 보스 EV 진단(BALANCE_TUNING_LOG.md
		# "J-2 R1 보스 0% 원인 진단")이 armor(2)/counter(2)를 고블린 왕 전용으로 지목해
		# armor 2->1(phase2도 4->3으로 같이 완화, 기존 "+2" 강화 폭 유지)/counter 2->1로
		# 완화. 결과는 BALANCE_TUNING_LOG.md "J-2 보스 튜닝 시도 로그" 참고.
		"id": "goblin_king", "name": "고블린 왕", "family": "humanoid", "tier": "boss",
		"color": Color(0.85, 0.65, 0.15),
		"skills": [{"id": "armor", "amount": 1}, {"id": "guard_up"}, {"id": "counter", "amount": 1}],
		"hp_mult": 1.0, "phase2_skills": [{"id": "armor", "amount": 3}],
		"personality": "고블린 무리를 호령하며 끝까지 버티는 왕",
	},
	{
		"id": "ooze_lord", "name": "점액 군주", "family": "amorphous", "tier": "boss",
		"color": Color(0.3, 0.55, 0.35),
		"skills": [{"id": "sticky"}, {"id": "seal"}], "atk_dice_delta": 1, "hp_mult": 1.0,
		"phase2_skills": [{"id": "dull"}],
		"personality": "끈적한 본체로 모든 움직임을 둔하게 만드는 군주",
	},
	{
		"id": "skeleton_general", "name": "해골 장군", "family": "undead", "tier": "boss",
		"color": Color(0.65, 0.62, 0.5),
		"skills": [{"id": "fixed_value"}, {"id": "drain"}, {"id": "chill"}], "hp_mult": 1.0,
		"phase2_skills": [{"id": "revive"}],
		"personality": "죽어서도 군대를 지휘하는 차가운 장군",
	},
	{
		"id": "frenzied_beast", "name": "광란의 마수", "family": "beast", "tier": "boss",
		"color": Color(0.55, 0.2, 0.15),
		"skills": [{"id": "anger_stack"}, {"id": "pounce", "amount": 3}, {"id": "bloodlust"}],
		"hp_mult": 1.0, "phase2_skills": [{"id": "min_max_only"}],
		"personality": "이성을 잃고 날뛰는 거대한 짐승",
	},
	{
		"id": "fallen_commander", "name": "타락한 기사단장", "family": "humanoid", "tier": "boss",
		"color": Color(0.35, 0.3, 0.45),
		"skills": [{"id": "steady_guard"}, {"id": "armor", "amount": 3}, {"id": "counter", "amount": 2}],
		"hp_mult": 1.0, "phase2_skills": [{"id": "bloodlust"}],
		"personality": "신념을 저버리고도 흔들림 없는 방어를 고수하는 기사단장",
	},
	{
		"id": "void_eye", "name": "공허의 눈", "family": "amorphous", "tier": "boss",
		"color": Color(0.2, 0.15, 0.3),
		"skills": [{"id": "dull"}, {"id": "seal"}, {"id": "numb"}], "hp_mult": 1.0,
		"phase2_skills": [{"id": "sticky"}],
		"personality": "모든 손놀림을 무디게 가라앉히는 거대한 눈동자",
	},
]

## G-8(2026-10-07): 라운드별 보스 후보 2종(인덱스 0=라운드1, 1=라운드2, 2=라운드3).
## build_monster_plan()이 각 라운드의 보스 자리(마지막 방)를 뽑을 때 이 2종 중 하나를
## run_seed 기반 rng로 고른다 — "보스 2종 중 등장은 랜덤, 런 안에서는 고정"(INBOX.md 원문).
const BOSS_ROSTER_BY_ROUND := [
	["goblin_king", "ooze_lord"],
	["skeleton_general", "frenzied_beast"],
	["fallen_commander", "void_eye"],
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


## G-6(2026-10-07): "일반 전투" 풀 뽑기 대상 20종 id. tier=="normal"인 몬스터 전부에서
## "다크 나이트"만 제외한다 — G-5 범위/의도적 보류 주석대로, 다크 나이트는 tier 필드이
## 여전히 "normal"이라 이 필터만으로는 걸러지지 않아 id로 직접 제외해둔 것(legacy_
## cycle_monster()의 기존 5종 순환 호환을 위해 MONSTERS 자체에서 빼지는 않음). G-7
## (2026-10-07)로 "다크 나이트"의 정예판은 다른 id("dark_knight_elite")로 따로 추가됐을
## 뿐, 이 id("dark_knight") 자체는 여전히 tier=="normal"인 채 일반 풀에서만 계속
## 제외된 상태로 남는다(레거시 경로 호환 — monster_catalog.gd 상단 G-7 주석 참고).
static func normal_roster_ids() -> Array:
	var ids := []
	for m in MONSTERS:
		if m.get("tier", "normal") == "normal" and m.get("id", "") != "dark_knight":
			ids.append(m["id"])
	return ids


## G-7(2026-10-07): "정예 전투" 풀 뽑기 대상 8종 id. tier=="elite"인 몬스터 전부.
static func elite_roster_ids() -> Array:
	var ids := []
	for m in MONSTERS:
		if m.get("tier", "normal") == "elite":
			ids.append(m["id"])
	return ids


## G-8(2026-10-07): 보스 풀 전체 6종 id(tier=="boss"). BOSS_ROSTER_BY_ROUND가 라운드별로
## 이 중 2종씩만 후보로 쓰므로, 이 함수는 "전체 풀 규모" 검증(dice_test.gd)과 카탈로그
## 조회용으로 쓰인다.
static func boss_roster_ids() -> Array:
	var ids := []
	for m in MONSTERS:
		if m.get("tier", "normal") == "boss":
			ids.append(m["id"])
	return ids


static func _family_of(id: String) -> String:
	return get_by_id(id).get("family", "")


static func _shuffled(ids: Array, rng: RandomNumberGenerator) -> Array:
	var arr: Array = ids.duplicate()
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr


## sequence 안에서 "바로 이웃한 두 자리가 같은 계열"인 경우를 뒤쪽의 다른 계열 자리와
## 맞바꿔 깨뜨린다(best-effort — INBOX.md 원문 "가능하면 같은 계열 연속 2번 금지", 맞바꿀
## 상대가 없으면 그대로 둔다). 한 번의 좌->우 스캔만 하므로 모든 경우를 완전히 보장하진
## 않는다.
static func _avoid_consecutive_family(sequence: Array) -> void:
	for i in range(1, sequence.size()):
		if _family_of(sequence[i]) == _family_of(sequence[i - 1]):
			for j in range(i + 1, sequence.size()):
				if _family_of(sequence[j]) != _family_of(sequence[i - 1]):
					var tmp = sequence[i]
					sequence[i] = sequence[j]
					sequence[j] = tmp
					break


## G-6(2026-10-07): 런 시작 시 한 번만 뽑는 "몬스터 계획" — RunState.monster_plan이
## 저장하는 값을 만드는 순수 함수(RunState 없이 직접 테스트 가능, F-3 원칙). seed가 같으면
## 항상 같은 결과를 내므로 RunState.run_seed로 재현 가능(QA/F-4 시뮬용).
## 반환: Array[Array[String]] — plan[round][room] = 몬스터 id (round/room 둘 다 0부터
## 시작, round는 rooms_per_round개의 방을 가짐 — 마지막 방이 보스 자리).
## - 보스가 아닌 자리(0 .. rooms_per_round-2)는 normal_roster_ids()(20종) 안에서
##   "이번 런 전체에서 중복 없이" 뽑는다(INBOX.md 원문 — total_rounds*(rooms_per_round-1)이
##   풀 크기 이하일 때만 전부 중복 없이 뽑을 수 있다, 지금 3*4=12 <= 20).
## - 마지막 방(보스 자리)은 G-8(2026-10-07)부터 전용 보스 풀(BOSS_ROSTER_BY_ROUND)에서
##   그 라운드의 후보 2종 중 하나를 뽑는다("보스 2종 중 등장은 랜덤, 런 안에서는 고정" —
##   INBOX.md 원문). 라운드 수가 BOSS_ROSTER_BY_ROUND보다 많아지는 경우(지금은 없음)는
##   `% BOSS_ROSTER_BY_ROUND.size()`로 순환해 크래시를 피한다.
static func build_monster_plan(seed: int, total_rounds: int, rooms_per_round: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pool := normal_roster_ids()
	var normal_slots_per_round: int = rooms_per_round - 1
	var normal_sequence: Array = _shuffled(pool, rng).slice(0, total_rounds * normal_slots_per_round)
	_avoid_consecutive_family(normal_sequence)
	var plan: Array = []
	var seq_i := 0
	for r in total_rounds:
		var round_slots: Array = []
		for room in rooms_per_round:
			if room == rooms_per_round - 1:
				var candidates: Array = BOSS_ROSTER_BY_ROUND[r % BOSS_ROSTER_BY_ROUND.size()]
				var boss_id: String = candidates[rng.randi_range(0, candidates.size() - 1)]
				round_slots.append(boss_id)
			else:
				round_slots.append(normal_sequence[seq_i])
				seq_i += 1
		plan.append(round_slots)
	return plan


## G-7(2026-10-07): "정예 전투" 선택지가 뽑을 몬스터를 라운드 시작 시 미리 정해두는
## 계획 — build_monster_plan()과 같은 "순수 함수 + seed 재현" 원칙(RunState.elite_plan이
## 저장). INBOX.md 원문 "방 1~3에서 확률로 일반 전투 옆에 추가 선택지로 노출" — "노출
## 여부"(확률) 자체는 dungeon_map.gd가 이미 상점/이벤트와 같은 방식(방 번호 기반
## 결정적 RNG)으로 따로 굴리므로, 이 함수는 "그 방에서 정예가 뜬다면 누가 나오는지"만
## 책임진다(0번째/마지막 방은 정예 선택지 자체가 없으므로 빈 문자열).
## 반환: Array[Array[String]] — plan[round][room] = 정예 몬스터 id, 또는 "" (room==0이거나
## room==rooms_per_round-1). seed는 build_monster_plan()과 "다른" 시드를 넘겨야
## 두 계획의 셔플 순서가 서로 상관되지 않는다(RunState.reset_run()이 run_seed에 오프셋을
## 더해 넘김).
## - 라운드마다 elite_roster_ids()(8종)를 셔플해 눈에 보이는 "방 1~3" 3자리에 앞에서부터
##   배정한다 — "정예 풀에서 중복 없이"(INBOX.md 원문)를 라운드 안에서는 완전히 보장한다
##   (3자리 <= 8종). 라운드를 넘어서는 전체 런 기준 중복까지는 보장하지 않는다
##   (3라운드 x 3자리 = 9자리 > 풀 크기 8이라 수학적으로 불가능 — build_monster_plan()의
##   "일반 전투 12자리 <= 20종" 전제와 달리 여기선 "라운드당"으로 범위를 좁힌 것).
static func build_elite_plan(seed: int, total_rounds: int, rooms_per_round: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pool := elite_roster_ids()
	var plan: Array = []
	for _r in total_rounds:
		var shuffled: Array = _shuffled(pool, rng)
		var round_slots: Array = []
		var next_i := 0
		for room in rooms_per_round:
			if room == 0 or room == rooms_per_round - 1 or pool.is_empty():
				round_slots.append("")
			else:
				round_slots.append(shuffled[next_i % shuffled.size()])
				next_i += 1
		plan.append(round_slots)
	return plan


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
