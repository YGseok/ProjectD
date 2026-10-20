extends Node2D
class_name MonsterPortraitPlaceholder
## 몬스터 초상화 플레이스홀더. 실제 몬스터 스프라이트(INBOX.md: "몬스터 무스메들이
## 나온다")가 생기기 전까지 도형 조립으로 "이 몬스터가 지금 화나있는지/기뻐하는지"만
## 표시하는 임시 실루엣. `combat_test.gd`가 이미 몬스터별로 부여하는 색(monster_color,
## MONSTER_PROFILES)을 그대로 받아 몸 색으로 쓰므로, 이름/색 구분에 이어 표정까지
## 몬스터별로 달라 보인다.
##
## 사람 형태가 아니라 "동그란 몸 + 뿔 두 개"의 최소 몬스터 실루엣으로 플레이어
## 초상화(character_portrait_placeholder.gd)와 형태를 분명히 구분한다.
##
## G-5(2026-10-07, INBOX.md [대형 기획 6] G-5): `family` export로 계열별 최소 장식을
## 덧붙인다 — "humanoid"=뿔 대신 투구 테두리(가로줄), "amorphous"=뿔 없이 몸 하단에
## 물방울이 떨어지는 장식, "beast"=기존 뿔을 더 뾰족한 귀+송곳니 느낌으로, "undead"=눈을
## 채운 원이 아니라 뚫린 눈구멍(테두리만)으로. family가 빈 문자열이면(기존 호출부가
## family를 안 넘기는 경우) 기존 그대로(뿔 두 개 + 채운 눈) 그려 동작 보존.
##
## ART-1c(2026-10-16, INBOX.md [미니 기획 ART-1] — ART-1b와 같은 방식): 몬스터
## id별 res://resources/monsters/<id>/face_{neutral,happy,hurt,sad,angry}.png 5장이
## 전부 입고되면 원화 표정 컷으로 전환한다. 경로 존재 확인/로드는 새 클래스를 만들지
## 않고 `CharacterArt.has_all_faces()`/`load_face()`(둘 다 character_id + base_dir를
## 받는 범용 순수 함수라 캐릭터 전용 로직이 없음)를 MONSTER_ART_BASE_DIR로 그대로
## 재사용한다. set_monster()/set_expression()의 원화 전환 흐름 자체는
## `CharacterPortraitPlaceholder.set_character()`와 동일한 구조.
##
## ART-1c-2(2026-10-16, [대형 기획 13] 인수인계 — 보스 6종이 face_* 없이 full.png만
## 입고됨): face_* 5장이 없고 full.png만 있으면, `CharacterArt.load_full_crop()`(=
## `load_face_thumb()`가 쓰는 것과 같은 "비율 → 크롭" 로직)로 상반신을 잘라 같은
## _face_rect에 표시한다. 크롭 비율 자체는 `CharacterArt.monster_face_crop_ratio()`가
## 정한다(ART-1c-6, 아래 참고). 이 상태(_use_full_crop)는 표정별 텍스처가 없으므로
## set_expression()을 호출해도 텍스처를 바꾸지 않고 무시 — _draw()도 도형
## 플레이스홀더를 안 그리도록 함께 막는다. 우선순위: face_* 5장(_use_face_art) >
## full.png 크롭(_use_full_crop) > 도형 플레이스홀더(둘 다 false).
##
## ART-1c-6(2026-10-21, 아트 스레드 요청 — 일반/정예 전투 컷에서 얼굴이 패널에
## 가려지거나 크롭이 가슴께부터 시작해 머리가 아예 안 보이는 문제): 두 가지를 고쳤다.
## ① 크롭 비율 — `CharacterArt.monster_face_crop_ratio()`가 일반/정예 티어에서는
## 더는 고정 `DEFAULT_FACE_CROP_RATIO`(캐릭터 전용, 항상 같은 구도를 가정)를 쓰지
## 않고, 원화 알파 채널로 몬스터별 머리 위치를 찾는 `detect_face_crop_ratio()`를
## 쓴다 — 포즈가 제각각인 몬스터(서 있는 포즈/웅크린 포즈)에서도 머리가 크롭 안에
## 들어오게 한다(보스는 기존 BOSS_FACE_CROP_RATIO 그대로, 변경 없음). ② HUD 패널
## 회피 — 보스만 있던 `BOSS_PORTRAIT_POSITION_SHIFT` 패턴을 일반/정예에도 적용해
## (`combat_test.gd`의 `MONSTER_PORTRAIT_POSITION_SHIFT_BY_TIER`) 포트레이트 상단이
## 몬스터 HUD 패널(우측 상단) 아래로 내려가게 했다 — 크롭이 아무리 잘 맞아도 패널에
## 가려지면 소용없으므로 두 수정이 함께 있어야 머리가 실제로 보인다.
##
## ART-1c-3(2026-10-16, [대형 기획 13] 인수인계 — 몬스터 컷 가장자리 페이드 + 경로
## 별칭): ① face_art_fade 셰이더에 side_fade/top_fade 유니폼을 추가(기본값 0.0이라
## 캐릭터 쪽은 동작 불변)하고 몬스터 쪽만 _ensure_face_rect()에서 10%로 켜 좌/우/위
## 가장자리도 하단과 같은 방식으로 투명 처리한다(qa_out/art1c3_fallen_commander_before.png
## 에서 사각 박스처럼 보이던 문제 — 하단 페이드(fade_start=0.76, 플레이어와 공유값)
## 자체는 셰이더 알파 수치로 정상 작동이 이미 확인돼 있었음, 다만 좌/우/위는 아예 페이드가
## 없어 하드 컷으로 보였음). ② `MonsterCatalog.art_resource_id()`(데이터 표
## `ART_ID_ALIASES`)로 원화 경로 조회 직전에 id를 별칭 해석한다 — `dark_knight`(MO005,
## 옛 5종 호환용)는 `dark_knight_elite`(MO600)와 원화를 공유하는데, 파일을 실제로
## 복제하지 않고 조회 경로만 바꿔치기한다(_art_monster_id가 _monster_id와 분리된 이유).
##
## ART-1c-4(2026-10-16, 몬스터 전신 34세트 전량 입고 후 감독 지시 — 어두운 몬스터
## 외곽 글로우): shadow(MO012)처럼 컷 자체가 거의 검은 실루엣인 몬스터는 어두운 전투
## 배경에서 윤곽이 잘 안 보인다. `CharacterArt.full_crop_luminance()`(불투명 픽셀만의
## 평균 상대 휘도)가 `CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD`보다 낮을 때만
## 자동으로 켜지는 "뒤에 확대한 복제 TextureRect" 방식 — 몬스터 id 하드코딩 없음(순전히
## 컷의 밝기로만 판정). `_glow_rect`를 `_face_rect`보다 먼저(= 뒤에) 그려 중심부는
## 원래 컷에 그대로 덮이고, GLOW_SCALE만큼 커진 가장자리 부분만 보여 옅은 림 라이트처럼
## 보인다(셰이더 블러 대신 "확대 복제" 쪽을 택함 — 과업 지시가 둘 중 더 간단한 쪽을
## 허용). 밝은 몬스터는 `_glow_rect`가 아예 안 만들어지거나(한 번도 어두웠던 적 없으면)
## visible=false로 남아 기존 화면과 완전히 동일하다.

const EYE_COLOR := Color(0.12, 0.1, 0.08)
const MOUTH_COLOR := Color(0.25, 0.08, 0.08)
const HORN_COLOR := Color(0.85, 0.82, 0.75)

const MONSTER_ART_BASE_DIR := "res://resources/monsters/%s/"

## 몬스터 쪽 표정 컷 크기는 캐릭터와 같은 정사각 구도를 그대로 쓴다(새 상수 중복 방지).
const FACE_ART_SIZE := CharacterPortraitPlaceholder.FACE_ART_SIZE

## [미니 기획 ART-1c] MonsterPortrait는 화면 우측(combat_test.tscn position.x=1170,
## 거의 화면 끝 1280 근처)에 있어 ART-2가 플레이어 쪽(화면 좌측)에서 고친 "왼쪽으로
## 잘림"과 반대로 "오른쪽으로 잘림" 문제가 생긴다 — 같은 보정을 반대 방향(좌측 이동,
## 음수)으로 적용. 당시 보스 배율(1.3)까지 고려해 셀프 피드백 캡처로 확정한 값 — 이후
## [대형 기획 15] Q-1(17,24)로 combat_test.gd의 MONSTER_PORTRAIT_SCALE_BY_TIER가
## 보스 배율을 1.6으로 올리면서 BOSS_PORTRAIT_POSITION_SHIFT로 앵커도 함께 보정한다.
const FACE_ART_SHIFT := Vector2(-56.0, 16.0)
const FACE_ART_FADE_SHADER := CharacterPortraitPlaceholder.FACE_ART_FADE_SHADER

## [미니 기획 ART-1c-3] 몬스터 컷만 좌/우/위 가장자리에 약 10% 알파 페이드를 켠다
## (플레이어 쪽 face_art_fade 기본값 0.0은 그대로 둬 캐릭터 화면은 영향 없음).
const FACE_ART_SIDE_FADE := 0.1
const FACE_ART_TOP_FADE := 0.1

## [미니 기획 ART-1c-5](2026-10-19) 보스 티어는 CharacterArt.BOSS_FACE_CROP_RATIO로
## 크롭을 왕관 꼭대기(y=0)까지 올리는데, 위 FACE_ART_TOP_FADE(10%)를 그대로 쓰면
## 왕관이 다시 페이드 영역에 걸린다 — 보스만 top_fade를 약 5%로 줄인다(side_fade는
## 전부 동일하게 10% 유지, 좌우 잘림 방지 목적은 티어와 무관). 일반/정예는 기존과
## 동일(FACE_ART_TOP_FADE).
const FACE_ART_TOP_FADE_BY_TIER := {
	"normal": FACE_ART_TOP_FADE,
	"elite": FACE_ART_TOP_FADE,
	"boss": 0.05,
}

## [미니 기획 ART-1c-4] 외곽 글로우(림 라이트) 상수. GLOW_SCALE은 _face_rect보다 몇 %
## 더 키워 뒤에 깔지(가장자리에 보이는 "두께") — 중심부는 어차피 _face_rect에 덮여 안
## 보이므로 전체 텍스처가 아니라 가장자리 margin만 실질적으로 노출된다. GLOW_COLOR는
## 배경 마법진/비네트와 어울리는 밝은 보라/회백 톤(캐릭터 퍼스널 컬러와는 무관 —
## 몬스터는 퍼스널 컬러 대상이 아님, DESIGN.md "퍼스널 컬러 적용 범위" 참고), GLOW_ALPHA는
## 과업 지시 범위(0.25~0.4) 안의 값.
const GLOW_SCALE := 1.18
const GLOW_COLOR := Color(0.78, 0.7, 0.95)
const GLOW_ALPHA := 0.32
## average_opaque_luminance()에 넘기는 알파 컷오프/샘플 간격 — full_crop_luminance()
## 기본값과 동일(한 곳에만 있는 상수를 두 곳에 안 흩어지게 로컬로 재선언하지 않고
## CharacterArt 쪽 기본값을 그대로 쓴다. 여기 선언하지 않는 이유 — 기본값 변경 시
## 한 곳만 고치면 되게).

## "neutral" / "happy" / "hurt" / "sad" / "angry"
@export var expression: String = "neutral"
@export var body_color: Color = Color(0.5, 0.5, 0.5)
## ""(기존 동작 보존) / "humanoid" / "amorphous" / "beast" / "undead"
## (MonsterCatalog.FAMILIES 키와 1:1 대응)
@export var family: String = ""

## ART-1c: set_monster()가 face_* 5장을 전부 찾으면 true — 이때 _draw()의 도형
## 플레이스홀더 대신 _face_rect 텍스처를 보여준다(1장이라도 없으면 항상 false로 유지돼
## 기존 플레이스홀더 그대로).
var _use_face_art := false
## ART-1c-2: face_* 5장은 없지만 full.png는 있을 때 true — 상반신 크롭을 _face_rect에
## 정적으로 보여준다(표정 전환 없음). _use_face_art가 true면 이쪽은 항상 false.
var _use_full_crop := false
var _monster_id := ""
## [미니 기획 ART-1c-3] 원화 경로 조회에만 쓰는 id — MonsterCatalog.art_resource_id()로
## 별칭(dark_knight -> dark_knight_elite)이 해석된 값. _monster_id(원래 id, 다른 용도로
## 남겨둠)와 분리해 둔다.
var _art_monster_id := ""
## [미니 기획 ART-1c-5] MonsterCatalog에서 읽은 "normal"/"elite"/"boss" — 크롭 비율/
## top_fade를 티어별로 고르는 데만 쓴다(카탈로그에 없는 id, 예: dice_test.gd의 가짜
## 테스트 id는 get("tier", "normal")로 "normal"에 안전하게 폴백).
var _tier := "normal"
var _face_rect: TextureRect = null
## [미니 기획 ART-1c-4] 어두운 컷일 때만 만들어지는 외곽 글로우(림 라이트) 노드. 밝은
## 몬스터는 끝까지 null로 남아 기존 화면과 완전히 동일하다.
var _glow_rect: TextureRect = null
## _texture_is_dark()로 한 번 계산해둔 "이 몬스터가 어두운 컷인가" — set_monster()가
## neutral/크롭 텍스처 기준으로 1회만 계산하고, 표정이 바뀌어도(set_expression()) 다시
## 계산하지 않는다(어둡다/밝다는 몬스터 단위 판정이지 표정 단위가 아님).
var _is_dark_portrait := false

## dice_test.gd가 user:// 임시 디렉터리를 주입해 "5장 모두/일부만/없음"을 실제 몬스터
## 입고 상태와 무관하게 검증할 수 있게 한다(character_portrait_placeholder.gd의
## art_base_dir와 동일한 패턴).
var art_base_dir: String = MONSTER_ART_BASE_DIR


## ART-1c: 전투 화면이 몬스터가 정해질 때 호출. face_* 5장이 전부 있으면 원화 모드로
## 전환해 이후 set_expression() 호출마다 텍스처만 갈아끼운다. 호출하지 않는 기존
## 사용처(없음)는 해당 없음 — _use_face_art는 기본값 false라 입고 전 몬스터는
## 이 함수가 호출돼도 그대로 플레이스홀더로 남는다.
func set_monster(monster_id: String) -> void:
	_monster_id = monster_id
	_art_monster_id = MonsterCatalog.art_resource_id(monster_id)
	_tier = MonsterCatalog.get_by_id(monster_id).get("tier", "normal")
	_use_face_art = CharacterArt.has_all_faces(_art_monster_id, art_base_dir)
	_use_full_crop = false
	var representative_tex: Texture2D = null
	if _use_face_art:
		_ensure_face_rect()
		representative_tex = CharacterArt.load_face(_art_monster_id, "neutral", art_base_dir)
	elif CharacterArt.has_full(_art_monster_id, art_base_dir):
		_use_full_crop = true
		_ensure_face_rect()
		var crop_ratio: Rect2 = CharacterArt.monster_face_crop_ratio(_art_monster_id, _tier, art_base_dir)
		representative_tex = CharacterArt.load_full_crop(_art_monster_id, crop_ratio, art_base_dir)
		_face_rect.texture = representative_tex
	if _face_rect != null:
		_face_rect.visible = _use_face_art or _use_full_crop
	_is_dark_portrait = _texture_is_dark(representative_tex)
	_update_glow()
	_apply_tier_fade()
	set_expression(expression)


## [미니 기획 ART-1c-5] _face_rect/_glow_rect(있으면)의 top_fade 셰이더 파라미터를
## 현재 _tier에 맞춰 갱신한다. _ensure_face_rect()/_ensure_glow_rect()는 노드를 1회만
## 만들고 기본값(FACE_ART_TOP_FADE)으로 초기화하므로, 몬스터가 바뀔 때마다(티어가
## 달라질 수 있음) 이 함수가 실제로 쓸 값을 다시 써넣는다.
func _apply_tier_fade() -> void:
	var top_fade: float = FACE_ART_TOP_FADE_BY_TIER.get(_tier, FACE_ART_TOP_FADE)
	if _face_rect != null and _face_rect.material != null:
		_face_rect.material.set_shader_parameter("top_fade", top_fade)
	if _glow_rect != null and _glow_rect.material != null:
		_glow_rect.material.set_shader_parameter("top_fade", top_fade)


func _ensure_face_rect() -> void:
	if _face_rect != null:
		return
	_face_rect = TextureRect.new()
	_face_rect.custom_minimum_size = FACE_ART_SIZE
	_face_rect.size = FACE_ART_SIZE
	_face_rect.position = Vector2(-FACE_ART_SIZE.x / 2.0, -FACE_ART_SIZE.y / 2.0) + FACE_ART_SHIFT
	_face_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_face_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_material := ShaderMaterial.new()
	fade_material.shader = FACE_ART_FADE_SHADER
	fade_material.set_shader_parameter("side_fade", FACE_ART_SIDE_FADE)
	fade_material.set_shader_parameter("top_fade", FACE_ART_TOP_FADE)
	_face_rect.material = fade_material
	add_child(_face_rect)


## [미니 기획 ART-1c-4] _face_rect보다 "뒤에"(먼저 그려지게, move_child로 인덱스 0) 두는
## 확대 복제 TextureRect. _face_rect와 같은 가장자리 페이드 셰이더를 쓰므로(별도
## ShaderMaterial 인스턴스) 글로우도 본체 실루엣과 같은 모양으로 가장자리에서 옅어진다 —
## 색/알파는 modulate로만 준다(셰이더 유니폼과 무관).
func _ensure_glow_rect() -> void:
	if _glow_rect != null:
		return
	var glow_size := FACE_ART_SIZE * GLOW_SCALE
	_glow_rect = TextureRect.new()
	_glow_rect.custom_minimum_size = glow_size
	_glow_rect.size = glow_size
	_glow_rect.position = FACE_ART_SHIFT - glow_size / 2.0
	_glow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_glow_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_rect.modulate = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, GLOW_ALPHA)
	var glow_material := ShaderMaterial.new()
	glow_material.shader = FACE_ART_FADE_SHADER
	glow_material.set_shader_parameter("side_fade", FACE_ART_SIDE_FADE)
	glow_material.set_shader_parameter("top_fade", FACE_ART_TOP_FADE)
	_glow_rect.material = glow_material
	add_child(_glow_rect)
	move_child(_glow_rect, 0) # _face_rect보다 먼저 그려지게(= 뒤에 깔리게).


## tex의 불투명 픽셀 평균 휘도가 DARK_PORTRAIT_LUMINANCE_THRESHOLD보다 낮으면 true.
## tex가 null이면(원화 없음, 도형 플레이스홀더 모드) false — 플레이스홀더는 글로우
## 대상이 아니다.
func _texture_is_dark(tex: Texture2D) -> bool:
	if tex == null:
		return false
	var image := tex.get_image()
	if image == null:
		return false
	return CharacterArt.average_opaque_luminance(image) < CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD


## _is_dark_portrait에 맞춰 글로우를 켜고(없으면 만들고 텍스처를 _face_rect와 맞춤)
## 끈다. 밝은 몬스터(_is_dark_portrait=false)는 글로우 노드를 아예 만들지 않거나(한 번도
## 어두웠던 적이 없으면) visible=false로만 남겨 화면이 기존과 완전히 같다.
func _update_glow() -> void:
	if not _is_dark_portrait:
		if _glow_rect != null:
			_glow_rect.visible = false
		return
	_ensure_glow_rect()
	_glow_rect.texture = _face_rect.texture if _face_rect != null else null
	_glow_rect.visible = _face_rect != null and _face_rect.visible


func set_expression(new_expression: String) -> void:
	expression = new_expression
	if _use_face_art and _face_rect != null:
		_face_rect.texture = CharacterArt.load_face(_art_monster_id, expression, art_base_dir)
		if _is_dark_portrait and _glow_rect != null:
			_glow_rect.texture = _face_rect.texture
	queue_redraw()


func set_body_color(color: Color) -> void:
	body_color = color
	queue_redraw()


func set_family(new_family: String) -> void:
	family = new_family
	queue_redraw()


func _draw() -> void:
	if _use_face_art or _use_full_crop:
		return
	if family == "amorphous":
		# 뿔 없이, 몸 하단에 흘러내리는 물방울 장식.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10, 60), Vector2(10, 60), Vector2(0, 86),
		]), body_color)
	elif family == "undead":
		# 뿔 대신 갈라진 뼈 장식(해골 컨셉).
		draw_colored_polygon(PackedVector2Array([
			Vector2(-40, -30), Vector2(-30, -30), Vector2(-35, -70), Vector2(-45, -70),
		]), HORN_COLOR)
		draw_colored_polygon(PackedVector2Array([
			Vector2(30, -30), Vector2(40, -30), Vector2(45, -70), Vector2(35, -70),
		]), HORN_COLOR)
	else:
		# "humanoid"/"beast"/빈 문자열(기존 호출부 호환) — 기존 뿔 두 개 그대로.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-46, -30), Vector2(-26, -30), Vector2(-40, -78),
		]), HORN_COLOR)
		draw_colored_polygon(PackedVector2Array([
			Vector2(26, -30), Vector2(46, -30), Vector2(40, -78),
		]), HORN_COLOR)
	if family == "humanoid":
		# 투구 테두리(가로줄) — 몸을 그리기 전에 그려서 몸에 살짝 덮이게.
		draw_line(Vector2(-50, -20), Vector2(50, -20), HORN_COLOR, 6.0)
	# 몸통 (둥근 블롭)
	draw_colored_polygon(_ellipse_points(Vector2(0, 10), 66, 74), body_color)

	var eye_l := Vector2(-20, -6)
	var eye_r := Vector2(20, -6)
	var mouth_center := Vector2(0, 24)

	match expression:
		"angry":
			draw_line(eye_l + Vector2(-8, -10), eye_l + Vector2(8, -3), EYE_COLOR, 3.0)
			draw_line(eye_r + Vector2(-8, -3), eye_r + Vector2(8, -10), EYE_COLOR, 3.0)
		"sad", "hurt":
			draw_line(eye_l + Vector2(-8, -3), eye_l + Vector2(8, -10), EYE_COLOR, 2.5)
			draw_line(eye_r + Vector2(-8, -10), eye_r + Vector2(8, -3), EYE_COLOR, 2.5)
		_:
			pass

	if family == "undead":
		# 눈구멍(테두리만, 채우지 않음) — 눈썹 선 위에 그려져 기존처럼 눈이 또렷이 보임.
		draw_arc(eye_l, 6, 0, TAU, 12, EYE_COLOR, 2.0)
		draw_arc(eye_r, 6, 0, TAU, 12, EYE_COLOR, 2.0)
	else:
		draw_circle(eye_l, 6, EYE_COLOR)
		draw_circle(eye_r, 6, EYE_COLOR)

	match expression:
		"happy":
			draw_polyline(_arc_points(mouth_center + Vector2(0, -6), 16, PI * 0.1, PI * 0.9), MOUTH_COLOR, 3.0)
		"angry":
			draw_polyline(PackedVector2Array([
				mouth_center + Vector2(-14, -2), mouth_center + Vector2(-5, 4),
				mouth_center + Vector2(5, -2), mouth_center + Vector2(14, 4),
			]), MOUTH_COLOR, 3.0)
		"sad", "hurt":
			draw_polyline(_arc_points(mouth_center + Vector2(0, 12), 16, PI * 1.1, PI * 1.9), MOUTH_COLOR, 3.0)
		_:
			draw_line(mouth_center + Vector2(-12, 2), mouth_center + Vector2(12, 2), MOUTH_COLOR, 3.0)


func _arc_points(center: Vector2, radius: float, angle_from: float, angle_to: float, segments: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle: float = lerp(angle_from, angle_to, t)
		pts.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	return pts


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float, segments: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return pts
