class_name MonsterCodexPanel
extends Control
## 몬스터 도감 오버레이 ([대형 기획 15] Q-11, INBOX.md 2026-10-20 사용자 추가 지시).
##
## 목적은 "리소스 확인용" — 발견 여부와 무관하게(SkillCodexPanel과 달리 가리지 않음)
## `MonsterCatalog.MONSTERS` 전체를 계열/티어 필터 격자로 보여주고, 선택하면 상세 뷰에서
## 전신 full.png + 표정 5종(neutral/happy/hurt/sad/angry) 전환 + 전투에서 쓰는 상반신
## 크롭 미리보기 + 파일별 입고 현황(✓/✗)을 보여준다. 다른 오버레이(achievement_panel.gd/
## skill_codex_panel.gd)와 같은 "스크립트 하나로 완결된 Control, 별도 .tscn 불필요" 패턴.
##
## 몬스터 id 하드코딩 금지(INBOX 원문) — 격자는 항상 `MonsterCatalog.MONSTERS`를 순회해
## 만든다. 새 몬스터가 추가되면 코드 변경 없이 격자/필터/상세 뷰에 자동으로 나타난다.
##
## 두 단계 뷰: "grid"(필터 + 격자)와 "detail"(선택한 몬스터 1종). Esc/우상단 X는 항상
## 패널 전체를 닫고(SkillCodexPanel/achievement_panel.gd와 동일한 Esc 규칙), 상세 뷰에서
## 격자로 돌아가려면 "← 목록" 버튼을 쓴다(별도 Esc 단계 없음 — Q-11 원문이 "Esc/우상단
## X로 닫기"만 요구할 뿐 다단계 뒤로가기는 요구하지 않음).
##
## art_base_dir(테스트 주입 지점, character_art.gd/monster_portrait_placeholder.gd와 같은
## 패턴): 기본값은 production 경로(MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)지만
## dice_test.gd가 user:// 임시 디렉터리로 바꿔 합성 에셋으로 검증할 수 있다 — 실제
## resources/monsters/ 입고 상태에 의존하지 않는다(과업 지시 "주입된 임시 디렉터리/합성
## 에셋 사용, 실제 resources 의존 금지").

signal closed

const COLUMNS := 6
## Q-11b(2026-10-20, 감독 캡처 피드백): 190x108 -> 182x100으로 줄여 썸네일을 넣고도
## 6열 × 182px + 5갭(GRID_GAP) 합계가 SCROLL_WIDTH(아래) 안에 들어오게(가로 스크롤 제거).
const CARD_SIZE := Vector2(182, 100)
const GRID_GAP := 10
## 격자 카드 왼쪽에 붙는 작은 리소스 썸네일(정사각) — 썸네일 없는 몬스터는 FamilyIcon
## 플레이스홀더가 같은 자리를 채운다(아래 _make_grid_card() 참고).
const THUMB_SIZE := Vector2(56, 56)
## 썸네일 1장의 최대 변 길이(px) — 전신 원화(보통 1000px대) 그대로 텍스처를 들고 있으면
## 35장이 한 번에 로드될 때 메모리/디코드 비용이 크다. 크롭 후 이 크기로 축소해 캐시한다.
const THUMB_MAX_PIXELS := 96
## 격자 폭(스크롤 컨테이너 안쪽 가용 폭) — COLUMNS*CARD_SIZE.x + (COLUMNS-1)*GRID_GAP이
## 이 값을 넘지 않아야 가로 스크롤바가 생기지 않는다(Q-11b 핵심 버그: 기존 1100으로는
## 1190이 필요해 6번째 열이 잘리고 가로 스크롤바가 떴었다).
const SCROLL_WIDTH := 1160.0

const TIER_ORDER := ["normal", "elite", "boss"]
const TIER_LABELS := {"normal": "일반", "elite": "정예", "boss": "보스"}

## CharacterArt.FACE_EXPRESSIONS와 같은 순서 — 표정 버튼/체크리스트가 항상 이 순서로
## 나열되게 한 곳에서만 쓴다.
const EXPRESSION_LABELS := {
	"neutral": "무표정", "happy": "기쁨", "hurt": "상처", "sad": "슬픔", "angry": "분노",
}

var art_base_dir: String = MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR

var _view_mode: String = "grid"
var _filter_family: String = ""
var _filter_tier: String = ""
var _detail_monster_id: String = ""
var _detail_expression: String = "neutral"

var _ui: Array[Node] = []
var _close_button: Button

## grid 뷰 — 테스트가 "플래그가 아니라 실제로 렌더된 결과"를 확인할 수 있게 공개.
var _card_controls: Array[Control] = []
var _grid_cards_by_id: Dictionary = {}
var _grid_face_tag_by_id: Dictionary = {}
## Q-11b 신규 — 카드마다 썸네일을 넣은 자리(Control). 테스트가 "카드 수만큼 썸네일
## 슬롯이 실제로 있는지"를 검증할 수 있게 공개(아래 _make_grid_card() 참고).
var _grid_thumb_slot_by_id: Dictionary = {}
var _family_filter_buttons: Dictionary = {} # family key("" 포함) -> Button
var _tier_filter_buttons: Dictionary = {} # tier key("" 포함) -> Button
var _summary_label: Label

## art_id("|"+art_base_dir로 키 구분) -> 썸네일 Texture2D(또는 null=원화 없음).
## _rebuild()가 필터를 바꿀 때마다 격자 카드를 전부 새로 만드는데, 인스턴스 멤버로
## 캐시하면 필터 클릭마다 같은 파일을 다시 크롭/축소하게 된다 — static으로 둬서
## 패널을 여러 번 열고 닫아도, 필터를 오가도 한 번만 로드한다.
static var _thumb_cache: Dictionary = {}

## detail 뷰 — 전부 테스트 공개.
var _detail_full_rect: TextureRect
var _detail_face_rect: TextureRect
var _detail_crop_rect: TextureRect
var _expression_buttons: Dictionary = {} # expression -> Button
var _resource_check_labels: Dictionary = {} # "full" 또는 expression -> Label
var _back_button: Button


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open() -> void:
	_view_mode = "grid"
	_filter_family = ""
	_filter_tier = ""
	visible = true
	_rebuild()


func close() -> void:
	_clear_ui()
	visible = false
	closed.emit()


func _clear_ui() -> void:
	for node in _ui:
		if is_instance_valid(node):
			node.queue_free()
	_ui.clear()
	_card_controls.clear()
	_grid_cards_by_id.clear()
	_grid_face_tag_by_id.clear()
	_grid_thumb_slot_by_id.clear()
	_family_filter_buttons.clear()
	_tier_filter_buttons.clear()
	_expression_buttons.clear()
	_resource_check_labels.clear()
	_detail_full_rect = null
	_detail_face_rect = null
	_detail_crop_rect = null
	_back_button = null


## Esc로 패널을 닫는다(오버레이 패널 공통 규칙, achievement_panel.gd/skill_codex_panel.gd와
## 동일 — 상세 뷰에서도 "뒤로"가 아니라 바로 닫힘, Q-11 원문이 요구하는 범위 그대로).
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return
	var viewport := get_viewport()
	close()
	if viewport != null:
		viewport.set_input_as_handled()


func _filtered_monsters() -> Array:
	var result: Array = []
	for m in MonsterCatalog.MONSTERS:
		if _filter_family != "" and m.get("family", "") != _filter_family:
			continue
		if _filter_tier != "" and m.get("tier", "normal") != _filter_tier:
			continue
		result.append(m)
	return result


func _rebuild() -> void:
	_clear_ui()

	var palette := CharacterTheme.ui_palette(RunState.character_id)

	# Q-11b(2026-10-20, 감독 캡처 피드백) — 패널 틀(아래 bg)이 화면 일부(x<40/y<30 등)만
	# 덮어서 뒤에 깔린 character_select 화면의 제목/버튼이 패널 상단에 비쳐 보이던 버그.
	# 다른 오버레이와 같은 "화면 전체를 덮는 딤 배경"(skill_detail_popup.gd의 backdrop과
	# 동일 패턴)을 bg보다 먼저 깔아, 패널 크기/위치와 무관하게 뒷 화면을 항상 가린다.
	# 반투명(예: 0.6~0.75)은 밝은 색 썸네일/텍스트가 뒤에 있으면 여전히 비쳐 보여서(1차
	# 캡처로 실제 확인) 완전 불투명으로 — 이 패널은 중앙 모달(skill_detail_popup 등, 뒤
	# 화면이 흐릿하게 보이는 게 의도)이 아니라 화면을 통째로 대체하는 전체 오버레이다.
	# 이 씬은 반응형 레이아웃이 아니라 1280x720 고정 좌표로 짜여 있다(이 파일의 다른
	# 요소들도 전부 position/size 절대값) — anchors_preset(FULL_RECT)은 Control의
	# 레이아웃 계산 타이밍에 기대게 되므로, 다른 요소들과 같은 방식으로 명시적
	# position/size를 직접 준다(한 프레임 안에 확실히 전체화면을 덮는다).
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.03, 0.04, 1.0)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(1280, 720)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	_ui.append(backdrop)

	var bg := Panel.new()
	var skin_applied := UIKit.apply_panel_skin(bg, "overlay", RunState.character_id)
	if not skin_applied:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0, 0, 0, 0.9)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(8)
		bg.add_theme_stylebox_override("panel", frame_style)
	bg.position = Vector2(40, 30)
	bg.size = Vector2(1200, 660)
	add_child(bg)
	_ui.append(bg)
	if not skin_applied:
		CharacterTheme.apply(bg, RunState.character_id, false)

	_close_button = Button.new()
	_close_button.text = "닫기"
	_close_button.position = Vector2(1140, 44)
	_close_button.size = Vector2(80, 32)
	_close_button.pressed.connect(close)
	UIKit.style_secondary_button(_close_button, RunState.character_id)
	add_child(_close_button)
	_ui.append(_close_button)

	if _view_mode == "detail":
		_build_detail_view(palette)
	else:
		_build_grid_view(palette)


# ---------------------------------------------------------------------------
# grid 뷰
# ---------------------------------------------------------------------------

func _build_grid_view(palette: Dictionary) -> void:
	var filtered := _filtered_monsters()

	_summary_label = Label.new()
	_summary_label.text = "몬스터 도감 — %d / %d종" % [filtered.size(), MonsterCatalog.MONSTERS.size()]
	_summary_label.position = Vector2(70, 44)
	_summary_label.size = Vector2(900, 28)
	_summary_label.add_theme_font_size_override("font_size", 18)
	_summary_label.add_theme_color_override("font_color", palette["accent"])
	add_child(_summary_label)
	_ui.append(_summary_label)

	var filter_row := HBoxContainer.new()
	filter_row.position = Vector2(70, 84)
	filter_row.size = Vector2(1100, 32)
	filter_row.add_theme_constant_override("separation", 6)
	add_child(filter_row)
	_ui.append(filter_row)

	var family_filters: Array[Control] = []
	family_filters.append(_make_filter_button("전체", "" == _filter_family, filter_row, _set_family_filter.bind("")))
	_family_filter_buttons[""] = family_filters[0]
	for family_id in MonsterCatalog.family_ids():
		var fam_name: String = MonsterCatalog.FAMILIES[family_id]["name"]
		var btn := _make_filter_button(fam_name, family_id == _filter_family, filter_row, _set_family_filter.bind(family_id))
		family_filters.append(btn)
		_family_filter_buttons[family_id] = btn

	var divider := VSeparator.new()
	filter_row.add_child(divider)

	var tier_filters: Array[Control] = []
	tier_filters.append(_make_filter_button("전체", "" == _filter_tier, filter_row, _set_tier_filter.bind("")))
	_tier_filter_buttons[""] = tier_filters[0]
	for tier_id in TIER_ORDER:
		var btn2 := _make_filter_button(TIER_LABELS[tier_id], tier_id == _filter_tier, filter_row, _set_tier_filter.bind(tier_id))
		tier_filters.append(btn2)
		_tier_filter_buttons[tier_id] = btn2

	var all_filter_buttons: Array[Control] = []
	all_filter_buttons.append_array(family_filters)
	all_filter_buttons.append_array(tier_filters)
	FocusNav.chain_linear(all_filter_buttons, true, false, false, palette["accent"])
	for b in all_filter_buttons:
		# 위로는 아무것도 없으니 자기 자신으로 가둔다(빈 NodePath로 남겨 엔진의 자동
		# geometry 탐색에 맡기면 테스트 환경에서 결과가 불안정하다 — FocusNav.gd 상단 주석).
		b.focus_neighbor_top = b.get_path_to(b)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 126)
	scroll.size = Vector2(SCROLL_WIDTH, 530)
	# Q-11b: 가로 스크롤바 완전 제거(세로만) — 폭은 SCROLL_WIDTH 상수가 COLUMNS*CARD_SIZE.x
	# 합계를 항상 담도록 보장하므로, 이건 내용이 넘칠 일이 없는 상태에서의 안전장치다
	# (deck_panel.gd와 같은 패턴).
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_ui.append(scroll)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	scroll.add_child(grid)

	for m in filtered:
		var card := _make_grid_card(m)
		grid.add_child(card)
		_card_controls.append(card)
		_grid_cards_by_id[m["id"]] = card

	_chain_grid(_card_controls, COLUMNS, palette["accent"])

	# 필터 행 <-> 격자 경계 연결(모든 방향을 명시적으로 채워야 테스트 환경에서 결정적).
	if not _card_controls.is_empty():
		var first_card := _card_controls[0]
		for b in all_filter_buttons:
			b.focus_neighbor_bottom = b.get_path_to(first_card)
		first_card.focus_neighbor_top = first_card.get_path_to(all_filter_buttons[0])

		var last_card := _card_controls[_card_controls.size() - 1]
		last_card.focus_neighbor_bottom = last_card.get_path_to(_close_button)
		_close_button.focus_neighbor_top = _close_button.get_path_to(last_card)
	else:
		for b in all_filter_buttons:
			b.focus_neighbor_bottom = b.get_path_to(_close_button)
		_close_button.focus_neighbor_top = _close_button.get_path_to(all_filter_buttons[0])

	FocusNav.make_focusable(_close_button, palette["accent"])
	_close_button.focus_neighbor_bottom = _close_button.get_path_to(_close_button)
	_close_button.focus_neighbor_left = _close_button.get_path_to(_close_button)
	_close_button.focus_neighbor_right = _close_button.get_path_to(_close_button)

	FocusNav.grab_first_focus([all_filter_buttons[0]])


func _make_filter_button(text: String, active: bool, parent: Node, on_pressed: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 30)
	btn.pressed.connect(on_pressed)
	if active:
		btn.modulate = Color(1, 1, 1, 1)
		UIKit.style_primary_button(btn, RunState.character_id)
	else:
		btn.modulate = Color(0.85, 0.85, 0.85)
		UIKit.style_secondary_button(btn, RunState.character_id)
	parent.add_child(btn)
	return btn


func _set_family_filter(family_id: String) -> void:
	_filter_family = family_id
	_rebuild()


func _set_tier_filter(tier_id: String) -> void:
	_filter_tier = tier_id
	_rebuild()


func _make_grid_card(monster: Dictionary) -> Control:
	var monster_id: String = monster["id"]
	var art_id: String = MonsterCatalog.art_resource_id(monster_id)
	var full_ok: bool = CharacterArt.has_full(art_id, art_base_dir)
	var face_n: int = CharacterArt.face_count(art_id, art_base_dir)

	var card := CharacterCardPanel.new()
	card.custom_minimum_size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.16, 0.95)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)

	# Q-11b(2026-10-20, 감독 캡처 피드백) — "리소스 확인용 도감인데 썸네일이 없다"는
	# 지적을 반영. full.png가 있으면 상세 뷰와 같은 크롭(전투 크롭과 동일 비율)을 작게
	# 축소해 보여주고, 없으면 FamilyIcon 플레이스홀더로 계열만이라도 알 수 있게 한다.
	var thumb_holder := Control.new()
	thumb_holder.custom_minimum_size = THUMB_SIZE
	thumb_holder.size = THUMB_SIZE
	thumb_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(thumb_holder)
	_grid_thumb_slot_by_id[monster_id] = thumb_holder

	var tier_for_thumb: String = monster.get("tier", "normal")
	var thumb_tex := _grid_thumbnail_texture(art_id, tier_for_thumb)
	if thumb_tex != null:
		var thumb_rect := TextureRect.new()
		thumb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_rect.texture = thumb_tex
		thumb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb_holder.add_child(thumb_rect)
	else:
		var fallback_icon := FamilyIcon.new()
		fallback_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback_icon.category = monster.get("family", "")
		fallback_icon.is_boss = tier_for_thumb == "boss"
		fallback_icon.is_elite = tier_for_thumb == "elite"
		thumb_holder.add_child(fallback_icon)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)

	var icon := FamilyIcon.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.category = monster.get("family", "")
	icon.is_boss = monster.get("tier", "normal") == "boss"
	icon.is_elite = monster.get("tier", "normal") == "elite"
	top_row.add_child(icon)

	var tier_label := Label.new()
	tier_label.text = TIER_LABELS.get(monster.get("tier", "normal"), "일반")
	tier_label.add_theme_font_size_override("font_size", 11)
	tier_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	top_row.add_child(tier_label)

	var name_label := Label.new()
	name_label.text = String(monster.get("name", monster_id))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	vbox.add_child(name_label)

	var resource_label := Label.new()
	resource_label.text = "원화 %s · 표정 %d/5" % ["✓" if full_ok else "✗", face_n]
	resource_label.clip_text = true
	resource_label.add_theme_font_size_override("font_size", 9)
	resource_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6) if full_ok else Color(0.7, 0.6, 0.6))
	vbox.add_child(resource_label)
	_grid_face_tag_by_id[monster_id] = resource_label

	card.activated.connect(_on_card_activated.bind(monster_id))
	return card


## Q-11b 신규 — 격자 카드 썸네일(캐시됨). full.png가 없으면 null(호출부가 FamilyIcon
## 폴백을 그린다). 상세 뷰와 같은 티어별 크롭 비율(CharacterArt.MONSTER_FACE_CROP_RATIO_
## BY_TIER)을 재사용해 "전투에서 실제로 보이는 구도"와 썸네일이 같게 한다.
func _grid_thumbnail_texture(art_id: String, tier: String) -> Texture2D:
	var cache_key := "%s|%s" % [art_id, art_base_dir]
	if _thumb_cache.has(cache_key):
		return _thumb_cache[cache_key]
	var tex: Texture2D = null
	if CharacterArt.has_full(art_id, art_base_dir):
		var crop_ratio: Rect2 = CharacterArt.MONSTER_FACE_CROP_RATIO_BY_TIER.get(tier, CharacterArt.DEFAULT_FACE_CROP_RATIO)
		var cropped := CharacterArt.load_full_crop(art_id, crop_ratio, art_base_dir)
		if cropped != null:
			tex = _downscale_for_thumbnail(cropped)
	_thumb_cache[cache_key] = tex
	return tex


## 긴 변이 THUMB_MAX_PIXELS를 넘으면 축소해 작은 텍스처로 캐시한다(35장을 한 번에 들고
## 있어도 메모리/디코드 비용이 전신 원화 그대로일 때보다 훨씬 작다).
func _downscale_for_thumbnail(source: Texture2D) -> Texture2D:
	var img := source.get_image()
	if img == null:
		return source
	var size := img.get_size()
	var longest: int = max(size.x, size.y)
	if longest > THUMB_MAX_PIXELS:
		var scale: float = float(THUMB_MAX_PIXELS) / float(longest)
		img.resize(max(1, int(size.x * scale)), max(1, int(size.y * scale)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _on_card_activated(monster_id: String) -> void:
	_detail_monster_id = monster_id
	_detail_expression = "neutral"
	_view_mode = "detail"
	_rebuild()


## SkillCodexPanel._chain_grid()와 같은 "격자 전체를 wrap으로 묶는" 패턴(격자만 재사용
## 가능하게 복제해둠 — 두 패널이 서로 다른 카드 크기/개수 전제라 공용 헬퍼로 뽑기보다
## 각자 들고 있는 게 이 코드베이스의 기존 선택, skill_codex_panel.gd 주석 참고).
func _chain_grid(cards: Array[Control], columns: int, accent: Color) -> void:
	var n := cards.size()
	if n == 0:
		return
	for c in cards:
		FocusNav.make_focusable(c, accent)
	for i in n:
		var row := i / columns
		var row_start := row * columns
		var row_end: int = min(row_start + columns - 1, n - 1)
		var left_idx: int = i - 1 if i > row_start else row_end
		var right_idx: int = i + 1 if i < row_end else row_start
		cards[i].focus_neighbor_left = cards[i].get_path_to(cards[left_idx])
		cards[i].focus_neighbor_right = cards[i].get_path_to(cards[right_idx])

		var col := i % columns
		var col_indices: Array[int] = []
		var j := col
		while j < n:
			col_indices.append(j)
			j += columns
		var pos_in_col := col_indices.find(i)
		var up_idx: int = col_indices[pos_in_col - 1] if pos_in_col > 0 else col_indices[col_indices.size() - 1]
		var down_idx: int = col_indices[pos_in_col + 1] if pos_in_col < col_indices.size() - 1 else col_indices[0]
		cards[i].focus_neighbor_top = cards[i].get_path_to(cards[up_idx])
		cards[i].focus_neighbor_bottom = cards[i].get_path_to(cards[down_idx])


# ---------------------------------------------------------------------------
# detail 뷰
# ---------------------------------------------------------------------------

func _build_detail_view(palette: Dictionary) -> void:
	var monster := MonsterCatalog.get_by_id(_detail_monster_id)
	var art_id: String = MonsterCatalog.art_resource_id(_detail_monster_id)
	var tier: String = monster.get("tier", "normal")

	_back_button = Button.new()
	_back_button.text = "← 목록"
	_back_button.position = Vector2(70, 44)
	_back_button.size = Vector2(90, 32)
	_back_button.pressed.connect(_on_back_pressed)
	UIKit.style_secondary_button(_back_button, RunState.character_id)
	add_child(_back_button)
	_ui.append(_back_button)

	var name_label := Label.new()
	name_label.text = "%s (id: %s) — %s / %s" % [
		monster.get("name", _detail_monster_id), _detail_monster_id,
		MonsterCatalog.FAMILIES.get(monster.get("family", ""), {}).get("name", "?"),
		TIER_LABELS.get(tier, "일반"),
	]
	name_label.position = Vector2(180, 44)
	name_label.size = Vector2(800, 32)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", palette["accent"])
	add_child(name_label)
	_ui.append(name_label)

	# 전신 full.png(크게).
	_detail_full_rect = TextureRect.new()
	_detail_full_rect.position = Vector2(70, 90)
	_detail_full_rect.size = Vector2(280, 320)
	_detail_full_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_full_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var full_ok: bool = CharacterArt.has_full(art_id, art_base_dir)
	if full_ok:
		_detail_full_rect.texture = CharacterArt.load_full(art_id, art_base_dir)
	add_child(_detail_full_rect)
	_ui.append(_detail_full_rect)
	if not full_ok:
		_ui.append(_make_missing_label(_detail_full_rect, "원화 미입고"))

	# 성격/스킬 정보.
	# Q-11b: 150 -> 220(아래쪽 여백을 줄여 패널 하단까지 정보 밀도를 맞춤).
	var info_label := Label.new()
	info_label.position = Vector2(70, 420)
	info_label.size = Vector2(280, 220)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	var skills_text := _format_skills(monster.get("skills", []))
	var text := "성격: %s\n스킬: %s" % [monster.get("personality", ""), skills_text]
	var phase2: Array = monster.get("phase2_skills", [])
	if not phase2.is_empty():
		text += "\n2페이즈: %s" % _format_skills(phase2)
	# [대형 기획 15] Q-12(c) — 보스는 성격 줄 근처에 기본 intro 문구도 보여준다(리소스/
	# 설정 확인용, 캐릭터 전용 변형은 도감에서 안 보여줌 — 여기선 항상 기본 문구).
	if monster.get("tier", "") == "boss":
		var intro: String = monster.get("intro", "")
		if intro != "":
			text += "\n등장: %s" % intro
	info_label.text = text
	add_child(info_label)
	_ui.append(info_label)

	# 표정 전환 영역(우측 상단).
	var expr_title := Label.new()
	expr_title.text = "표정 전환"
	expr_title.position = Vector2(380, 90)
	expr_title.size = Vector2(300, 22)
	expr_title.add_theme_font_size_override("font_size", 13)
	expr_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(expr_title)
	_ui.append(expr_title)

	var expr_row := HBoxContainer.new()
	expr_row.position = Vector2(380, 116)
	expr_row.size = Vector2(300, 32)
	expr_row.add_theme_constant_override("separation", 4)
	add_child(expr_row)
	_ui.append(expr_row)

	var expression_order: Array = CharacterArt.FACE_EXPRESSIONS
	var enabled_buttons: Array[Control] = []
	for expression in expression_order:
		var exists: bool = FileAccess.file_exists(CharacterArt.face_path(art_id, expression, art_base_dir))
		var ebtn := Button.new()
		ebtn.text = EXPRESSION_LABELS.get(expression, expression)
		ebtn.custom_minimum_size = Vector2(56, 30)
		ebtn.disabled = not exists
		ebtn.pressed.connect(_select_expression.bind(expression))
		UIKit.style_secondary_button(ebtn, RunState.character_id)
		expr_row.add_child(ebtn)
		_expression_buttons[expression] = ebtn
		if exists:
			enabled_buttons.append(ebtn)

	# Q-11b: 200x200 -> 260x300(표정 컷이 있는 몬스터는 더 크게 보이고, 없는 몬스터는
	# 어차피 비어 있으니 이 크기 변화 자체는 영향 없음 — 아래 안내 문구 위치가 핵심 수정).
	_detail_face_rect = TextureRect.new()
	_detail_face_rect.position = Vector2(380, 156)
	_detail_face_rect.size = Vector2(260, 300)
	_detail_face_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_face_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_detail_face_rect)
	_ui.append(_detail_face_rect)
	_apply_detail_expression_texture()
	if _detail_face_rect.texture == null:
		# 표정 컷이 아예 없는 몬스터(2026-10-20 현재 보스 포함 전체 입고 상태 — "표정 없음
		# -> 전투 크롭 참고"를 정직하게 안내, STATUS.md 기록 참고). 버튼이 전부 disabled라
		# 사용자가 다른 표정을 골라도 이 상태를 벗어날 수 없으므로 한 번만 붙여도 된다.
		# Q-11b 수정: 예전엔 _detail_face_rect(지금은 300px 큰 빈 상자)의 세로 한가운데에
		# 안내 문구를 띄워 그 위아래로 거대한 빈 공간이 생겼다 — 버튼 줄(expr_row) 바로
		# 아래에 붙여 "빈 상자 한복판에 떠 있는" 느낌을 없앤다.
		var no_face_label := Label.new()
		no_face_label.text = "표정 미입고\n오른쪽 크롭 참고"
		no_face_label.position = expr_row.position + Vector2(0, expr_row.size.y + 10)
		no_face_label.size = Vector2(_detail_face_rect.size.x, 40)
		no_face_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_face_label.add_theme_font_size_override("font_size", 13)
		no_face_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		add_child(no_face_label)
		_ui.append(no_face_label)

	# 전투 화면 상반신 크롭 미리보기(나란히). Q-11b: 표정 컷이 거의 없는 현재 입고
	# 상태에서는 이 크롭이 상세 뷰의 유일한 "표정 참고용" 시각 정보라 더 크게 키운다
	# (200x240 -> 230x320).
	var crop_title := Label.new()
	crop_title.text = "전투 크롭"
	crop_title.position = Vector2(700, 90)
	crop_title.size = Vector2(220, 22)
	crop_title.add_theme_font_size_override("font_size", 13)
	crop_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(crop_title)
	_ui.append(crop_title)

	_detail_crop_rect = TextureRect.new()
	_detail_crop_rect.position = Vector2(700, 116)
	_detail_crop_rect.size = Vector2(230, 320)
	_detail_crop_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_crop_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_detail_crop_rect)
	_ui.append(_detail_crop_rect)
	if full_ok:
		var crop_ratio: Rect2 = CharacterArt.MONSTER_FACE_CROP_RATIO_BY_TIER.get(tier, CharacterArt.DEFAULT_FACE_CROP_RATIO)
		_detail_crop_rect.texture = CharacterArt.load_full_crop(art_id, crop_ratio, art_base_dir)
	else:
		_ui.append(_make_missing_label(_detail_crop_rect, "원화 미입고"))

	# 리소스 입고 현황 체크리스트.
	var check_title := Label.new()
	check_title.text = "리소스 입고 현황"
	check_title.position = Vector2(940, 90)
	check_title.size = Vector2(220, 22)
	check_title.add_theme_font_size_override("font_size", 13)
	check_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(check_title)
	_ui.append(check_title)

	var check_list := VBoxContainer.new()
	check_list.position = Vector2(940, 116)
	check_list.size = Vector2(220, 220)
	check_list.add_theme_constant_override("separation", 4)
	add_child(check_list)
	_ui.append(check_list)

	var full_check := Label.new()
	full_check.text = "full.png: %s" % ("✓" if full_ok else "✗")
	full_check.add_theme_font_size_override("font_size", 12)
	full_check.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6) if full_ok else Color(0.9, 0.55, 0.55))
	check_list.add_child(full_check)
	_resource_check_labels["full"] = full_check

	for expression in expression_order:
		var exists2: bool = FileAccess.file_exists(CharacterArt.face_path(art_id, expression, art_base_dir))
		var row_label := Label.new()
		row_label.text = "face_%s.png: %s" % [expression, "✓" if exists2 else "✗"]
		row_label.add_theme_font_size_override("font_size", 12)
		row_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6) if exists2 else Color(0.9, 0.55, 0.55))
		check_list.add_child(row_label)
		_resource_check_labels[expression] = row_label

	# 포커스 체인: 뒤로 + 닫기 + 입고된 표정 버튼만(한 줄 wrap+trap, FocusNav.gd 패턴).
	var chain: Array[Control] = [_back_button]
	chain.append_array(enabled_buttons)
	chain.append(_close_button)
	FocusNav.chain_linear(chain, true, true, true, palette["accent"])
	FocusNav.grab_first_focus(chain)


func _make_missing_label(anchor: TextureRect, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.position = anchor.position + Vector2(0, anchor.size.y * 0.5 - 10)
	label.size = Vector2(anchor.size.x, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(label)
	return label


func _on_back_pressed() -> void:
	_view_mode = "grid"
	_rebuild()


## 표정 버튼이 눌렸을 때만 호출(비활성 버튼은 pressed 자체가 안 울림 — 미입고 표정은
## 전환 불가 처리). 전체 _rebuild() 없이 텍스처만 바꿔 포커스가 끊기지 않게 한다.
func _select_expression(expression: String) -> void:
	_detail_expression = expression
	_apply_detail_expression_texture()


func _apply_detail_expression_texture() -> void:
	if _detail_face_rect == null:
		return
	var art_id: String = MonsterCatalog.art_resource_id(_detail_monster_id)
	var tex := CharacterArt.load_face(art_id, _detail_expression, art_base_dir)
	_detail_face_rect.texture = tex


func _format_skills(skills: Array) -> String:
	if skills.is_empty():
		return "없음"
	var parts: Array[String] = []
	for s in skills:
		var id: String = s.get("id", "")
		if s.has("amount"):
			parts.append("%s(%s)" % [id, s["amount"]])
		else:
			parts.append(id)
	return ", ".join(parts)
