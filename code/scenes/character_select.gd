extends Node2D
## 캐릭터 선택 화면.
##
## INBOX.md 피드백("던전에 입장하면, 플레이어블 캐릭터를 선택해야한다. 슬더스와
## 유사" + "일단은 능력 없는 기본 캐릭터. 이쁘장한 여캐 하나 디자인한다")을 반영한
## 최소 구현에서 시작해, [대형 기획 1]("플레이어블 캐릭터 4종 추가, 총 5종 중 선택
## 입장", 2026-09-09)의 첫 조각으로 카드 1개("확인")에서 여러 카드 중 하나를 고르는
## 형태로 확장했다. 실제 캐릭터 정의는 code/systems/character_profiles.gd
## (CharacterProfiles.PROFILES)에 있고, 이 씬은 그 목록을 카드로 그리고 클릭한
## 카드를 금테로 강조하는 역할만 한다(achievement_panel.gd의 카드 스타일 패턴을
## 재사용). 실제 일러스트 에셋은 없어서(아트 파이프라인 필요, 사람 확인 대기) 도형으로
## 조립한 플레이스홀더 실루엣(character_portrait_placeholder.gd)을 캐릭터별로 색만
## 바꿔서 보여준다.
##
## 흐름: 이 화면이 project.godot의 main_scene이 됨 -> 카드 클릭으로 캐릭터 선택
## (기본값: 첫 번째 프로필) -> "던전 시작" 버튼 -> RunState.reset_run(선택한 id)로
## 새 런 시작 -> dungeon_map.tscn.

## CARD_WIDTH/CARD_HEIGHT/CARD_GAP: 왼쪽 카드 목록 한 행의 "기대" 크기 — 실제 행
## 간격은 _build_cards()가 각 카드의 실제 결합 최소 높이(get_combined_minimum_size())를
## 측정해서 쌓으므로(ART-1a, 2026-10-07), CARD_HEIGHT는 다른 계산의 기준값으로만 쓰인다.
## **2026-10-13 [대형 기획 11] K-2**: "카드가 큰 편이다 — 얼굴 위주 정사각 썸네일 + 이름 +
## 한 줄 기믹 라벨로 줄여서 8명이 스크롤 없이 한눈에 보이게" 반영 — 92px짜리 행(초상+이름+
## 버튼)에서 56px짜리 행(정사각 얼굴 썸네일+이름/기믹 2줄+선택 버튼)으로 축소. 8행 ×
## (56+12)=544 ≈ 목록 가시 영역(540px)과 거의 같아 스크롤이 사실상 필요 없다(폭 넓은
## 폰트/해상도에서 약간 넘쳐도 기존처럼 ScrollContainer가 받아준다).
## N-2b(2026-10-15, [대형 기획 14] 감독 확인): N-2는 전신 컬럼을 300×560으로 만들었지만
## 원화(약 1181×1332, 캐릭터가 거의 전체 폭을 채움 — Image.get_used_rect()로 8명 전부
## 확인한 실측값은 novice 1108×1308 ~ shieldbearer(최대) 1181×1314)가 폭 300에 맞춰져
## STRETCH_KEEP_ASPECT_CENTERED가 "폭 기준"으로 축소돼 실제로 그려지는 캐릭터 높이는
## ~330~346px뿐이었다(세로로 비어있는 투명 여백이 거의 없어 bbox 크롭으로는 해결 안 됨 —
## 원화 자체가 이미 거의 끝까지 그려져 있음). 유일한 해법은 컬럼 폭을 넓히는 것 — 8명 중
## 가로 폭이 가장 넓은 shieldbearer(1181×1314) 기준으로 "렌더 높이 ≥520"을 만족하려면
## 홀더 폭이 520*1181/1314 ≈ 467.4 이상이어야 한다(폭이 좁은 enchantress/juggler는 이미
## 세로 기준으로 꽉 차 문제없음). 좌측 카드 목록 폭을 줄여(INBOX 제안대로 360->280) 그
## 여유를 전신 컬럼에 더한다. CARD_WIDTH는 이제 ScrollContainer(폭 300, .tscn 참고) 안
## 카드 한 장의 실제 폭이다.
const CARD_WIDTH := 280.0
const CARD_HEIGHT := 56.0
const CARD_GAP := 12.0
## FACE_THUMB_SIZE: 좌측 목록의 정사각 얼굴 썸네일 한 변(K-2). CharacterArt.load_face_thumb()
## (face_neutral.png 또는 full.png 얼굴 크롭)을 이 크기로 그대로 채워 넣고, 원화가 전혀
## 없으면 같은 칸에 도형 플레이스홀더를 축소해 넣는다(PORTRAIT_SCALE_COMPACT).
const FACE_THUMB_SIZE := 48.0
## PORTRAIT_SCALE_COMPACT: 좌측 목록 폴백용 — CharacterPortraitPlaceholder(원래 약
## 136x248px로 그려짐)를 FACE_THUMB_SIZE 정사각 칸에 맞춰 더 작게 축소한다(기존
## PORTRAIT_SCALE=0.32는 92px 높이 행 기준이었음).
const PORTRAIT_SCALE_COMPACT := 0.2
## PORTRAIT_COLUMN_WIDTH/PORTRAIT_COLUMN_GAP/PORTRAIT_COLUMN_TOP_PAD: N-2(2026-10-15,
## [대형 기획 14]) — 상세 패널(DetailPanelContainer, N-2b로 폭 920 — .tscn 참고)을
## 좌(전신 이미지 큰 컬럼)/우(정보 구역 컬럼) 2단으로 나눈다(INBOX.md 원문 "전신 원화를
## 화면에서 가장 크게 보이는 요소로"). INFO_COLUMN_WIDTH는 920 - PORTRAIT_COLUMN_WIDTH -
## PORTRAIT_COLUMN_GAP과 정확히 일치시켰다(둘을 더하면 항상 920).
## **N-2b(감독 확인)로 PORTRAIT_COLUMN_WIDTH 340->500, INFO_COLUMN_WIDTH 480->400** —
## FULL_ART_SIZE.x(아래, 실제 렌더 폭)를 300->480으로 넓혀야 렌더 높이 ≥520을 만족하므로
## (위 CARD_WIDTH 주석의 계산 참고) 그만큼 좌측 카드 목록 폭을 줄여 확보했다.
const PORTRAIT_COLUMN_WIDTH := 500.0
const PORTRAIT_COLUMN_GAP := 20.0
const PORTRAIT_COLUMN_TOP_PAD := 10.0
const INFO_COLUMN_WIDTH := 400.0
## FULL_ART_SIZE: 좌측 전신 이미지 컬럼 안, 실제 이미지/플레이스홀더가 들어갈 칸의 크기.
## 높이 560은 N-2 테스트 기준("전신 이미지 노드 rect 높이 ≥ 560")을 그대로 상수로
## 못박았다(DetailPanelContainer 높이가 580으로 늘어난 것(.tscn 참고)에서 위아래 여백
## 10px씩을 뺀 값). **N-2b로 폭 300->480** — STRETCH_KEEP_ASPECT_CENTERED는
## min(홀더폭/텍스처폭, 홀더높이/텍스처높이)로 스케일을 정하는데, 원화(약 1181×1332,
## 세로 투명 여백이 거의 없어 폭이 좁으면 폭이 항상 병목이 됨)가 폭 300에서는 렌더
## 높이가 ~330~346px로 INBOX N-2b가 요구하는 "실제로 그려지는 높이 ≥520"에 크게
## 못 미쳤다(8명 중 가로가 가장 넓은 shieldbearer(1181×1314) 기준 필요 폭 ≈
## 520*1181/1314 ≈ 467.4). 480으로 넓히면 shieldbearer 기준 렌더 높이 ≈
## 1314*(480/1181) ≈ 534(폭이 병목인 채로 유지, 여유 14px) — 나머지 7명은 가로가
## 더 좁거나(enchantress/juggler) 세로/가로 비율이 비슷해 오히려 높이가 병목이 되며
## 그 경우 홀더 높이(560)를 그대로 채운다(둘 다 ≥520을 만족). 이 칸은 홀더(Control,
## Container가 아님)라 레이아웃 패스 타이밍과 무관하게 항상 이 값으로 고정된다
## (_detail_art.size처럼 기존부터 쓰던 패턴). PORTRAIT_COLUMN_WIDTH(500)와의 차이
## 20px은 위아래 패딩과 같은 비율로 좌우 패딩(각 10px)에 쓴다.
const FULL_ART_SIZE := Vector2(480, 560)
## PORTRAIT_SCALE_FULL: 전신 이미지 컬럼 폴백용 CharacterPortraitPlaceholder 확대 배율.
## 원본 그리기 범위(세로 248, x -68~68 / y -108~140)를 FULL_ART_SIZE 안에 여유를 두고
## 들어오도록(그려지는 실제 높이 ≈ 248*2.15 ≈ 533, 폭 ≈ 136*2.15 ≈ 292 — 세로 기준으로
## 꽉 채우는 계산이라 N-2b로 FULL_ART_SIZE.x가 300->480으로 넓어져도(가로 여유가
## 늘어났을 뿐) 그대로 유효) 2.15로 잡았다(과거 PORTRAIT_SCALE(0.56, K-2 당시
## 130x146 칸 기준)과 같은 계산 패턴 — 칸이 커진 만큼 배율만 올림).
const PORTRAIT_SCALE_FULL := 2.15
## ABILITY_DESC_MAX_CHARS: 고유 능력 섹션(③) 설명을 "최대 2줄" 예산 안에 묶기 위한
## 문자 수 상한(K-2 원문 "최대 2줄 설명") — 섹션 폭(~300px)·폰트(13px) 기준 대략
## 2줄에 들어오는 길이를 감으로 잡았다. 넘치면 잘라내고 말줄임표(…)를 붙이되 전체
## 문장은 tooltip_text로 항상 볼 수 있게 한다.
## N-2로 고유 능력 섹션 폭이 좁아진(아래 ABILITY_DESC_WRAP_WIDTH 참고) 만큼 "최대
## 2줄" 예산도 비례해서 줄였다(이전 70자는 폭 720 기준 — 720->412로 줄어든 비율
## (약 0.57)만큼 70->40으로 축소). **N-2b로 정보 컬럼이 다시 좁아져(480->400,
## ABILITY_DESC_WRAP_WIDTH 412->332) 같은 비율(720 기준)로 재축소: 70*332/720 ≈ 32.**
const ABILITY_DESC_MAX_CHARS := 32
## DISPLAY_PLAYER_HP: 능력치 칩(②)의 HP 표시용 — DESIGN.md 확정값(플레이어 초기
## HP 20, combat_test.gd의 PLAYER_MAX_HP와 동일)을 그대로 복사한 상수다. 캐릭터마다
## 다른 값이 아니라 표시 전용이라 profile 필드로 두지 않았다.
const DISPLAY_PLAYER_HP := 20
## SECTION_BODY_WRAP_WIDTH/ABILITY_DESC_WRAP_WIDTH: autowrap 라벨의 줄바꿈 폭을 레이아웃
## 패스 전에도 못박아두는 값(위 _build_starting_skill_section()/_build_note_section()/
## _build_ability_section() 참고) — N-2로 우측 정보 컬럼 폭이 INFO_COLUMN_WIDTH로
## 좁아져서 기준도 거기(이전엔 detail_container 전체 폭 840)로 바뀌었다. 섹션 패널
## 좌우 여백(14x2=28)을 뺀 값, 고유 능력 섹션은 아이콘(30)+separation(10)만큼 더 좁게.
## **N-2b로 INFO_COLUMN_WIDTH 480->400 — 같은 공식으로 재계산.**
const SECTION_BODY_WRAP_WIDTH := 372.0
const ABILITY_DESC_WRAP_WIDTH := 332.0
## STARTING_SKILL_SLOT_WIDTH: 시작 스킬 슬롯 버튼 한 칸의 폭 — SECTION_BODY_WRAP_WIDTH
## 안에 최대 3칸(+separation 10 x2=20)이 들어와야 하므로 (SECTION_BODY_WRAP_WIDTH-20)/3
## 이하로 잡아야 한다. **N-2b로 (372-20)/3 ≈ 117.**
const STARTING_SKILL_SLOT_WIDTH := 115.0
## N-4(2026-10-15 [대형 기획 14]): 주사위 줄의 ShapeDieChip 한 칸 크기/간격 + 라벨
## ("공격"/"방어"/"이벤트") 고정 폭. MAX_DICE(=6)개가 한 줄에 다 들어가도(6*(26+4)-4=176)
## + 라벨(44) + 여유가 SECTION_BODY_WRAP_WIDTH(372) 예산을 넉넉히 넘지 않는다.
const DICE_CHIP_SIZE := 26.0
const DICE_CHIP_GAP := 4.0
const DICE_ROW_LABEL_WIDTH := 44.0

@onready var cards_container: Control = $CardsContainer/CardsList
@onready var detail_container: Control = $DetailPanelContainer
@onready var start_button: Button = $StartButton
@onready var achievement_button: Button = $AchievementButton
@onready var achievement_panel: AchievementPanel = $AchievementPanel
@onready var test_battle_button: Button = $TestBattleButton
@onready var skill_codex_panel: SkillCodexPanel = $SkillCodexPanel
## [대형 기획 15] Q-2(2026-10-16) — "①캐릭터 ②시작 스킬 ③던전 입장" 3단계 흐름을
## 화면에서도 보이게 하는 작은 안내 띠. 어느 단계가 지금 활성인지는 매 프레임
## 포커스 소유자를 확인해서(_process() 참고) 판단한다 — 카드/슬롯/시작 버튼으로
## 가는 경로가 방향키 체인 이동/Esc/마우스 클릭 등 여러 갈래라, 전환 지점마다
## 일일이 갱신 호출을 추가하는 대신 "지금 포커스가 어디 있는지"만 보면 항상 맞는
## 값이 나온다.
@onready var _step_indicator_label: RichTextLabel = $StepIndicatorLabel

var _selected_id: String = CharacterProfiles.PROFILES[0]["id"]
var _card_panels: Dictionary = {} # id -> PanelContainer (선택 강조 갱신용)
var _current_step := 1
var _last_rendered_step := -1

## L-3(2026-10-14, [대형 기획 12] K-3 후속): 배경을 처음 칠할 때는(화면 진입 직후)
## 즉시 적용하고, 그 뒤로 카드를 바꿀 때마다는 짧은 Tween으로 부드럽게 전환한다
## (INBOX.md 원문 "카드를 고르면 배경이 그 캐릭터 색으로 부드럽게 전환").
var _background_themed := false

## 상세 정보 패널(오른쪽)의 자식 노드들. _build_detail_panel()에서 한 번만 만들고,
## 카드를 고를 때마다 _refresh_detail_panel()이 텍스트/초상만 바꿔 다시 만들지 않는다
## (매번 새로 만들면 불필요하게 무겁고, 스크롤 위치 등 상태가 있다면 리셋될 수 있음).
## **2026-10-13 [대형 기획 11] K-2**: "줄글 나열" 대신 구역(섹션) 단위로 쪼갰다 — 섹션은
## _detail_sections_vbox에 순서대로 쌓이고(①헤더 ②능력치 ③고유 능력 ④시작 스킬
## ⑤안내), 각 섹션의 실제 내용 라벨/아이콘만 아래 필드로 보관한다.
var _detail_sections_vbox: VBoxContainer
## N-2(2026-10-15, [대형 기획 14]): 상세 패널 좌측 "전신 이미지 큰 컬럼"의 배경 패널 +
## 그 안의 고정 크기 홀더(Control, Container가 아니라 자식을 자동으로 리사이즈하지
## 않음 — 레이아웃 패스 타이밍과 무관하게 FULL_ART_SIZE를 그대로 유지하기 위함) +
## 퍼스널 컬러 스포트라이트(CharacterTheme의 비네트 텍스처 재사용, 장식은 약하게).
var _detail_portrait_panel: Panel
var _detail_portrait_holder: Control
var _detail_portrait_spotlight: TextureRect
var _detail_portrait: CharacterPortraitPlaceholder
## 원화가 입고된 캐릭터는 이 TextureRect에 전신(CharacterArt.load_full)을 띄우고
## _detail_portrait(플레이스홀더)를 숨긴다. 원화가 없으면 반대로.
var _detail_art: TextureRect
var _detail_placeholder_note: Label
var _detail_name_label: Label
## ① 헤더의 "컨셉 한 줄" — concept 필드 전체가 아니라 _header_concept_line()으로 줄인
## 짧은 한 줄만 담는다(전체 문장은 tooltip_text로).
var _detail_concept_label: Label
## [대형 기획 12] L-2(c): 헤더 섹션 안에 떠 있는 "스킬 도감" 진입 버튼 — 선택된 캐릭터의
## 도감을 연다(캐릭터 선택 화면이라 owned_skill_ids는 항상 빈 배열, INBOX.md L-2 원문
## "선택 화면에서는 보유 0개" 참고). 캐릭터를 바꿔도 버튼 자체는 다시 만들지 않는다
## (텍스트/클릭 대상이 _selected_id를 매번 읽으므로 그대로 재사용 가능).
var _skill_codex_button: Button
## ② 주사위 줄(N-4, 2026-10-15 [대형 기획 14]): "공격 D4×3" 같은 문자열 대신 실제
## ShapeDieChip을 attack_count/defense_count만큼 나열한다. 각 row는
## _make_dice_row()가 돌려준 {"chips": HBoxContainer(칩이 들어갈 자리, 캐릭터가
## 바뀔 때마다 비우고 다시 채움), "bonus": Label("+n" 배지, 기본 숨김)} — 칩 틀 자체는
## 한 번만 만들고 _refresh_dice_chips()가 내용만 다시 그린다(기존 "텍스트만 갱신"
## 패턴과 동일한 이유).
var _detail_attack_dice_row: Dictionary = {}
var _detail_defense_dice_row: Dictionary = {}
var _detail_event_die_label: Label
var _detail_event_die_visual: EventDieVisual
## ③ 고유 능력 — 아이콘 + 짧은 이름(_ability_short_name) + 2줄 예산 설명(_truncate).
var _detail_skill_icon: SkillIcon
var _detail_ability_name_label: Label
var _detail_skill_label: Label
## ⑤ 안내 섹션의 바깥 패널 — 원화가 있는 캐릭터(대다수)는 보여줄 안내가 없어 라벨만
## 숨기면 "내용 없는 빈 테두리 상자"가 남는다(실제로 screenshot에서 확인됨). 섹션
## 패널 자체를 숨겨 그 자리를 아예 차지하지 않게 한다.
var _detail_note_section_panel: Control

## K-3(캐릭터 퍼스널 컬러): _make_section()이 만든 섹션마다 {panel, title_label(또는
## null)}을 쌓아둔다 — 캐릭터를 바꿀 때마다 _refresh_detail_panel()이 이 목록을 돌며
## CharacterTheme.ui_palette(_selected_id)로 테두리/제목 색을 다시 칠한다(섹션 틀
## 자체는 다시 안 만듦, 기존 "텍스트만 갱신" 패턴과 동일).
var _detail_section_entries: Array[Dictionary] = []

## 시작 스킬 선택([미니 기획 E]-3, INBOX.md 2026-09-17 기획자 결정) — 캐릭터마다
## SkillPool.starting_skills_for_character()가 돌려주는 후보(항상 최대 2개, 슬롯
## 0/1)를 _starting_skill_container 안에 버튼으로 채운다. 캐릭터를 바꿀 때마다 후보
## 목록 자체가 달라지므로(cards_container와 달리) 매번 자식을 지우고 다시 만든다.
var _starting_skill_container: HBoxContainer
var _starting_skill_desc_label: Label
var _starting_skill_lock_badge_label: Label
var _starting_skill_unlock_label: Label

## 잠긴 슬롯을 "미리보기" 중인 스킬 id([대형 기획 5] F-1) — 빈 문자열이면 미리보기
## 없음(설명란은 RunState.chosen_starting_skill_id를 보여줌). 캐릭터를 바꾸거나 실제로
## 해금된 스킬을 고르면 비운다. chosen_starting_skill_id와 별개 상태이므로 미리보기
## 중에도 "던전 시작"은 항상 chosen_starting_skill_id(해금된 마지막 선택) 기준으로 진행된다.
var _preview_skill_id: String = ""

## FocusNav로 방향키 이동(위/아래) + 스페이스 확정 체인을 만드는 데 쓴다(INBOX.md
## 2026-10-13 [대형 기획 11] K-1 — 기존 숫자 단축키를 대체). 캐릭터 카드 패널 자체
## (개수는 PROFILES 길이만큼, 지금 8개 — [대형 기획 12] L-1부터는 카드마다 있던 "선택"
## 버튼이 사라지고 카드 패널(CharacterCardPanel)이 직접 체인에 들어간다)가 먼저 오고,
## 그 뒤로 "던전 시작"/"업적"/"테스트 전투" 화면 공용 버튼이 이어진다. Button이 아닌
## Control도 섞여 들어가므로 타입은 Array[Control](FocusNav.chain_linear/grab_first_focus
## 둘 다 Array를 받아 혼용 가능) — 카드 목록은 _build_cards()에서 한 번만 만들고 이후
## 카드를 다시 그리지 않으므로(선택은 강조 갱신만 함), 여기서도 한 번만 채우면 된다.
var _shortcut_buttons: Array[Control] = []
## 시작 스킬 슬롯(가로 배열) 전용 포커스 체인 — 캐릭터를 바꿀 때마다 후보가 달라지므로
## _rebuild_starting_skill_slots()가 매번 다시 모아 FocusNav.chain_linear()를 다시 부른다.
var _starting_skill_slot_buttons: Array[Button] = []


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	achievement_button.pressed.connect(_on_achievement_pressed)
	_setup_test_battle_button()
	_build_detail_panel()
	_style_header_buttons()
	_build_cards()
	_update_step_indicator()


## [대형 기획 15] Q-2 — 매 프레임 포커스 소유자를 확인해 "①캐릭터 ②시작 스킬
## ③던전 입장" 중 지금 단계를 판단한다. 세 그룹에 속하지 않는 다른 컨트롤(업적/
## 스킬 도감/테스트 전투 버튼 등 화면 공용 단축 버튼)에 포커스가 가 있는 동안은
## 마지막으로 유효했던 단계를 그대로 유지한다(깜빡이며 꺼지지 않게).
func _process(_delta: float) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		# _starting_skill_slot_buttons는 Array[Button]이라, Control로 받은 focus를
		# 캐스팅 없이 그대로 .has()에 넘기면 타입 검사 오류가 난다(값 자체는 Button이어도
		# 정적 타입이 Control이라 막힘) — Button일 때만 캐스팅해서 확인한다.
		if focus is Button and _starting_skill_slot_buttons.has(focus as Button):
			_current_step = 2
		elif focus == start_button:
			_current_step = 3
		elif _card_panels.values().has(focus):
			_current_step = 1
	if _current_step != _last_rendered_step:
		_last_rendered_step = _current_step
		_update_step_indicator()


func _update_step_indicator() -> void:
	var labels := ["① 캐릭터", "② 시작 스킬", "③ 던전 입장"]
	var parts: Array[String] = []
	for i in labels.size():
		if i + 1 == _current_step:
			parts.append("[b][color=#e0c060]%s[/color][/b]" % labels[i])
		else:
			parts.append("[color=#808080]%s[/color]" % labels[i])
	_step_indicator_label.text = "  →  ".join(parts)


## [대형 기획 15] Q-2 — Esc로 "②시작 스킬" 단계에서 "①캐릭터" 단계로 한 단계
## 되돌아간다(요구사항 "Esc는 한 단계 뒤로"). 지금 포커스가 시작 스킬 슬롯 중
## 하나일 때만 반응하므로, 업적/스킬 도감 오버레이 패널이 열려 있을 때의 기존
## Esc(패널 닫기) 동작과 전혀 겹치지 않는다(그때는 포커스가 슬롯에 있지 않음).
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null or not (focus is Button and _starting_skill_slot_buttons.has(focus as Button)):
		return
	var card: Control = _card_panels.get(_selected_id)
	if card == null or not is_instance_valid(card):
		return
	card.grab_focus()
	get_viewport().set_input_as_handled()


## [대형 기획 14] N-3(2026-10-15) — "던전 시작"/"업적"/"테스트 전투"/"스킬 도감" 네
## 버튼이 전수 검색에서 UIKit 스타일링을 전혀 안 받고 기본 Godot 테마로만 그려지고
## 있던 것(사용자 지적 "단순 글자처럼 보인다")을 발견해 고친다. 이 화면의 "공용 버튼은
## 아직 런이 시작되지 않았으니 캐릭터 퍼스널 컬러 대신 중립색을 유지"(DESIGN.md
## "플레이어블 캐릭터" 절 K-3 — 좌측 카드 목록/화면 공용 버튼은 중립, 우측 상세 패널만
## 선택한 카드의 색을 따름)한다는 기존 결정을 지키려고, _selected_id의 퍼스널 컬러가
## 아니라 FocusNav.ACCENT_DEFAULT(이 화면의 포커스 강조색과 같은 중립 시안색)를 tint로
## 넘긴다. _skill_codex_button은 _build_detail_panel()이 먼저 만들어둬야 하므로 그
## 호출 다음에 와야 한다.
func _style_header_buttons() -> void:
	var neutral := FocusNav.ACCENT_DEFAULT
	UIKit.style_secondary_button(achievement_button, RunState.character_id, neutral)
	UIKit.style_secondary_button(test_battle_button, RunState.character_id, neutral)
	UIKit.style_secondary_button(_skill_codex_button, RunState.character_id, neutral)
	_restyle_start_button()


## [대형 기획 15] Q-2(원문 10) — "던전 입장" 버튼은 다른 화면 공용 버튼들과 달리
## (K-3/N-3가 정한 "아직 런이 시작되지 않았으니 중립색" 원칙의 유일한 예외로 사용자가
## 명시 지시) **지금 고른 캐릭터의 퍼스널 컬러**를 그대로 쓴다 — tint 인자를 생략하면
## UIKit.style_primary_button()이 CharacterTheme.ui_palette(_selected_id)["accent"]를
## 쓴다. 카드를 바꿀 때마다(_on_card_selected) 다시 불러야 색이 따라온다.
func _restyle_start_button() -> void:
	UIKit.style_primary_button(start_button, _selected_id)


## [대형 기획 8] H-4: "테스트 전투" 진입 버튼 — RunState.TEST_BATTLE_ENABLED가 false면
## 아예 숨겨서 정식 빌드에서 노출되지 않게 한다. 정식 플레이 흐름(던전 시작/업적)을
## 방해하지 않도록 업적 버튼 바로 아래 작은 크기 + 흐린 색으로 둬 눈에 띄지 않게 한다.
func _setup_test_battle_button() -> void:
	test_battle_button.visible = RunState.TEST_BATTLE_ENABLED
	if not RunState.TEST_BATTLE_ENABLED:
		return
	test_battle_button.add_theme_font_size_override("font_size", 12)
	test_battle_button.modulate = Color(1, 1, 1, 0.55)
	test_battle_button.pressed.connect(_on_test_battle_pressed)


func _build_cards() -> void:
	for c in cards_container.get_children():
		c.queue_free()
	_card_panels.clear()

	# [대형 기획 12] L-1: 카드마다 있던 "선택" 버튼이 사라지고 카드 패널 자체가 포커스
	# 체인에 들어간다(각 카드의 activated 시그널은 _make_card() 안에서 바로 연결됨).
	var card_controls: Array[Control] = []
	# ART-1a(2026-10-07): CARD_HEIGHT(92)를 고정 행 간격으로 썼더니, 패널의 실제
	# 결합 최소 높이(panel 스타일박스 여백 + 내부 버튼/라벨 최소 크기)가 그보다 커서
	# Godot이 자동으로 size를 키우며 다음 행과 겹쳤다. 대신 카드를 추가할 때마다
	# get_combined_minimum_size()로 실제 필요한 높이를 재고 그만큼만 다음 행을 내린다.
	var y := 0.0
	for i in CharacterProfiles.PROFILES.size():
		var profile: Dictionary = CharacterProfiles.PROFILES[i]
		var card := _make_card(profile)
		cards_container.add_child(card)
		card.position = Vector2(0, y)
		var card_height: float = max(CARD_HEIGHT, card.get_combined_minimum_size().y)
		card.size = Vector2(CARD_WIDTH, card_height)
		y += card_height + CARD_GAP
		_card_panels[profile["id"]] = card
		card_controls.append(card)
	cards_container.custom_minimum_size = Vector2(CARD_WIDTH, max(0.0, y - CARD_GAP))

	_refresh_selection_highlight()
	_refresh_detail_panel()

	_shortcut_buttons = card_controls
	_shortcut_buttons.append(_skill_codex_button)
	_shortcut_buttons.append(start_button)
	_shortcut_buttons.append(achievement_button)
	if RunState.TEST_BATTLE_ENABLED:
		_shortcut_buttons.append(test_battle_button)
	FocusNav.chain_linear(_shortcut_buttons, false)
	FocusNav.grab_first_focus(_shortcut_buttons)


## 목록 한 행(K-2, 2026-10-13 개편 / [대형 기획 12] L-1(2026-10-14)로 "선택" 버튼 제거):
## 정사각 얼굴 썸네일 + (이름 / 기믹 한 줄) — 카드 패널(CharacterCardPanel) 전체가
## 클릭/스페이스 선택 영역이라 더는 별도 버튼이 없다. "얼굴 위주 정사각 썸네일 + 이름 +
## 한 줄 기믹 라벨"로 압축해 8명이 스크롤 없이 한눈에 들어오게 했다(INBOX.md 2026-10-13
## [대형 기획 11] K-2). 컨셉 설명/시작 다이스/고유 능력 같은 상세 정보는 여전히 오른쪽
## DetailPanel에만 있다.
func _make_card(profile: Dictionary) -> CharacterCardPanel:
	var panel := CharacterCardPanel.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.activated.connect(_on_card_selected.bind(profile["id"]))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 카드 안의 자식 컨트롤이 클릭을 가로채지 않도록 IGNORE로 비워, 마우스 클릭이 항상
	# panel._gui_input()까지 그대로 통과하게 한다(L-1 원문 "mouse_filter 정리").
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	var portrait_holder := Control.new()
	portrait_holder.custom_minimum_size = Vector2(FACE_THUMB_SIZE, FACE_THUMB_SIZE)
	portrait_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 얼굴 이미지 소스 우선순위(K-2): ① face_neutral.png ② full.png 얼굴 크롭
	# ③ 도형 플레이스홀더(CharacterArt.load_face_thumb()가 ①②를 내부에서 처리).
	var thumb := CharacterArt.load_face_thumb(profile["id"])
	if thumb != null:
		var thumb_rect := TextureRect.new()
		thumb_rect.texture = thumb
		thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_holder.add_child(thumb_rect)
	else:
		_add_placeholder_thumb(portrait_holder, profile)
	hbox.add_child(portrait_holder)

	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 1)
	name_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_vbox)

	var name_label := Label.new()
	name_label.text = profile["name"]
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_vbox.add_child(name_label)

	# 한 줄 기믹 라벨(K-2) — GIMMICK_LABELS의 짧은 이름표를 그대로 재사용, 한 줄로
	# 잘려도(text_overrun) 상세 패널에서 전체 설명을 볼 수 있으니 괜찮다.
	var gimmick_label := Label.new()
	gimmick_label.text = CharacterProfiles.gimmick_label(String(profile.get("gimmick", "")))
	gimmick_label.add_theme_font_size_override("font_size", 12)
	gimmick_label.add_theme_color_override("font_color", Color(0.62, 0.62, 0.65))
	gimmick_label.clip_text = true
	gimmick_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_vbox.add_child(gimmick_label)

	return panel


func _add_placeholder_thumb(portrait_holder: Control, profile: Dictionary) -> void:
	var portrait := CharacterPortraitPlaceholder.new()
	portrait.scale = Vector2(PORTRAIT_SCALE_COMPACT, PORTRAIT_SCALE_COMPACT)
	# 실루엣 그리기 범위는 원본 스케일 기준 x -68~68 / y -108~140(character_portrait_
	# placeholder.gd 참고). PORTRAIT_SCALE_COMPACT(0.2)을 곱하면 x -13.6~13.6 /
	# y -21.6~28 — holder(FACE_THUMB_SIZE 정사각) 안에서 가로/세로 모두 중앙에 오도록
	# 원점을 범위 중간((-21.6+28)/2 ≈ 3.2)만큼 살짝 아래로 내린다.
	portrait.position = Vector2(FACE_THUMB_SIZE / 2.0, FACE_THUMB_SIZE / 2.0 + 3.2)
	portrait.set_palette(profile["hair_color"], profile["dress_color"])
	portrait_holder.add_child(portrait)


## 오른쪽 상세 정보 패널의 뼈대 — K-2(2026-10-13)로 "줄글 한 덩어리" 대신 **구역(섹션)
## 단위**로 다시 짰다. 중요도 순(고유 능력 > 시작 스킬 > 능력치 > 부가 설명)이 아니라
## 읽는 흐름(①누구인지 ②수치 ③고유 능력 ④시작 스킬 ⑤부가 안내) 순서로 쌓되, 가장 위
## "헤더"는 항상 보이는 식별 정보라 별도 취급한다. 각 섹션은 _make_section()으로 만든
## 독립된 테두리 패널이라 "제목 라벨 + 구분선/배경 패널로 시각적으로 분리"(INBOX.md
## 원문) 요구를 구조적으로 만족한다. 실제 텍스트는 _refresh_detail_panel()이 채운다.
func _build_detail_panel() -> void:
	var columns := HBoxContainer.new()
	columns.set_anchors_preset(Control.PRESET_FULL_RECT)
	columns.add_theme_constant_override("separation", PORTRAIT_COLUMN_GAP)
	detail_container.add_child(columns)

	_build_portrait_column(columns)

	_detail_sections_vbox = VBoxContainer.new()
	_detail_sections_vbox.custom_minimum_size = Vector2(INFO_COLUMN_WIDTH, 0)
	_detail_sections_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_sections_vbox.add_theme_constant_override("separation", 8)
	columns.add_child(_detail_sections_vbox)

	_build_header_section()
	_build_stats_section()
	_build_ability_section()
	_build_starting_skill_section()
	_build_note_section()


## N-2(2026-10-15, [대형 기획 14]): 상세 패널 좌측 "전신 이미지 큰 컬럼" — 원화가
## 주인공이 되도록 테두리 패널 하나에 퍼스널 컬러 스포트라이트(약한 방사형 그라데이션)만
## 깔고 그 위에 전신 원화(또는 플레이스홀더)를 크게 띄운다. INBOX.md 지시대로 장식은
## 스포트라이트 하나뿐 — 추가 장식(바닥 그림자 등)은 넣지 않았다. 패널(Panel, 자식을
## 자동으로 리사이즈하지 않는 단순 Control)을 쓴 이유는 PanelContainer처럼 레이아웃
## 패스 시점에 홀더 크기를 바꿔버리면 FULL_ART_SIZE로 못박은 테스트 기준이 레이아웃
## 타이밍에 따라 달라질 수 있기 때문.
func _build_portrait_column(parent: Control) -> void:
	_detail_portrait_panel = Panel.new()
	_detail_portrait_panel.custom_minimum_size = Vector2(PORTRAIT_COLUMN_WIDTH, 0)
	_detail_portrait_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.85)
	style.border_color = CharacterTheme.NEUTRAL_PRIMARY
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	_detail_portrait_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(_detail_portrait_panel)

	_detail_portrait_holder = Control.new()
	_detail_portrait_holder.custom_minimum_size = FULL_ART_SIZE
	_detail_portrait_holder.size = FULL_ART_SIZE
	var pad_x: float = (PORTRAIT_COLUMN_WIDTH - FULL_ART_SIZE.x) / 2.0
	_detail_portrait_holder.position = Vector2(pad_x, PORTRAIT_COLUMN_TOP_PAD)
	_detail_portrait_panel.add_child(_detail_portrait_holder)

	_detail_portrait_spotlight = TextureRect.new()
	_detail_portrait_spotlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_portrait_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_portrait_spotlight.stretch_mode = TextureRect.STRETCH_SCALE
	_detail_portrait_spotlight.texture = CharacterTheme.get_portrait_spotlight_texture()
	_detail_portrait_holder.add_child(_detail_portrait_spotlight)

	_detail_portrait = CharacterPortraitPlaceholder.new()
	_detail_portrait.scale = Vector2(PORTRAIT_SCALE_FULL, PORTRAIT_SCALE_FULL)
	# 실루엣 그리기 범위는 원본 스케일 기준 x -68~68 / y -108~140(세로 중심 16) —
	# PORTRAIT_SCALE_FULL을 곱한 뒤 홀더 중앙에 오도록 원점을 보정한다(_add_placeholder_thumb/
	# 과거 헤더 섹션과 같은 계산 패턴).
	_detail_portrait.position = Vector2(FULL_ART_SIZE.x / 2.0, FULL_ART_SIZE.y / 2.0 - 16 * PORTRAIT_SCALE_FULL)
	_detail_portrait_holder.add_child(_detail_portrait)

	_detail_art = TextureRect.new()
	_detail_art.custom_minimum_size = FULL_ART_SIZE
	_detail_art.size = FULL_ART_SIZE
	_detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_detail_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_portrait_holder.add_child(_detail_art)


## 섹션 공통 틀 — title이 있으면 제목 라벨을 맨 위에 두고, 테두리+배경 패널로 감싼
## VBoxContainer(섹션 내용을 담을 "body")를 반환한다. title이 빈 문자열이면 제목 없이
## 틀만 만든다(헤더 섹션 전용 — 이름 자체가 이미 제목 역할을 하므로 중복 라벨 불필요).
## 생성한 panel(+title_label, 있으면)은 _detail_section_entries에 쌓아 K-3이 캐릭터별
## 색으로 다시 칠할 수 있게 한다 — 여기서 넣는 색은 아직 중립값(NEUTRAL_PRIMARY 계열)일
## 뿐, 실제 캐릭터색 적용은 항상 _refresh_detail_panel()이 담당한다(최초 호출도 포함).
func _make_section(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.13, 0.92)
	style.border_color = Color(0.32, 0.32, 0.37)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	_detail_sections_vbox.add_child(panel)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	panel.add_child(body)

	var title_label: Label = null
	if title != "":
		title_label = Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", 13)
		title_label.add_theme_color_override("font_color", Color(0.55, 0.78, 0.82))
		body.add_child(title_label)

	_detail_section_entries.append({"panel": panel, "title_label": title_label})
	return body


## K-3: 캐릭터를 바꿀 때마다 섹션 5개의 테두리를 그 캐릭터의 primary 색으로, 제목
## 라벨을 accent 색으로 다시 칠한다. character_id가 비어있던 적은 없지만(RunState.
## character_id는 항상 PROFILES[0]으로 초기화) 방어적으로 CharacterTheme.ui_palette()의
## "" 폴백(중립색)도 그대로 성립한다.
func _apply_detail_section_theme(character_id: String) -> void:
	var palette := CharacterTheme.ui_palette(character_id)
	for entry in _detail_section_entries:
		var panel: PanelContainer = entry["panel"]
		CharacterTheme.apply(panel, character_id, false)
		var title_label: Label = entry["title_label"]
		if title_label != null:
			title_label.add_theme_color_override("font_color", palette["accent"])


## ① 헤더: 이름 + 컨셉 한 줄 (전신 원화는 N-2로 좌측 전용 컬럼(_build_portrait_column)으로
## 분리됐다 — "전신 원화를 화면에서 가장 크게 보이는 요소로" INBOX.md 지시 반영).
func _build_header_section() -> void:
	var body := _make_section("")

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	body.add_child(hbox)

	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 6)
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(name_vbox)

	_detail_name_label = Label.new()
	_detail_name_label.add_theme_font_size_override("font_size", 28)
	_detail_name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	name_vbox.add_child(_detail_name_label)

	# 컨셉 "한 줄"(K-2 원문) — clip_text+OVERRUN_TRIM_ELLIPSIS로 폭을 넘는 긴 문장도
	# 시각적으로는 항상 한 줄로만 보이게 강제한다(전체 문장은 tooltip_text로).
	_detail_concept_label = Label.new()
	_detail_concept_label.add_theme_font_size_override("font_size", 15)
	_detail_concept_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_detail_concept_label.clip_text = true
	_detail_concept_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_vbox.add_child(_detail_concept_label)

	# [대형 기획 12] L-2(c): name_vbox가 SIZE_EXPAND_FILL이라 남는 가로 공간을 전부 먹으므로,
	# 그 뒤에 버튼을 추가하면 hbox 맨 오른쪽(헤더 섹션 안)에 자리잡는다 — 새 섹션/고정
	# 좌표 없이 기존 레이아웃만으로 "우측 패널의 스킬 도감 버튼"(INBOX.md 원문)을 만족.
	_skill_codex_button = Button.new()
	_skill_codex_button.text = "스킬 도감"
	_skill_codex_button.custom_minimum_size = Vector2(110, 32)
	_skill_codex_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_skill_codex_button.pressed.connect(_on_skill_codex_pressed)
	hbox.add_child(_skill_codex_button)


## ② 주사위 줄(N-4, 2026-10-15 [대형 기획 14]): "공격 D4×3" 같은 문자열 대신 실제
## 다이스 칩/아이콘을 개수만큼 나열한다 — INBOX.md 원문 "실제 주사위를 나열해서
## 보여주기", shape_die_chip.gd/event_die_visual.gd를 그대로 재사용하고 새로 그리지
## 않는다. 공격/방어/이벤트 3줄 + (고정값) HP 한 줄 구조. 칩 내용(개수/모양/시작
## 보너스 배지)은 캐릭터·시작 스킬 선택이 바뀔 때마다 _refresh_dice_chips()가 다시
## 그린다 — 여기서는 "줄" 틀(라벨+칩 컨테이너+배지)만 한 번 만든다.
func _build_stats_section() -> void:
	var body := _make_section("능력치")
	var dice_rows := VBoxContainer.new()
	dice_rows.add_theme_constant_override("separation", 6)
	body.add_child(dice_rows)

	_detail_attack_dice_row = _make_dice_row(dice_rows, "공격")
	_detail_defense_dice_row = _make_dice_row(dice_rows, "방어")

	# 이벤트 주사위(INBOX.md 2026-09-15 [미니 기획 B]-4): 공격/방어와 별개인 특수 이벤트
	# 전용 다이스 — 로마 숫자 육각 칩(EventDieVisual)으로 일반 다이스와 구분해서 보여준다.
	# N-4: "공격"/"방어"와 같은 라벨+칩 줄 구조를 맞추고, 로마 숫자만으로는 면 수가
	# 바로 안 읽히므로 옆에 "D%d" 텍스트를 같이 둔다.
	var event_row := HBoxContainer.new()
	event_row.add_theme_constant_override("separation", 8)
	dice_rows.add_child(event_row)

	var event_tag := Label.new()
	event_tag.text = "이벤트"
	event_tag.custom_minimum_size = Vector2(DICE_ROW_LABEL_WIDTH, 0)
	event_tag.add_theme_font_size_override("font_size", 13)
	event_tag.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	event_row.add_child(event_tag)

	_detail_event_die_visual = EventDieVisual.new()
	_detail_event_die_visual.custom_minimum_size = Vector2(DICE_CHIP_SIZE, DICE_CHIP_SIZE)
	event_row.add_child(_detail_event_die_visual)

	_detail_event_die_label = Label.new()
	_detail_event_die_label.add_theme_font_size_override("font_size", 13)
	_detail_event_die_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	event_row.add_child(_detail_event_die_label)

	var hp_chip := _make_stat_chip()
	# [대형 기획 13] M-5(b): icon/hp.png(흰 하트 실루엣)가 있으면 그 이미지를 빨간색으로
	# 칠해 쓰고, 없으면 기존 "♥" 글자 아이콘 그대로(폴백).
	var hp_icon_color := Color(0.85, 0.3, 0.35)
	var hp_icon_tex := UIKit.icon_texture("hp", hp_icon_color)
	if hp_icon_tex != null:
		var hp_icon_rect := TextureRect.new()
		hp_icon_rect.texture = hp_icon_tex
		hp_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		hp_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hp_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hp_icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hp_chip["icon_holder"].add_child(hp_icon_rect)
	else:
		var hp_icon := Label.new()
		hp_icon.text = "♥"
		hp_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hp_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		hp_icon.add_theme_font_size_override("font_size", 16)
		hp_icon.add_theme_color_override("font_color", hp_icon_color)
		hp_chip["icon_holder"].add_child(hp_icon)
	hp_chip["label"].text = "HP %d" % DISPLAY_PLAYER_HP
	body.add_child(hp_chip["chip"])


## 주사위 줄 하나(라벨 + 칩이 채워질 빈 컨테이너 + "+n" 보너스 배지, 기본 숨김) 틀을
## parent에 추가하고 {"chips": HBoxContainer, "bonus": Label}을 돌려준다. 실제 칩은
## _refresh_dice_chips()가 캐릭터/시작 스킬이 바뀔 때마다 chips 컨테이너를 비우고
## 다시 채운다.
func _make_dice_row(parent: Control, label_text: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var tag := Label.new()
	tag.text = label_text
	tag.custom_minimum_size = Vector2(DICE_ROW_LABEL_WIDTH, 0)
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	row.add_child(tag)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", DICE_CHIP_GAP)
	row.add_child(chips)

	var bonus := Label.new()
	bonus.add_theme_font_size_override("font_size", 13)
	bonus.add_theme_color_override("font_color", FaceChipStyle.MAX_FACE_BG_COLOR)
	bonus.visible = false
	row.add_child(bonus)

	return {"chips": chips, "bonus": bonus}


## N-4: 캐릭터(또는 캐릭터의 attack_count/defense_count/event_die_sides)가 바뀔 때마다
## 공격/방어/이벤트 다이스 칩을 다시 그린다. "시작 보너스" 배지는 여기서 건드리지 않고
## _refresh_dice_bonus_badges()가 따로 맡는다 — 호출 시점에 RunState.chosen_starting_
## skill_id가 아직 새 캐릭터 기준으로 검증되지 않았을 수 있어서(_rebuild_starting_
## skill_slots()가 그 검증을 끝낸 뒤에야 배지를 계산해야 함, 아래 참고).
func _refresh_dice_chips(profile: Dictionary) -> void:
	var attack_count: int = int(profile.get("attack_count", 3))
	var defense_count: int = int(profile.get("defense_count", 3))
	# attack_sides/defense_sides: 지금은 8명 전부 D4로 동일해 프로필에 없는 필드지만,
	# get()의 기본값(4)으로 "면 수가 다른 시작 다이스"가 생겨도 이 함수는 손댈 필요가
	# 없다(INBOX.md N-4 원문 "서로 다른 면 수라면 각각 다른 모양/숫자로").
	var attack_sides: int = int(profile.get("attack_sides", 4))
	var defense_sides: int = int(profile.get("defense_sides", 4))
	_fill_dice_chip_row(_detail_attack_dice_row["chips"], attack_count, attack_sides)
	_fill_dice_chip_row(_detail_defense_dice_row["chips"], defense_count, defense_sides)

	var event_sides: int = int(profile.get("event_die_sides", 6))
	_detail_event_die_label.text = "D%d" % event_sides
	_detail_event_die_visual.value = 1


## chips 컨테이너를 비우고 count개의 ShapeDieChip을 다시 채운다 — 각 칩은 그 다이스의
## 면 모양(shape_sides_for_dice_sides)을 그리고, 값 칸에는 굴림 결과가 아니라 면 수
## 자체(sides)를 보여준다(예: D4 세모 칩에 "4") — "이 주머니에 D4가 몇 개 있는지"를
## 한눈에 보여주는 정적 미리보기이지, 전투 중 굴림 결과 칩(combat_test.gd)과는 용도가
## 다르다.
func _fill_dice_chip_row(container: HBoxContainer, count: int, sides: int) -> void:
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()
	var shape_sides := ShapeDieChip.shape_sides_for_dice_sides(sides)
	for i in count:
		var chip := ShapeDieChip.new()
		chip.custom_minimum_size = Vector2(DICE_CHIP_SIZE, DICE_CHIP_SIZE)
		chip.size = Vector2(DICE_CHIP_SIZE, DICE_CHIP_SIZE)
		chip.shape_sides = shape_sides
		chip.value = sides
		container.add_child(chip)


## N-4 "+n 배지": 캐릭터 선택 화면은 전투 상태(HP/골드/인벤토리/보유 재질 등)가 없는
## "런 시작 전" 화면이라, RunState에 의존하는 시작 스킬 조건(수집가/선제/대비/황금손/
## 과적/오뚝이/잡화점/강철 방비)은 미리 계산할 수 없다 — attack_count/defense_count
## "개수"만으로 결정되는 4종(맹공/철벽/확장/정예)만 미리보기 배지로 보여준다.
## combat_test.gd의 실제 전투 적용 함수를 그대로 재사용해(load() 패턴은 dice_test.gd가
## 이미 쓰는 것과 동일) 공식을 두 곳에 중복 정의하지 않는다.
func _static_dice_bonus(skill_id: String, attack_count: int, defense_count: int) -> Dictionary:
	var combat_script := load("res://code/scenes/combat_test.gd")
	var atk := 0
	var def := 0
	match skill_id:
		"start_aggro":
			atk = combat_script._aggro_bonus(attack_count, defense_count)
		"start_wall":
			def = combat_script._wall_bonus(attack_count, defense_count)
		"start_expand":
			var expand_bonus: int = combat_script._expand_bonus(attack_count, defense_count)
			atk = expand_bonus
			def = expand_bonus
		"start_lean":
			var lean_bonus: int = combat_script._lean_bonus(attack_count, defense_count)
			atk = lean_bonus
			def = lean_bonus
	return {"attack": atk, "defense": def}


## RunState.chosen_starting_skill_id가 바뀔 때마다(캐릭터 전환으로 검증된 기본값으로
## 되돌아갈 때 포함) 공격/방어 다이스 줄의 "+n" 배지를 다시 계산한다.
## _rebuild_starting_skill_slots()가 chosen_starting_skill_id를 검증/확정한 직후에만
## 호출돼야 하므로(이 함수 자체는 호출 시점을 가리지 않음), 그 함수 맨 끝에서만 부른다.
func _refresh_dice_bonus_badges() -> void:
	var profile := CharacterProfiles.get_profile(_selected_id)
	var attack_count: int = int(profile.get("attack_count", 3))
	var defense_count: int = int(profile.get("defense_count", 3))
	var bonus := _static_dice_bonus(RunState.chosen_starting_skill_id, attack_count, defense_count)
	_set_bonus_label(_detail_attack_dice_row["bonus"], int(bonus["attack"]))
	_set_bonus_label(_detail_defense_dice_row["bonus"], int(bonus["defense"]))


func _set_bonus_label(label: Label, n: int) -> void:
	if n > 0:
		label.text = "+%d" % n
		label.visible = true
	else:
		label.text = ""
		label.visible = false


## 칩 하나(테두리 패널 + 아이콘 칸 + 텍스트 라벨)의 공통 틀. 아이콘은 호출하는 쪽이
## icon_holder에 직접 add_child하고, 텍스트는 label.text로 채운다(캐릭터가 바뀌어도
## 칩 틀 자체는 다시 만들지 않고 label.text만 _refresh_detail_panel()이 갱신).
func _make_stat_chip() -> Dictionary:
	var chip := PanelContainer.new()
	# [대형 기획 13] M-5(b): deco/chip.png가 있으면 그 배경 이미지를 쓰고, 없으면 기존
	# StyleBoxFlat 절차적 칩 배경 그대로(폴백).
	if not UIKit.apply_chip_skin(chip):
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.16, 0.2, 0.9)
		style.border_color = Color(0.4, 0.4, 0.46)
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 10
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		chip.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	chip.add_child(row)

	var icon_holder := Control.new()
	icon_holder.custom_minimum_size = Vector2(22, 22)
	row.add_child(icon_holder)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	row.add_child(label)

	return {"chip": chip, "icon_holder": icon_holder, "label": label}


## ③ 고유 능력: SkillIcon + 짧은 이름(_ability_short_name) + 최대 2줄 설명(_truncate로
## ABILITY_DESC_MAX_CHARS 예산 안에 자름, 전체 문장은 tooltip_text).
func _build_ability_section() -> void:
	var body := _make_section("고유 능력")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)

	_detail_skill_icon = SkillIcon.new()
	_detail_skill_icon.custom_minimum_size = Vector2(30, 30)
	row.add_child(_detail_skill_icon)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_vbox)

	_detail_ability_name_label = Label.new()
	_detail_ability_name_label.add_theme_font_size_override("font_size", 15)
	_detail_ability_name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	text_vbox.add_child(_detail_ability_name_label)

	_detail_skill_label = _make_detail_body_label()
	_detail_skill_label.add_theme_font_size_override("font_size", 13)
	# autowrap 라벨은 줄바꿈 폭을 "실제 할당된 size.x"로 계산하는데, 이 화면은 아직
	# 레이아웃 패스(컨테이너 sort_children)를 한 번도 안 거친 시점에 바로 다음 카드를
	# 고를 수 있어(예: QA가 _on_card_selected를 연속 호출) size.x가 0인 채로 최소 높이가
	# 계산될 수 있다(모든 글자가 한 줄씩 줄바꿈돼 비정상적으로 커짐) — custom_minimum_size
	# 뿐 아니라 size도 미리 못박아 K-2 레이아웃 예산 검증(dice_test.gd)이 항상 정확한
	# 값을 읽게 한다.
	_detail_skill_label.custom_minimum_size = Vector2(ABILITY_DESC_WRAP_WIDTH, 0)
	_detail_skill_label.size = Vector2(ABILITY_DESC_WRAP_WIDTH, _detail_skill_label.size.y)
	text_vbox.add_child(_detail_skill_label)


## ④ 시작 스킬 (하나만 선택) — 슬롯 버튼 목록 + 선택/미리보기 설명. 슬롯 버튼 자체는
## 후보가 캐릭터마다 다르므로 여기서는 빈 컨테이너만 만들고, 실제 채우기는
## _rebuild_starting_skill_slots()가 캐릭터를 고를 때마다 담당한다.
func _build_starting_skill_section() -> void:
	var body := _make_section("시작 스킬 (하나만 선택)")

	_starting_skill_container = HBoxContainer.new()
	_starting_skill_container.add_theme_constant_override("separation", 10)
	body.add_child(_starting_skill_container)

	# 잠긴 슬롯 미리보기([대형 기획 5] F-1) — 자물쇠+"잠김" 배지(맨 위) / 효과 설명
	# (기존 _starting_skill_desc_label 재사용, 선택/미리보기 공통) / 해금 조건(노란 계열,
	# 미리보기 중일 때만 보임) 순서로 쌓는다.
	_starting_skill_lock_badge_label = _make_detail_body_label()
	_starting_skill_lock_badge_label.text = "🔒 잠김 (미리보기)"
	_starting_skill_lock_badge_label.add_theme_color_override("font_color", Color(0.85, 0.68, 0.25))
	_starting_skill_lock_badge_label.visible = false
	body.add_child(_starting_skill_lock_badge_label)

	_starting_skill_desc_label = _make_detail_body_label()
	_starting_skill_desc_label.add_theme_font_size_override("font_size", 13)
	# _build_ability_section()의 _detail_skill_label과 같은 이유로 size를 미리 못박는다.
	_starting_skill_desc_label.custom_minimum_size = Vector2(SECTION_BODY_WRAP_WIDTH, 0)
	_starting_skill_desc_label.size = Vector2(SECTION_BODY_WRAP_WIDTH, _starting_skill_desc_label.size.y)
	body.add_child(_starting_skill_desc_label)

	_starting_skill_unlock_label = _make_detail_body_label()
	_starting_skill_unlock_label.add_theme_font_size_override("font_size", 12)
	_starting_skill_unlock_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	_starting_skill_unlock_label.custom_minimum_size = Vector2(SECTION_BODY_WRAP_WIDTH, 0)
	_starting_skill_unlock_label.size = Vector2(SECTION_BODY_WRAP_WIDTH, _starting_skill_unlock_label.size.y)
	_starting_skill_unlock_label.visible = false
	body.add_child(_starting_skill_unlock_label)


## ⑤ 해금/참고 안내 — 지금은 "원화 미입고 플레이스홀더" 안내 한 줄뿐이다(원화가 입고된
## 캐릭터는 visible=false). 새 안내 문구가 필요해지면 이 섹션에 라벨을 추가하면 된다.
func _build_note_section() -> void:
	var body := _make_section("")
	_detail_note_section_panel = body.get_parent()
	_detail_placeholder_note = Label.new()
	_detail_placeholder_note.text = "※ 플레이스홀더 실루엣 — 실제 일러스트는 추후 작업"
	_detail_placeholder_note.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_placeholder_note.add_theme_font_size_override("font_size", 11)
	_detail_placeholder_note.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_detail_placeholder_note.custom_minimum_size = Vector2(SECTION_BODY_WRAP_WIDTH, 0)
	_detail_placeholder_note.size = Vector2(SECTION_BODY_WRAP_WIDTH, _detail_placeholder_note.size.y)
	body.add_child(_detail_placeholder_note)


func _make_detail_body_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	return label


## concept 문자열에서 "—"(기호) 앞부분만 뽑아 헤더용 짧은 한 줄로 쓴다(예: "극단형 —
## 공격/방어 다이스가..." -> "극단형"). "—"가 없으면(견습 모험가 등) _truncate()로
## 길이만 제한한다.
func _header_concept_line(concept: String) -> String:
	var dash_idx := concept.find("—")
	if dash_idx != -1:
		return concept.substr(0, dash_idx).strip_edges()
	return _truncate(concept, 40)


## CharacterProfiles.gimmick_label()의 "극단 (Min/Max 전용, 중간값 없음)" 같은 문자열에서
## " (" 앞부분만 뽑아 고유 능력 섹션의 짧은 이름으로 쓴다.
func _ability_short_name(gimmick: String) -> String:
	var label := CharacterProfiles.gimmick_label(gimmick)
	var paren_idx := label.find(" (")
	if paren_idx == -1:
		return label
	return label.substr(0, paren_idx)


## 문자열을 max_chars 이내로 자르고, 실제로 잘렸으면 말줄임표(…)를 붙인다.
func _truncate(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars - 1).strip_edges() + "…"


## 선택된 캐릭터가 바뀔 때마다 상세 패널 내용을 갱신한다(섹션 틀 자체는 다시 안 만들고
## 텍스트/아이콘 category만 바꾼다). "시작 다이스"는 desc의 서술형 문장을 다시 파싱하지
## 않고 attack_count/defense_count에서 직접 만들어(DESIGN.md 확정대로 면 개수는 8종
## 전부 D4) 캐릭터별 수치 변경에 항상 정확하다.
func _refresh_detail_panel() -> void:
	var profile := CharacterProfiles.get_profile(_selected_id)
	_apply_detail_section_theme(_selected_id)
	CharacterTheme.apply_background(self, _selected_id, _background_themed)
	_background_themed = true
	var title := get_node_or_null("Title")
	if title is Label:
		CharacterTheme.apply_label(title, _selected_id)
	_detail_portrait.set_palette(profile["hair_color"], profile["dress_color"])
	var art := CharacterArt.load_full(_selected_id)
	_detail_art.texture = art
	_detail_art.visible = art != null
	_detail_portrait.visible = art == null
	_detail_placeholder_note.visible = art == null
	_detail_note_section_panel.visible = art == null
	# N-2: 전신 이미지 컬럼의 테두리/스포트라이트도 섹션들과 같은 캐릭터 색으로.
	CharacterTheme.apply(_detail_portrait_panel, _selected_id, false)
	var spotlight_tint: Color = CharacterTheme.ui_palette(_selected_id)["primary"]
	spotlight_tint.a = 1.0
	_detail_portrait_spotlight.modulate = spotlight_tint
	_detail_name_label.text = profile["name"]

	var concept: String = String(profile.get("concept", profile.get("desc", "")))
	_detail_concept_label.text = _header_concept_line(concept)
	_detail_concept_label.tooltip_text = concept

	_refresh_dice_chips(profile)

	var gimmick: String = String(profile.get("gimmick", ""))
	_detail_skill_icon.category = gimmick
	_detail_ability_name_label.text = _ability_short_name(gimmick)
	_detail_skill_label.text = _truncate(concept, ABILITY_DESC_MAX_CHARS)
	_detail_skill_label.tooltip_text = concept

	_preview_skill_id = "" # 캐릭터가 바뀌면 이전 캐릭터의 잠긴 슬롯 미리보기는 의미가 없다.
	_rebuild_starting_skill_slots()


## [미니 기획 E]-3: 캐릭터를 고를 때마다 그 캐릭터의 시작 스킬 후보(항상 슬롯 0/1,
## SkillPool.starting_skills_for_character() 등장 순서)로 슬롯 버튼을 다시 그린다.
## 먼저 RunState.chosen_starting_skill_id가 이 캐릭터에서 여전히 유효한지(후보에
## 있고, 잠겨있지 않은지) 검증해 아니면 슬롯 0으로 되돌린다 — 예를 들어 "확장"
## (start_expand)은 견습 모험가의 슬롯 0(항상 해금)이지만 폭발병의 슬롯 1(업적
## 해금 필요)이기도 해서, 같은 id라도 캐릭터가 바뀌면 잠금 상태가 달라질 수 있다.
func _rebuild_starting_skill_slots() -> void:
	# remove_child()로 즉시 트리에서 떼어낸 뒤 queue_free()로 지운다(단순 queue_free()만
	# 쓰면 그 프레임 끝까지 컨테이너 자식 목록에 남아 새로 추가한 버튼과 인덱스가
	# 섞인다 — 이 함수는 같은 프레임 안에서 슬롯 버튼 자신의 pressed 핸들러
	# (_on_starting_skill_selected)에서도 호출되므로, remove_child()로 즉시 떼어내되
	# 실제 메모리 해제는 여전히 queue_free()로 미뤄 시그널 처리 중 해제로 인한
	# 크래시를 피한다).
	for c in _starting_skill_container.get_children():
		_starting_skill_container.remove_child(c)
		c.queue_free()

	var candidates := SkillPool.starting_skills_for_character(_selected_id)
	RunState.chosen_starting_skill_id = _valid_or_default_starting_skill_id(_selected_id, RunState.chosen_starting_skill_id, candidates)

	_starting_skill_slot_buttons = []
	for i in candidates.size():
		var skill: Dictionary = candidates[i]
		var unlocked: bool = _is_slot_unlocked(_selected_id, i)
		if unlocked:
			# [대형 기획 12] L-2(a): 해금된 슬롯은 이름/효과가 곧바로 보이므로(아래
			# _make_starting_skill_slot()의 unlocked 분기), 렌더링 시점이 곧 "발견"이다.
			# 잠긴 슬롯은 "???"만 보이므로 여기서는 기록하지 않고
			# _on_starting_skill_locked_preview()가 대신 기록한다.
			SkillCodex.mark_discovered(_selected_id, skill["id"])
		var slot_button := _make_starting_skill_slot(skill, unlocked, i)
		_starting_skill_container.add_child(slot_button)
		_starting_skill_slot_buttons.append(slot_button)
	# K-3: 시작 스킬 슬롯의 포커스 테두리도 캐릭터 accent 색을 쓴다(K-1의 ACCENT_DEFAULT
	# 대신). 상세 패널 전체가 이미 그 캐릭터 색이므로 포커스 색도 일관되게 맞춘다.
	FocusNav.chain_linear(_starting_skill_slot_buttons, true, false, false, CharacterTheme.ui_palette(_selected_id)["accent"])
	# [대형 기획 14] N-1 전수 감사에서 발견: 이 수평 체인이 카드 목록(수직 체인,
	# _shortcut_buttons)과 전혀 연결돼 있지 않아 시작 스킬 슬롯이 마우스로만 닿을 수
	# 있었다(카드 체인의 상/하 이동은 chain_linear가 설정하지만, 좌/우는 건드리지
	# 않으므로 여기서 직접 이어도 카드 체인을 깨지 않는다). 카드 목록 쪽에서
	# 오른쪽으로 들어오면 슬롯[0]으로, 슬롯 쪽에서 위/아래/왼쪽으로 나가면 지금 선택된
	# 캐릭터 카드로 돌아간다 — 캐릭터를 바꿀 때마다(이 함수가 다시 불릴 때마다) 새로
	# 만들어진 슬롯 버튼에 매번 다시 걸어야 한다.
	_link_cards_to_skill_slots()

	_update_starting_skill_description(candidates)
	# N-4: chosen_starting_skill_id가 방금 이 캐릭터 기준으로 검증/확정됐으므로(위
	# _valid_or_default_starting_skill_id 호출), 이 시점에만 "+n" 배지를 다시 계산한다.
	_refresh_dice_bonus_badges()


## _on_starting_skill_selected()/_on_starting_skill_locked_preview()의 공통 마무리.
## [대형 기획 14] N-1 전수 감사에서 발견: _rebuild_starting_skill_slots()는 슬롯
## 버튼을 매번 통째로 지우고 새로 만드는데(remove_child+queue_free), 그 호출이 슬롯
## 버튼 자신의 pressed 핸들러에서 일어나면 방금 눌렀던(그래서 포커스를 갖고 있던)
## 버튼이 사라지고 아무도 포커스를 새로 받지 않아, 방향키를 다시 눌러도 반응이 없는
## "키보드 진행 끊김" 상태가 됐다(마우스로 다시 클릭해야만 포커스가 생김). 방금
## 고르거나 미리보던 스킬과 같은 슬롯에 포커스를 돌려줘 방향키 조작이 끊기지 않게
## 한다. **_refresh_detail_panel()(캐릭터 카드를 바꿀 때)의 _rebuild_starting_skill_
## slots() 호출에는 이 함수를 쓰지 않는다** — 그때는 포커스가 여전히 카드 목록에
## 있어야 하므로(연속으로 카드를 훑어보는 중일 수 있음), 상세 패널로 포커스를 뺏으면
## 카드 탐색이 끊긴다.
func _restore_starting_skill_focus(target_id: String) -> void:
	if _starting_skill_slot_buttons.is_empty():
		return
	var candidates := SkillPool.starting_skills_for_character(_selected_id)
	for i in candidates.size():
		if candidates[i]["id"] == target_id:
			_starting_skill_slot_buttons[i].grab_focus()
			return
	_starting_skill_slot_buttons[0].grab_focus()


## _rebuild_starting_skill_slots()가 매번 호출 — 카드 목록(수직 체인)과 시작 스킬
## 슬롯(수평 체인)을 오갈 수 있게 바깥쪽 축만 잇는다. 어느 카드에서든 오른쪽으로
## 슬롯[0]에 들어가고, 어느 슬롯에서든 위/아래/왼쪽으로 "지금 선택된" 카드로 나간다
## (슬롯이 몇 개든, 어느 슬롯에 포커스가 있든 돌아갈 곳은 항상 하나로 고정해 방향키
## 이동이 예측 가능하게 한다).
func _link_cards_to_skill_slots() -> void:
	if _starting_skill_slot_buttons.is_empty():
		return
	var selected_card: Control = _card_panels.get(_selected_id)
	if selected_card == null or not is_instance_valid(selected_card):
		return
	var first_slot: Button = _starting_skill_slot_buttons[0]
	for card in _card_panels.values():
		if card == null or not is_instance_valid(card):
			continue
		card.focus_neighbor_right = card.get_path_to(first_slot)
	for slot in _starting_skill_slot_buttons:
		slot.focus_neighbor_left = slot.get_path_to(selected_card)
		slot.focus_neighbor_top = slot.get_path_to(selected_card)
		slot.focus_neighbor_bottom = slot.get_path_to(selected_card)


## 슬롯 해금 여부를 SkillPool.is_slot_requirement_met() 한 곳에서만 판정한다([대형 기획 5]
## F-1, F-2(a)) — 예전에는 이 파일 안에 "clear_" + id 하드코딩이 두 곳 있었는데, 그 둘을
## 포함해 SkillPool로 단일화했다(마이그레이션 "또는" 판정도 거기서 처리).
func _is_slot_unlocked(character_id: String, slot_index: int) -> bool:
	return SkillPool.is_slot_requirement_met(character_id, slot_index)


## chosen_id가 candidates 안에서 "잠기지 않은" 슬롯을 가리키면 그대로 유지하고,
## 아니면 슬롯 0(candidates[0], 후보가 있는 한 항상 해금 상태)으로 되돌린다.
## 후보가 비어있으면(정의 누락 등 이상 상황) 빈 문자열을 반환한다.
func _valid_or_default_starting_skill_id(character_id: String, chosen_id: String, candidates: Array[Dictionary]) -> String:
	if candidates.is_empty():
		return ""
	for i in candidates.size():
		if candidates[i]["id"] == chosen_id:
			if _is_slot_unlocked(character_id, i):
				return chosen_id
			break
	return candidates[0]["id"]


## 슬롯 하나(PanelContainer 역할을 겸하는 Button)를 만든다. [대형 기획 5] F-1부터는
## 잠긴 슬롯도 클릭 가능하다(disabled=false로 유지) — 클릭하면 chosen_starting_skill_id를
## 바꾸는 대신 "미리보기"(_on_starting_skill_locked_preview)로 빠진다. 잠긴 슬롯은
## 여전히 LockIcon + 흐린 이름표로 구분해 보이지만, "선택 불가"는 이제 스타일이 아니라
## pressed 핸들러의 분기(실제로 chosen을 바꾸는지 여부)로 보장한다.
func _make_starting_skill_slot(skill: Dictionary, unlocked: bool, slot_index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(STARTING_SKILL_SLOT_WIDTH, 56)
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(content)

	# K-4b: 효과 모티프 아이콘(SkillPool.icon_motif_for)을 이름 왼쪽에 붙인다. 잠긴
	# 슬롯도 윤곽(실루엣)은 그대로 보이되 modulate 알파를 낮춰 "어둡게"를 표현 —
	# INBOX.md 지시대로 자물쇠 배지는 그대로 유지하고 모티프를 완전히 숨기지 않는다.
	var motif := SkillPool.icon_motif_for(skill["id"])
	if unlocked:
		var name_row := HBoxContainer.new()
		name_row.alignment = BoxContainer.ALIGNMENT_CENTER
		name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_row.add_theme_constant_override("separation", 4)
		if motif != "":
			var skill_icon := SkillIcon.new()
			skill_icon.custom_minimum_size = Vector2(16, 16)
			skill_icon.motif = motif
			skill_icon.skill_id = skill["id"]
			name_row.add_child(skill_icon)
		var name_label := Label.new()
		name_label.text = skill["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		name_row.add_child(name_label)
		content.add_child(name_row)
	else:
		var lock_row := HBoxContainer.new()
		lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
		lock_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_row.add_theme_constant_override("separation", 4)
		var lock_icon := LockIcon.new()
		lock_icon.custom_minimum_size = Vector2(16, 16)
		lock_row.add_child(lock_icon)
		if motif != "":
			var skill_icon := SkillIcon.new()
			skill_icon.custom_minimum_size = Vector2(16, 16)
			skill_icon.motif = motif
			skill_icon.skill_id = skill["id"]
			skill_icon.modulate = Color(1, 1, 1, 0.4)
			lock_row.add_child(skill_icon)
		var name_label := Label.new()
		name_label.text = skill["name"]
		name_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		lock_row.add_child(name_label)
		content.add_child(lock_row)
		button.tooltip_text = SkillPool.unlock_requirement(_selected_id, slot_index)["text"]

	var is_previewing: bool = not unlocked and skill["id"] == _preview_skill_id
	var selected: bool = unlocked and skill["id"] == RunState.chosen_starting_skill_id
	button.add_theme_stylebox_override("normal", _starting_skill_slot_style(selected, unlocked, is_previewing))
	button.add_theme_stylebox_override("hover", _starting_skill_slot_style(selected, unlocked, is_previewing))
	button.add_theme_stylebox_override("pressed", _starting_skill_slot_style(selected, unlocked, is_previewing))

	if unlocked:
		button.pressed.connect(_on_starting_skill_selected.bind(skill["id"]))
	else:
		button.pressed.connect(_on_starting_skill_locked_preview.bind(skill["id"]))

	return button


## selected(현재 chosen_starting_skill_id와 일치)면 캐릭터 카드 선택과 같은 금테,
## previewing(잠긴 슬롯을 지금 미리보는 중)이면 얇은 노란 테두리로 "보는 중"임을 표시,
## 그 외 잠긴 슬롯은 어두운 배경, 나머지(선택 안 된 해금 슬롯)는 일반 회색 테두리.
func _starting_skill_slot_style(selected: bool, unlocked: bool, previewing: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	if not unlocked:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		if previewing:
			style.border_color = Color(0.85, 0.68, 0.25)
			style.set_border_width_all(2)
		else:
			style.border_color = Color(0.3, 0.3, 0.3)
			style.set_border_width_all(1)
	elif selected:
		style.bg_color = Color(0.22, 0.19, 0.08, 0.95)
		style.border_color = Color(0.85, 0.68, 0.25)
		style.set_border_width_all(3)
	else:
		style.bg_color = Color(0.14, 0.14, 0.16, 0.9)
		style.border_color = Color(0.35, 0.35, 0.35)
		style.set_border_width_all(1)
	return style


## 해금된 슬롯을 고르면 실제로 선택이 바뀐다 — 미리보기 상태였다면 비운다(이제 선택된
## 스킬 자체가 설명란에 보이므로 미리보기와 구분할 필요가 없다).
func _on_starting_skill_selected(id: String) -> void:
	RunState.chosen_starting_skill_id = id
	_preview_skill_id = ""
	_rebuild_starting_skill_slots()
	# [대형 기획 15] Q-2(원문 1) 요구 흐름 — 시작 스킬을 확정(클릭/스페이스)하면 포커스가
	# 자동으로 "던전 입장" 버튼으로 넘어간다. 이전에는 여기서 _restore_starting_skill_
	# focus(id)로 같은 슬롯에 포커스를 되돌렸는데(슬롯이 매번 새로 만들어져 포커스가
	# 통째로 사라지는 버그를 막기 위함, 위 _restore_starting_skill_focus() 주석 참고),
	# 이제 start_button.grab_focus()가 그 역할(어딘가에는 반드시 포커스를 줘야 함)을
	# 대신하면서 동시에 요구된 다음 단계로의 이동까지 한 번에 해결한다.
	start_button.grab_focus()


## 잠긴 슬롯을 클릭([대형 기획 5] F-1)하면 RunState.chosen_starting_skill_id는 그대로
## 두고 "미리보기"만 바꾼다 — 설명란에 그 스킬의 효과 + 해금 조건이 보이지만, 실제
## 시작 스킬(그리고 "던전 시작"이 쓰는 값)은 여전히 해금된 마지막 선택이다.
func _on_starting_skill_locked_preview(id: String) -> void:
	# [대형 기획 12] L-2(a): 잠긴 슬롯을 클릭해 상세(효과+해금 조건)를 본 순간이 곧
	# "발견"이다(skill_codex.gd 상단 주석의 "잠금 미리보기로 상세를 본 순간" 기록 시점).
	SkillCodex.mark_discovered(_selected_id, id)
	_preview_skill_id = id
	_rebuild_starting_skill_slots()
	_restore_starting_skill_focus(id)


## 미리보기 중이면(_preview_skill_id != "") 그 스킬의 효과+해금 조건을, 아니면 현재
## chosen_starting_skill_id의 효과만 보여준다. 자물쇠 배지/해금 조건 줄은 미리보기 중일
## 때만 visible=true가 된다(선택된 스킬은 항상 해금 상태이므로 평소엔 숨김).
func _update_starting_skill_description(candidates: Array[Dictionary]) -> void:
	var show_id: String = _preview_skill_id if _preview_skill_id != "" else RunState.chosen_starting_skill_id
	for i in candidates.size():
		var skill: Dictionary = candidates[i]
		if skill["id"] != show_id:
			continue
		_starting_skill_desc_label.text = "효과: %s" % skill["description"]
		if _preview_skill_id != "":
			_starting_skill_lock_badge_label.visible = true
			_starting_skill_unlock_label.text = "해금 조건: %s" % SkillPool.unlock_requirement(_selected_id, i)["text"]
			_starting_skill_unlock_label.visible = true
		else:
			_starting_skill_lock_badge_label.visible = false
			_starting_skill_unlock_label.visible = false
		return
	_starting_skill_desc_label.text = ""
	_starting_skill_lock_badge_label.visible = false
	_starting_skill_unlock_label.visible = false


func _on_card_selected(id: String) -> void:
	_selected_id = id
	_refresh_selection_highlight()
	_refresh_detail_panel()
	_restyle_start_button()
	# [대형 기획 15] Q-2(원문 1) 요구 흐름 — 카드를 확정(클릭/스페이스)하면 포커스가
	# 자동으로 시작 스킬 슬롯[0]으로 넘어간다. _refresh_detail_panel()이 그 바로 전에
	# _rebuild_starting_skill_slots()를 호출해 이 캐릭터의 슬롯 후보로 다시 채워둔
	# 상태이므로, 이 시점에는 항상 유효하다.
	if not _starting_skill_slot_buttons.is_empty():
		_starting_skill_slot_buttons[0].grab_focus()


## QA 전용(GAME_QA_CALL) — L-3 배경 전환 Tween은 실제 플레이에선 바람직하지만
## (INBOX.md 원문 "부드럽게 전환"), 자동 스크린샷은 호출 후 딱 1프레임만 기다리고
## 캡처하므로(visual_qa.gd) 애니메이션 도중의 색만 찍히는 문제가 있다. _background_themed를
## 일부러 false로 되돌려 _refresh_detail_panel()이 평소처럼 쓰는 Tween 대신 즉시 적용
## 분기를 타게 만든다 — _on_card_selected() 자체의 로직은 건드리지 않는다.
func _debug_qa_instant_select_pirate() -> void:
	_background_themed = false
	_on_card_selected("pirate")


func _debug_qa_instant_select_shieldbearer() -> void:
	_background_themed = false
	_on_card_selected("shieldbearer")


## QA 전용(GAME_QA_CALL) — [대형 기획 15] Q-2 흐름(카드 확정 -> 시작 스킬 확정 ->
## 던전 입장 버튼)이 "③ 던전 입장" 단계까지 실제로 도달한 화면을 스크린샷으로 눈으로
## 확인하기 위한 훅. 입력 파이프라인 자체는 scripts/qa_key_os_harness.ps1로 이미 실제
## OS 키 입력으로 검증했으므로, 여기서는 같은 연결 로직(pressed.emit())을 재사용해
## 레이아웃만 빠르게 재현한다.
func _debug_qa_show_step3() -> void:
	_background_themed = false
	_on_card_selected("novice")
	if not _starting_skill_slot_buttons.is_empty():
		_starting_skill_slot_buttons[0].pressed.emit()


## 선택된 카드는 금테(업적 패널의 "해금" 카드와 같은 색 언어), 나머지는 회색 테두리로
## 표시해 "지금 무엇이 골라져 있는지"를 한눈에 알 수 있게 한다.
func _refresh_selection_highlight() -> void:
	for id in _card_panels:
		var panel: PanelContainer = _card_panels[id]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.14, 0.16, 0.9)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		if id == _selected_id:
			style.bg_color = Color(0.22, 0.19, 0.08, 0.95)
			style.border_color = Color(0.85, 0.68, 0.25)
			style.set_border_width_all(3)
		else:
			style.border_color = Color(0.35, 0.35, 0.35)
			style.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", style)


func _on_start_pressed() -> void:
	# INBOX.md [대형 기획 3] 업적 #25 "첫 런 시작" — 던전 시작 버튼을 누른 시점이
	# 가장 확실한 트리거 지점(캐릭터가 몇 종으로 늘어나도 항상 이 버튼을 거쳐감).
	AchievementManager.unlock("first_run_start")
	RunState.reset_run(_selected_id)
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


func _on_test_battle_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/test_battle_setup.tscn")


func _on_achievement_pressed() -> void:
	if achievement_panel.visible:
		achievement_panel.close()
	else:
		achievement_panel.open()


## [대형 기획 12] L-2(c): 지금 선택된 캐릭터의 스킬 도감을 연다. 이 화면은 아직 런이
## 시작되지 않은 상태라 "보유 스킬"이라는 개념이 없으므로 owned_skill_ids는 항상
## 빈 배열 — INBOX.md L-2 원문 "선택 화면에서는 보유 0개(전부 ①②)"를 그대로 따른다.
func _on_skill_codex_pressed() -> void:
	if skill_codex_panel.visible:
		skill_codex_panel.close()
	else:
		skill_codex_panel.open(_selected_id, [])


## QA 전용: 클릭을 흉내낼 수 없는 자동 스크린샷에서 버튼 동작을 검증하기 위한 래퍼.
func _debug_start_run() -> void:
	_on_start_pressed()


## QA 전용: 카드 클릭을 흉내내 "광전사" 카드를 고른 상태를 스크린샷으로 검증하기
## 위함. scripts/qa_shot.sh의 GAME_QA_CALL은 인자 없이 메서드를 호출하므로
## (code/qa/visual_qa.gd 참고), 인자가 있는 메서드를 직접 넘기면 GDScript 오류로
## 창이 멈춰버릴 수 있어(2026-09-09 실제로 겪음 — 아래 STATUS.md 알려진 이슈 참고)
## 캐릭터별로 인자 없는 래퍼를 따로 둔다.
func _debug_select_berserker() -> void:
	_on_card_selected("berserker")


## QA 전용: "수호자" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유).
func _debug_select_guardian() -> void:
	_on_card_selected("guardian")


## QA 전용: "폭발병" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유).
func _debug_select_explosive() -> void:
	_on_card_selected("explosive")


## QA 전용: "방패병" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유).
func _debug_select_shieldbearer() -> void:
	_on_card_selected("shieldbearer")


## QA 전용: "광전사"를 고른 채로 실제 던전 시작까지 이어지는 전체 경로를 한 번에
## 검증하기 위한 래퍼(선택 -> 시작 -> dungeon_map 전환까지, 실제 플레이와 동일 경로).
## 던전 맵의 "공격/방어 주머니" 패널에 1/4만 보이는지(force_min_max_faces 효과)로
## 캐릭터 기믹이 실제로 새 런에 반영됐는지 화면에서 확인할 수 있다.
func _debug_start_run_as_berserker() -> void:
	_on_card_selected("berserker")
	_on_start_pressed()


## QA 전용: "수호자"로 던전 시작까지 이어지는 전체 경로 검증(_debug_start_run_as_berserker와
## 같은 이유). 방어 주머니 다이스 하나만 고정값(3)이고 나머지는 그대로인지 화면에서 확인.
func _debug_start_run_as_guardian() -> void:
	_on_card_selected("guardian")
	_on_start_pressed()


## QA 전용: "폭발병"으로 던전 시작까지 이어지는 전체 경로 검증(_debug_start_run_as_berserker와
## 같은 이유). explosive_stack은 정적 다이스 개조가 없어(character_profiles.gd 참고)
## 덱 패널에는 다른 캐릭터와 달리 아무 차이가 안 보이는 게 정상 — 실제 효과는
## combat_test.gd의 전투 중 상태(_debug_show_explosive_dice() 참고)로 확인해야 한다.
func _debug_start_run_as_explosive() -> void:
	_on_card_selected("explosive")
	_on_start_pressed()


## QA 전용: "방패병"으로 던전 시작까지 이어지는 전체 경로 검증(_debug_start_run_as_berserker와
## 같은 이유). guard_stack은 explosive_stack과 마찬가지로 정적 다이스 개조가 없어
## 덱 패널에는 아무 차이가 안 보이는 게 정상 — 실제 효과는 combat_test.gd의 전투 중
## 상태(_debug_show_guard_dice() 참고)로 확인해야 한다.
func _debug_start_run_as_shieldbearer() -> void:
	_on_card_selected("shieldbearer")
	_on_start_pressed()


## QA 전용: "곡예사" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유,
## INBOX.md 2026-09-24 [대형 기획 4]-C 신규). 7번째(목록 맨 아래) 카드라 왼쪽 목록
## 스크롤/상세 패널 겹침 여부까지 함께 확인할 수 있다.
func _debug_select_juggler() -> void:
	_on_card_selected("juggler")


## QA 전용: [대형 기획 8] H-4 — "테스트 전투" 버튼을 눌러 test_battle_setup.tscn으로
## 실제로 전환되는지 확인(다른 _debug_start_run_as_*()와 같은 이유, 씬 전환을 포함하므로
## get_viewport() 선취득 패턴은 필요 없음 — 이 메서드 자신은 더 이상 아무 것도 하지 않음).
func _debug_open_test_battle() -> void:
	_on_test_battle_pressed()


## QA 전용: "해적" 카드를 고른 상태 + 왼쪽 목록 스크롤을 맨 아래로 내린 상태를 한 번에
## 검증한다(INBOX.md 2026-10-08 [대형 기획 9] I-1 신규, _debug_show_achievements_
## scrolled()와 같은 이유로 call_deferred — ScrollContainer의 스크롤 범위는 레이아웃
## 정렬이 끝나야 갱신된다). 8번째(목록 맨 아래) 카드라 (1) 왼쪽 목록이 겹침/잘림 없이
## 스크롤되는지, (2) 상세 패널에 cannon_volley 기믹 아이콘(SkillIcon)이 겹침 없이
## 그려지는지 둘 다 한 스크린샷으로 확인할 수 있다.
func _debug_select_pirate() -> void:
	_on_card_selected("pirate")
	call_deferred("_debug_scroll_to_bottom")


## QA 전용: 왼쪽 캐릭터 목록(ScrollContainer) 스크롤을 맨 아래로 내린다
## (achievement_panel.gd._debug_scroll_to_bottom()과 같은 패턴).
func _debug_scroll_to_bottom() -> void:
	var scroll := $CardsContainer as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 100000


## QA 전용: 이전 QA 실행에서 남은 해금 상태가 섞이지 않도록 초기화한 뒤, 업적 하나를
## 미리 해금해 "잠김/해금" 두 상태가 동시에 보이는 화면을 스크린샷으로 검증한다.
func _debug_show_achievements() -> void:
	AchievementManager._debug_reset_for_qa()
	AchievementManager.unlock("first_run_start")
	achievement_panel.open()


## QA 전용: 업적 유형별 아이콘(achievement_icon.gd)이 목록 아래쪽 항목(pip/bag/shop/
## material 카테고리)에서도 겹침/누락 없이 그려지는지 스크린샷으로 확인하기 위해,
## 패널을 연 뒤 스크롤을 맨 아래로 내린다.
func _debug_show_achievements_scrolled() -> void:
	_debug_show_achievements()
	# 목록(ScrollContainer)의 스크롤 범위는 VBoxContainer의 레이아웃 정렬(queue_sort,
	# 다음 프레임에 처리됨)이 끝나야 갱신되므로, 같은 프레임에 바로 스크롤 값을 설정하면
	# 아직 갱신 전인 max_value(0에 가까움)로 클램프돼 무시된다 — call_deferred로 한 프레임
	# 미뤄서 레이아웃이 끝난 뒤에 스크롤하도록 한다.
	achievement_panel.call_deferred("_debug_scroll_to_bottom")


## QA 전용: [미니 기획 E]-3 슬롯 1이 "잠김" 상태(자물쇠 아이콘 + disabled)로 보이는
## 기본 화면을 검증하기 위해, 이전 QA 실행에서 남은 해금 상태를 초기화하고 견습
## 모험가를 선택한다(견습 모험가의 슬롯 1 "정예"가 잠긴 채로 보여야 정상).
func _debug_show_starting_skill_locked() -> void:
	AchievementManager._debug_reset_for_qa()
	SkillCodex._debug_reset_for_qa()
	_on_card_selected("novice")


## QA 전용: "clear_novice" 업적을 미리 해금해 슬롯 1("정예")이 해금 상태(자물쇠 없이
## 클릭 가능)로 보이는지 검증한다. 실제로 슬롯 1을 골라 chosen_starting_skill_id가
## 바뀌는 것까지 한 번에 확인한다.
func _debug_show_starting_skill_unlocked() -> void:
	AchievementManager._debug_reset_for_qa()
	SkillCodex._debug_reset_for_qa()
	AchievementManager.unlock("clear_novice")
	_on_card_selected("novice")
	_on_starting_skill_selected("start_lean")


## QA 전용: [대형 기획 5] F-1 — 잠긴 슬롯("정예")을 클릭해 미리보기 상태(자물쇠 배지 +
## 효과 설명 + 노란 해금 조건 줄)가 겹침 없이 보이는지 확인한다. chosen_starting_skill_id는
## 바뀌지 않아야 한다(여전히 슬롯 0 "확장").
func _debug_show_starting_skill_locked_preview() -> void:
	AchievementManager._debug_reset_for_qa()
	SkillCodex._debug_reset_for_qa()
	_on_card_selected("novice")
	_on_starting_skill_locked_preview("start_lean")


## QA 전용: [대형 기획 5] F-2(b) — 견습 모험가의 3개 슬롯(확장/정예/황금손)이 모두
## 해금된 상태(r1_novice + clear_novice)로 겹침 없이 가로 배치되는지 확인한다. 상세
## 패널 폭(~600px)에서 150px 버튼 3개(+separation 10px x2)가 들어가는지가 핵심
## 검증 지점(F-2(a) 완료 기록 참고 — 그때는 슬롯이 2개뿐이라 이 레이아웃을 아직
## 확인할 수 없었음).
func _debug_show_starting_skill_all_unlocked() -> void:
	AchievementManager._debug_reset_for_qa()
	SkillCodex._debug_reset_for_qa()
	AchievementManager.unlock("r1_novice")
	AchievementManager.unlock("clear_novice")
	_on_card_selected("novice")


## QA 전용 — 방향키/스페이스 조작(K-1)의 전체 경로를 흉내낸다: 두 번째 카드("광전사")
## 패널에 실제로 grab_focus()한 뒤(방향키 이동이 도달했다고 가정) CharacterCardPanel의
## activated를 emit해(스페이스 확정, [대형 기획 12] L-1부터 카드 패널 자신이 선택 단위)
## 실제로 광전사 카드가 금테로 강조되는지로 검증한다.
func _debug_press_shortcut_2() -> void:
	var card := _shortcut_buttons[1] as CharacterCardPanel
	card.grab_focus()
	card.activated.emit()


## QA 전용 — 카드 8장 다음에 오는 "던전 시작"/"업적"/"테스트 전투" 중 두 번째("업적")에
## 포커스가 가서 확정되면 AchievementPanel이 실제로 열리는지로 검증한다(_debug_press_
## shortcut_2와 같은 패턴).
func _debug_press_shortcut_7() -> void:
	var btn := achievement_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 업적 패널을 연 뒤, 패널 자신의 Esc 핸들러(achievement_panel.gd의
## _unhandled_input())가 실제 Esc 키 입력으로 패널을 닫는지 끝까지 확인한다. 업적 패널이
## character_select의 자식 노드이지만, 이 씬은 더 이상 _unhandled_input()을 쓰지 않으므로
## 입력이 그대로 achievement_panel로 전달된다.
func _debug_press_shortcut_close_achievements() -> void:
	achievement_panel.open()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_ESCAPE
	achievement_panel._unhandled_input(key)


## QA 전용 — [대형 기획 12] L-2(c). 포커스+확정 경로(방향키 이동 후 스페이스, K-1)로
## 헤더 섹션의 "스킬 도감" 버튼까지 이어지고, 실제로 SkillCodexPanel이 지금 선택된
## 캐릭터로 열리는지 확인한다(_debug_press_shortcut_7과 같은 패턴).
func _debug_press_shortcut_skill_codex() -> void:
	var btn := _skill_codex_button
	btn.grab_focus()
	btn.pressed.emit()


## QA 전용 — 다른 캐릭터(해적)를 고른 상태에서 스킬 도감을 열어, 도감 내용이
## _selected_id를 따라 실제로 바뀌는지 확인한다(캐릭터 선택 화면은 owned_skill_ids가
## 항상 빈 배열이라 전부 미발견/발견 상태만 보여야 정상).
func _debug_show_skill_codex_pirate() -> void:
	SkillCodex._debug_reset_for_qa()
	_on_card_selected("pirate")
	_on_skill_codex_pressed()


## QA 전용 — [대형 기획 14] N-5(c): 곡예사 도감에 눈속임/한탕/곡예 흥행(+) 4종(이벤트
## 테마 event_check 모티프)이 실제로 그려지는지 확인한다(_debug_show_skill_codex_pirate와
## 같은 패턴).
func _debug_show_skill_codex_juggler() -> void:
	SkillCodex._debug_reset_for_qa()
	_on_card_selected("juggler")
	_on_skill_codex_pressed()


## QA 전용 — 스킬 도감 패널을 연 뒤, 패널 자신의 Esc 핸들러로 실제로 닫히는지 확인한다
## (_debug_press_shortcut_close_achievements와 같은 패턴).
func _debug_press_shortcut_close_skill_codex() -> void:
	_on_skill_codex_pressed()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_ESCAPE
	skill_codex_panel._unhandled_input(key)
