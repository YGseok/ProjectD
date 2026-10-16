extends Node2D
## 특수 이벤트 방 (INBOX.md [미니 기획 B] 2~3번, 2026-09-16).
##
## 예전에는 무작위 2개 중 하나를 무료로 골라 즉시 획득하는 방식이었는데(리스크 없음),
## 이제 선택지를 항상 2개로 통일한다 — "안전하게 넘어가기"(리스크 없음, 확정 C급 아이템)
## / "위험을 감수하기"(RunState.event_die_sides를 1회 굴려 DC와 비교, 성공하면 A/S급
## 무작위 1개, 실패하면 보상 없음). DC = min(5, 3 + room_index / 2) — DESIGN.md에
## 명시된 정수 나눗셈 공식 그대로(room_index는 RunState.rooms_cleared와 동일 기준).
##
## systems/event_item_pool.gd(EventItemPool)의 등급(grade) 필터로 안전/위험 풀을
## 나누고, apply()는 DiceItemPool.apply()를 그대로 재사용한다(item dict 형식이 같음).
## 아이템을 실제로 주머니에 넣거나 인벤토리에 담는 로직(_apply_pick/_apply_pips/
## _apply_upgrade, _on_pick_* 핸들러)은 예전 구현을 그대로 유지했다 — dice_test.gd의
## 기존 회귀 테스트가 이 함수들을 직접 호출해 이중 실행 가드를 검증하므로, 시그니처와
## 동작을 바꾸지 않아야 그 테스트들이 계속 유효하다.
##
## [미니 기획 C]-1(INBOX.md, 2026-09-16, "새 방 종류를 만들지 않고 기존 물음표 이벤트가
## 가끔 스킬 이벤트로도 나오게 한다"): _ready()에서 SKILL_EVENT_CHANCE 확률로 이번
## 인스턴스가 "아이템 이벤트"(_setup_item_event, 위 문단의 안전/위험 흐름) 대신
## "스킬 이벤트"(_setup_skill_event)가 되도록 분기한다. 방을 고르는 시점의 아이콘은
## 여전히 물음표 하나뿐이라(reward_icon.gd의 "mystery") 어느 쪽이 나올지 미리 알 수
## 없다 — 스포일링 방지 요구사항과 그대로 호환된다. systems/skill_pool.gd(SkillPool)가
## 후보 정의를 담당.
##
## [미니 기획 D]-3(INBOX.md, 2026-09-17): 위 두 분기보다 먼저, 이 방이 "스킬 강화"
## 이벤트가 될지를 별도 확률(SKILL_UPGRADE_EVENT_CHANCE)로 한 번 더 굴린다.
## SkillPool.available_upgrade_choices()가 빈 배열이면(강화할 base 스킬이 아예 없거나
## 전부 이미 강화됨) 확률과 무관하게 항상 기존 흐름(스킬 이벤트 또는 아이템 이벤트)으로
## 대체된다 — "강화 가능한 스킬이 하나도 없으면 반드시 기존 이벤트로 대체" 지시 반영.
## 카드 UI는 기존 _setup_skill_event()가 쓰던 _show_skill_offer()/_on_pick_skill_pressed()/
## _apply_skill_pick()을 그대로 재사용한다 — UPGRADE_SKILLS 항목도 SKILLS/UNIQUE_SKILLS와
## 같은 {id, name, description} 형태라 별도 처리가 필요 없다(강화판 자신의 "+"id를
## skill_flags에 추가하면 그대로 강화 완료).
##
## [대형 기획 14] N-5(a)(INBOX.md 2026-10-15, 곡예사를 이벤트 특화 클래스로): 곡예사
## 전용 시작/고유 스킬 3종(눈속임/한탕/곡예 흥행(+))이 이 "위험을 감수하기" 판정에
## 직접 끼어든다 — ① "눈속임"(start_sleight)/"승부사"(start_gambler, 매혹사)는
## gambler_adjusted_dc() 호출 시 OR로 함께 확인해 DC를 1 낮춘다(둘 다 효과가 같아
## 함수 자체는 그대로, 호출 조건만 확장) ② "곡예 흥행"(juggle_fortune)/"곡예 흥행+"
## (juggle_fortune_plus)은 event_roll_bonus() 순수 함수로 주사위 굴림 결과에 +1/+2
## 보정을 더한다(_on_risky_pressed()에서만 적용 — QA 훅 _debug_force_risky_*는 결정적
## 재현이 목적이라 보정 없이 그대로 둠) ③ "한탕"(start_fortune)은 판정 성공 시
## FORTUNE_GOLD_BONUS 골드를 추가로 준다(_resolve_risky()).
##
## [대형 기획 14] N-5(b)(INBOX.md 2026-10-15, 이벤트 판정 콘텐츠 확충 + 대성공): 위
## N-5(a)가 남긴 "판정이 '보물' 한 상황에만 쓰여서 D12 곡예사의 체감 이득이 성공률
## 하나뿐"인 문제를 두 가지로 해결한다. ① systems/event_challenge_pool.gd
## (EventChallengePool)의 데이터 표 CHALLENGES에 도박/탐색/함정 해체 3종을 추가해
## "위험을 감수하기"가 매번 다른 상황(보물/도박/탐색/함정 해체 무작위 1개, _ready()가
## 고름)으로 나오게 한다 — 보상 종류(아이템/골드/눈금)만 바뀌고 판정 로직은
## EventChallengePool.tier_for_roll()/roll_reward() 하나를 전부 공유(종류별 하드코딩
## 없음). ② tier_for_roll()이 "대성공"(roll >= DC + CRIT_MARGIN) 단계를 추가로 반환해
## success_reward보다 더 좋은 crit_reward를 준다 — CRIT_MARGIN이 모든 종류 공통이라
## D6 클래스는 사실상 대성공이 불가능(최댓값 6 < DC+3=8, 방 4 이상)인 반면 D12
## 곡예사는 약 42% 확률로 대성공한다(dice_test.gd 확률 비교 검증 참고). DC 보정(눈속임/
## 승부사)·굴림 보정(곡예 흥행(+))·성공 보너스(한탕)는 챌린지 종류와 무관하게 그대로
## 전부 적용된다(_dc는 종류 선택 전에 한 번만 계산, event_roll_bonus/FORTUNE_GOLD_BONUS는
## tier 분기 전에 적용).
##
## [대형 기획 14] N-6(2026-10-16, INBOX.md "남은 이슈" 최종 조각): 캐릭터 전용 이벤트 +
## 특별 선택지. CHALLENGES 추첨을 "randi() % size"(전역 RNG, 재현 불가)에서
## EventChallengePool.pick_challenge(character_id, rng)로 교체해 run_seed+방 번호로
## 시드한 RandomNumberGenerator 하나로 "전용 이벤트 대체 여부 + 최종 챌린지"까지 전부
## 결정적으로 만든다(challenge_seed(), 아래) — 같은 런의 같은 방이면 테스트 전투/QA
## 시드에서도 항상 같은 챌린지가 나온다. 선택된 챌린지가 only_characters를 가지면
## (= 전용 이벤트, 이 캐릭터만 볼 수 있음) 제목에 "(이름 전용)" 배지를 붙이고
## (_setup_item_event()), special_choice가 있으면 safe/risky 버튼 아래 세 번째
## 선택지를 추가로 그린다(_build_special_choice_button()) — 소유 캐릭터(RunState.
## character_id가 requires_character에 있음)에게는 활성(굴림 없이 즉시 reward 획득,
## 그 challenge의 safe_reward보다 같은 type 기준으로 더 크다), 그 외에게는 잠김
## (자물쇠 문구 + 흐린 효과 설명, pressed 미연결이라 방향키로 포커스는 가지만 Space를
## 눌러도 아무 일도 일어나지 않는다 — character_select.gd의 잠긴 시작 스킬 슬롯과 같은
## "포커스는 가능, 실행은 불가" 패턴).

@onready var items_root: Node2D = $ItemsRoot
@onready var roll_root: Node2D = $RollRoot
@onready var customize_button: Button = $CustomizeButton
@onready var customize_panel: CustomizePanel = $CustomizePanel
@onready var skill_codex_button: Button = $SkillCodexButton
@onready var skill_codex_panel: SkillCodexPanel = $SkillCodexPanel
@onready var title_label: Label = $Title
@onready var prompt_label: Label = $PromptLabel
@onready var safe_button: Button = $SafeButton
@onready var risky_button: Button = $RiskyButton
@onready var fail_label: Label = $FailLabel
@onready var continue_button: Button = $ContinueButton

## 이 방이 이번에 "스킬 이벤트"(아이템 대신 스킬 후보 2개 중 1개 선택)로 나올 확률
## (INBOX.md [미니 기획 C]-1, 2026-09-16). 물음표 아이콘은 그대로라 방을 고르기
## 전엔 어느 쪽인지 알 수 없다(스포일링 방지, 기존 물음표 아이콘 항목과 일관성 유지).
## SkillPool.available_choices()가 빈 배열을 돌려주면(후보를 전부 이미 보유) 확률과
## 무관하게 항상 아이템 이벤트로 대체된다. 수치 자체는 감으로 잡은 잠정값 — 실제
## 등장 빈도가 적당한지는 사람 플레이 피드백 필요.
const SKILL_EVENT_CHANCE := 0.3

## 이 방이 이번에 "스킬 강화" 이벤트(이미 보유한 스킬 중 하나를 "+"판으로 강화)로
## 나올 확률([미니 기획 D]-3). SKILL_EVENT_CHANCE와 완전히 별개의 독립된 굴림 —
## 두 확률이 동시에 이 방에 적용되는 게 아니라, 강화 이벤트 판정이 먼저이고 실패하면
## (또는 강화 후보가 없으면) 그 다음에 기존 스킬/아이템 이벤트 분기로 넘어간다.
## 수치는 기획자가 지시한 "예시로 든 20%" 그대로 — 잠정값, 실제 등장 빈도가 적당한지는
## 사람 플레이 피드백 필요.
const SKILL_UPGRADE_EVENT_CHANCE := 0.2

## N-5(a) "한탕"(start_fortune, 곡예사 전용 시작 스킬): "위험을 감수하기" 성공 시 주는
## 추가 골드. 전투 승리 보상(`combat_test.GOLD_REWARD_BASE`=8)과 비슷한 체감 크기로
## 잡은 잠정값 — 실제 밸런스는 사람 플레이 피드백 필요.
const FORTUNE_GOLD_BONUS := 10

## N-5(a) "곡예 흥행"/"곡예 흥행+"(juggle_fortune/juggle_fortune_plus, 곡예사 전용
## 고유 스킬 쌍): 이벤트 주사위 굴림 결과 보정치.
const JUGGLE_FORTUNE_ROLL_BONUS := 1
const JUGGLE_FORTUNE_PLUS_ROLL_BONUS := 2

## 이번 인스턴스가 스킬 강화 이벤트인지 — _ready()에서 한 번만 정해지고 이후 바뀌지
## 않는다. true면 _is_skill_event 여부와 무관하게 강화 카드가 표시된다.
var _is_skill_upgrade_event := false

## 이번 인스턴스가 스킬 이벤트인지(true) 아이템 이벤트인지(false) — _ready()에서
## 한 번만 정해지고 이후 바뀌지 않는다.
var _is_skill_event := false

## 안전/위험 중 하나를 이미 골랐는지(중복 클릭으로 두 선택지가 동시에 진행되는 것을
## 막음) — _picked(아래, 아이템 적용/실패 계속 단계의 이중 실행 가드)와는 별개 지점이라
## 별도 플래그가 필요하다.
var _choice_made := false
## 아이템 적용(_apply_pick/_apply_pips/_apply_upgrade) 또는 실패 후 "계속"의 이중 실행
## 방지 가드 — 예전 event.gd의 _picked와 동일한 이름/역할을 유지(테스트 호환).
var _picked := false

var _dc: int
var _row_ui: Array[Node] = []
var _shortcut_buttons: Array[Button] = []

## N-5(b): 이번 인스턴스가 "위험을 감수하기" 분기로 들어갔을 때 어떤 상황(보물/도박/
## 탐색/함정 해체)인지 — _ready()에서 EventChallengePool.CHALLENGES 중 무작위 1개로
## 정해지고(스킬 이벤트/스킬 강화 이벤트로 빠지면 쓰이지 않음) 이후 바뀌지 않는다.
## 기본값은 0번(treasure) — _debug_force_risky_* QA 훅이 _ready() 거치지 않고(또는
## 거친 뒤 덮어써서) 결정적으로 재현할 때도 항상 유효한 값을 갖는다.
var _challenge: Dictionary = EventChallengePool.CHALLENGES[0]

## N-6: _challenge.special_choice가 있을 때 safe/risky 아래에 그려지는 세 번째
## 선택지 버튼 — _setup_item_event()가 호출될 때마다(최초 또는 _debug_force_challenge())
## 새로 만들어지므로, 이전 것을 지우기 위해 참조를 들고 있는다(없으면 null).
var _special_button: Button = null

## N-6: run_seed+방 번호로 챌린지 선택을 결정적으로 만드는 시드 공식 — 몬스터 플랜
## (run_state.gd의 ELITE_SEED_OFFSET)이나 던전 맵 방 선택지(dungeon_map.gd의
## idx*104729+7, run_seed 미포함)와 오프셋을 분리해 "이 시드가 어디서 왔는지"
## 추적하기 쉽게 한다(실제로 겹쳐도 서로 다른 RandomNumberGenerator 인스턴스라
## 문제는 없음).
const CHALLENGE_SEED_OFFSET := 50021

static func challenge_seed(run_seed: int, room_index: int) -> int:
	return run_seed + room_index * 104729 + CHALLENGE_SEED_OFFSET


func _ready() -> void:
	# L-3(2026-10-14, [대형 기획 12] K-3 후속): 배경/제목을 현재 캐릭터 퍼스널 컬러로.
	# M-5(b): resources/backgrounds/event.png가 있으면 그 사진을 깐다(없으면 폴백).
	CharacterTheme.apply_background(self, RunState.character_id, false, 0.25, "event")
	CharacterTheme.apply_label(title_label, RunState.character_id)
	# N-5(a): "눈속임"(곡예사)도 "승부사"(매혹사)와 동일하게 DC -1을 적용 — 둘 다
	# 효과가 같아 함수는 그대로 재사용하고 OR 조건만 넓힌다(한 런에 둘 다 가질 수는
	# 없지만(캐릭터별 전용 시작 스킬), 둘 다 없어도/둘 다 있어도 안전하게 동작).
	_dc = gambler_adjusted_dc(difficulty_for_room(RunState.rooms_cleared), RunState.skill_flags.has("start_gambler") or RunState.skill_flags.has("start_sleight"))
	customize_button.pressed.connect(customize_panel.open)
	skill_codex_button.pressed.connect(_on_skill_codex_pressed)
	fail_label.hide()
	continue_button.hide()
	continue_button.pressed.connect(_on_continue_after_fail_pressed)
	# [대형 기획 13] M-4 — 던전 맵/전투와 같은 버튼 위계로 통일. "계속"(실패 후 유일한
	# 진행 행동)만 주 행동, 나머지는 보조. 안전/위험은 서로 대등한 두 선택지라 등급 대신
	# tint로 의미(안전=초록/위험=주황-빨강)를 더한다 — dungeon_map의 정예 전투 빨간
	# tint와 같은 패턴. 카드 안 버튼(적용/획득)들은 그릴 때마다 _show_item_offer/
	# _show_skill_offer에서 개별 스타일링.
	UIKit.style_secondary_button(safe_button, RunState.character_id, Color(0.3, 0.62, 0.35))
	UIKit.style_secondary_button(risky_button, RunState.character_id, Color(0.82, 0.38, 0.18))
	UIKit.style_primary_button(continue_button, RunState.character_id)
	UIKit.style_secondary_button(customize_button, RunState.character_id)
	UIKit.style_secondary_button(skill_codex_button, RunState.character_id)
	# "상황" 배경 프레임 — 기존 PromptLabel은 그대로 두고(테스트/참조 호환) 뒤에 깔아
	# dungeon_map/combat의 구역 패널과 시각 언어를 맞춘다(INBOX M-4 "구역 패널로 맞춘다").
	# [대형 기획 15] Q-1(23, 2026-10-16): 프레임 높이를 48->74로 키웠다 — PromptLabel이
	# EventChallengePool의 긴 prompt(최대 2줄, 실측 49px)를 autowrap으로 담도록
	# PromptLabel 자체도 60px로 키웠는데(이 밑 event.tscn의 offset_top/bottom 참고),
	# 프레임이 그대로 48이면 2줄짜리 prompt가 프레임 밖으로 삐져나와 보인다.
	var prompt_backdrop := UIKit.make_backdrop(self, RunState.character_id, Rect2(Vector2(32, 62), Vector2(900, 74)))
	move_child(prompt_backdrop, 1)

	var upgrade_candidates := SkillPool.available_upgrade_choices(2, RunState.character_id)
	_is_skill_upgrade_event = not upgrade_candidates.is_empty() and randf() < SKILL_UPGRADE_EVENT_CHANCE
	if _is_skill_upgrade_event:
		_setup_skill_upgrade_event(upgrade_candidates)
		return

	var skill_candidates := SkillPool.available_choices(2, RunState.character_id)
	_is_skill_event = not skill_candidates.is_empty() and randf() < SKILL_EVENT_CHANCE
	if _is_skill_event:
		_setup_skill_event(skill_candidates)
	else:
		# N-5(b)/N-6: "위험을 감수하기" 상황을 고른다(보물/도박/탐색/함정 해체 중 1개,
		# 전용 이벤트가 있는 캐릭터는 EXCLUSIVE_EVENT_CHANCE로 그 캐릭터의 전용 이벤트로
		# 대체) — 다른 두 분기(스킬/스킬 강화)와 완전히 독립된 별도 굴림이라 서로
		# 확률에 영향을 주지 않는다. run_seed+방 번호로 시드해 같은 런의 같은 방이면
		# 항상 같은 챌린지가 나오게 한다(테스트 전투/QA 시드에서도 재현 가능해야 한다는
		# INBOX N-6 지시 반영).
		var challenge_rng := RandomNumberGenerator.new()
		challenge_rng.seed = challenge_seed(RunState.run_seed, RunState.rooms_cleared)
		_challenge = EventChallengePool.pick_challenge(RunState.character_id, challenge_rng)
		_setup_item_event()


## N-5(b): 제목/문구/보상 괄호 설명이 전부 _challenge(EventChallengePool.CHALLENGES의
## 항목 하나)에서 나온다 — "보물"이든 새로 추가된 종류든 이 함수는 전혀 분기하지 않고
## 그대로 동작한다(하드코딩 금지 원칙).
func _setup_item_event() -> void:
	title_label.text = "특수 이벤트 — %s" % _challenge["subtitle"]
	# N-6: 전용 이벤트(이 캐릭터만 볼 수 있는 챌린지)는 제목 옆에 배지를 붙인다 —
	# pick_challenge()가 전용 이벤트를 소유 캐릭터에게만 돌려주므로 only_characters
	# 목록을 따로 확인할 필요 없이 현재 RunState.character_id 이름만 쓰면 된다.
	if EventChallengePool.is_exclusive(_challenge):
		title_label.text += "  (%s 전용)" % CharacterProfiles.get_profile(RunState.character_id)["name"]
	prompt_label.text = _challenge["prompt"]
	safe_button.text = "안전하게 넘어가기 (%s)" % EventChallengePool.reward_blurb(_challenge["safe_reward"])
	risky_button.text = "위험을 감수하기 (D%d, %d+ 성공/%d+ 대성공)" % [
		RunState.event_die_sides, _dc, _dc + EventChallengePool.CRIT_MARGIN
	]
	safe_button.pressed.connect(_on_safe_pressed)
	risky_button.pressed.connect(_on_risky_pressed)
	# N-6: 이전 호출(최초 또는 _debug_force_challenge())이 만든 특별 선택지 버튼이
	# 남아있으면 지우고 이번 _challenge에 맞게 새로 만든다.
	if _special_button != null:
		_special_button.queue_free()
		_special_button = null
	_special_button = _build_special_choice_button()
	var offer_buttons: Array[Button] = [safe_button, risky_button]
	if _special_button != null:
		offer_buttons.append(_special_button)
	offer_buttons.append(customize_button)
	offer_buttons.append(skill_codex_button)
	_refresh_shortcuts(offer_buttons)


## N-6: _challenge에 special_choice가 있으면 그 상태(활성/잠김)에 맞는 세 번째
## 선택지 버튼을 safe/risky 버튼 아래에 만들어 돌려준다(없으면 null, 호출부가 그대로
## 건너뛴다). 활성(소유 캐릭터)은 굴림 없이 즉시 reward를 받는다(_on_special_pressed,
## _grant_reward() 재사용) — 잠긴 상태는 pressed를 연결하지 않아(INBOX "Space를 눌러도
## 실행되지 않는다") 방향키로 포커스는 갈 수 있지만 눌러도 아무 일도 안 일어나고,
## tooltip_text로 왜 안 되는지만 짧게 안내한다(character_select.gd의 잠긴 시작 스킬
## 슬롯과 같은 패턴).
func _build_special_choice_button() -> Button:
	if not EventChallengePool.has_special_choice(_challenge):
		return null
	var spec: Dictionary = _challenge["special_choice"]
	var active := EventChallengePool.special_choice_active_for(_challenge, RunState.character_id)
	var owner_names: Array[String] = []
	for cid in EventChallengePool.special_choice_requires(_challenge):
		owner_names.append(String(CharacterProfiles.get_profile(cid)["name"]))
	var owner_label := "/".join(owner_names)

	var btn := Button.new()
	# RiskyButton(x 660~1020)이 DeckPanel(x 980~)과 겹치는 기존의 작은 코너 겹침과
	# 달리, 이 버튼은 safe+risky 전체 폭(260~1020)만큼 넓어 그 겹침이 두드러진다 —
	# DeckPanel 좌측(980)보다 20px 여유를 두고 960에서 끝나도록 폭을 줄인다.
	btn.position = Vector2(260.0, 186.0)
	btn.size = Vector2(700.0, 76.0)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 2)
	btn.add_child(content)

	var title_row_label := Label.new()
	title_row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var desc_label := Label.new()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(620.0, 0.0)
	desc_label.add_theme_font_size_override("font_size", 12)

	if active:
		title_row_label.text = "%s 전용 — %s" % [owner_label, spec["label"]]
		title_row_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
		desc_label.text = String(spec["description"])
		desc_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
		UIKit.style_secondary_button(btn, RunState.character_id, Color(0.85, 0.68, 0.2))
		btn.pressed.connect(_on_special_pressed)
	else:
		title_row_label.text = "🔒 %s 선택 가능 — %s" % [owner_label, spec["label"]]
		title_row_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.63))
		desc_label.text = String(spec["description"])
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.53, 0.8))
		UIKit.style_secondary_button(btn, RunState.character_id, Color(0.35, 0.35, 0.38))
		btn.tooltip_text = "%s만 선택할 수 있는 특별 선택지입니다." % owner_label

	content.add_child(title_row_label)
	content.add_child(desc_label)
	add_child(btn)
	return btn


## N-6: 특별 선택지(활성 상태에서만 눌릴 수 있음 — 잠긴 상태는 _build_special_choice_button()
## 에서 pressed를 아예 연결하지 않아 이 함수가 호출될 일이 없다)를 고르면 굴림 없이
## 즉시 그 challenge의 special_choice.reward를 받는다. _grant_reward()를 그대로
## 재사용해 보상 화면(_show_item_offer/_show_simple_result)까지 안전/위험 성공 경로와
## 동일하게 보여준다.
func _on_special_pressed() -> void:
	if _choice_made:
		return
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	if _special_button != null:
		_special_button.hide()
	_grant_reward(_challenge["special_choice"]["reward"])


## [미니 기획 C]-1: 물음표 이벤트가 가끔 아이템 대신 스킬 후보를 제시한다. 안전/위험
## 선택지 자체가 없이(리스크 개념 없음 — [미니 기획 C]-5가 "안전/위험 선택 대신 후보
## 2개 중 1개 선택"으로 명시) 바로 카드를 보여준다.
func _setup_skill_event(skills: Array[Dictionary]) -> void:
	title_label.text = "특수 이벤트 — 새로운 능력을 배울 기회"
	prompt_label.text = "낯선 기운이 스며든다. 후보 중 하나를 익힐 수 있을 것 같다."
	safe_button.hide()
	risky_button.hide()
	_show_skill_offer(skills)


## [미니 기획 D]-3: 물음표 이벤트가 가끔 이미 보유한 스킬을 "+"판으로 강화할 기회를
## 제시한다. _setup_skill_event()와 마찬가지로 안전/위험 선택지 없이 바로 카드를
## 보여주고, 카드/픽업 로직 자체는 _show_skill_offer()/_on_pick_skill_pressed()를
## 그대로 재사용한다 — UPGRADE_SKILLS 항목도 {id, name, description} 형태라 별도 처리가
## 필요 없다.
## _is_skill_upgrade_event를 여기서도 true로 세팅한다([미니 기획 D]-5, 카드 강조용) —
## _ready()가 이미 호출 전에 세팅해두지만, QA 훅(_debug_force_skill_upgrade_event() 등)이
## _ready() 경로를 거치지 않고 이 함수를 직접 부르는 경우에도 _show_skill_offer()가 읽는
## 플래그가 항상 정확하도록 자기 완결적으로 만든다.
func _setup_skill_upgrade_event(skills: Array[Dictionary]) -> void:
	_is_skill_upgrade_event = true
	title_label.text = "특수 이벤트 — 이미 익힌 능력을 강화할 기회"
	prompt_label.text = "낯익은 기운이 한층 짙어진다. 후보 중 하나를 골라 더 강하게 벼릴 수 있을 것 같다."
	safe_button.hide()
	risky_button.hide()
	_show_skill_offer(skills)


## DC 공식(DESIGN.md [미니 기획 B]-3): 방 0~1은 DC3, 2~3은 DC4, 4 이상은 DC5(상한).
## room_index는 RunState.rooms_cleared와 같은 기준(0부터 시작, 몇 번째 몬스터/방인지).
static func difficulty_for_room(room_index: int) -> int:
	return min(5, 3 + room_index / 2)


## "승부사"([대형 기획 5] F-2(c), 매혹사 시작 스킬): "위험을 감수하기"의 DC를 1
## 낮춘다(최저 2). difficulty_for_room()과 분리된 순수 함수라, dice_test.gd가 물리/
## 노드 없이 "스킬 있음/없음"일 때 실제 DC 값이 달라지는지 직접 검증할 수 있다.
static func gambler_adjusted_dc(base_dc: int, has_gambler: bool) -> int:
	if has_gambler:
		return max(2, base_dc - 1)
	return base_dc


func _refresh_shortcuts(buttons: Array[Button]) -> void:
	_shortcut_buttons = buttons
	# K-3: 포커스 강조색도 현재 캐릭터 accent로(K-1의 ACCENT_DEFAULT 대신).
	FocusNav.chain_linear(_shortcut_buttons, false, false, false, CharacterTheme.ui_palette(RunState.character_id)["accent"])
	FocusNav.grab_first_focus(_shortcut_buttons)


func _on_safe_pressed() -> void:
	if _choice_made:
		return
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_grant_reward(_challenge["safe_reward"])


func _on_risky_pressed() -> void:
	if _choice_made:
		return
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(_effective_risky_roll(randi_range(1, RunState.event_die_sides)))


## N-5(a) "곡예 흥행"/"곡예 흥행+": 실제 굴림(raw_roll)에 더할 보정치. 다른 "다이스
## 결과값 보정" 스킬들과 같은 관례로 상한(이벤트 주사위 면 개수)은 호출부
## (_effective_risky_roll())가 min()으로 직접 건다 — 이 함수는 보정치 자체만 돌려주는
## 순수 함수라 물리/노드 없이 바로 테스트할 수 있다.
static func event_roll_bonus(skill_flags: Array) -> int:
	if skill_flags.has("juggle_fortune_plus"):
		return JUGGLE_FORTUNE_PLUS_ROLL_BONUS
	if skill_flags.has("juggle_fortune"):
		return JUGGLE_FORTUNE_ROLL_BONUS
	return 0


## _on_risky_pressed()의 보정 계산을 별도 함수로 분리 — RNG(randi_range)가 섞인
## _on_risky_pressed() 전체를 거치지 않고도, dice_test.gd가 임의의 raw_roll 값을
## 직접 넣어 "실제 적용되는 보정+상한 공식"이 맞는지 결정적으로 검증할 수 있게 한다.
func _effective_risky_roll(raw_roll: int) -> int:
	return min(RunState.event_die_sides, raw_roll + event_roll_bonus(RunState.skill_flags))


## roll을 인자로 받아 QA에서 결정적으로 강제할 수 있게 한다(아래 _debug_force_risky_*).
## QA 훅들은 이 함수를 직접(= _on_risky_pressed()를 거치지 않고) 불러 event_roll_bonus()
## 보정 없이 roll 값 그대로 판정한다 — "강제 성공/실패"의 결정성이 목적이라 의도적.
## N-5(b): 성공/실패 2단만 있던 판정을 EventChallengePool.tier_for_roll()로 교체해
## "fail"/"success"/"crit"(대성공) 3단으로 늘렸다. 보상도 더 이상 EventItemPool을 직접
## 부르지 않고 _challenge의 success_reward/crit_reward를 _grant_reward()에 넘긴다 —
## 어떤 챌린지든(보물/도박/탐색/함정 해체) 이 함수는 전혀 분기하지 않는다.
func _resolve_risky(roll: int) -> void:
	var tier := EventChallengePool.tier_for_roll(roll, _dc)
	_show_roll_result(roll, tier)
	if tier == "fail":
		_show_fail(_challenge.get("fail_penalty", {"type": "none"}))
		return
	AchievementManager.unlock("risk_taker")
	# N-5(a) "한탕"(곡예사 전용 시작 스킬): 성공(대성공 포함) 시 추가 골드. 챌린지
	# 종류와 무관하게 적용(도박/탐색/함정 해체에서도 동일하게 적용되는 것이 의도).
	if RunState.skill_flags.has("start_fortune"):
		RunState.gold += FORTUNE_GOLD_BONUS
	var reward_spec: Dictionary = _challenge["crit_reward"] if tier == "crit" else _challenge["success_reward"]
	_grant_reward(reward_spec)


## 로마 숫자 육각 칩(EventDieVisual) + 결과 문구를 roll_root 아래에 만든다. 화면당
## 한 번만 호출되므로(다시 굴리는 경로가 없음) 기존 자식을 지우는 처리는 필요 없다.
## N-5(b): success(bool) 대신 tier(String, "fail"/"success"/"crit")를 받아 대성공을
## 구분해 보여준다.
func _show_roll_result(roll: int, tier: String) -> void:
	var visual := EventDieVisual.new()
	visual.custom_minimum_size = Vector2(56, 56)
	visual.position = Vector2(0, 0)
	roll_root.add_child(visual)
	visual.value = roll

	var tier_text := "대성공!" if tier == "crit" else ("성공!" if tier == "success" else "실패...")
	var tier_color := Color(0.65, 0.85, 1.0) if tier == "crit" else (Color(0.7, 0.95, 0.6) if tier == "success" else Color(0.9, 0.5, 0.45))

	# N-5(b): DC/대성공 기준은 이미 risky_button 텍스트(굴리기 전)에 나와 있어 여기서
	# 또 반복하면 글자가 길어져 우측 패널(x≈980부터)과 겹친다 — 굴림값과 결과만 보여준다.
	var label := Label.new()
	label.position = Vector2(70, 14)
	label.text = "이벤트 주사위 결과: %s (%d) → %s" % [
		EventDieVisual._to_roman(roll), roll, tier_text
	]
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", tier_color)
	roll_root.add_child(label)


## N-5(b): reward spec(아이템/골드/눈금/없음, EventChallengePool.roll_reward()가 해석)을
## 한 번 추첨해 실제로 RunState에 반영하고 화면에 보여준다. "type"으로만 분기해 챌린지
## 종류와는 무관하다 — 새 챌린지가 생겨도 이 함수는 그대로다.
func _grant_reward(spec: Dictionary) -> void:
	var rolled := EventChallengePool.roll_reward(spec)
	match String(rolled.get("type", "none")):
		"item":
			_show_item_offer(rolled["item"])
		"gold":
			var amount: int = int(rolled["amount"])
			RunState.gold += amount
			_show_simple_result("골드 %d를 더 얻었다!" % amount, true)
		"pips":
			var count: int = int(rolled["count"])
			for i in count:
				RunState.pip_inventory.append(randi_range(1, 6))
			_show_simple_result("눈금 %d개를 더 얻었다!" % count, true)
		_:
			_show_simple_result("...하지만 손에 넣을 것이 없었다.", true)


## _show_fail()/_grant_reward()가 공유하는 "카드 없이 문구+계속 버튼만" 결과 표시.
## is_success는 글자 색(성공=녹/실패=빨강) 구분용.
func _show_simple_result(text: String, is_success: bool) -> void:
	fail_label.text = text
	fail_label.add_theme_color_override("font_color", Color(0.7, 0.95, 0.6) if is_success else Color(0.9, 0.5, 0.45))
	fail_label.show()
	continue_button.show()
	_refresh_shortcuts([continue_button, customize_button, skill_codex_button])


## N-5(b): penalty_spec(기본값 "없음")으로 실패 패널티를 함께 처리한다 — "gold_loss"
## 타입이면 온건한 금액만큼 골드를 깎고(0 밑으로 내려가지 않음) 문구에 덧붙인다. 기존
## "보물" 챌린지의 fail_penalty는 "none"이라 이전과 동일하게 패널티 문구가 없다.
func _show_fail(penalty_spec: Dictionary = {"type": "none"}) -> void:
	var rolled := EventChallengePool.roll_reward(penalty_spec)
	var penalty_text := ""
	if String(rolled.get("type", "none")) == "gold_loss":
		var amount: int = int(rolled["amount"])
		if amount > 0:
			RunState.gold = max(0, RunState.gold - amount)
			penalty_text = " 허둥대다 금화 %d를 떨어뜨렸다." % amount
	_show_simple_result("아쉽게도 손에 넣지 못했다... 이번 기회는 여기서 끝이다.%s" % penalty_text, false)


func _on_continue_after_fail_pressed() -> void:
	if not _apply_fail():
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 실패 시에도 "방을 하나 소비했다"는 진행은 그대로 인정한다(DESIGN.md — "페널티는
## 이번 기회를 놓침 그 자체로 충분"). _apply_pick/_apply_pips/_apply_upgrade와 동일한
## _picked 가드를 공유해 더블클릭으로 방이 두 번 소비되지 않게 한다.
func _apply_fail() -> bool:
	if _picked:
		return false
	_picked = true
	RunState.rooms_cleared += 1
	return true


## _show_item_offer/_show_skill_offer가 공유하는 카드 정리 — 이전에 그려둔 카드가
## 남아있으면(예: 이 인스턴스가 스킬 이벤트로 열렸다가 QA 훅으로 강제로 아이템 이벤트
## 경로를 재현하는 경우) 새 카드와 겹쳐 보이거나 _row_ui 검증이 틀어질 수 있다.
func _clear_row_ui() -> void:
	for node in _row_ui:
		node.queue_free()
	_row_ui.clear()


## 안전/위험 성공 양쪽이 공유하는 단일 아이템 카드 표시. 예전 _rebuild_items()가 2개
## 아이템을 나란히 보여주던 것을 1개짜리로 단순화했을 뿐, 카드 구성/버튼 배선 로직
## 자체는 그대로다.
func _show_item_offer(item: Dictionary) -> void:
	_clear_row_ui()

	var built := ItemCardStyle.build_card(item)
	var card: PanelContainer = built["card"]
	card.position = Vector2(0.0, 0.0)
	card.size = Vector2(320.0, 300.0)
	items_root.add_child(card)
	_row_ui.append(card)

	var button_row: VBoxContainer = built["button_row"]
	var offer_buttons: Array[Button] = []

	if item.get("kind", "") == "gain_pips":
		var pip_btn := Button.new()
		pip_btn.text = "눈금 획득"
		pip_btn.custom_minimum_size = Vector2(0, 38)
		pip_btn.pressed.connect(_on_pick_pips.bind(item))
		UIKit.style_secondary_button(pip_btn, RunState.character_id)
		button_row.add_child(pip_btn)
		offer_buttons.append(pip_btn)
	elif item.get("kind", "") == "upgrade_die":
		var upgrade_btn := Button.new()
		upgrade_btn.text = "다이스 획득 (인벤토리)"
		upgrade_btn.custom_minimum_size = Vector2(0, 38)
		upgrade_btn.pressed.connect(_on_pick_upgrade.bind(item))
		UIKit.style_secondary_button(upgrade_btn, RunState.character_id)
		button_row.add_child(upgrade_btn)
		offer_buttons.append(upgrade_btn)
	else:
		var atk_preview := ItemCardStyle.build_effect_preview(item, RunState.player_attack_bag)
		if atk_preview:
			button_row.add_child(atk_preview)
		var atk_applicable := DiceItemPool.is_applicable(item, RunState.player_attack_bag)
		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 적용" if atk_applicable else DiceItemPool.unavailable_reason(item)
		atk_btn.disabled = not atk_applicable
		atk_btn.custom_minimum_size = Vector2(0, 38)
		atk_btn.pressed.connect(_on_pick_pressed.bind(item, "attack"))
		UIKit.style_secondary_button(atk_btn, RunState.character_id)
		button_row.add_child(atk_btn)
		offer_buttons.append(atk_btn)

		var def_preview := ItemCardStyle.build_effect_preview(item, RunState.player_defense_bag)
		if def_preview:
			button_row.add_child(def_preview)
		var def_applicable := DiceItemPool.is_applicable(item, RunState.player_defense_bag)
		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 적용" if def_applicable else DiceItemPool.unavailable_reason(item)
		def_btn.disabled = not def_applicable
		def_btn.custom_minimum_size = Vector2(0, 38)
		def_btn.pressed.connect(_on_pick_pressed.bind(item, "defense"))
		UIKit.style_secondary_button(def_btn, RunState.character_id)
		button_row.add_child(def_btn)
		offer_buttons.append(def_btn)

	offer_buttons.append(customize_button)
	offer_buttons.append(skill_codex_button)
	_refresh_shortcuts(offer_buttons)


## 스킬 후보(1~2개, SkillPool.available_choices()가 부족하게 돌려준 경우 1개일 수도
## 있음)를 나란히 카드로 보여준다. _show_item_offer()와 달리 카드가 여러 장이라
## 폭 계산이 필요하다 — items_root 기준 좌우 대칭으로 배치.
## [미니 기획 D]-5(INBOX.md 2026-09-17): _is_skill_upgrade_event가 true(스킬 강화
## 이벤트)면 build_card()의 highlight=true를 넘겨 카드 테두리가 두껍고 노란색으로
## 강조된다 — 새 스킬 획득 이벤트(_setup_skill_event)는 같은 함수를 쓰되 그때는
## _is_skill_upgrade_event가 false라 기존 등급색 테두리 그대로 나온다.
func _show_skill_offer(skills: Array[Dictionary]) -> void:
	# [대형 기획 12] L-2(a): 후보로 화면에 뜨는 순간이 곧 "발견"이다(skill_codex.gd
	# 상단 주석의 "표시된 순간" 기록 시점). RunState.test_battle이면 내부에서 자동으로
	# 건너뛴다.
	for skill in skills:
		SkillCodex.mark_discovered(RunState.character_id, skill["id"])

	_clear_row_ui()

	var offer_buttons: Array[Button] = []
	var card_width := 300.0
	var gap := 40.0
	var start_x := -(skills.size() * card_width + (skills.size() - 1) * gap) / 2.0
	for i in skills.size():
		var skill: Dictionary = skills[i]
		var built := ItemCardStyle.build_card(skill, "", false, _is_skill_upgrade_event)
		var card: PanelContainer = built["card"]
		card.position = Vector2(start_x + i * (card_width + gap), 0.0)
		card.size = Vector2(card_width, 300.0)
		items_root.add_child(card)
		_row_ui.append(card)

		var pick_btn := Button.new()
		pick_btn.text = "이 능력 익히기"
		pick_btn.custom_minimum_size = Vector2(0, 38)
		pick_btn.pressed.connect(_on_pick_skill_pressed.bind(skill))
		UIKit.style_secondary_button(pick_btn, RunState.character_id)
		var button_row: VBoxContainer = built["button_row"]
		button_row.add_child(pick_btn)
		offer_buttons.append(pick_btn)

	offer_buttons.append(customize_button)
	offer_buttons.append(skill_codex_button)
	_refresh_shortcuts(offer_buttons)


func _on_pick_skill_pressed(skill: Dictionary) -> void:
	if not _apply_skill_pick(skill):
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## _apply_pick과 동일한 이유의 이중 실행 가드(카드가 여러 장이라 더블클릭으로 두
## 스킬이 동시에 적용될 위험이 있음 — 같은 _picked 플래그를 공유해 재사용).
## 반환값 = 이번 호출이 실제로 적용됐는지.
func _apply_skill_pick(skill: Dictionary) -> bool:
	if _picked:
		return false
	_picked = true
	SkillPool.grant(skill["id"])
	RunState.rooms_cleared += 1
	return true


func _on_pick_pressed(item: Dictionary, target: String) -> void:
	if not _apply_pick(item, target):
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## shop.gd의 이중 구매 방지(이터레이션 45)와 같은 이유로 필요한 가드다. shop은
## "골드 부족"으로 자연스럽게 재검증되지만, 이 방은 무료라 그런 재검증 수단이 없어서
## 별도 플래그가 필요하다 — change_scene_to_file()이 그 프레임 안에서 즉시 씬을 바꾸지
## 않으므로, 버튼 더블클릭 등으로 같은 프레임에 이 핸들러가 두 번 불리면 가드 없이는
## 아이템이 중복 적용되고 rooms_cleared가 2 증가해 방 하나를 건너뛸 수 있었다.
## 씬 전환과 분리해둔 이유: dice_test.gd 회귀 테스트가 실제 event.tscn을 인스턴스화해
## 이 함수를 직접 호출해 가드를 검증하는데, _on_pick_pressed를 그대로 호출하면
## change_scene_to_file()이 QA 중인 dice_test 씬 자체를 바꿔버려 스크린샷이 깨진다.
## 반환값(true=이번 호출이 실제로 적용됨)으로 테스트가 부작용 없이 결과를 검증할 수 있다.
func _apply_pick(item: Dictionary, target: String) -> bool:
	if _picked:
		return false
	_picked = true
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	RunState.rooms_cleared += 1
	return true


## gain_pips 아이템(공격/방어 어느 주머니에도 속하지 않고 RunState.pip_inventory에
## 바로 쌓임) 전용 픽 핸들러. _on_pick_pressed/_apply_pick과 대칭 구조 — attack/defense
## 대상 선택이 필요 없어서 별도 함수로 분리했다(같은 _picked 플래그를 공유해 이중 실행
## 가드도 그대로 재사용됨).
func _on_pick_pips(item: Dictionary) -> void:
	if not _apply_pips(item):
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 반환값 = 이번 호출이 실제로 적용됐는지 (_apply_pick과 동일한 이중 실행 방지 이유).
## pip_min..pip_max 개수만큼, 각각 1..6 범위의 무작위 값을 RunState.pip_inventory에
## 추가한다(전투 승리 보상 1개짜리 눈금과 값 범위는 별개 — "여러 개를 한 번에"가 이
## 아이템의 핵심이라 개수 쪽에 무게를 둠).
func _apply_pips(item: Dictionary) -> bool:
	if _picked:
		return false
	_picked = true
	var count := randi_range(item["pip_min"], item["pip_max"])
	for i in count:
		RunState.pip_inventory.append(randi_range(1, 6))
	RunState.rooms_cleared += 1
	return true


## upgrade_die 아이템(공격/방어 어느 주머니에도 즉시 속하지 않고 RunState.die_inventory에
## 바로 쌓임) 전용 픽 핸들러. _on_pick_pips/_apply_pips와 대칭 구조 — attack/defense
## 대상 선택이 필요 없어서 별도 함수로 분리했다(같은 _picked 플래그를 공유해 이중 실행
## 가드도 그대로 재사용됨).
func _on_pick_upgrade(item: Dictionary) -> void:
	if not _apply_upgrade(item):
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 반환값 = 이번 호출이 실제로 적용됐는지 (_apply_pick/_apply_pips와 동일한 이유).
func _apply_upgrade(item: Dictionary) -> bool:
	if _picked:
		return false
	_picked = true
	DiceItemPool.apply_upgrade_gain(item)
	RunState.rooms_cleared += 1
	return true


func _find_item_by_sides(sides: int) -> Dictionary:
	for it in EventItemPool.ITEMS:
		if it.get("kind", "") == "add_die" and it.get("sides", -1) == sides:
			return it
	return EventItemPool.ITEMS[0]


func _find_item_by_kind(kind: String) -> Dictionary:
	for it in EventItemPool.ITEMS:
		if it.get("kind", "") == kind:
			return it
	return EventItemPool.ITEMS[0]


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용). 안전
## 선택지를 눌러 확정 C급 아이템(지금은 gain_pips 하나뿐) 카드까지 화면에 나오는지
## 확인한다.
func _debug_pick_safe() -> void:
	_on_safe_pressed()


## QA 전용(GAME_QA_CALL) — [대형 기획 14] N-5(c) "위험을 감수하기" 버튼 텍스트가
## 곡예사(D12)에서도 실제로 D12로 보이는지 확인하기 위한 0-arity 래퍼.
## _setup_item_event() 전체를 다시 부르면 safe/risky 버튼의 pressed 시그널이 중복
## 연결되므로, 프로덕션과 같은 포맷 문자열(risky_button.text 대입부, _setup_item_event()
## 참고)만 event_die_sides=12로 다시 계산한다.
func _debug_qa_juggler_risky_button() -> void:
	RunState.event_die_sides = 12
	risky_button.text = "위험을 감수하기 (D%d, %d+ 성공/%d+ 대성공)" % [
		RunState.event_die_sides, _dc, _dc + EventChallengePool.CRIT_MARGIN
	]


## QA 전용: 실제 randi_range() 대신 항상 최댓값(event_die_sides)을 굴린 것으로 강제해
## "위험을 감수하기" 성공 경로(아이템 카드 표시까지)를 결정적으로 재현한다. DC가 아무리
## 커져도(최대 5) 이벤트 다이스 최댓값은 항상 DC 이상이므로 반드시 성공(또는 대성공)한다.
## N-5(b): _challenge를 "treasure"로 고정한다 — _ready()가 매번 무작위로 고르는
## 4종 중 보물 외의 종류(도박/탐색)는 보상이 아이템이 아니라 골드/눈금이라
## dice_test.gd의 기존 "_row_ui.size()==1(카드)" 검증이 깨진다. _clear_row_ui()를 먼저
## 부르는 이유: 이 인스턴스가 _ready()에서 우연히 스킬 이벤트로 열렸을 수 있어서
## (SKILL_EVENT_CHANCE) 이미 스킬 카드가 _row_ui에 남아있을 수 있음 — 이 훅은 "보물
## 챌린지의 위험 감수 경로"를 결정적으로 재현하는 게 목적이라 항상 깨끗한 상태에서
## 시작해야 dice_test.gd의 _row_ui 검증이 두 분기와 무관하게 안정된다.
func _debug_force_risky_success() -> void:
	_challenge = EventChallengePool.get_challenge("treasure")
	_clear_row_ui()
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(RunState.event_die_sides)


## QA 전용: 항상 최솟값(1)을 굴린 것으로 강제해 실패 경로("아쉽게도..." + 계속 버튼)를
## 결정적으로 재현한다. DC는 항상 3 이상이므로 1은 반드시 실패한다. _challenge를
## "treasure"로 고정하는 이유/_clear_row_ui() 이유 모두 _debug_force_risky_success()와
## 동일(보물의 fail_penalty="none"이라 패널티 문구도 기존과 동일하게 비어 있다).
func _debug_force_risky_failure() -> void:
	_challenge = EventChallengePool.get_challenge("treasure")
	_clear_row_ui()
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(1)


## N-5(b) QA 전용: _ready()가 무작위로 고르는 챌린지와 무관하게 id로 직접 지정해
## 초기 화면(제목/문구/안전·위험 버튼 텍스트)을 재현한다. _setup_item_event()가 이미
## _ready()에서 safe_button/risky_button에 신호를 연결해둔 상태라 중복 연결을 막기
## 위해 먼저 해제하고 다시 연결한다.
func _debug_force_challenge(id: String) -> void:
	_is_skill_event = false
	_is_skill_upgrade_event = false
	_choice_made = false
	_picked = false
	fail_label.hide()
	continue_button.hide()
	_clear_row_ui()
	if safe_button.pressed.is_connected(_on_safe_pressed):
		safe_button.pressed.disconnect(_on_safe_pressed)
	if risky_button.pressed.is_connected(_on_risky_pressed):
		risky_button.pressed.disconnect(_on_risky_pressed)
	safe_button.show()
	risky_button.show()
	_challenge = EventChallengePool.get_challenge(id)
	_setup_item_event()


## qa/visual_qa.gd의 GAME_QA_CALL용 인자 없는 래퍼 3개(아래) — N-5(b)로 추가된 각
## 챌린지의 초기 화면이 겹침/잘림 없이 보이는지 확인하기 위함.
func _debug_force_challenge_gambling() -> void:
	_debug_force_challenge("gambling")


func _debug_force_challenge_exploration() -> void:
	_debug_force_challenge("exploration")


func _debug_force_challenge_trap_disarm() -> void:
	_debug_force_challenge("trap_disarm")


## N-6 QA 전용(GAME_QA_CALL) — 특별 선택지가 "활성"(소유 캐릭터) 상태로 겹침 없이
## 보이는지 확인. "treasure"(enchantress 전용 특별 선택지 보유)를 강제하고 캐릭터를
## enchantress로 바꾼다.
func _debug_force_special_choice_active() -> void:
	RunState.character_id = "enchantress"
	_debug_force_challenge("treasure")


## N-6 QA 전용 — 같은 "treasure" 챌린지를 비소유 캐릭터(novice)로 보면 특별 선택지가
## "잠김"(자물쇠 문구 + 흐린 설명)으로 보이는지 확인.
func _debug_force_special_choice_locked() -> void:
	RunState.character_id = "novice"
	_debug_force_challenge("treasure")


## N-6 QA 전용 — 전용 이벤트(캐릭터만 볼 수 있는 챌린지) 화면이 제목의 "전용" 배지와
## 함께 겹침 없이 보이는지 확인. pirate를 "보물 지도" 전용 이벤트로 강제한다.
func _debug_force_exclusive_event() -> void:
	RunState.character_id = "pirate"
	_debug_force_challenge("treasure_map")


## [대형 기획 15] Q-1(23) QA 전용 — 전용 챌린지 중 prompt가 가장 긴 "circus_master"
## (곡예사 전용, dice_test.gd _check_q1_event_text_layout()의 실측 최대 필요 높이
## 49.0의 출처)를 강제로 보여준다. _debug_force_exclusive_event()와 같은 패턴.
func _debug_force_circus_master_event() -> void:
	RunState.character_id = "juggler"
	_debug_force_challenge("circus_master")


## N-5(b) QA 전용: "도박" 챌린지에서 대성공(roll = DC + CRIT_MARGIN)을 강제해 골드
## 보상 결과 화면(아이템 카드 없이 문구+계속 버튼만)이 겹침 없이 보이는지 확인한다.
## _debug_force_challenge()를 먼저 거쳐 제목/문구도 "도박"으로 갱신한다 — 그냥
## _challenge만 바꾸면 _ready()가 처음에 고른(무관계) 챌린지의 제목이 화면에 남아있는
## 채로 결과만 도박 보상이 나와 스크린샷이 서로 다른 챌린지처럼 보이는 불일치가 있었다.
func _debug_force_gambling_crit_success() -> void:
	_debug_force_challenge("gambling")
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(_dc + EventChallengePool.CRIT_MARGIN)


## N-5(b) QA 전용: "함정 해체" 챌린지에서 강제 실패(roll=1)시 온건한 골드 손실 패널티
## 문구("...허둥대다 금화 N를 떨어뜨렸다")가 기존 실패 문구와 겹침 없이 이어지는지
## 확인한다. 제목/문구 갱신 이유는 _debug_force_gambling_crit_success()와 동일.
func _debug_force_trap_disarm_failure() -> void:
	_debug_force_challenge("trap_disarm")
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(1)


## QA 전용: D20 아이템(위험 성공 풀의 S급)이 카드에 안 겹치고 표시되는지 확인하기 위해
## 안전/위험 선택 없이 곧바로 카드를 강제로 띄운다.
func _debug_force_show_d20() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_show_item_offer(_find_item_by_sides(20))


## QA 전용: "눈금 주머니 획득"(gain_pips, 안전 선택지의 유일한 C급) 카드가 정상
## 표시되는지 확인.
func _debug_force_show_pips() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_show_item_offer(_find_item_by_kind("gain_pips"))


## QA 전용: "다이스 대승급 (-> D10)"(upgrade_die, 위험 성공 풀의 A급) 카드가 정상
## 표시되는지 확인.
func _debug_force_show_upgrade() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_show_item_offer(_find_item_by_kind("upgrade_die"))


## QA 전용: D20 아이템을 공격 주머니에 적용했을 때 실제로 sides=20 다이스가 하나
## 추가되는지 콘솔로 검증한다 (apply() 로직 자체를 확인, 화면 표시와는 별개).
func _debug_verify_d20_pickup() -> void:
	var item: Dictionary = _find_item_by_sides(20)
	var bag := RunState.player_attack_bag
	var before_count := bag.dice.size()
	DiceItemPool.apply(item, bag)
	var after_count := bag.dice.size()
	var added_sides := bag.dice[after_count - 1].size() if after_count > before_count else -1
	print("[qa] d20 pickup: before=%d after=%d added_sides=%d" % [before_count, after_count, added_sides])


## QA 전용 — 포커스+확정 경로(방향키 이동 후 스페이스, K-1)로 커스터마이징 버튼까지
## 이어지는지 확인하기 위함(dungeon_map.gd/story_event.gd의 _debug_press_shortcut_*와
## 같은 목적).
func _debug_press_shortcut_customize() -> void:
	customize_button.grab_focus()
	customize_button.pressed.emit()


## QA 전용 — [대형 기획 12] L-2(c). 포커스+확정 경로로 "스킬 도감" 버튼까지 이어지는지
## 확인(_debug_press_shortcut_customize와 같은 패턴).
func _debug_press_shortcut_skill_codex() -> void:
	RunState.skill_flags = ["deep_breath"]
	skill_codex_button.grab_focus()
	skill_codex_button.pressed.emit()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅 (dungeon_map.gd의
## _debug_open_customize와 같은 목적).
func _debug_open_customize() -> void:
	customize_panel.open()


## [대형 기획 12] L-2(c): 던전 진행 중에는 "이번 회차 보유"가 반영돼야 하므로
## RunState.skill_flags를 그대로 넘긴다(dungeon_map.gd의 _on_skill_codex_pressed()와
## 같은 이유).
func _on_skill_codex_pressed() -> void:
	if skill_codex_panel.visible:
		skill_codex_panel.close()
	else:
		skill_codex_panel.open(RunState.character_id, RunState.skill_flags)


## QA 전용: 스킬 이벤트 분기(30% 확률)가 실제로 카드 2장을 겹침 없이 보여주는지
## 확인하기 위해, _ready()의 확률 결과와 무관하게 강제로 스킬 이벤트 화면을 그린다.
func _debug_force_skill_event() -> void:
	_setup_skill_event(SkillPool.available_choices(2, RunState.character_id))


## QA 전용: "수호 심화"(수호자 전용 고유 스킬) 카드가 실제로 후보에 섞여 표시되는지
## 확인하기 위해, RunState.character_id를 강제로 "guardian"으로 바꾸고 스킬 이벤트를
## 다시 그린다(_debug_force_skill_event와 같은 목적, frenzy_deepen 검증 때는 캐릭터
## 선택 화면을 거쳐야 했던 것과 달리 이 씬 하나로 바로 확인 가능하게 하는 전용 훅).
func _debug_force_skill_event_as_guardian() -> void:
	RunState.character_id = "guardian"
	RunState.skill_flags = []
	# 무작위 추첨(available_choices)이 아니라 "수호 심화"가 포함된 2장을 직접 골라
	# 넘긴다 — 실제 게임에서 보이는 카드 개수(항상 2장)와 정확히 같은 레이아웃으로
	# 검증하기 위함(무작위 추첨으로는 3종 후보 중 2장만 뽑히는 매번의 실행에서 수호
	# 심화가 빠질 수 있어 화면 확인이 불안정했음). 무작위 추첨/캐릭터 필터 로직
	# 자체는 dice_test.gd가 이미 검증하므로 이 QA 훅은 카드 렌더링/겹침 확인이 목적.
	_setup_skill_event([SkillPool.SKILLS[0], SkillPool.UNIQUE_SKILLS[1]])


## QA 전용: "연쇄 폭발"(폭발병 전용 고유 스킬) 카드가 실제로 후보에 섞여 표시되는지
## 확인 — _debug_force_skill_event_as_guardian()과 같은 패턴.
func _debug_force_skill_event_as_explosive() -> void:
	RunState.character_id = "explosive"
	RunState.skill_flags = []
	_setup_skill_event([SkillPool.SKILLS[1], SkillPool.UNIQUE_SKILLS[2]])


## QA 전용: "연쇄 방어"(방패병 전용 고유 스킬) 카드가 실제로 후보에 섞여 표시되는지
## 확인 — _debug_force_skill_event_as_explosive()와 완전히 대칭 패턴.
func _debug_force_skill_event_as_shieldbearer() -> void:
	RunState.character_id = "shieldbearer"
	RunState.skill_flags = []
	_setup_skill_event([SkillPool.SKILLS[0], SkillPool.UNIQUE_SKILLS[3]])


## QA 전용: "임기응변"(견습 모험가 전용 고유 스킬) 카드가 실제로 후보에 섞여
## 표시되는지 확인 — 위 3개 훅과 같은 패턴.
func _debug_force_skill_event_as_novice() -> void:
	RunState.character_id = "novice"
	RunState.skill_flags = []
	_setup_skill_event([SkillPool.SKILLS[1], SkillPool.UNIQUE_SKILLS[4]])


## QA 전용([미니 기획 D]-3): "스킬 강화" 이벤트 카드(예: "임기응변+")가 겹침 없이
## 표시되는지 확인. 무작위 확률(SKILL_UPGRADE_EVENT_CHANCE)과 무관하게 강제로
## _setup_skill_upgrade_event()를 호출한다 — _debug_force_skill_event()와 같은 목적,
## 견습 모험가가 이미 "임기응변"을 보유한 상태를 만들어 "임기응변+"가 후보에 뜨는지
## 확인(_debug_force_skill_event_as_novice()와 같이 캐릭터를 강제 지정).
func _debug_force_skill_upgrade_event() -> void:
	RunState.character_id = "novice"
	RunState.skill_flags = ["versatile_surge"]
	_setup_skill_upgrade_event([SkillPool.UPGRADE_SKILLS[6]])


## QA 전용: 스킬을 실제로 습득하면 RunState.skill_flags에 반영되는지, 이미 보유한
## 스킬은 두 번째 후보 목록에서 제외되는지를 콘솔로 검증한다(apply 로직 확인, 화면
## 표시와는 별개).
func _debug_verify_skill_pickup() -> void:
	var skill: Dictionary = SkillPool.SKILLS[0]
	var before: Array[String] = RunState.skill_flags.duplicate()
	SkillPool.grant(skill["id"])
	var after: Array[String] = RunState.skill_flags.duplicate()
	var remaining := SkillPool.available_choices(SkillPool.SKILLS.size())
	print("[qa] skill pickup: before=%s after=%s remaining_choices=%d" % [before, after, remaining.size()])
