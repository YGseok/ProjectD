extends RefCounted
class_name CharacterArt
## 캐릭터 원화(일러스트) 경로 규칙과 로드 헬퍼.
##
## 파일 위치는 docs/art/ART_RESOURCES.md "폴더 규칙"을 따른다:
##   res://resources/characters/<캐릭터 id>/full.png   — 선택 화면 전신
##   res://resources/characters/<캐릭터 id>/face_<표정>.png — 전투 화면 상반신 표정 컷(추후)
## 파일이 아직 입고되지 않은 캐릭터는 load_*()가 null을 돌려주므로, 호출하는 쪽은
## null이면 기존 도형 플레이스홀더(CharacterPortraitPlaceholder)를 그대로 쓰면 된다.

const BASE_DIR := "res://resources/characters/%s/"

## 목록 카드용 썸네일 크롭 영역(전신 원화 1181x1332 기준). 입고된 원화들은 머리가
## 대략 x 450~700 / y 50~400 부근에 있어서, 가운데 위쪽(머리~허리)을 카드 칸 비율
## (72x92 ≈ 0.78)에 맞춰 잘라낸다. 특정 캐릭터 구도가 크게 다르면 프로필별 오버라이드를
## 추가할 것.
const THUMB_REGION := Rect2(250, 30, 620, 792)

## 얼굴 전용 정사각 크롭 비율(INBOX.md 2026-10-13 [대형 기획 11] K-2 — 좌측 목록을
## "얼굴 중심 정사각 썸네일"로 개편). 전신 원화의 실제 픽셀 크기와 무관하게 0..1 비율로
## 저장해 어떤 해상도의 full.png가 와도 같은 구도(머리~눈썹 아래 정도까지)를 잘라낸다.
## THUMB_REGION(상반신, 비율로 환산하면 폭 0.525/높이 0.595)보다 더 좁고 위쪽에 집중된
## 정사각 영역 — 입고된 원화 머리 위치(x 450~700 / y 50~400, 1181x1332 기준)를 비율로
## 옮기면 대략 x 0.26~0.73 / y 0.02~0.45가 되므로, 정사각(가로=세로)으로 맞추기 위해
## 폭 0.48을 기준으로 삼았다. 캐릭터별로 구도가 크게 다르면 CharacterProfiles.PROFILES에
## "face_crop": Rect2(...) 필드를 추가해 이 기본값을 덮어쓸 수 있다(아직 쓰는 캐릭터 없음).
const DEFAULT_FACE_CROP_RATIO := Rect2(0.26, 0.015, 0.48, 0.48)

## [미니 기획 ART-1c-5](2026-10-19) 몬스터 보스 티어 전용 크롭. v3 보스 원화는 큰
## 왕관/머리장식이 있는데, DEFAULT_FACE_CROP_RATIO(플레이어 기준 "머리~눈썹" 구도,
## y 시작 0.015)를 그대로 쓰면 face_art_fade 셰이더의 top_fade(10%)가 왕관 꼭대기의
## 가는 첨탑~관 테두리 바로 그 자리와 겹쳐 왕관이 거의 안 보인다(보스 6종 전수 측정 —
## 불투명 픽셀이 시작하는 행이 전부 y 비율 0.010~0.017로 이미지 맨 위부터 왕관이
## 시작하는데, 크롭 시작(0.015)+그 위 10% 페이드가 정확히 그 구간을 가림). 보스만
## y를 0(이미지 최상단)으로 당기고 height를 0.48->0.52로 늘려 왕관 꼭대기~허리
## 정도까지 담는다(MonsterPortraitPlaceholder가 top_fade도 보스만 5%로 함께 줄임).
## 일반/정예는 DEFAULT_FACE_CROP_RATIO 그대로(요구사항 — 변경 없음). 몬스터 쪽 표시
## 박스(FACE_ART_SIZE*보스 배율 1.6=384px 정사각)는 가로=0.48 폭 기준 크롭 비율이
## 0.4256보다 크면(0.48/0.52 둘 다 해당) 항상 세로가 박스 전체를 채우는
## height-bound 로 렌더되므로, height 값을 더 늘려도 화면 차지 면적(384px)은 늘지
## 않고 "같은 박스 안에 더 많이 보이느냐"만 바뀐다 — combat_test.gd의
## BOSS_PORTRAIT_POSITION_SHIFT.y(HUD 패널 회피)가 실제 화면 여백을 결정한다.
const BOSS_FACE_CROP_RATIO := Rect2(0.26, 0.0, 0.48, 0.52)

## 몬스터 티어별 크롭 비율 데이터 표 — MonsterPortraitPlaceholder가 MonsterCatalog에서
## 읽은 tier 문자열로만 조회한다(몬스터 id 하드코딩 금지).
const MONSTER_FACE_CROP_RATIO_BY_TIER := {
	"normal": DEFAULT_FACE_CROP_RATIO,
	"elite": DEFAULT_FACE_CROP_RATIO,
	"boss": BOSS_FACE_CROP_RATIO,
}


static func full_path(character_id: String, base_dir: String = BASE_DIR) -> String:
	return (base_dir % character_id) + "full.png"


## 전신 원화. 없으면 null. base_dir 의미는 face_path()/load_face()와 동일(기본값은
## production 경로, ART-1c-2가 몬스터 전용 base_dir(res://resources/monsters/%s/,
## CharacterArt.BASE_DIR과 다른 상수)을 넘기기 위해 매개변수화했다 — 그래서 "production
## 경로인가"는 BASE_DIR과의 등호 비교 대신 res:// 접두어로 판단한다(아래 load_face()와
## 동일한 이유로 동일하게 고침).
static func load_full(character_id: String, base_dir: String = BASE_DIR) -> Texture2D:
	var path := full_path(character_id, base_dir)
	if base_dir.begins_with("res://"):
		if not ResourceLoader.exists(path):
			return null
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(path) != OK:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## full.png 존재 여부만(디코드 없이) 확인 — has_all_faces()와 같은 패턴(FileAccess로
## production/테스트 경로 양쪽 공통 처리).
static func has_full(character_id: String, base_dir: String = BASE_DIR) -> bool:
	return FileAccess.file_exists(full_path(character_id, base_dir))


## 목록 카드용 썸네일(전신 원화의 상반신 부분). 원화가 없으면 null.
static func load_thumb(character_id: String) -> Texture2D:
	var full := load_full(character_id)
	if full == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = full
	atlas.region = THUMB_REGION
	return atlas


## base_dir(2026-10-16 [대형 기획 14] N-6 인수인계 수정 — "berserker는 face_*가
## 없다"는 가정이 실제 아트 입고로 깨져 dice_test.gd ART-1b 검증 4건이 FAIL로
## 돌아선 문제): 기본값은 production 경로(BASE_DIR)지만, dice_test.gd가 user://
## 임시 디렉터리를 넘겨 "5장 모두 있음/일부만 있음/없음" 세 경우를 실제 캐릭터
## 입고 상태에 의존하지 않고 검증할 수 있게 한다 — ui_kit.gd/skill_icon.gd의
## base_dir 주입 패턴(FileAccess.file_exists + Image.load, ResourceLoader 경유
## 안 함)과 동일한 이유.
static func face_path(character_id: String, expression: String, base_dir: String = BASE_DIR) -> String:
	return (base_dir % character_id) + "face_%s.png" % expression


## 전투 화면용 표정 컷(ART-1b 규칙) 1장. 파일이 없으면 null(호출하는 쪽이 기존 도형
## 플레이스홀더로 폴백). base_dir가 production 경로(res:// 접두어 — 캐릭터 BASE_DIR/
## 몬스터 MONSTER_ART_BASE_DIR 둘 다 포함)면 기존과 동일하게 ResourceLoader(load())로
## 가져온다 — res:// 임포트된 리소스를 그대로 쓰므로 export 경고("Loaded resource as
## image file...")가 없고 기존 동작과 완전히 같다. base_dir가 주입된 테스트 경로
## (user:// 등)일 때만 FileAccess.file_exists + Image.load로 읽는다(ui_kit.gd/
## skill_icon.gd의 base_dir 주입 패턴과 동일한 이유 — ResourceLoader는 .import가 없는
## user:// raw PNG를 못 읽는다).
static func load_face(character_id: String, expression: String, base_dir: String = BASE_DIR) -> Texture2D:
	var path := face_path(character_id, expression, base_dir)
	if base_dir.begins_with("res://"):
		if not ResourceLoader.exists(path):
			return null
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(path) != OK:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## ART-1b: face_{neutral,happy,hurt,sad,angry} 5장이 전부 입고됐는지 — 전투 화면이
## "일부만 원화로 섞이는" 상태를 막기 위해 5장 모두 있을 때만 원화 모드로 전환한다.
const FACE_EXPRESSIONS := ["neutral", "happy", "hurt", "sad", "angry"]

static func has_all_faces(character_id: String, base_dir: String = BASE_DIR) -> bool:
	for expression in FACE_EXPRESSIONS:
		if not FileAccess.file_exists(face_path(character_id, expression, base_dir)):
			return false
	return true


## [대형 기획 15] Q-11(몬스터 도감) — has_all_faces()와 같은 존재 확인을 "전부 있는가"
## 대신 "몇 장 있는가"로 센다. 도감 격자 카드의 "표정 n/5" 태그와 상세 뷰 리소스 입고
## 현황(파일별 ✓/✗)이 둘 다 이 숫자 하나로 일관되게 계산된다.
static func face_count(character_id: String, base_dir: String = BASE_DIR) -> int:
	var count := 0
	for expression in FACE_EXPRESSIONS:
		if FileAccess.file_exists(face_path(character_id, expression, base_dir)):
			count += 1
	return count


## 캐릭터 프로필의 "face_crop" 필드(Rect2, 0..1 비율)가 있으면 그것을, 없으면
## DEFAULT_FACE_CROP_RATIO를 돌려준다.
static func face_crop_ratio(character_id: String) -> Rect2:
	var profile := CharacterProfiles.get_profile(character_id)
	return profile.get("face_crop", DEFAULT_FACE_CROP_RATIO)


## full.png에서 비율(ratio, 0..1) 영역만 잘라낸 텍스처 — load_face_crop()의 공용
## 크롭 로직. full.png가 없으면 null. ART-1c-2가 몬스터 쪽(CharacterProfiles에 없는
## id라 face_crop_ratio()를 못 씀)에서 DEFAULT_FACE_CROP_RATIO를 직접 넘겨 재사용한다
## — 크롭 방식 자체(비율 → 잘라낸 이미지)는 여기 하나뿐, 새로 만들지 않는다.
##
## [미니 기획 ART-1c-3](2026-10-16) 전에는 AtlasTexture(원본 이미지 전체를 참조하고
## region만 지정)를 썼는데, canvas_item 셰이더의 UV 빌트인이 AtlasTexture에서는 0..1
## 전체가 아니라 "원본 이미지 기준 region 비율 구간"(예: DEFAULT_FACE_CROP_RATIO면
## y가 0.015~0.495 구간)으로 들어와, face_art_fade 셰이더의 fade_start(=0.76)가 크롭
## UV 범위 밖이라 전혀 발동하지 않는 버그가 있었다(몬스터 쪽 하단 페이드가 거의 안
## 보인다는 피드백의 실제 원인 — qa_out/art1c3_fallen_commander_before.png에서 확인,
## dice_test.gd의 SubViewport 알파 샘플링으로도 재현: 크롭 모드 바닥 알파가 1.000으로
## 전혀 안 떨어짐). Image.get_region()으로 실제 픽셀을 오려낸 독립 ImageTexture를
## 돌려주면 그 텍스처 자체의 UV가 0..1로 크롭 영역 전체를 가리켜(face_* 표정 컷과
## 동일한 상황), 셰이더의 하단/좌/우/상단 페이드가 전부 의도대로 작동한다.
static func load_full_crop(character_id: String, ratio: Rect2, base_dir: String = BASE_DIR) -> Texture2D:
	var cropped_image := _crop_image(character_id, ratio, base_dir)
	if cropped_image == null:
		return null
	cropped_image.generate_mipmaps()
	return ImageTexture.create_from_image(cropped_image)


## load_full_crop()/full_crop_luminance() 공용 — 비율(ratio, 0..1) 영역만 실제 픽셀로
## 오려낸 Image(텍스처로 감싸기 전). full.png가 없으면 null.
static func _crop_image(character_id: String, ratio: Rect2, base_dir: String = BASE_DIR) -> Image:
	var full := load_full(character_id, base_dir)
	if full == null:
		return null
	var full_image := full.get_image()
	if full_image == null:
		return null
	var size := full_image.get_size()
	var region := Rect2i(
		Vector2i(ratio.position * Vector2(size)),
		Vector2i(ratio.size * Vector2(size))
	).intersection(Rect2i(Vector2i.ZERO, size))
	if region.size.x <= 0 or region.size.y <= 0:
		return null
	return full_image.get_region(region)


## [미니 기획 ART-1c-4] 어두운 몬스터 외곽 글로우 판정 기준값(0..1 상대 휘도, ITU-R
## BT.709 계수). 이 값보다 평균 휘도가 낮으면 "어두운 컷"으로 보고 외곽에 옅은 림
## 라이트를 깐다(MonsterPortraitPlaceholder._texture_is_dark() 참고) — 몬스터별
## 하드코딩 없이 이 하나의 상수만으로 전체 카탈로그를 판정한다. 값 근거는
## docs/STATUS.md 완료 기록의 카탈로그 전수 휘도표(어두운 쪽 shadow/mist/ghost류와
## 밝은 쪽 대다수 사이에 뚜렷한 간격이 있던 지점으로 선택).
const DARK_PORTRAIT_LUMINANCE_THRESHOLD := 0.22

## 이미지의 "불투명 픽셀만" 평균 상대 휘도(0=검정, 1=흰색)를 구한다. 알파가
## alpha_threshold 미만인 픽셀(크롭 과정에서 생기는 투명 배경/레터박스)은 평균 계산에서
## 제외한다 — 안 그러면 투명 배경이 전부 검정(0,0,0,0)으로 저장된 PNG는 몬스터 실루엣이
## 밝아도 평균이 크게 낮아져 오판한다. 성능을 위해 stride(기본 1=전체 픽셀)로 샘플
## 간격을 띄울 수 있다 — 큰 원화 이미지를 매 몬스터 교체 시 1회만 계산하면 되므로
## 기본값은 정밀도를 우선하고, 호출하는 쪽(full_crop_luminance())이 필요시 더 크게 넘긴다.
## 불투명 픽셀이 하나도 없으면(크롭 결과가 전부 투명 등) 1.0(밝음, 글로우 없음)을 돌려줘
## 안전하게 폴백한다.
static func average_opaque_luminance(image: Image, alpha_threshold: float = 0.5, stride: int = 1) -> float:
	if image == null:
		return 1.0
	var size := image.get_size()
	var step: int = max(1, stride)
	var total := 0.0
	var count := 0
	var y := 0
	while y < size.y:
		var x := 0
		while x < size.x:
			var c := image.get_pixel(x, y)
			if c.a >= alpha_threshold:
				total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
				count += 1
			x += step
		y += step
	if count == 0:
		return 1.0
	return total / count


## full.png의 ratio 크롭 영역에 대한 average_opaque_luminance() — MonsterPortrait가
## 실제로 표시하는 크롭과 동일한 픽셀을 본다(별도 이미지 로드/계산 로직 없음).
## full.png가 없으면 1.0(밝음, 글로우 없음)을 돌려준다. stride=3 기본값은 320x320 안팎인
## 크롭 이미지 기준 체감 속도와 정밀도 사이의 절충(몬스터 교체 시 1회만 계산).
static func full_crop_luminance(character_id: String, ratio: Rect2, base_dir: String = BASE_DIR, stride: int = 3) -> float:
	return average_opaque_luminance(_crop_image(character_id, ratio, base_dir), 0.5, stride)


## full.png에서 얼굴 비율 영역만 잘라낸 텍스처(캐릭터 전용 — face_crop_ratio()로 프로필
## 오버라이드를 반영). full.png가 없으면 null.
static func load_face_crop(character_id: String) -> Texture2D:
	return load_full_crop(character_id, face_crop_ratio(character_id), BASE_DIR)


## K-2 좌측 목록용 "얼굴 중심 정사각 썸네일" — 우선순위: ① face_neutral.png
## ② full.png에서 얼굴 비율 크롭 ③ 둘 다 없으면 null(호출하는 쪽이 기존 도형
## 플레이스홀더로 폴백).
static func load_face_thumb(character_id: String) -> Texture2D:
	var face := load_face(character_id, "neutral")
	if face != null:
		return face
	return load_face_crop(character_id)


## [대형 기획 15] Q-10(2026-10-20): 스토리 이벤트/특수 이벤트 일러스트 경로.
## 캐릭터(<id>/full.png, <id>/face_*.png, 하위 폴더)와 달리 이벤트는 캐릭터 폴더
## 구조가 필요 없는 평면 1파일 1이벤트라, BASE_DIR(%s 폴더 포맷)이 아니라
## skill_icon.gd의 EXTERNAL_ART_DIR 패턴(base_dir + id + ".png")을 그대로 따른다.
const EVENT_ART_DIR := "res://resources/events/"

static func event_art_path(event_id: String, base_dir: String = EVENT_ART_DIR) -> String:
	return base_dir + event_id + ".png"


static func has_event_art(event_id: String, base_dir: String = EVENT_ART_DIR) -> bool:
	return FileAccess.file_exists(event_art_path(event_id, base_dir))


## load_face()와 동일한 이유로 production(res://, .import 경유 ResourceLoader)과
## 테스트 주입 경로(user:// 등, FileAccess+Image.load)를 나눈다 — dice_test.gd가
## 합성 PNG로 "파일 있음/없음" 양쪽을 production 리소스에 의존하지 않고 검증할 수
## 있게 하기 위함.
static func load_event_art(event_id: String, base_dir: String = EVENT_ART_DIR) -> Texture2D:
	var path := event_art_path(event_id, base_dir)
	if base_dir.begins_with("res://"):
		if not ResourceLoader.exists(path):
			return null
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(path) != OK:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## face_art_fade.gdshader(ART-2/ART-1c-3) 재사용 — 캐릭터 표정 컷은 "하단만 잘림"
## 용도로 fade_start만 쓰지만, 이벤트 일러스트는 상황 전체를 담은 사각 그림이라
## 네 방향(상/하/좌/우) 모두 옅게 블렌딩해 배경 비네트와 자연스럽게 섞이게 한다.
const ILLUSTRATION_FADE_SHADER := preload("res://code/shaders/face_art_fade.gdshader")


## 이벤트 일러스트용 TextureRect 하나를 만들어 돌려준다(아직 add_child는 안 함 —
## 호출부가 parent/표시 시점을 결정). rect(위치+크기)만 받고 비율 유지로 중앙
## 배치한다(CharacterPortraitPlaceholder._ensure_face_rect()와 같은 설정).
static func build_illustration_rect(texture: Texture2D, rect: Rect2) -> TextureRect:
	var tex_rect := TextureRect.new()
	tex_rect.position = rect.position
	tex_rect.size = rect.size
	tex_rect.custom_minimum_size = rect.size
	tex_rect.texture = texture
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_material := ShaderMaterial.new()
	fade_material.shader = ILLUSTRATION_FADE_SHADER
	fade_material.set_shader_parameter("fade_start", 0.88)
	fade_material.set_shader_parameter("side_fade", 0.1)
	fade_material.set_shader_parameter("top_fade", 0.1)
	tex_rect.material = fade_material
	return tex_rect


## event.gd/story_event.gd 공용 갱신 헬퍼 — 이전에 만들어둔 일러스트(current, 없으면
## null)를 지우고, event_id의 아트가 있으면 parent에 새로 붙여 반환하고(폴백 없음,
## 호출부가 보여주는 위치/숨김 시점을 결정), 없으면(= 폴백: 화면은 기존 배경
## 그대로) null을 반환한다. base_dir는 dice_test.gd가 합성 PNG로 주입하는 테스트
## 지점(character_portrait_placeholder.gd의 art_base_dir과 같은 패턴).
static func refresh_illustration_rect(parent: Node, current: TextureRect, event_id: String, rect: Rect2, base_dir: String = EVENT_ART_DIR) -> TextureRect:
	if current != null:
		current.queue_free()
	var art := load_event_art(event_id, base_dir)
	if art == null:
		return null
	var tex_rect := build_illustration_rect(art, rect)
	parent.add_child(tex_rect)
	return tex_rect
