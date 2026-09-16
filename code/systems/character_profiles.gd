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
## 이번 조각으로 5종 전부 구현(기존 1 + 신규 4). INBOX.md가 예시로 든 세 성격
## (극단형/안정형/폭발형) 중 "폭발형"(분노 스택 — 몬스터 "고블린"처럼 매 턴 상태를
## 추적하고 턴 로직 자체를 바꿔야 함)은 combat_test.gd의 anger_stack 분기를 플레이어
## 공격턴에도 그대로 적용하는 방식(player_dice_gimmick/player_explosive_stacks/
## player_explosive_pending, combat_test.gd 참고)으로 완성했고, 다섯 번째 컨셉
## "방패병"(guard_stack)은 같은 스택 추적 방식을 플레이어 방어턴에 대칭 적용해
## 완성함(둘 다 정적 다이스 개조가 아니라 턴 상태 추적이 필요) —
## run_state.gd._apply_character_gimmick()의 match 문에는 걸리지 않고, 대신
## combat_test.gd가 CharacterProfiles.get_profile(RunState.character_id)를 직접 읽어
## "explosive_stack"/"guard_stack"일 때만 턴 로직에서 분기한다. 캐릭터 5종 각각의
## 이름/컨셉/기믹 배정은 INBOX.md가 "AI가 제안해도 됨"이라고 허용한 것을 따름 —
## 사람이 다른 이름/배정을 원하면 이 배열만 고치면 됨.
##
## "attack_count"/"defense_count": INBOX.md 2026-09-14 "캐릭터별 현재 개성 및 스타일에
## 맞추어 시작 주사위를 다르게 한다" 반영. 기존에는 5종 전부 표준 D4x3/D4x3로 동일해서
## "기믹"만 다르고 시작 다이스 구성 자체는 차이가 없었다. 이제 각 캐릭터의 기믹 방향에
## 맞춰 공격/방어 다이스 개수 배분을 다르게 준다(면 개수는 DESIGN.md가 확정한 시작
## D4를 5종 전부 그대로 유지 — 면 개수까지 다르게 하는 건 별도 결정 필요). 값을 생략하면
## RunState.reset_run()이 기존 기본값(3/3)으로 폴백한다. DiceBag.MAX_DICE(=6)보다 항상
## 작게 잡아 캡에 안 걸림. 배분 근거(감으로 잡은 잠정값, 재조정 가능):
##   - 광전사(berserker, 극단형/하이리스크): 공격 4 / 방어 2 — "공격에 몰빵"
##   - 수호자(guardian, 안정형/방어): 공격 2 / 방어 4 — 광전사와 대칭
##   - 폭발병(explosive, 공격 다이스 최댓값 스택): 공격 4 / 방어 3 — 스택을 더 자주 쌓게
##   - 방패병(shieldbearer, 방어 다이스 최댓값 스택): 공격 3 / 방어 4 — 폭발병과 대칭
##
## "event_die_sides": INBOX.md 2026-09-15 [미니 기획 B]-4 "공격/방어 주사위처럼 직업마다
## 특수 이벤트용 이벤트 주사위 1개가 있으면 어떨까" 반영의 첫 조각(4번 -> 1 -> 2+3 순서
## 권장 중 4번). 특수 이벤트 "위험을 감수하기" 판정에 쓸 별도 다이스의 면 개수 — 공격/
## 방어 주머니(DiceBag)와 무관한 독립 필드라 눈금 교환/승급 등 커스터마이징 대상에서
## 자동으로 제외된다. 지금은 5종 전부 6(=D6)으로 동일 — "직업별로 다른 이벤트 주사위"라는
## 원 요청의 구조만 미리 열어두고, 실제 차등 부여는 이벤트 특화 캐릭터가 생기면 그때 값만
## 바꾸면 됨. 실제 판정 로직([미니 기획 B]-2/3)과 로마 숫자 시각화 사용처는 아직 없음 —
## 이번 조각은 필드 + event_die_visual.gd 시각화 컴포넌트까지만.
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
##   "guard_stack"   : 정적 다이스 개조 없음(explosive_stack과 동일) — 대신 방어 다이스가
##                     최댓값 면을 보여줄 때마다 combat_test.gd가 전투 중 상태로 스택을
##                     쌓고, 3스택에서 다음 방어 한 턴만 1D20으로 굴림 (explosive_stack과
##                     완전히 같은 메커니즘을 플레이어 방어턴에 대칭 적용)
## GIMMICK_LABELS: 캐릭터 선택 화면의 상세 정보 패널(2026-09-15 신설, INBOX.md
## 2026-09-14 "패널 선택시 오른쪽에 상세 정보를 제공, 초기 제공 주사위/보유 스킬 등"
## 반영)에서 "보유 스킬" 줄에 쓸 짧은 이름표. gimmick 필드 값(위 주석 참고) ->
## 사람이 읽는 짧은 이름. "desc"의 긴 서술형 설명과 별개로, 목록에서 한눈에 훑어볼
## 짧은 라벨이 필요해 추가했다.
const GIMMICK_LABELS := {
	"": "없음 (표준 다이스)",
	"min_max_only": "극단 (Min/Max 전용, 중간값 없음)",
	"fixed_defense_die": "고정 방어 (방어 다이스 1개 항상 같은 값)",
	"explosive_stack": "폭발 스택 (공격 최댓값 3회 누적 → 1D20)",
	"guard_stack": "수호 스택 (방어 최댓값 3회 누적 → 1D20)",
}

const PROFILES := [
	{
		"id": "novice",
		"name": "견습 모험가",
		"desc": "기본 캐릭터 (능력 차이 없음). 시작 다이스: 공격 D4x3 / 방어 D4x3 (표준형)",
		"concept": "기본 캐릭터 (능력 차이 없음).",
		"gimmick": "",
		"attack_count": 3,
		"defense_count": 3,
		"event_die_sides": 6,
		"hair_color": Color(0.78, 0.62, 0.86),
		"dress_color": Color(0.92, 0.55, 0.66),
	},
	{
		"id": "berserker",
		"name": "광전사",
		"desc": "극단형 — 공격/방어 다이스가 항상 최솟값 아니면 최댓값만 나옴 (중간값 없음, 하이리스크 하이리턴). 시작 다이스: 공격 D4x4 / 방어 D4x2 (공격 몰빵)",
		"concept": "극단형 — 공격/방어 다이스가 항상 최솟값 아니면 최댓값만 나옴 (중간값 없음, 하이리스크 하이리턴).",
		"gimmick": "min_max_only",
		"attack_count": 4,
		"defense_count": 2,
		"event_die_sides": 6,
		"hair_color": Color(0.85, 0.25, 0.2),
		"dress_color": Color(0.35, 0.1, 0.1),
	},
	{
		"id": "guardian",
		"name": "수호자",
		"desc": "안정형 — 방어 다이스 하나가 항상 고정값으로만 나옴 (예측 가능한 안정적 방어). 시작 다이스: 공격 D4x2 / 방어 D4x4 (방어 몰빵)",
		"concept": "안정형 — 방어 다이스 하나가 항상 고정값으로만 나옴 (예측 가능한 안정적 방어).",
		"gimmick": "fixed_defense_die",
		"attack_count": 2,
		"defense_count": 4,
		"event_die_sides": 6,
		"hair_color": Color(0.4, 0.55, 0.85),
		"dress_color": Color(0.25, 0.4, 0.55),
	},
	{
		"id": "explosive",
		"name": "폭발병",
		"desc": "폭발형 — 공격 다이스가 최댓값을 보여줄 때마다 폭발 스택이 쌓임 (3스택에서 다음 공격이 20면체 주사위로 터짐). 시작 다이스: 공격 D4x4 / 방어 D4x3 (스택을 더 자주 쌓음)",
		"concept": "폭발형 — 공격 다이스가 최댓값을 보여줄 때마다 폭발 스택이 쌓임 (3스택에서 다음 공격이 20면체 주사위로 터짐).",
		"gimmick": "explosive_stack",
		"attack_count": 4,
		"defense_count": 3,
		"event_die_sides": 6,
		"hair_color": Color(0.95, 0.55, 0.15),
		"dress_color": Color(0.5, 0.18, 0.05),
	},
	{
		"id": "shieldbearer",
		"name": "방패병",
		"desc": "인내형 — 방어 다이스가 최댓값을 보여줄 때마다 수호 스택이 쌓임 (3스택에서 다음 방어가 20면체 주사위로 굳건해짐). 시작 다이스: 공격 D4x3 / 방어 D4x4 (스택을 더 자주 쌓음)",
		"concept": "인내형 — 방어 다이스가 최댓값을 보여줄 때마다 수호 스택이 쌓임 (3스택에서 다음 방어가 20면체 주사위로 굳건해짐).",
		"gimmick": "guard_stack",
		"attack_count": 3,
		"defense_count": 4,
		"event_die_sides": 6,
		"hair_color": Color(0.55, 0.6, 0.65),
		"dress_color": Color(0.2, 0.3, 0.4),
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


## gimmick 필드 값 -> GIMMICK_LABELS의 짧은 사람 읽기용 이름표. 모르는 값이 들어오면
## (새 기믹을 추가하고 라벨을 깜빡한 경우) 원래 문자열을 그대로 반환해 완전히
## 빈 화면이 되는 대신 최소한 뭔가는 보이게 한다.
static func gimmick_label(gimmick: String) -> String:
	return GIMMICK_LABELS.get(gimmick, gimmick)


## 방어 다이스 고정값 계산: 몬스터 "오크"(fixed_value)와 같은 공식(면 개수 평균 반올림)을
## 재사용해 D4 기준 3(=ceil(5/2))이 되도록 한다 — 새 밸런스 상수를 따로 만들지 않음.
static func fixed_defense_die_value(sides: int) -> int:
	return ceili((sides + 1) / 2.0)
