extends Node2D
## 전투 씬 (플레이어 vs 몬스터).
## 플레이어 HP는 DESIGN.md 확정 그대로 하드코딩(20)이며 매 전투 시작 시 풀피로
## 초기화된다. 공격/방어 다이스 주머니(RunState.player_attack_bag/player_defense_bag)는
## 초기값은 DESIGN.md 확정 수치(D4x3)지만, 승리 보상으로 얻는 다이스 개조 아이템에 따라
## 런이 진행되는 동안 계속 바뀔 수 있다 (_show_reward_ui() 참고).
## 몬스터는 DESIGN.md에 1번째 방(공격 D4x2/방어 D4x1·HP10)만 확정되어 있고, 그 이후
## 방의 몬스터 구성은 아직 미정이라 RunState.rooms_cleared를 기반으로 잠정적인 난이도
## 스케일링(_monster_config_for_room())을 적용한다 (아래 "몬스터 스케일링" 참고).
##
## 판정은 기존 systems/dice_bag.gd(DiceBag), systems/combat_math.gd(CombatMath)를
## 그대로 재사용한다. 물리적으로 굴러가는 dice/die_d4.tscn(Die)은 "손맛" 연출용이며,
## 실제 합계는 DiceBag.roll()의 RNG 결과를 쓴다 (물리 다이스의 착지 면을 읽어 판정하는
## 기능은 아직 없음 — 알려진 이슈로 STATUS.md에 남김). 다만 다이스 "모양"(면 개수)은
## 각 다이스의 실제 face 배열 길이(bag.dice[i].size())에 맞춰 스폰하므로, 개조 아이템으로
## D6/D8 등으로 승급/추가된 다이스는 굴러갈 때도 그 모양으로 보인다.
##
## 교환 결과가 나오면 다이스별 개별 값(DiceBag.roll_detailed())을 면 모양(삼각/사각/
## 오각) 칩(ShapeDieChip)으로 화면에 표시한다 (INBOX.md 2026-09-03: "어떤 주사위에서
## 어떤 값이 나왔는지 이미지로 보이면 좋겠다"). 다만 이 칩도 여전히 RNG 결과를 보여줄
## 뿐, 물리적으로 굴러가는 다이스가 실제로 그 면으로 착지한 것을 읽어오는 것은 아니다.
##
## 다이스가 완전히 멈췄는지 실제로 감지한다 (linear/angular velocity가 임계값 밑으로
## SETTLE_MIN_FRAMES 프레임 연속 유지되면 정지로 판단). **다이스별로 독립적으로
## 판정한다** — 전체 다이스를 하나의 공용 카운터로 묶으면, 다이스 개수가 많을 때
## 서로 맞닿은 접촉 잔진동으로 어느 한 다이스라도 순간적으로 임계값을 넘기면 전체
## 카운터가 리셋되어 사실상 절대 정지 판정을 못 받는 문제가 있었다 (STATUS.md 알려진
## 이슈: 14개 이상에서 항상 SETTLE_MAX_WAIT로 강제 종료). 다이스마다 자기 카운터가
## SETTLE_MIN_FRAMES에 도달하면 그 다이스는 이후 다시 흔들려도 재검사하지 않으므로,
## 다이스 개수가 늘어도 "다른 다이스의 잔진동 때문에 이미 멈춘 다이스까지 계속
## 기다려야 하는" 상황이 없다. 물리 이상 등으로 끝내 멈추지 않는 경우를 대비해
## SETTLE_MAX_WAIT 초과 시 강제로 진행한다 (안전장치).

const DieScene := preload("res://code/dice/die_d4.tscn")

## 다이스 면 개수(sides)에 따른 잠정 재질 배정. 아직 재질을 직접 고르는 획득 시스템이
## 없어서 "개조로 다이스가 커질수록 더 고급 재질처럼 보인다"는 감으로 매핑함(사람
## 피드백 필요, die_d4.gd 클래스 주석 참고). D4/D6은 시작 재질(plastic) 그대로 둔다.
const MATERIAL_WOOD := preload("res://resources/materials/wood.tres")
const MATERIAL_GLASS := preload("res://resources/materials/glass.tres")
const MATERIAL_METAL := preload("res://resources/materials/metal.tres")

static func _material_for_sides(sides: int) -> DiceMaterial:
	match sides:
		8:
			return MATERIAL_WOOD
		10:
			return MATERIAL_GLASS
		12, 20:
			return MATERIAL_METAL
		_:
			return null # null이면 die_d4.tscn 기본값(plastic)을 그대로 씀

const SETTLE_LIN_THRESHOLD := 0.08
const SETTLE_ANG_THRESHOLD := 0.5
const SETTLE_MIN_FRAMES := 10
const SETTLE_MAX_WAIT := 4.0
const EXCHANGE_PAUSE_TIME := 0.8
const MAX_LOG_LINES := 6

## 다이스 개수가 아이템(다이스 추가/승급)으로 늘어나도 바닥 벽(x ±2.45 부근) 밖으로
## 스폰되지 않도록, 한 줄에 최대 이만큼만 놓고 그 이상은 z축으로 다음 줄에 놓는다
## (알려진 이슈: 큐 2 "다이스 개수가 늘어나면 재검증 필요" 반영).
const DICE_SPAWN_PER_ROW := 4
const DICE_SPAWN_COL_SPACING := 0.45
const DICE_SPAWN_ROW_SPACING := 0.5

@onready var player_hp_label: Label = $PlayerHPLabel
@onready var monster_hp_label: Label = $MonsterHPLabel
@onready var monster_debug_info_label: Label = $MonsterDebugInfoLabel
@onready var player_hp_bar_fill: ColorRect = $PlayerHPBarFill
@onready var monster_hp_bar_fill: ColorRect = $MonsterHPBarFill
@onready var turn_label: Label = $TurnLabel
@onready var log_label: Label = $LogLabel
@onready var dice_root: Node3D = $DiceViewportContainer/DiceViewport/DiceRoot
@onready var next_button: Button = $NextButton
@onready var player_portrait: CharacterPortraitPlaceholder = $PlayerPortrait
@onready var monster_portrait: MonsterPortraitPlaceholder = $MonsterPortrait
@onready var deck_toggle_button: Button = $DeckToggleButton
@onready var deck_panel: DeckPanel = $DeckPanel
@onready var customize_toggle_button: Button = $CustomizeToggleButton
@onready var customize_panel: CustomizePanel = $CustomizePanel

var player_hp := 20
const PLAYER_MAX_HP := 20

## INBOX.md 피드백(2026-09-09) "체력바 추가 등 정보를 텍스트보다 이미지로 표현하는게
## 좋을 듯" — HP를 텍스트 라벨뿐 아니라 채워진 정도로 보여주는 막대(ColorRect 2장,
## combat_test.tscn 참고)를 추가한다. 너비는 각 Bg/Fill의 tscn 초기 크기와 맞춰둠.
const PLAYER_HP_BAR_WIDTH := 380.0
const MONSTER_HP_BAR_WIDTH := 340.0
## 체력 비율에 따라 초록(넉넉) -> 주황(경고) -> 빨강(위험)으로 막대 색이 바뀐다 —
## "쪼이는 맛"(위기감)을 색으로도 드러내기 위함.
const HP_BAR_COLOR_HIGH := Color(0.35, 0.85, 0.35)
const HP_BAR_COLOR_MID := Color(0.95, 0.75, 0.25)
const HP_BAR_COLOR_LOW := Color(0.9, 0.25, 0.25)

var monster_hp: int
var monster_max_hp: int
var monster_attack_bag: DiceBag
var monster_defense_bag: DiceBag
var monster_name := "몬스터"
var monster_color := Color(1, 1, 1, 0)
var monster_dice_gimmick := ""
## 이번 방의 몬스터가 "보스"였는지([대형 기획 2] 조각 (b)) — _monster_config_for_room()의
## is_boss를 _ready()에서 그대로 저장해두고, _apply_room_advance()가 승리 시 이 방이
## 라운드의 마지막(보스) 방이었는지 판단해 RunState.advance_round() 호출 여부를 정하는 데 쓴다.
var monster_is_boss := false

## "anger_stack" 기믹 전용 전투 중 상태(패배/승리로 씬이 끝나면 함께 사라짐, RunState에는
## 저장 안 함 — 몬스터 개별 전투 한정 상태이므로). 몬스터가 공격턴에 자기 공격 다이스의
## 최댓값 면을 ANGER_STACK_THRESHOLD번 보여주면(DiceBag.count_max_rolls() 참고) 다음
## 공격턴 하나만 1D20으로 굴린다("주사위 값 x가 나올 때마다 분노 스택이 쌓여서 몇 개
## 이상 쌓이면 다음 턴에 20면체 주사위를 돌린다"는 INBOX.md 예시를 그대로 구현 — x를
## "그 다이스의 최댓값 면"으로 해석).
var monster_anger_stacks := 0
var monster_anger_pending := false
const ANGER_STACK_THRESHOLD := 3
const ANGER_DICE_SIDES := 20

## "explosive_stack" 캐릭터 기믹(플레이어블 캐릭터 "폭발병", character_profiles.gd 참고)
## 전용 전투 중 상태 — monster_anger_stacks/monster_anger_pending과 완전히 같은 구조를
## 플레이어 공격턴에 적용한 것. 플레이어 공격 다이스(RunState.player_attack_bag)가 자기
## 최댓값 면을 EXPLOSIVE_STACK_THRESHOLD번 보여주면 다음 공격 한 턴만 1D20으로 굴린다.
var player_dice_gimmick := ""
var player_explosive_stacks := 0
var player_explosive_pending := false
const EXPLOSIVE_STACK_THRESHOLD := 3
const EXPLOSIVE_DICE_SIDES := 20

## "guard_stack" 캐릭터 기믹(플레이어블 캐릭터 "방패병") 전용 전투 중 상태 —
## player_explosive_stacks/player_explosive_pending과 완전히 같은 구조를 플레이어
## 방어턴(몬스터 공격턴)에 적용한 것. 플레이어 방어 다이스(RunState.player_defense_bag)가
## 자기 최댓값 면을 GUARD_STACK_THRESHOLD번 보여주면 다음 방어 한 턴만 1D20으로 굴린다.
var player_guard_stacks := 0
var player_guard_pending := false
const GUARD_STACK_THRESHOLD := 3
const GUARD_DICE_SIDES := 20

## 캐릭터 스킬(RunState.skill_flags) 전투 중 상태 — INBOX.md [미니 기획 C]-3/4
## (2026-09-16)가 확정한 공용 스킬 2종 + 광전사 전용 고유 스킬 1종의 실제 효과 배선.
## player_deep_breath_used: "심호흡"이 이번 전투에서 이미 적용됐는지(첫 방어턴 1회
## 한정이라 전투마다, 즉 _ready()마다 초기화).
var player_deep_breath_used := false
## player_frenzy_active: "광기 심화"(광전사 전용 고유 스킬) 보유 여부. RunState.
## skill_flags는 캐릭터와 무관하게 문자열만 쌓이므로, SkillPool이 캐릭터 필터로
## 이 스킬을 광전사에게만 제시했다는 전제 하에 플래그 존재 여부만 확인한다. true이면
## 아래 _do_exchange()에서 player_dice_gimmick이 "explosive_stack"이 아니어도(광전사
## 본인 기믹은 min_max_only) 폭발 스택 파이프라인을 그대로 열어주고, 보너스 턴은
## 1D20 한 번이 아니라 두 번 굴려 더 높은 값을 채택한다.
var player_frenzy_active := false
## player_frenzy_deepen_plus_active: "광기 심화+"([미니 기획 D]-4, 광전사 전용 강화판)
## 보유 여부. base(frenzy_deepen)의 "1D20 두 번 굴려 최댓값"을 "세 번 굴려 최댓값"으로
## 강화한다 — 파이프라인 자체(임계치, 스택 조건)는 그대로, 보너스 턴 굴림 품질만 올림.
var player_frenzy_deepen_plus_active := false
## player_guard_deepen_active: "수호 심화"(수호자 전용 고유 스킬) 보유 여부.
## frenzy_deepen과 완전히 대칭 구조(공격 스택 대신 방어 스택) — 수호자 본인 기믹은
## fixed_defense_die라 원래 guard_stack 파이프라인이 없지만, 이 스킬을 획득하면
## player_dice_gimmick이 "guard_stack"이 아니어도 방패병과 같은 스택 파이프라인이
## 열리고, 보너스 방어턴은 1D20 한 번이 아니라 두 번 굴려 더 높은 값을 채택한다.
var player_guard_deepen_active := false
## player_guard_deepen_plus_active: "수호 심화+"([미니 기획 D]-4, 수호자 전용 강화판)
## 보유 여부. player_frenzy_deepen_plus_active와 완전히 대칭 — 보너스 방어턴 굴림
## 횟수를 두 번에서 세 번으로 늘린다.
var player_guard_deepen_plus_active := false
## player_chain_explosion_active: "연쇄 폭발"(폭발병 전용 고유 스킬) 보유 여부.
## frenzy_deepen/guard_deepen과 달리 폭발병은 이미 explosive_stack 파이프라인을 갖고
## 있어 "없던 파이프라인을 열어준다" 패턴을 쓸 수 없다 — 대신 스택 임계치 자체를
## 낮춰(_player_explosive_threshold() 참고) 보너스 공격턴을 더 자주 받게 한다.
var player_chain_explosion_active := false
## player_chain_explosion_plus_active: "연쇄 폭발+"([미니 기획 D]-4, 폭발병 전용
## 강화판) 보유 여부. base(chain_explosion)는 임계치만 2로 낮추고 보너스 턴 굴림
## 품질은 그대로였는데, "+"는 임계치는 2로 유지한 채 보너스 공격턴을 1D20 한
## 번에서 두 번 굴려 최댓값 채택으로 강화한다(frenzy_deepen이 쓰는 것과 같은
## _apply_bonus_reroll(), extra_rolls=1) — frenzy_deepen과 달리 광전사가 아닌
## 폭발병 전용이라 별도 플래그로 분리했다.
var player_chain_explosion_plus_active := false
## player_chain_guard_active: "연쇄 방어"(방패병 전용 고유 스킬) 보유 여부.
## chain_explosion과 완전히 대칭 구조(공격 대신 방어) — 방패병은 이미 guard_stack
## 파이프라인을 갖고 있어 스택 임계치 자체를 낮춰(_player_guard_threshold() 참고)
## 보너스 방어턴을 더 자주 받게 한다.
var player_chain_guard_active := false
## player_chain_guard_plus_active: "연쇄 방어+"([미니 기획 D]-4, 방패병 전용
## 강화판) 보유 여부. player_chain_explosion_plus_active와 완전히 대칭 — 보너스
## 방어턴 굴림을 1D20 한 번에서 두 번 굴려 최댓값 채택으로 강화한다.
var player_chain_guard_plus_active := false
## player_versatile_active: "임기응변"(견습 모험가 전용 고유 스킬) 보유 여부.
## frenzy_deepen/guard_deepen과 같은 "없던 파이프라인을 열어준다" 패턴을 공격+방어
## 양쪽에 동시에 적용한다(견습 모험가 본인 기믹은 아예 없음, player_dice_gimmick == "").
## 두 파이프라인 모두 기존 기본 임계치(EXPLOSIVE_STACK_THRESHOLD/GUARD_STACK_THRESHOLD)와
## 기본 보너스(1D20 한 번 굴림)를 그대로 쓴다 — frenzy_deepen/guard_deepen의 "두 번 굴려
## 채택" 강화나 chain_explosion/chain_guard의 "임계치 2로 낮춤" 강화는 넣지 않는다(넓지만
## 얕게가 견습 모험가의 정체성, INBOX.md 2026-09-17 기획자 결정 참고).
var player_versatile_active := false
## player_versatile_plus_active: "임기응변+"([미니 기획 D]-4, 견습 모험가 전용
## 강화판) 보유 여부. 다른 4개 "+"(광기/수호 심화+, 연쇄 폭발/방어+)는 전부 보너스
## 턴 굴림 품질을 올리는데, 임기응변+는 base와 같은 축("발동 빈도")을 마저 강화한다
## — chain_explosion/chain_guard와 같은 방식으로 공격+방어 두 파이프라인의 임계치를
## 동시에 3에서 2로 낮춘다(_player_explosive_threshold()/_player_guard_threshold()
## 참고, INBOX.md 2026-09-17 [미니 기획 D] 원문 설계 그대로).
var player_versatile_plus_active := false

var battle_over := false
var player_won := false
var _room_advanced := false
var _reward_resolved := false
var _log_lines: Array[String] = []
var _reward_ui: Array[Node] = []
var _reward_items: Array[Dictionary] = []

## dungeon_map.gd/shop.gd 등과 같은 패턴(KeyboardShortcuts) — 지금 화면에 보이는
## 선택지 버튼(승리 보상 카드/건너뛰기/커스터마이징 또는 "다음")에 숫자 1~9 키를
## 순서대로 배정한다. 전투 중에는 자동 진행이라 누를 버튼이 "덱 보기" 토글뿐이지만,
## 화면마다 버튼 구성이 계속 바뀌므로(대기 중 -> 보상 선택 -> 다음) _rebuild_shortcuts()가
## 그때그때 호출되어 목록을 다시 만든다. 승리 보상 카드의 버튼은 카드 생성 시점에
## _reward_action_buttons에 함께 담아둔다(카드 자체를 담는 _reward_ui와 별개 — 카드는
## PanelContainer라 그 안의 실제 클릭 대상은 button_row의 자식 Button들이므로).
var _reward_action_buttons: Array[Button] = []
var _shortcut_buttons: Array[Button] = []

## 이번 교환에서 어떤 다이스가 어떤 값을 냈는지 보여주는 칩(ShapeDieChip). 매 교환마다
## 지우고 새로 그린다 (INBOX.md 2026-09-03: "전투 시 어떤 주사위에서 어떤 값이
## 나왔는지 이미지로 보이면 좋겠다").
var _exchange_chip_nodes: Array[Node] = []
## INBOX.md 피드백(2026-09-09) "전투의 재미가 없다. 다이스 값이 잘 안보여서 쪼이는 맛이
## 덜하다" — 칩 크기를 34 -> 44로 키워 값이 더 잘 보이게 함(라벨 폰트 크기는
## ShapeDieChip이 size.y 비례로 자동 조정하므로 숫자도 함께 커짐). Y좌표는 다이스
## 개수가 많을 때(최대 한 줄) LogLabel(y=556)과 안 겹치도록 같이 조정.
const EXCHANGE_CHIP_SIZE := 44.0
const EXCHANGE_CHIP_GAP := 7.0
const EXCHANGE_CHIP_Y := 504.0

## 커스터마이징(눈금 교환)은 이제 code/scenes/customize_panel.gd(CustomizePanel)
## 하나로 통합됨 — 승리 보상 화면의 "커스터마이징" 버튼도 이 화면 전용 로직 대신 그
## 공용 오버레이를 그대로 연다 (_open_customize_from_reward 참고). INBOX.md
## 피드백(2026-09-03) "인벤토리 창에 눈금이 쌓이고, 해당 눈금과 주사위 눈금이
## 교환되는 형태"를 반영한 상호작용 모델 변경으로, 기존에 이 파일에 있던 자체
## 다이스/면/값 선택 체인(자유 입력 방식)은 제거함.

## 승리 시 골드 보상. INBOX.md 피드백 "승리하면 골드를 주며, 상점 이벤트에서 사용할 수
## 있다"를 반영. 방이 진행될수록 조금씩 더 주는 잠정값 (밸런스는 사람 피드백 필요).
const GOLD_REWARD_BASE := 8
const GOLD_REWARD_PER_ROOM := 2

## 승리 시 커스터마이징용 "눈금" 보상. 값은 PIP_REWARD_MIN..(PIP_REWARD_MAX_BASE +
## rooms_cleared * PIP_REWARD_MAX_PER_ROOM) 범위에서 무작위 1개 — 방이 진행될수록
## 더 큰 눈금이 나올 여지가 커지는 잠정값(밸런스는 사람 피드백 필요).
const PIP_REWARD_MIN := 1
const PIP_REWARD_MAX_BASE := 4
const PIP_REWARD_MAX_PER_ROOM := 1

## 몬스터별 이름/다이스 색 (시각 구분용, 능력치와는 무관). room_index를 이 배열 길이로
## 나눈 나머지로 순환시키고, 배열을 다 돌면 이름 앞에 "강화"를 붙여 재사용한다
## (DESIGN.md에는 몬스터별 모양/색 자체가 아직 미정이라 잠정 목록).
##
## "dice_gimmick"(선택 필드): INBOX.md(2026-09-09) "몬스터별 다이스 특이 특징" 요청의
## 예시 3개(고정값 다이스 / min·max만 있는 다이스 / 분노 스택 -> D20)를 전부 시범
## 적용함(작고 독립적으로 검증 가능한 조각씩 나눠 진행). "anger_stack"(분노 스택 ->
## D20)은 매 턴 상태 추적이 필요해 monster_anger_stacks/monster_anger_pending으로
## 전투 중에만 유지되는 상태를 추가로 둠(_do_exchange() 참고).
##
## 2026-09-16 [미니 기획 A]-1(INBOX.md 2026-09-15 몬스터 성격 기획)로 fixed_value/
## min_max_only 배정을 성격에 맞게 재배정함(코드 스왑만, 로직 자체는 그대로):
##   - "해골 전사"(감정 없이 명령대로만 움직이는 병사): fixed_value를 "오크"에서 옮겨받음.
##   - "오크"(힘만 믿고 저돌적으로 날뛰는 성격, 전부 아니면 전무): min_max_only를
##     "다크 나이트"에서 옮겨받음.
##   - "슬라임"(무기력하고 단순함)/"고블린"(성급하고 화를 잘 냄)은 기존 그대로 유지.
## [미니 기획 A]-2(2026-09-16, 별도 이터레이션)로 "다크 나이트"(차갑고 노련하며
## 방어에서 흔들리지 않는 기사)에 신규 기믹 `steady_guard`를 배정함 — 방어 다이스
## 굴림 결과가 면 개수 절반(올림)보다 낮으면 절반값으로 끌어올림(DiceBag.
## apply_steady_guard() 참고). fixed_value/min_max_only처럼 _ready()에서 면 값
## 자체를 바꾸는 방식이 아니라, _do_exchange()에서 매 방어턴 굴림 "결과"만 사후
## 보정하는 방식이라 이 dict에는 별도 표시가 필요 없음(문자열 키만 배정).
## [미니 기획 A]-3(2026-09-16): 5종 각각에 "personality" 필드(1줄, INBOX.md
## 2026-09-15가 확정한 성격 요약)를 추가한다. dice_gimmick 배정 근거를 문구로도
## 확인할 수 있게 하려는 목적 — _monster_config_for_room()이 그대로 config에 담아
## 넘기고, _monster_debug_info_text()가 디버그 표시줄에 함께 보여준다.
const MONSTER_PROFILES := [
	{"name": "슬라임", "color": Color(0.35, 0.85, 0.4), "personality": "무기력하고 단순함"},
	{"name": "고블린", "color": Color(0.75, 0.55, 0.25), "dice_gimmick": "anger_stack", "personality": "성급하고 화를 잘 냄"},
	{"name": "해골 전사", "color": Color(0.85, 0.85, 0.8), "dice_gimmick": "fixed_value", "personality": "감정 없이 명령대로만 움직이는 병사, 늘 같은 힘으로 정확하게 타격"},
	{"name": "오크", "color": Color(0.3, 0.55, 0.3), "dice_gimmick": "min_max_only", "personality": "힘만 믿고 저돌적으로 날뛰는 성격, 전부 아니면 전무"},
	{"name": "다크 나이트", "color": Color(0.55, 0.25, 0.75), "dice_gimmick": "steady_guard", "personality": "차갑고 노련하며 방어에서 흔들리지 않는 기사"},
]


## 몬스터 다이스 면 개수(sides) 스케일링. 지금까지 몬스터 주머니는 방과 무관하게 항상
## DiceBag.new(4, ...)(D4 고정)이라 개수만 늘어날 뿐 다이스 "모양"은 절대 안 바뀌는
## 간극이 있었음 (STATUS.md 큐 1 "몬스터별로 의도적으로 다른 다이스 형태를 쓰게 할지는
## 아직 미정"에서 제안된 방향을 그대로 적용). room_index가 늘수록 D4 -> D6 -> D8로
## 커지게 해 "던전이 진행될수록 몬스터가 강해진다"는 체감을 다이스 개수뿐 아니라
## 다이스 모양(과 그에 딸린 재질/색, _material_for_sides() 참고)으로도 드러낸다.
## 값 자체는 감으로 잡은 잠정값 — 이 스케일링이 기존 개수/HP 스케일링과 겹쳐 후반
## 난이도가 과도해지는 건 아닌지 사람 피드백 필요.
func _monster_dice_sides_for_room(room_index: int) -> int:
	if room_index >= 4:
		return 8
	if room_index >= 2:
		return 6
	return 4


## 잠정 난이도 스케일링 (DESIGN.md 미확정 — 1번째 방만 확정 수치 그대로 유지).
## room_index: 0부터 시작 (RunState.rooms_cleared와 동일한 기준, 즉 몇 번째 몬스터인지).
## room_index=0 -> 공격 2D4 / 방어 1D4 / HP10 (DESIGN.md 확정값과 동일).
##
## "보스"(INBOX.md 2026-09-09 [대형 기획 2] "던전 마지막에 보스급 몬스터"의 가장 작은
## 착수 조각): 라운드/재진입 구조 없이, 지금 런의 마지막 방(room_index ==
## RunState.TOTAL_ROOMS - 1)의 몬스터 스탯만 눈에 띄게 강화한다. 공격 다이스 +2개,
## 방어 다이스 +1개, HP는 그 방 기본값의 2배(감으로 잡은 잠정값 — 실제 체감 난이도는
## 사람 플레이 피드백 필요). TOTAL_ROOMS가 5로 고정돼 있는 한 room_index=4만 해당되고,
## QA에서 GAME_QA_ROOM_OVERRIDE로 더 큰 값(9, 14 등)을 줘도 정확히 일치하지 않는 한
## 보스로 취급하지 않는다(다음 라운드 개념이 아직 없으므로).
func _monster_config_for_room(room_index: int) -> Dictionary:
	var profile: Dictionary = MONSTER_PROFILES[room_index % MONSTER_PROFILES.size()]
	var cycle := int(room_index / float(MONSTER_PROFILES.size()))
	var name_text: String = profile["name"]
	if cycle > 0:
		name_text = "강화 ".repeat(cycle) + name_text
	var gimmick: String = profile.get("dice_gimmick", "")
	var dice_sides := _monster_dice_sides_for_room(room_index)
	var gimmick_value := 0
	if gimmick == "min_max_only":
		name_text += " [극단]"
	elif gimmick == "fixed_value":
		# 다이스 면 개수(sides)의 평균값 근처로 반올림 — "굴려도 늘 같은 값"이 다른
		# 몬스터의 평균 기댓값과 비슷하게 맞춰지도록 잡은 잠정 공식(밸런스는 사람 피드백
		# 필요). 예: D6 -> ceil(7/2) = 4.
		gimmick_value = int(ceil((dice_sides + 1) / 2.0))
		name_text += " [고정값 %d]" % gimmick_value
	elif gimmick == "anger_stack":
		name_text += " [분노]"
	elif gimmick == "steady_guard":
		# 방어 다이스 결과의 하한선("면 개수 절반, 올림") — DiceBag.apply_steady_guard()와
		# 정확히 같은 공식(ceil(sides/2.0))을 여기서도 계산해 디버그 문구에 노출한다.
		# 예: D4 -> 2, D6 -> 3, D8 -> 4.
		gimmick_value = int(ceil(dice_sides / 2.0))
		name_text += " [철벽]"
	var attack_count := 2 + int(room_index / 2.0)
	var defense_count := 1 + int(room_index / 3.0)
	var max_hp := 10 + room_index * 3
	var is_boss: bool = room_index == RunState.TOTAL_ROOMS - 1
	if is_boss:
		attack_count += 2
		defense_count += 1
		max_hp *= 2
		name_text += " [보스]"
	return {
		"attack_count": attack_count,
		"defense_count": defense_count,
		"dice_sides": dice_sides,
		"max_hp": max_hp,
		"name": name_text,
		"color": profile["color"],
		"dice_gimmick": gimmick,
		"dice_gimmick_value": gimmick_value,
		"is_boss": is_boss,
		"personality": profile.get("personality", ""),
	}


## INBOX.md 피드백(2026-09-14) "전투 시, 몬스터 hp바 하단에 해당 몬스터에 대한
## 스킬/전투 정보를 알려준다. 이는 개발용으로 추후 제거되거나 정보를 간소화시킬 수
## 있다" — 몬스터 이름에 이미 "[분노]"/"[고정값 4]"/"[극단]"/"[보스]" 같은 태그가
## 붙어있긴 하지만, 그 태그가 정확히 어떤 규칙인지(임계치 몇 번, D몇으로 바뀌는지
## 등)는 이름만 봐서는 알 수 없었다. _monster_config_for_room()이 만든 config
## dict만 받는 순수 함수라 인스턴스 상태 없이(다이스를 실제로 굴리지 않고) 바로
## 검증 가능(dice_test.gd 참고). 사람이 "너무 장황하다"고 피드백하면 이 함수만
## 줄이면 되고, 완전히 필요 없다고 하면 _ready()의 호출 한 줄과 이 라벨 노드만
## 지우면 된다.
func _monster_debug_info_text(config: Dictionary) -> String:
	var sides: int = config["dice_sides"]
	var text := "[QA] 공격 %dD%d · 방어 %dD%d" % [
		config["attack_count"], sides, config["defense_count"], sides
	]
	var personality: String = config.get("personality", "")
	if personality != "":
		text += "\n성격: %s" % personality
	match config.get("dice_gimmick", ""):
		"anger_stack":
			text += "\n기믹: 분노 스택 (공격 최댓값 %d회 -> 다음 공격 1D%d)" % [
				ANGER_STACK_THRESHOLD, ANGER_DICE_SIDES
			]
		"fixed_value":
			text += "\n기믹: 고정값 (항상 %d만 나옴, 안 굴림)" % config["dice_gimmick_value"]
		"min_max_only":
			text += "\n기믹: 극단 (최소·최대값만 나옴)"
		"steady_guard":
			text += "\n기믹: 철벽 방어 (방어 다이스 결과가 %d 미만이면 %d로 보정)" % [
				config["dice_gimmick_value"], config["dice_gimmick_value"]
			]
	if config.get("is_boss", false):
		text += "\n[보스] 공격+2 / 방어+1 / HP x2 강화됨"
	return text


## QA 전용 — GAME_QA_ROOM_OVERRIDE 환경변수(정수)가 있으면 RunState.rooms_cleared
## 대신 그 room_index로 몬스터를 구성한다. RunState 자체는 건드리지 않아(다른 화면/
## 다음 판에 영향 없음) 순수 QA 검증용. 방마다 몬스터 다이스 개수/모양(sides)이 실제
## "정지 감지가 끝난 뒤" 물리적으로 벽(combat_test.tscn Wall*) 안에 잘 들어와
## 있는지를, freeze로 고정한 스냅샷이 아니라 정상 플레이와 동일한 경로
## (_run_battle() -> _do_exchange() -> _wait_for_dice_to_settle())로 검증하기 위함
## (여러 방을 실제로 깨야만 후반 몬스터 다이스를 볼 수 있어 느린 문제를 우회).
func _room_index_for_monster_config() -> int:
	var override_env := OS.get_environment("GAME_QA_ROOM_OVERRIDE")
	if override_env.is_valid_int():
		return override_env.to_int()
	return RunState.rooms_cleared


func _ready() -> void:
	var config := _monster_config_for_room(_room_index_for_monster_config())
	var monster_sides: int = config["dice_sides"]
	monster_attack_bag = DiceBag.new(monster_sides, config["attack_count"])
	monster_defense_bag = DiceBag.new(monster_sides, config["defense_count"])
	monster_dice_gimmick = config["dice_gimmick"]
	if monster_dice_gimmick == "min_max_only":
		monster_attack_bag.force_min_max_faces()
		monster_defense_bag.force_min_max_faces()
	elif monster_dice_gimmick == "fixed_value":
		monster_attack_bag.force_fixed_value(config["dice_gimmick_value"])
		monster_defense_bag.force_fixed_value(config["dice_gimmick_value"])
	monster_anger_stacks = 0
	monster_anger_pending = false
	monster_max_hp = config["max_hp"]
	monster_hp = monster_max_hp
	monster_name = config["name"]
	monster_color = config["color"]
	monster_is_boss = config["is_boss"]
	monster_portrait.set_body_color(monster_color if monster_color.a > 0 else Color(0.5, 0.5, 0.5))
	monster_debug_info_label.text = _monster_debug_info_text(config)

	player_dice_gimmick = CharacterProfiles.get_profile(RunState.character_id).get("gimmick", "")
	player_explosive_stacks = 0
	player_explosive_pending = false
	player_guard_stacks = 0
	player_guard_pending = false
	player_deep_breath_used = false
	player_frenzy_active = RunState.skill_flags.has("frenzy_deepen")
	player_frenzy_deepen_plus_active = RunState.skill_flags.has("frenzy_deepen_plus")
	player_guard_deepen_active = RunState.skill_flags.has("guard_deepen")
	player_guard_deepen_plus_active = RunState.skill_flags.has("guard_deepen_plus")
	player_chain_explosion_active = RunState.skill_flags.has("chain_explosion")
	player_chain_explosion_plus_active = RunState.skill_flags.has("chain_explosion_plus")
	player_chain_guard_active = RunState.skill_flags.has("chain_guard")
	player_chain_guard_plus_active = RunState.skill_flags.has("chain_guard_plus")
	player_versatile_active = RunState.skill_flags.has("versatile_surge")
	player_versatile_plus_active = RunState.skill_flags.has("versatile_surge_plus")

	next_button.pressed.connect(_on_next_button_pressed)
	deck_toggle_button.pressed.connect(_on_deck_toggle_pressed)
	customize_toggle_button.pressed.connect(_on_customize_toggle_pressed)
	customize_toggle_button.visible = false
	customize_panel.closed.connect(_on_customize_panel_closed)
	_update_labels()
	_rebuild_shortcuts()
	_run_battle()


## dungeon_map.gd/shop.gd 등과 같은 패턴 — 지금 화면에 실제로 눌러야 할 버튼들을
## 화면에 보이는 순서(승리 보상 카드/건너뛰기/커스터마이징 -> "다음" -> 커스터마이징
## 토글 -> 덱 보기 토글)대로 모아 KeyboardShortcuts.apply_hints()로 "[n] " 접두어를
## 다시 붙인다. 버튼 구성이 바뀌는 지점(전투 시작/승패 판정 직후/보상 선택-건너뛰기/
## 덱 보기 토글)마다 호출해야 한다 — 안 그러면 예전 구성 그대로 눌리거나(이미 지워진
## 보상 버튼이 배열에 남아 있음) 덱 보기 버튼의 "[n] " 접두어가 텍스트 갱신으로 지워진
## 채로 남는다.
func _rebuild_shortcuts() -> void:
	var buttons: Array[Button] = []
	buttons.append_array(_reward_action_buttons)
	if next_button.visible:
		buttons.append(next_button)
	if customize_toggle_button.visible:
		buttons.append(customize_toggle_button)
	buttons.append(deck_toggle_button)
	_shortcut_buttons = buttons
	KeyboardShortcuts.apply_hints(_shortcut_buttons)


## 숫자 키(1~9)로 지금 보이는 전투 화면 버튼을 순서대로 누른다. dungeon_map.gd/shop.gd와
## 같은 이유로 커스터마이징 패널이 열려있을 때는 뒤에 가려진 버튼이 함께 눌리지 않도록
## 무시하고, get_viewport()는 try_press() 이후가 아니라 이전에 미리 받아둔다 — "다음"
## 버튼처럼 눌렸을 때 change_scene_to_file()로 씬을 바꾸는 버튼이면 이 노드가 try_press()
## 도중 트리에서 빠져나가 그 뒤의 get_viewport()가 null을 반환해 set_input_as_handled()
## 호출이 크래시하기 때문(2026-09-15 (105)에서 shop.gd 등 5개 화면에서 실제로 겪은
## 버그와 동일 패턴 — 처음부터 안전한 순서로 작성).
func _unhandled_input(event: InputEvent) -> void:
	if customize_panel.visible:
		return
	var idx := KeyboardShortcuts.digit_index(event)
	if idx < 0:
		return
	var viewport := get_viewport()
	if KeyboardShortcuts.try_press(_shortcut_buttons, idx) and viewport != null:
		viewport.set_input_as_handled()


## INBOX.md 피드백(2026-09-03) "내 공격 덱과 방어 덱이 ... 항상 떠있으면 좋겠다
## (전투 중에도)"의 "전투 중에도" 부분. combat_test는 다이스 뷰포트/초상화/로그로
## 화면이 이미 꽉 차 있어 dungeon_map 등처럼 상시 표시 패널을 놓을 자리가 없어서,
## 대신 버튼으로 여닫는 오버레이로 구현한다 (STATUS.md 큐 0번 "접이식/토글 버튼"
## 대안 채택).
func _on_deck_toggle_pressed() -> void:
	deck_panel.visible = not deck_panel.visible
	deck_toggle_button.text = "덱 닫기" if deck_panel.visible else "덱 보기"
	_rebuild_shortcuts()


## INBOX.md 피드백(2026-09-03) "커스터마이징은 전투 중에는 불가능해야 한다" — 이전
## 이터레이션이 "어디서든 커스터마이징"을 위해 combat_test에도 상시 토글 버튼을
## 붙였던 것을 사용자가 되돌리라고 지시함. 버튼 자체를 battle_over가 될 때까지 숨겨서
## (_ready()/_do_exchange() 참고) 보통은 누를 수조차 없지만, QA의 GAME_QA_CALL처럼
## 시그널을 직접 emit해 visible 체크를 우회하는 경로까지 막기 위해 핸들러에서도
## battle_over를 한 번 더 확인한다.
func _on_customize_toggle_pressed() -> void:
	if not battle_over:
		return
	customize_panel.open()


## "연쇄 폭발"(폭발병 전용 고유 스킬) 또는 "임기응변+"(견습 모험가 전용 강화판) 보유
## 시 폭발 스택 임계치를 3에서 2로 낮춘다. 미보유(또는 광기 심화로 열린 광전사 쪽)는
## 기존 EXPLOSIVE_STACK_THRESHOLD 그대로.
func _player_explosive_threshold() -> int:
	return 2 if (player_chain_explosion_active or player_versatile_plus_active) else EXPLOSIVE_STACK_THRESHOLD


## "연쇄 방어"(방패병 전용 고유 스킬) 또는 "임기응변+"(견습 모험가 전용 강화판) 보유
## 시 수호 스택 임계치를 3에서 2로 낮춘다. _player_explosive_threshold()와 완전히
## 대칭 구조. 미보유(또는 수호 심화로 열린 수호자 쪽)는 기존 GUARD_STACK_THRESHOLD 그대로.
func _player_guard_threshold() -> int:
	return 2 if (player_chain_guard_active or player_versatile_plus_active) else GUARD_STACK_THRESHOLD


func _run_battle() -> void:
	while not battle_over:
		await _do_exchange(true)
		if battle_over:
			break
		await _do_exchange(false)


## is_player_attacking == true  -> 내 공격턴 (플레이어 공격 주머니 vs 몬스터 방어 주머니)
## is_player_attacking == false -> 몬스터 공격턴 (몬스터 공격 주머니 vs 플레이어 방어 주머니)
func _do_exchange(is_player_attacking: bool) -> void:
	# "anger_stack" 기믹이 이전 몬스터 공격턴에 임계치를 채웠으면, 이번 몬스터 공격턴은
	# 평소 monster_attack_bag 대신 1D20 임시 주머니로 굴린다(다음 문단에서 스택 집계 시
	# used_anger_dice로 구분해 이 굴림 자체는 다시 스택을 쌓지 않게 함).
	var used_anger_dice := false
	var used_explosive_dice := false
	var used_guard_dice := false
	var atk_bag: DiceBag
	if is_player_attacking:
		if (player_dice_gimmick == "explosive_stack" or player_frenzy_active or player_versatile_active) and player_explosive_pending:
			atk_bag = DiceBag.new(EXPLOSIVE_DICE_SIDES, 1)
			used_explosive_dice = true
		else:
			atk_bag = RunState.player_attack_bag
	elif monster_dice_gimmick == "anger_stack" and monster_anger_pending:
		atk_bag = DiceBag.new(ANGER_DICE_SIDES, 1)
		used_anger_dice = true
	else:
		atk_bag = monster_attack_bag
	# "guard_stack" 기믹이 이전 플레이어 방어턴에 임계치를 채웠으면, 이번 플레이어
	# 방어턴은 평소 RunState.player_defense_bag 대신 1D20 임시 주머니로 굴린다
	# (explosive_stack의 atk_bag 분기와 완전히 대칭 구조).
	var def_bag: DiceBag
	if is_player_attacking:
		def_bag = monster_defense_bag
	elif (player_dice_gimmick == "guard_stack" or player_guard_deepen_active or player_versatile_active) and player_guard_pending:
		def_bag = DiceBag.new(GUARD_DICE_SIDES, 1)
		used_guard_dice = true
	else:
		def_bag = RunState.player_defense_bag

	turn_label.text = "내 공격턴" if is_player_attacking else "몬스터 공격턴 (내 방어턴)"

	var default_color := Color(1, 1, 1, 0)
	var atk_color := monster_color if not is_player_attacking else default_color
	var def_color := monster_color if is_player_attacking else default_color

	_clear_dice()
	_spawn_dice(atk_bag, -1.4, atk_color)
	_spawn_dice(def_bag, 1.4, def_color)

	await _wait_for_dice_to_settle()

	var atk_values := atk_bag.roll_detailed()
	var def_values := def_bag.roll_detailed()
	# "steady_guard" 기믹(다크 나이트, [미니 기획 A]-2): 몬스터가 방어턴일 때만(플레이어
	# 공격턴, def_bag == monster_defense_bag) 굴림 결과에 하한선을 적용한다 — 실제 데미지
	# 계산과 화면에 보이는 결과 칩(_show_exchange_dice_chips) 둘 다 보정된 값을 쓴다.
	if is_player_attacking and monster_dice_gimmick == "steady_guard":
		def_values = def_bag.apply_steady_guard(def_values)
	# "광기 심화"(INBOX.md [미니 기획 C]-4): 이번 공격턴이 폭발 스택 보너스 턴(1D20)이고
	# 광기 심화를 보유했다면, 한 번 더 굴려 더 높은 값을 채택한다("두 번 굴려 advantage").
	# "광기 심화+"([미니 기획 D]-4): 추가 리롤을 1번이 아니라 2번 해서 총 굴림 횟수를
	# 2번->3번으로 늘린다(임계치/스택 조건은 그대로, 보너스 턴 굴림 품질만 강화).
	# _apply_bonus_reroll()로 분리해 _apply_spare_die()와 같은 이유(물리 없이 단위
	# 테스트 가능)로 순수 함수화했다.
	if used_explosive_dice and player_frenzy_active:
		var frenzy_extra_rolls := 2 if player_frenzy_deepen_plus_active else 1
		var frenzy_total_rolls := frenzy_extra_rolls + 1
		var frenzy_before: int = atk_values[0]
		atk_values = _apply_bonus_reroll(atk_bag, atk_values, frenzy_extra_rolls)
		if atk_values[0] > frenzy_before:
			_append_log("광기 심화: %d 대신 %d 채택 (1D20 %d번 중 최댓값)" % [frenzy_before, atk_values[0], frenzy_total_rolls])
		else:
			_append_log("광기 심화: %d 유지 (1D20 %d번 중 최댓값)" % [frenzy_before, frenzy_total_rolls])
	# "수호 심화"(수호자 전용 고유 스킬, frenzy_deepen과 완전히 대칭): 이번 방어턴이
	# 수호 스택 보너스 턴(1D20)이고 수호 심화를 보유했다면, 한 번 더 굴려 더 높은 값을
	# 채택한다. "수호 심화+"는 frenzy_deepen_plus와 동일하게 총 굴림 횟수를 3번으로 늘림.
	if used_guard_dice and player_guard_deepen_active:
		var guard_extra_rolls := 2 if player_guard_deepen_plus_active else 1
		var guard_total_rolls := guard_extra_rolls + 1
		var guard_before: int = def_values[0]
		def_values = _apply_bonus_reroll(def_bag, def_values, guard_extra_rolls)
		if def_values[0] > guard_before:
			_append_log("수호 심화: %d 대신 %d 채택 (1D20 %d번 중 최댓값)" % [guard_before, def_values[0], guard_total_rolls])
		else:
			_append_log("수호 심화: %d 유지 (1D20 %d번 중 최댓값)" % [guard_before, guard_total_rolls])
	# "연쇄 폭발+"([미니 기획 D]-4, 폭발병 전용 강화판): base(chain_explosion)는
	# 임계치만 2로 낮췄을 뿐 보너스 턴 굴림 자체는 그대로 1D20 한 번이었는데,
	# "+"는 frenzy_deepen과 같은 방식으로 한 번 더 굴려("advantage") 더 높은 값을
	# 채택한다(_apply_bonus_reroll(), extra_rolls=1, 총 2번 굴림).
	if used_explosive_dice and player_chain_explosion_plus_active:
		var chain_explosion_before: int = atk_values[0]
		atk_values = _apply_bonus_reroll(atk_bag, atk_values, 1)
		if atk_values[0] > chain_explosion_before:
			_append_log("연쇄 폭발+: %d 대신 %d 채택 (1D20 2번 중 최댓값)" % [chain_explosion_before, atk_values[0]])
		else:
			_append_log("연쇄 폭발+: %d 유지 (1D20 2번 중 최댓값)" % chain_explosion_before)
	# "연쇄 방어+"([미니 기획 D]-4, 방패병 전용 강화판): 연쇄 폭발+와 완전히 대칭
	# (공격 대신 방어).
	if used_guard_dice and player_chain_guard_plus_active:
		var chain_guard_before: int = def_values[0]
		def_values = _apply_bonus_reroll(def_bag, def_values, 1)
		if def_values[0] > chain_guard_before:
			_append_log("연쇄 방어+: %d 대신 %d 채택 (1D20 2번 중 최댓값)" % [chain_guard_before, def_values[0]])
		else:
			_append_log("연쇄 방어+: %d 유지 (1D20 2번 중 최댓값)" % chain_guard_before)
	# "여분"(INBOX.md [미니 기획 C]-3): 폭발 보너스 턴이 아닌 평소 공격턴마다 여분
	# 다이스를 하나 더 굴려, 이번 공격에서 가장 낮았던 다이스 값보다 높으면 그 자리를
	# 대체한다(advantage를 가장 약한 다이스 한 곳에만 적용) — "이번 런 내내 유지"이므로
	# skill_flags에 남아있는 한 매 공격턴 계속 적용된다.
	# "여분+"([미니 기획 D]-4, 공용 강화): 여분 다이스를 1개가 아니라 2개 굴려 그 중
	# 더 높은 값으로 대체한다. "+" > base > 없음 우선순위 — spare_die_plus가 있으면
	# spare_die 자체는 확인하지 않는다(둘 다 skill_flags에 있어도 상위 효과만 적용).
	if is_player_attacking and not used_explosive_dice:
		if RunState.skill_flags.has("spare_die_plus"):
			atk_values = _apply_spare_die(atk_bag, atk_values, 2)
		elif RunState.skill_flags.has("spare_die"):
			atk_values = _apply_spare_die(atk_bag, atk_values, 1)
	# "맹공"([미니 기획 E]-4, 시작 스킬): 공격 다이스 개수가 방어 다이스 개수보다 많으면
	# 공격 다이스 결과값 전체 +1. 주머니 구성(개수)만 보는 정적 조건이라 전투 중 바뀌지
	# 않음 — 매 공격턴(폭발 보너스 턴 포함)마다 다시 확인해 적용한다.
	if is_player_attacking and RunState.skill_flags.has("start_aggro"):
		if RunState.player_attack_bag.dice.size() > RunState.player_defense_bag.dice.size():
			atk_values = atk_bag.apply_flat_bonus(atk_values, 1)
			_append_log("맹공 효과: 공격 다이스 결과값 +1 (공격 다이스가 더 많음)")
	# "심호흡+"([미니 기획 D]-4, 공용 강화): base는 이번 전투 첫 방어턴 한 번만
	# 적용되지만, "+"는 매 방어턴마다 적용된다(상한은 base와 동일하게 다이스별 면
	# 개수). "+" > base 우선순위 — 두 id가 함께 있어도 "+"만 적용하고 player_deep_
	# breath_used는 건드리지 않는다(혹시 나중에 "+"를 잃는 경우를 대비해 base의
	# 1회성 상태를 훼손하지 않음).
	if not is_player_attacking:
		if RunState.skill_flags.has("deep_breath_plus"):
			def_values = def_bag.apply_flat_bonus(def_values, 1)
			_append_log("심호흡+ 효과: 방어 다이스 결과값 +1 (매 방어턴)")
		elif RunState.skill_flags.has("deep_breath") and not player_deep_breath_used:
			def_values = def_bag.apply_flat_bonus(def_values, 1)
			player_deep_breath_used = true
			_append_log("심호흡 효과: 방어 다이스 결과값 +1 (이번 전투 최초 1회)")
	# "철벽"([미니 기획 E]-4, 시작 스킬): 방어 다이스 개수가 공격 다이스 개수보다 많으면
	# 방어 다이스 결과값 전체 +1. 맹공과 완전히 대칭 구조(공격 대신 방어) — 주머니
	# 구성(개수)만 보는 정적 조건이라 매 방어턴(수호 보너스 턴 포함)마다 다시 확인한다.
	if not is_player_attacking and RunState.skill_flags.has("start_wall"):
		if RunState.player_defense_bag.dice.size() > RunState.player_attack_bag.dice.size():
			def_values = def_bag.apply_flat_bonus(def_values, 1)
			_append_log("철벽 효과: 방어 다이스 결과값 +1 (방어 다이스가 더 많음)")
	var atk_total := 0
	for v in atk_values:
		atk_total += v
	var def_total := 0
	for v in def_values:
		def_total += v
	var dmg := CombatMath.calculate_damage(atk_total, def_total)

	_show_exchange_dice_chips(atk_bag, atk_values, def_bag, def_values, atk_color, def_color)

	if is_player_attacking:
		monster_hp = max(0, monster_hp - dmg)
		_append_log("플레이어 공격 %d vs 몬스터 방어 %d -> 데미지 %d (몬스터 HP %d)" % [atk_total, def_total, dmg, monster_hp])
		player_portrait.set_expression("happy")
		monster_portrait.set_expression("hurt" if dmg > 0 else "neutral")
	else:
		player_hp = max(0, player_hp - dmg)
		_append_log("몬스터 공격 %d vs 플레이어 방어 %d -> 데미지 %d (플레이어 HP %d)" % [atk_total, def_total, dmg, player_hp])
		monster_portrait.set_expression("happy")
		player_portrait.set_expression("hurt" if dmg > 0 else "neutral")

	if not is_player_attacking and monster_dice_gimmick == "anger_stack":
		if used_anger_dice:
			monster_anger_stacks = 0
			monster_anger_pending = false
			_append_log("분노가 가라앉았다 (분노 스택 초기화)")
		else:
			var max_hits: int = monster_attack_bag.count_max_rolls(atk_values)
			if max_hits > 0:
				monster_anger_stacks += max_hits
				_append_log("몬스터 분노 스택 +%d (%d/%d)" % [max_hits, monster_anger_stacks, ANGER_STACK_THRESHOLD])
				if monster_anger_stacks >= ANGER_STACK_THRESHOLD:
					monster_anger_pending = true
					_append_log("몬스터가 분노했다! 다음 공격은 20면체 주사위로 굴린다")

	if is_player_attacking and (player_dice_gimmick == "explosive_stack" or player_frenzy_active or player_versatile_active):
		if used_explosive_dice:
			player_explosive_stacks = 0
			player_explosive_pending = false
			_append_log("광기가 가라앉았다 (스택 초기화)" if player_frenzy_active else "폭발이 진정됐다 (폭발 스택 초기화)")
		else:
			var max_hits: int = RunState.player_attack_bag.count_max_rolls(atk_values)
			if max_hits > 0:
				player_explosive_stacks += max_hits
				var stack_label := "광기" if player_frenzy_active else "폭발"
				var explosive_threshold := _player_explosive_threshold()
				_append_log("%s 스택 +%d (%d/%d)" % [stack_label, max_hits, player_explosive_stacks, explosive_threshold])
				if player_explosive_stacks >= explosive_threshold:
					player_explosive_pending = true
					_append_log("광기가 정점에 달했다! 다음 공격은 1D20을 두 번 굴려 더 높은 값을 채택한다" if player_frenzy_active else "폭발 직전! 다음 공격은 20면체 주사위로 터진다")

	if not is_player_attacking and (player_dice_gimmick == "guard_stack" or player_guard_deepen_active or player_versatile_active):
		if used_guard_dice:
			player_guard_stacks = 0
			player_guard_pending = false
			_append_log("수호가 가라앉았다 (수호 스택 초기화)" if player_guard_deepen_active else "수호 태세가 풀렸다 (수호 스택 초기화)")
		else:
			var guard_hits: int = RunState.player_defense_bag.count_max_rolls(def_values)
			if guard_hits > 0:
				player_guard_stacks += guard_hits
				var guard_stack_label := "수호 심화" if player_guard_deepen_active else "수호"
				var guard_threshold := _player_guard_threshold()
				_append_log("%s 스택 +%d (%d/%d)" % [guard_stack_label, guard_hits, player_guard_stacks, guard_threshold])
				if player_guard_stacks >= guard_threshold:
					player_guard_pending = true
					_append_log("수호 심화가 정점에 달했다! 다음 방어는 1D20을 두 번 굴려 더 높은 값을 채택한다" if player_guard_deepen_active else "수호 태세 완성! 다음 방어는 20면체 주사위로 굳건해진다")

	_update_labels()

	if monster_hp <= 0:
		battle_over = true
		player_won = true
		turn_label.text = "승리! (몬스터 처치)"
		# INBOX.md [대형 기획 3] 업적 #6 "D20 다이스를 보유한 채로 전투 승리". D20 다이스는
		# faces 배열 크기가 20인 다이스로 판별한다(표준 다이스는 add_die(sides)로 만들어져
		# faces.size() == sides가 항상 성립 — force_fixed_value() 등으로 면 값이 바뀌어도
		# 면 "개수" 자체는 그대로임).
		if _bag_has_d20(RunState.player_attack_bag) or _bag_has_d20(RunState.player_defense_bag):
			AchievementManager.unlock("win_with_d20")
		if _is_flawless_win(player_hp):
			AchievementManager.unlock("flawless_win")
		if _is_comeback_win(player_hp):
			AchievementManager.unlock("comeback_win")
		if _is_overkill_win(dmg, monster_max_hp):
			AchievementManager.unlock("overkill_win")
		var gold_gain := GOLD_REWARD_BASE + RunState.rooms_cleared * GOLD_REWARD_PER_ROOM
		RunState.gold += gold_gain
		_append_log("골드 획득: +%d (보유 %d)" % [gold_gain, RunState.gold])
		if RunState.gold >= 100:
			AchievementManager.unlock("gold_100")
		var pip_max := PIP_REWARD_MAX_BASE + RunState.rooms_cleared * PIP_REWARD_MAX_PER_ROOM
		var pip_gain := randi_range(PIP_REWARD_MIN, pip_max)
		RunState.pip_inventory.append(pip_gain)
		_append_log("눈금 획득: [%d] (커스터마이징에서 다이스 면과 교환 가능)" % pip_gain)
		player_portrait.set_expression("happy")
		monster_portrait.set_expression("sad")
	elif player_hp <= 0:
		battle_over = true
		player_won = false
		turn_label.text = "패배... (플레이어 사망)"
		player_portrait.set_expression("angry" if randi() % 2 == 0 else "sad")
		monster_portrait.set_expression("happy")
		_unlock_defeat_achievement()

	# INBOX.md 피드백(2026-09-03) "커스터마이징은 전투 중에는 불가능해야 한다" — 전투가
	# 끝난 뒤에만 상단 토글 버튼을 보여준다 (battle_over가 막 true가 된 시점에 맞춰 동기화).
	customize_toggle_button.visible = battle_over

	await get_tree().create_timer(EXCHANGE_PAUSE_TIME).timeout

	if battle_over:
		# INBOX.md 피드백(2026-09-09) "결과 화면이 나왔을 때, 덱 보기 토글이 열려있다면
		# 닫힌다" — 결과 화면(보상/패배)이 덱 패널과 겹쳐 보이지 않도록 강제로 닫는다.
		if deck_panel.visible:
			deck_panel.visible = false
			deck_toggle_button.text = "덱 보기"
		if player_won:
			next_button.text = "다음"
			_show_reward_ui()
		else:
			next_button.text = "처음부터 다시"
			next_button.show()
			_rebuild_shortcuts()


## 씬에 있는 모든 다이스가 정지했다고 판단될 때까지 기다린다.
## 다이스마다 독립적인 "연속 정지 프레임" 카운터를 두고, 한 번 SETTLE_MIN_FRAMES에
## 도달한 다이스는 이후 다시 검사하지 않는다 (위 클래스 주석 참고).
func _wait_for_dice_to_settle() -> void:
	var quiet_frames: Dictionary = {}
	for child in dice_root.get_children():
		if child is RigidBody3D:
			quiet_frames[child] = 0

	var elapsed := 0.0
	while true:
		await get_tree().physics_frame
		# QA 하네스가 캡처 직후 get_tree().quit()을 호출하면 이 await가 재개되는
		# 시점에는 이미 dice_root와 그 자식들이 해제된 상태일 수 있다 (셧다운 중
		# 프리즈된 인스턴스를 타입 있는 for 루프 변수에 대입하면
		# "Trying to assign invalid previously freed instance" 에러가 남).
		if not is_instance_valid(dice_root):
			return
		elapsed += get_physics_process_delta_time()

		var all_settled := true
		for die in quiet_frames.keys():
			if not is_instance_valid(die):
				continue
			if quiet_frames[die] >= SETTLE_MIN_FRAMES:
				continue
			var is_quiet: bool = die.linear_velocity.length() <= SETTLE_LIN_THRESHOLD \
				and die.angular_velocity.length() <= SETTLE_ANG_THRESHOLD
			quiet_frames[die] = quiet_frames[die] + 1 if is_quiet else 0
			if quiet_frames[die] < SETTLE_MIN_FRAMES:
				all_settled = false

		if all_settled:
			return
		if elapsed >= SETTLE_MAX_WAIT:
			return


## visual_qa.gd(GAME_QA_SETTLE=1)가 스크린샷을 찍기 전에 폴링하는 훅 (DESIGN.md
## "다이스 정지 감지 후 스크린샷을 찍는 정확한 타이밍/방식" 항목 반영). 위
## `_wait_for_dice_to_settle()`과 같은 임계값을 재사용해, "지금 이 순간 다이스가
## 눈에 띄게 구르고 있는가"만 독립적으로 판단한다 (게임 로직의 정지 대기 상태와는
## 무관 — dice_root가 비어 있으면(스폰 전/후) 트리비얼하게 정지로 간주).
func _qa_is_settled() -> bool:
	if not is_instance_valid(dice_root):
		return true
	for child in dice_root.get_children():
		if child is RigidBody3D:
			if child.linear_velocity.length() > SETTLE_LIN_THRESHOLD \
				or child.angular_velocity.length() > SETTLE_ANG_THRESHOLD:
				return false
	return true


## bag의 다이스별 실제 면 개수(faces.size())에 맞춰 다이스 모양(D4/D6/D8/...)을
## 스폰한다 (Die.sides는 add_child()로 트리에 들어가 _ready()가 도는 시점에 이미
## 메시를 만드므로, 반드시 add_child() 이전에 설정해야 함).
func _spawn_dice(bag: DiceBag, base_x: float, color: Color = Color(1, 1, 1, 0)) -> void:
	var count := bag.count
	var total_rows := int(ceil(float(count) / DICE_SPAWN_PER_ROW))
	for i in count:
		var die := DieScene.instantiate()
		die.sides = bag.dice[i].size()
		die.color_override = color
		var material := _material_for_sides(die.sides)
		if material != null:
			die.material = material
		dice_root.add_child(die)
		var row := i / DICE_SPAWN_PER_ROW
		var row_start := row * DICE_SPAWN_PER_ROW
		var cols_in_row: int = min(DICE_SPAWN_PER_ROW, count - row_start)
		var col := i - row_start
		var x: float = base_x + (col - (cols_in_row - 1) / 2.0) * DICE_SPAWN_COL_SPACING
		var z := (row - (total_rows - 1) / 2.0) * DICE_SPAWN_ROW_SPACING + randf_range(-0.15, 0.15)
		var y := 1.4 + i * 0.35
		die.transform = Transform3D(Basis(), Vector3(x, y, z))
		die.linear_velocity = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
		die.angular_velocity = Vector3(randf_range(2.0, 5.0), randf_range(2.0, 5.0), randf_range(2.0, 5.0))


func _clear_dice() -> void:
	for child in dice_root.get_children():
		child.queue_free()


## 이번 교환의 공격/방어 다이스 결과를 각각 화면 좌/우에서 안쪽으로 나열해 보여준다.
## NextButton(x540-740, 전투 진행 중에는 hidden)과 겹치는 중앙부는 비워 둔다.
func _show_exchange_dice_chips(atk_bag: DiceBag, atk_values: Array, def_bag: DiceBag, def_values: Array, atk_tint: Color, def_tint: Color) -> void:
	_clear_exchange_dice_chips()
	_layout_dice_chip_row(atk_bag, atk_values, 150.0, atk_tint, false)
	_layout_dice_chip_row(def_bag, def_values, 1130.0, def_tint, true)


func _layout_dice_chip_row(bag: DiceBag, values: Array, x_start: float, tint: Color, right_align: bool) -> void:
	var border := tint if tint.a > 0 else Color(0.15, 0.12, 0.08)
	var x := x_start
	for i in bag.dice.size():
		var sides: int = bag.dice[i].size()
		var chip := ShapeDieChip.new()
		chip.custom_minimum_size = Vector2(EXCHANGE_CHIP_SIZE, EXCHANGE_CHIP_SIZE)
		chip.size = Vector2(EXCHANGE_CHIP_SIZE, EXCHANGE_CHIP_SIZE)
		chip.shape_sides = ShapeDieChip.shape_sides_for_dice_sides(sides)
		chip.border_color = border
		chip.value = values[i]
		if right_align:
			x -= EXCHANGE_CHIP_SIZE
		chip.position = Vector2(x, EXCHANGE_CHIP_Y)
		add_child(chip)
		_exchange_chip_nodes.append(chip)
		x += -EXCHANGE_CHIP_GAP if right_align else EXCHANGE_CHIP_SIZE + EXCHANGE_CHIP_GAP


func _clear_exchange_dice_chips() -> void:
	for node in _exchange_chip_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_exchange_chip_nodes.clear()


func _update_labels() -> void:
	player_hp_label.text = "플레이어 HP: %d / %d" % [player_hp, PLAYER_MAX_HP]
	monster_hp_label.text = "%s HP: %d / %d" % [monster_name, monster_hp, monster_max_hp]
	_update_hp_bar(player_hp_bar_fill, PLAYER_HP_BAR_WIDTH, player_hp, PLAYER_MAX_HP)
	_update_hp_bar(monster_hp_bar_fill, MONSTER_HP_BAR_WIDTH, monster_hp, monster_max_hp)


## fill(ColorRect)의 너비를 hp/max_hp 비율만큼 줄이고(왼쪽 기준 고정, 오른쪽부터
## 닳는 형태), 남은 비율에 따라 초록->주황->빨강으로 색을 바꾼다.
func _update_hp_bar(fill: ColorRect, full_width: float, hp: int, max_hp: int) -> void:
	var ratio: float = clamp(float(hp) / max_hp, 0.0, 1.0) if max_hp > 0 else 0.0
	fill.size.x = full_width * ratio
	if ratio > 0.5:
		fill.color = HP_BAR_COLOR_HIGH
	elif ratio > 0.25:
		fill.color = HP_BAR_COLOR_MID
	else:
		fill.color = HP_BAR_COLOR_LOW


## "여분"/"여분+" 스킬(INBOX.md [미니 기획 C]-3, [미니 기획 D]-4) 전용 헬퍼 — bag의
## 첫 번째 다이스와 같은 면 개수의 여분 다이스를 count개 굴려 그 중 최댓값을 구하고,
## values 중 가장 낮은 값보다 높으면 그 자리를 대체한 새 배열을 반환한다(원본 배열은
## 건드리지 않음, DiceBag.apply_steady_guard()와 같은 "새 배열 반환" 관례). base
## "여분"은 count=1(굴림 1회, advantage 없음), "여분+"는 count=2(두 번 굴려 최댓값
## 채택)로 호출한다 — 굴리는 다이스 개수만 다르고 나머지 로직은 완전히 공유. bag이
## 비어있으면(이론상 발생하지 않지만 방어적으로) D4를 기본값으로 쓴다.
func _apply_spare_die(bag: DiceBag, values: Array, count: int = 1) -> Array:
	if values.is_empty():
		return values
	var spare_sides := 4
	if bag.dice.size() > 0:
		spare_sides = bag.dice[0].size()
	var spare_bag := DiceBag.new(spare_sides, 1)
	var spare_value: int = spare_bag.roll_detailed()[0]
	for i in count - 1:
		var reroll: int = spare_bag.roll_detailed()[0]
		if reroll > spare_value:
			spare_value = reroll
	var adjusted: Array = values.duplicate()
	var min_index := 0
	for i in adjusted.size():
		if adjusted[i] < adjusted[min_index]:
			min_index = i
	if spare_value > adjusted[min_index]:
		_append_log("여분 다이스 결과 %d로 최저 공격 다이스 값 %d 대체" % [spare_value, adjusted[min_index]])
		adjusted[min_index] = spare_value
	return adjusted


## "광기 심화"/"수호 심화"(및 각각의 "+" 강화판) 공용 헬퍼: bag에서 extra_rolls번
## 추가로 굴려, values[0]과 그 중 최댓값을 비교해 더 높으면 그 자리를 대체한다("두
## 번(또는 세 번) 굴려 advantage"). _apply_spare_die()와 같은 이유로 순수 함수로
## 분리해 물리 시뮬레이션 없이 단위 테스트가 가능하게 한다. 로그 출력은 호출부
## (_do_exchange) 책임 — 이 함수는 값만 계산한다.
func _apply_bonus_reroll(bag: DiceBag, values: Array, extra_rolls: int) -> Array:
	var result: Array = values.duplicate()
	var best: int = result[0]
	for _i in range(extra_rolls):
		var reroll: Array = bag.roll_detailed()
		if reroll[0] > best:
			best = reroll[0]
	result[0] = best
	return result


func _append_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


## AchievementManager 업적 "win_with_d20" 판정용. bag 안에 면 20개짜리 다이스가
## 하나라도 있으면 true.
func _bag_has_d20(bag: DiceBag) -> bool:
	for faces in bag.dice:
		if faces.size() == 20:
			return true
	return false


## AchievementManager 업적 3종(무결점 승리/기사회생/오버킬) 판정용 순수 함수 —
## _bag_has_d20과 같은 패턴으로 _do_exchange()의 승리 분기에서 호출한다.
## 체력이 이 값 이하로 떨어진 채로 이긴 경우 "기사회생"으로 친다 (PLAYER_MAX_HP=20의 10%).
const COMEBACK_HP_THRESHOLD := 2


## 승리 시점의 플레이어 HP가 최대 HP 그대로면(이번 전투에서 한 번도 안 맞았으면) true.
func _is_flawless_win(hp_at_win: int) -> bool:
	return hp_at_win >= PLAYER_MAX_HP


## 승리 시점의 플레이어 HP가 COMEBACK_HP_THRESHOLD 이하로 떨어져 있었으면 true.
func _is_comeback_win(hp_at_win: int) -> bool:
	return hp_at_win <= COMEBACK_HP_THRESHOLD


## 몬스터를 처치한 한 방의 데미지가 몬스터 최대 체력 이상이면(풀피 상태였어도 한 방에
## 죽였을 만큼 큰 데미지) true.
func _is_overkill_win(final_hit_dmg: int, target_max_hp: int) -> bool:
	return final_hit_dmg >= target_max_hp


## event.gd의 _on_pick_pressed/_apply_pick(이터레이션 46)와 같은 이유로 이중 실행
## 가드가 필요하다: change_scene_to_file()은 그 프레임 안에서 즉시 씬을 바꾸지 않으므로,
## NextButton을 더블클릭하면 같은 프레임에 이 핸들러가 두 번 불려 rooms_cleared가 2
## 증가(방 스킵)하거나 reset_run()이 중복 호출될 수 있었다. 상태 변경(_apply_room_advance)과
## 씬 전환(_on_next_button_pressed)을 분리한 이유도 동일 — 회귀 테스트가 change_scene_to_file
## 없이 가드만 검증할 수 있게 하기 위함.
func _on_next_button_pressed() -> void:
	if not _apply_room_advance():
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 반환값 = 이번 호출이 실제로 적용됐는지 (이미 적용됐으면 false, 아무 것도 안 함).
## [대형 기획 2] 조각 (b): 이번에 이긴 방이 보스 방(monster_is_boss)이었고 아직 마지막
## 라운드가 아니면(RunState.is_last_round()) RunState.advance_round()를 불러 라운드를
## 넘긴다 — advance_round()가 rooms_cleared를 0으로 되돌려주므로, 뒤이어
## dungeon_map.tscn으로 전환되는 순간 곧바로 "새 라운드의 1번째 방"으로 보인다(별도의
## "다음 라운드로" 확인 화면 없이 승리 -> 재진입이 한 번에 이어짐). 마지막 라운드의
## 보스를 잡았을 때는 advance_round()가 스스로 아무 일도 안 하므로(가드) rooms_cleared가
## TOTAL_ROOMS에 그대로 남아 dungeon_map의 기존 "던전 클리어!"(최종 클리어) 분기로 이어짐.
func _apply_room_advance() -> bool:
	if _room_advanced:
		return false
	_room_advanced = true
	if player_won:
		RunState.rooms_cleared += 1
		if monster_is_boss:
			# advance_round()가 round_index를 바꾸기 전에, "방금 어느 라운드를 끝냈는지"를
			# 정확히 알 수 있는 유일한 시점 — dungeon_map.gd에서 RunState.is_run_complete()
			# 기준으로 판정하면 advance_round()가 매 라운드 즉시 rooms_cleared를 0으로
			# 되돌려버려 "최종 라운드까지 전부 클리어"할 때만 참이 되므로 여기서 처리한다.
			_unlock_round_clear_achievements(RunState.round_index)
			if not RunState.is_last_round():
				RunState.advance_round()
	else:
		RunState.reset_run()
	return true


## 보스를 잡아 cleared_round(라운드 번호)를 막 끝낸 순간 불린다. 큐 13("[대형 기획 1]
## 5종 캐릭터 + [대형 기획 2] 라운드/보스 구조가 둘 다 갖춰져 트리거 지점이 생겼다")를
## 반영 — 라운드 1/2 클리어와, 마지막 라운드(TOTAL_ROUNDS) 클리어 시 "최종 승리" +
## 지금 플레이 중인 캐릭터 전용 "~로 첫 클리어" 업적을 함께 해금한다.
func _unlock_round_clear_achievements(cleared_round: int) -> void:
	if cleared_round == 1:
		AchievementManager.unlock("round1_clear")
	elif cleared_round == 2:
		AchievementManager.unlock("round2_clear")
	elif cleared_round == RunState.TOTAL_ROUNDS:
		AchievementManager.unlock("game_clear")
		AchievementManager.unlock(_character_clear_achievement_id(RunState.character_id))


## 패배(HP 0) 시점에 "패배도 경험이다" 업적을 해금한다. _unlock_round_clear_achievements()와
## 같은 이유로 별도 함수로 분리 — 물리 다이스 정지 대기가 포함된 코루틴 안에서 직접
## 호출되는 unlock()은 dice_test.gd가 코루틴 없이 곧바로 호출해 검증할 수 없으므로,
## 조건 판단이 끝난 직후의 부수효과만 함수로 떼어내 테스트 가능하게 만든다.
func _unlock_defeat_achievement() -> void:
	AchievementManager.unlock("first_defeat")


## character_id(예: "berserker") -> achievement_manager.gd DEFINITIONS의 "clear_<id>" 키.
## 새 캐릭터를 추가할 때 이 함수는 그대로 두고 DEFINITIONS에 "clear_<새id>" 항목만
## 추가하면 된다(character_profiles.gd의 id 값과 이름이 그대로 맞아떨어지는 구조).
func _character_clear_achievement_id(char_id: String) -> String:
	return "clear_%s" % char_id


## 승리 시 다이스 개조 아이템 2개를 제시하고, 어느 주머니(공격/방어)에 적용할지
## 고르게 한다. 다이스 뷰포트가 차지하던 영역(140,120)-(1140,540) 위에 반투명 배경과
## 함께 그려서 전투가 끝난 뒤 화면을 재활용한다. NextButton은 아이템을 고르거나
## 건너뛰기 전까지는 숨겨서 보상을 먼저 보게 한다.
func _show_reward_ui() -> void:
	if _reward_items.is_empty():
		_reward_items = DiceItemPool.random_choices(2, RunState.player_attack_bag, RunState.player_defense_bag)

	_clear_reward_ui()
	next_button.hide()
	_add_reward_frame("승리 보상 — 다이스 아이템을 고르고 적용할 주머니를 선택하세요")

	# INBOX.md 피드백(2026-09-09) "덱보기 토글 또는 결과 선택지의 위치를 조정해서 ...
	# 겹치지 않도록 한다" — 덱 패널(DeckPanel, x=980~1240)이 결과 화면 도중 다시
	# 열리더라도 겹치지 않도록, 보상 카드 영역을 x=980 앞(140~960)에서 끝나게 좁힌다.
	var card_width := 380.0
	var card_height := 260.0
	var card_y := 185.0
	var card_x := [160.0, 560.0]
	for i in _reward_items.size():
		var item: Dictionary = _reward_items[i]
		var built := ItemCardStyle.build_card(item)
		var card: PanelContainer = built["card"]
		card.position = Vector2(card_x[i], card_y)
		card.size = Vector2(card_width, card_height)
		add_child(card)
		_reward_ui.append(card)

		var button_row: VBoxContainer = built["button_row"]

		if item.get("kind", "") == "upgrade_die":
			var upgrade_btn := Button.new()
			upgrade_btn.text = "다이스 획득 (인벤토리)"
			upgrade_btn.custom_minimum_size = Vector2(0, 38)
			upgrade_btn.pressed.connect(_on_reward_upgrade_chosen.bind(item))
			button_row.add_child(upgrade_btn)
			_reward_action_buttons.append(upgrade_btn)
			continue

		var atk_preview := ItemCardStyle.build_effect_preview(item, RunState.player_attack_bag)
		if atk_preview:
			button_row.add_child(atk_preview)
		var atk_applicable := DiceItemPool.is_applicable(item, RunState.player_attack_bag)
		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 적용" if atk_applicable else DiceItemPool.unavailable_reason(item)
		atk_btn.disabled = not atk_applicable
		atk_btn.custom_minimum_size = Vector2(0, 38)
		atk_btn.pressed.connect(_on_reward_chosen.bind(item, "attack"))
		button_row.add_child(atk_btn)
		_reward_action_buttons.append(atk_btn)

		var def_preview := ItemCardStyle.build_effect_preview(item, RunState.player_defense_bag)
		if def_preview:
			button_row.add_child(def_preview)
		var def_applicable := DiceItemPool.is_applicable(item, RunState.player_defense_bag)
		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 적용" if def_applicable else DiceItemPool.unavailable_reason(item)
		def_btn.disabled = not def_applicable
		def_btn.custom_minimum_size = Vector2(0, 38)
		def_btn.pressed.connect(_on_reward_chosen.bind(item, "defense"))
		button_row.add_child(def_btn)
		_reward_action_buttons.append(def_btn)

	var custom_btn := Button.new()
	custom_btn.text = "커스터마이징: 눈금 교환"
	custom_btn.position = Vector2(160, card_y + card_height + 15)
	custom_btn.size = Vector2(340, 40)
	custom_btn.pressed.connect(_open_customize_from_reward)
	add_child(custom_btn)
	_reward_ui.append(custom_btn)
	_reward_action_buttons.append(custom_btn)

	var skip_btn := Button.new()
	skip_btn.text = "건너뛰기"
	skip_btn.position = Vector2(560, card_y + card_height + 15)
	skip_btn.size = Vector2(160, 40)
	skip_btn.pressed.connect(_on_reward_skipped)
	add_child(skip_btn)
	_reward_ui.append(skip_btn)
	_reward_action_buttons.append(skip_btn)

	_rebuild_shortcuts()


## 공통 배경+제목 프레임을 그린다 (보상 화면의 3단계 — 아이템 선택 / 다이스 선택 /
## 면 선택 — 모두 이 위에 그려서 화면을 재활용한다). D8~D12처럼 면이 많은 다이스는
## 얼굴 그리드가 두 줄이 될 수 있어 height를 늘려 부를 수 있게 함(기본 420).
func _add_reward_frame(title_text: String, height: float = 420.0) -> void:
	# INBOX.md 피드백(2026-09-09) — 폭을 980(DeckPanel 왼쪽 끝)보다 좁게 잡아 덱 패널이
	# 결과 화면 중에 다시 열려도 겹치지 않게 한다 (위 card_x 주석 참고).
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.position = Vector2(140, 120)
	bg.size = Vector2(820, height)
	add_child(bg)
	_reward_ui.append(bg)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(170, 140)
	title.size = Vector2(760, 30)
	add_child(title)
	_reward_ui.append(title)


func _clear_reward_ui() -> void:
	for node in _reward_ui:
		node.queue_free()
	_reward_ui.clear()
	_reward_action_buttons.clear()


## shop.gd/event.gd(이터레이션 45)와 같은 이유의 이중 실행 가드. _clear_reward_ui()가
## queue_free()로 카드/버튼을 지우는데 이는 그 프레임 끝까지 실제로는 트리에 남아있어
## 클릭 가능한 상태다 — 가드 없이는 버튼을 빠르게 두 번 누르면(더블클릭 등) 같은
## 아이템이 두 번 적용되거나(dict가 bind()로 같은 item/target을 물고 있음) 골드/눈금
## 보상과 달리 재검증 수단(예: shop의 "골드 부족")이 없어 조용히 중복 적용될 수 있었다.
## _apply_room_advance()/_apply_pick()과 같은 패턴으로 상태 변경(_apply_reward_choice)과
## UI 갱신(_on_reward_chosen)을 분리해, @onready 노드 없이도(script.new()) 가드만
## 회귀 테스트로 검증할 수 있게 한다. "선택"과 "건너뛰기"는 이 보상 단계의 한 번뿐인
## 결정을 같은 플래그로 공유한다.
func _apply_reward_choice(item: Dictionary, target: String) -> bool:
	if _reward_resolved:
		return false
	_reward_resolved = true
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	return true


func _apply_reward_skip() -> bool:
	if _reward_resolved:
		return false
	_reward_resolved = true
	return true


## upgrade_die 아이템(공격/방어 어느 주머니에도 즉시 속하지 않고 RunState.die_inventory에
## 바로 쌓임) 전용 — _apply_reward_choice와 같은 이중 실행 가드(_reward_resolved)를 공유한다.
func _apply_reward_upgrade(item: Dictionary) -> bool:
	if _reward_resolved:
		return false
	_reward_resolved = true
	DiceItemPool.apply_upgrade_gain(item)
	return true


func _on_reward_chosen(item: Dictionary, target: String) -> void:
	if not _apply_reward_choice(item, target):
		return
	_append_log("아이템 획득: %s (%s 주머니)" % [item["name"], "공격" if target == "attack" else "방어"])
	_clear_reward_ui()
	next_button.show()
	_rebuild_shortcuts()


func _on_reward_upgrade_chosen(item: Dictionary) -> void:
	if not _apply_reward_upgrade(item):
		return
	_append_log("아이템 획득: %s (인벤토리)" % item["name"])
	_clear_reward_ui()
	next_button.show()
	_rebuild_shortcuts()


func _on_reward_skipped() -> void:
	if not _apply_reward_skip():
		return
	_clear_reward_ui()
	next_button.show()
	_rebuild_shortcuts()


## 승리 보상 화면에서 "커스터마이징" 버튼을 누르면 다른 화면들과 동일한 공용
## CustomizePanel 오버레이를 그대로 연다 (더 이상 이 화면만의 별도 다이스/면/값 선택
## 체인을 두지 않음). 보상 아이템 버튼들은 미리 치워두고, 패널이 닫히면(closed 시그널)
## _on_customize_panel_closed()가 next_button을 다시 보여줘 보상 흐름을 마무리한다.
func _open_customize_from_reward() -> void:
	_clear_reward_ui()
	_rebuild_shortcuts()
	customize_panel.open()


## customize_panel.closed 시그널 핸들러. 전투 중(승패 전) 상단 토글 버튼으로 열고
## 닫을 때도 이 시그널이 발생하지만, 그때는 battle_over가 false이므로 아무 일도
## 일어나지 않는다 — 승리 보상 화면에서 연 경우에만 next_button을 다시 보여준다.
func _on_customize_panel_closed() -> void:
	if battle_over and player_won:
		next_button.show()
		_rebuild_shortcuts()


## QA 전용 — 실제 InputEventKey를 만들어 _unhandled_input()에 직접 넣는 방식으로,
## shop.gd/dungeon_map.gd 등에서 쓴 것과 같은 검증(키 입력 -> 버튼 클릭과 동일한 결과)을
## combat_test에도 적용한다. "다음" 버튼은 눌리면 change_scene_to_file()로 dungeon_map
## 씬으로 전환하는 버튼이라(2026-09-15 (105)에서 발견한 크래시 패턴과 동일 계열),
## 패배 상태를 강제로 만들어 이 버튼이 숫자 키로도 크래시 없이 실제 씬 전환까지
## 이어지는지 확인하는 용도.
func _debug_press_shortcut_next() -> void:
	battle_over = true
	player_won = false
	next_button.text = "처음부터 다시"
	next_button.show()
	_rebuild_shortcuts()
	var idx := _shortcut_buttons.find(next_button)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_1 + idx
	_unhandled_input(key)


## QA 전용 — 승리 보상 화면(카드 버튼들)에서 숫자 키로 "건너뛰기" 버튼을 실제로 누르면
## 카드가 정리되고 next_button이 다시 나타나는지 확인한다(건너뛰기 자체는 씬을 바꾸지
## 않아 크래시 우려는 없지만, 동적으로 구성이 바뀌는 _reward_action_buttons 기반 단축키
## 배정이 실제로 올바른 인덱스를 가리키는지 검증하는 용도).
func _debug_press_shortcut_skip() -> void:
	battle_over = true
	player_won = true
	_show_reward_ui()
	# "건너뛰기" 버튼은 항상 _reward_action_buttons의 마지막 자리(카드 버튼들 -> 커스터마이징
	# -> 건너뛰기 순)이고, _shortcut_buttons도 _reward_action_buttons를 그대로 앞에 이어붙이므로
	# 같은 인덱스를 그대로 쓸 수 있다.
	var idx := _reward_action_buttons.size() - 1
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_1 + idx
	_unhandled_input(key)


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅 (dungeon_map.gd의
## _debug_open_customize와 같은 목적 — 전투 중 언제든 열 수 있는 CustomizePanel
## 오버레이가 실제로 열리는지 확인).
func _debug_open_customize() -> void:
	customize_panel.open()


## QA 전용 — INBOX.md 피드백(2026-09-03) "커스터마이징은 전투 중에는 불가능해야 한다"
## 검증용. 이전(2026-09-03 (10)) 조사 당시에는 이 훅이 "버튼이 실수로 안 열리는 게
## 아닌지" 확인하는 용도였지만, 이번에 사용자가 요구사항을 뒤집어 이제는 반대로
## "battle_over=false일 때 정말로 안 열리는지"를 확인하는 용도로 쓴다. GAME_QA_CALL은
## 메서드를 직접 호출할 뿐 실제 마우스 클릭을 흉내내지 않으므로, visible만으로는
## "숨겨서 못 누르게 함"과 "핸들러 자체가 막음"을 구별 못 한다 — 그래서 emit_signal로
## pressed를 강제로 발생시켜서, 핸들러의 battle_over 체크가 실제로 막는지까지 확인한다.
func _debug_verify_customize_button_during_battle() -> void:
	print("[customize_btn_check] visible=%s disabled=%s mouse_filter=%s battle_over=%s" % [
		customize_toggle_button.visible, customize_toggle_button.disabled,
		customize_toggle_button.mouse_filter, battle_over,
	])
	customize_toggle_button.emit_signal("pressed")
	print("[customize_btn_check] panel_visible_after_press=%s" % customize_panel.visible)


## QA 전용 — 실제 플레이로 승리해 얻은 진짜 눈금 보상으로 커스터마이징 화면을 열어
## 보이는지 확인하기 위함 (frame을 충분히 늦게 잡아 승리 보상 화면이 이미 떠 있는
## 상태에서 호출됨을 전제로 함).
func _debug_open_reward_customize() -> void:
	_open_customize_from_reward()


## QA 전용 — 승리 보상 화면에서 커스터마이징을 열고 닫았을 때 next_button이 다시
## 나타나는지(보상 흐름 복귀)는 스크린샷 한 장으로 보이지 않는 시점 차이라 콘솔로 검증.
func _debug_verify_reward_customize_flow() -> void:
	battle_over = true
	player_won = true
	next_button.hide()
	_open_customize_from_reward()
	var hidden_while_open := not next_button.visible
	customize_panel.close()
	print("[reward_customize_check] hidden_while_open=%s visible_after_close=%s (기대: true, true)" % [hidden_while_open, next_button.visible])


## QA 전용 — INBOX.md 피드백(2026-09-09) "덱보기 토글 또는 결과 선택지의 위치를
## 조정해서 ... 겹치지 않도록 한다" 검증용. 정상 플레이로 승리 보상 화면까지 도달한
## 뒤 덱 패널을 다시 여는 것은 물리 정지 대기 때문에 느리므로, 보상 화면을 강제로
## 띄우고 덱 패널을 곧바로 연 상태로 스크린샷 한 장에서 겹침 여부를 확인한다.
func _debug_show_reward_with_deck_open() -> void:
	battle_over = true
	player_won = true
	_show_reward_ui()
	deck_panel.visible = true
	deck_toggle_button.text = "덱 닫기"
	_rebuild_shortcuts()


## QA 전용 — 이 세션 환경에서 스크린샷 캡처 폭이 1280px 대신 1028px로 잘리는 현상
## 때문에 화면 오른쪽 끝(x>=980)의 DeckPanel(캐릭터 정보 섹션 포함, 2026-09-15 신규)이
## 매번 잘려서 안 보임 — 확인용으로 패널을 화면 왼쪽으로 옮기고 열어서 캡처한다
## (게임 로직에는 영향 없음, dungeon_map.gd의 _debug_move_deck_panel_left와 같은 이유).
func _debug_move_deck_panel_left() -> void:
	deck_panel.offset_left = 20.0
	deck_panel.offset_right = 280.0
	deck_panel.visible = true
	deck_toggle_button.text = "덱 닫기"


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용). 정상
## 플레이로는 다이스가 D6/D8/D10으로 섞이려면 승리 보상을 여러 번 받아야 해서 확인이
## 느리므로, 공격 주머니 다이스 3개를 강제로 D6/D8/D10으로 바꾸고 즉시 다시 스폰해
## 물리 다이스 모양이 실제 면 개수를 따라가는지(Die.sides 배선) 스크린샷 한 장으로
## 바로 확인하기 위함.
func _debug_show_mixed_dice_shapes() -> void:
	RunState.player_attack_bag.replace_die(0, 6)
	RunState.player_attack_bag.replace_die(1, 8)
	RunState.player_attack_bag.replace_die(2, 10)
	_clear_dice()
	_spawn_dice(RunState.player_attack_bag, -1.4)
	_spawn_dice(RunState.player_defense_bag, 1.4)
	# QA 캡처는 스폰 직후 1프레임만 지나 찍히므로(물리가 정지할 시간이 없음), 다이스가
	# 낙하/회전 중인 흐릿한 모습 대신 모양을 또렷이 보이도록 그 자리에서 얼린다.
	var i := 0
	for child in dice_root.get_children():
		if child is RigidBody3D:
			child.freeze = true
			child.rotation = Vector3(0.4, i * 0.6, 0.3)
			i += 1


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용). 다이스가
## 여럿 뒤섞인 `_debug_show_mixed_dice_shapes()`는 다이스끼리 겹쳐 보여서 개별 모양
## (특히 새로 추가한 D10)이 뚜렷이 구별되는지 확인하기 어려우므로, D10 하나만 화면
## 중앙에 크게 띄워 지오메트리(면 개수/구멍 유무)를 또렷이 확인하기 위함.
func _debug_show_single_d10() -> void:
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = 10
	die.die_size = 0.6
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(0, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 디버그 전용 — `_debug_show_single_d10()`과 같은 패턴으로 D12(정십이면체) 하나를
## 화면 중앙에 크게 띄워 위상 오류(구멍, 뒤집힌 면) 없이 렌더링되는지 육안 확인한다.
func _debug_show_single_d12() -> void:
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = 12
	die.die_size = 0.6
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(0, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 디버그 전용 — `_debug_show_single_d10()`/`_debug_show_single_d12()`와 같은
## 패턴으로 D20(정이십면체) 하나를 화면 중앙에 크게 띄워 위상 오류(구멍, 뒤집힌 면)
## 없이 렌더링되는지 육안 확인한다.
func _debug_show_single_d20() -> void:
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = 20
	die.die_size = 0.6
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(0, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 디버그 전용 — 재질별 시각 색(visual_color) 추가 검증용. D4(플라스틱)/D8(나무)/
## D10(유리)/D12(철제) 하나씩을 나란히 띄우고 `_material_for_sides()`로 실제 게임과
## 동일하게 재질을 배정해, 네 재질이 눈으로 뚜렷이 구별되는지 한 장으로 확인한다.
func _debug_show_material_swatch() -> void:
	_clear_dice()
	var sides_list := [4, 8, 10, 12]
	for i in sides_list.size():
		var die := DieScene.instantiate()
		die.sides = sides_list[i]
		die.die_size = 0.5
		var material := _material_for_sides(die.sides)
		if material != null:
			die.material = material
		dice_root.add_child(die)
		die.transform = Transform3D(Basis(), Vector3(-1.8 + i * 1.2, 1.0, 0))
		die.freeze = true
		die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 디버그 전용 — 몬스터 다이스 면 개수(sides) 스케일링(_monster_dice_sides_for_room())
## 검증용. GAME_QA_CALL은 _ready() 이후(즉 몬스터 주머니가 이미 room 0 기준으로
## 만들어진 뒤)에, 그리고 settle 대기보다 나중에 실행되므로, 새로 스폰한 다이스는
## 떨어지는 도중일 수 있다 — _debug_show_material_swatch()와 같은 패턴으로 freeze=true를
## 줘서 낙하 중간 프레임이 찍히지 않고 항상 같은 자세로 보이게 한다.
func _debug_show_monster_dice_for_room(room_index: int) -> void:
	var config := _monster_config_for_room(room_index)
	var sides: int = config["dice_sides"]
	monster_attack_bag = DiceBag.new(sides, config["attack_count"])
	_clear_dice()
	var count: int = config["attack_count"]
	for i in count:
		var die := DieScene.instantiate()
		die.sides = sides
		die.color_override = config["color"]
		var material := _material_for_sides(sides)
		if material != null:
			die.material = material
		dice_root.add_child(die)
		die.transform = Transform3D(Basis(), Vector3(-1.0 + i * 1.0, 1.0, 0))
		die.freeze = true
		die.rotation = Vector3(0.5, 0.6, 0.0)


## GAME_QA_CALL은 인자 없는 메서드만 호출할 수 있어 각 room_index별로 래퍼를 둔다.
func _debug_show_monster_dice_room4() -> void:
	_debug_show_monster_dice_for_room(4)


## GAME_QA_CALL 전용 — "anger_stack" 기믹이 임계치(ANGER_STACK_THRESHOLD)에 도달해
## 다음 몬스터 공격이 1D20으로 바뀌는 상태를 보여준다. 실제 트리거는 몬스터 공격 다이스가
## 우연히 최댓값 면을 여러 번 보여줘야 하는 확률적 사건이라 한 프레임짜리 QA 캡처로는
## 재현을 기다릴 수 없고, GAME_QA_CALL은 _do_exchange()의 await 체인이 끝나기 전에
## 스크린샷을 찍어버리므로(한 프레임만 대기) 다른 _debug_show_* 훅들과 같은 패턴으로
## D20 다이스를 직접 얼려서 스폰해 모양/재질/문구만 확인한다.
func _debug_show_anger_dice() -> void:
	monster_dice_gimmick = "anger_stack"
	monster_anger_stacks = ANGER_STACK_THRESHOLD
	monster_anger_pending = true
	monster_name = "고블린 [분노]"
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = ANGER_DICE_SIDES
	die.color_override = monster_color
	var material := _material_for_sides(ANGER_DICE_SIDES)
	if material != null:
		die.material = material
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(-1.0, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)
	# 실제 _do_exchange()와 동일하게 turn_label이 아니라 로그(_append_log)로 알린다 —
	# turn_label은 짧은 "누구 턴인지"만 담당하는 자리(폭 400px, 중앙 정렬)라 이 문구처럼
	# 긴 텍스트를 넣으면 옆의 MonsterHPLabel과 시각적으로 붐빌 수 있음.
	_append_log("몬스터가 분노했다! 다음 공격은 20면체 주사위로 굴린다")
	_update_labels()


## GAME_QA_CALL 전용 — 플레이어 캐릭터 "폭발병"의 explosive_stack 기믹이 임계치에
## 도달해 다음 플레이어 공격이 1D20으로 바뀌는 상태를 보여준다(_debug_show_anger_dice()와
## 완전히 같은 이유/패턴 — 우연히 최댓값이 여러 번 나와야 하는 확률적 사건이라 한
## 프레임짜리 QA 캡처로는 자연 발생을 기다릴 수 없어 상태를 직접 만들고 D20을 얼려서
## 스폰한다).
func _debug_show_explosive_dice() -> void:
	player_dice_gimmick = "explosive_stack"
	player_explosive_stacks = EXPLOSIVE_STACK_THRESHOLD
	player_explosive_pending = true
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = EXPLOSIVE_DICE_SIDES
	var material := _material_for_sides(EXPLOSIVE_DICE_SIDES)
	if material != null:
		die.material = material
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(-1.4, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)
	_append_log("폭발 직전! 다음 공격은 20면체 주사위로 터진다")
	_update_labels()


## GAME_QA_CALL 전용 — 플레이어 캐릭터 "방패병"의 guard_stack 기믹이 임계치에 도달해
## 다음 플레이어 방어가 1D20으로 바뀌는 상태를 보여준다(_debug_show_explosive_dice()와
## 완전히 같은 이유/패턴).
func _debug_show_guard_dice() -> void:
	player_dice_gimmick = "guard_stack"
	player_guard_stacks = GUARD_STACK_THRESHOLD
	player_guard_pending = true
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = GUARD_DICE_SIDES
	var material := _material_for_sides(GUARD_DICE_SIDES)
	if material != null:
		die.material = material
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(1.4, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)
	_append_log("수호 태세 완성! 다음 방어는 20면체 주사위로 굳건해진다")
	_update_labels()


## QA 전용 래퍼 — 패배 시 표정(플레이어 분노, 몬스터 기쁨)을 스크린샷으로 확인하기
## 위함. randi() 기반 분노/슬픔 분기 중 "분노" 쪽을 강제로 보여준다.
func _debug_show_defeat_expressions() -> void:
	player_portrait.set_expression("angry")
	monster_portrait.set_expression("happy")


