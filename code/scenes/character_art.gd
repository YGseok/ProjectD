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


static func full_path(character_id: String) -> String:
	return (BASE_DIR % character_id) + "full.png"


## 전신 원화. 없으면 null.
static func load_full(character_id: String) -> Texture2D:
	var path := full_path(character_id)
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


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
## 플레이스홀더로 폴백). base_dir가 production 경로(기본값)면 기존과 동일하게
## ResourceLoader(load())로 가져온다 — res:// 임포트된 리소스를 그대로 쓰므로 export
## 경고("Loaded resource as image file...")가 없고 기존 동작과 완전히 같다. base_dir가
## 주입된 테스트 경로(user:// 등)일 때만 FileAccess.file_exists + Image.load로 읽는다
## (ui_kit.gd/skill_icon.gd의 base_dir 주입 패턴과 동일한 이유 — ResourceLoader는
## .import가 없는 user:// raw PNG를 못 읽는다).
static func load_face(character_id: String, expression: String, base_dir: String = BASE_DIR) -> Texture2D:
	var path := face_path(character_id, expression, base_dir)
	if base_dir == BASE_DIR:
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


## 캐릭터 프로필의 "face_crop" 필드(Rect2, 0..1 비율)가 있으면 그것을, 없으면
## DEFAULT_FACE_CROP_RATIO를 돌려준다.
static func face_crop_ratio(character_id: String) -> Rect2:
	var profile := CharacterProfiles.get_profile(character_id)
	return profile.get("face_crop", DEFAULT_FACE_CROP_RATIO)


## full.png에서 얼굴 비율 영역만 잘라낸 텍스처. full.png가 없으면 null.
static func load_face_crop(character_id: String) -> Texture2D:
	var full := load_full(character_id)
	if full == null:
		return null
	var ratio := face_crop_ratio(character_id)
	var size := full.get_size()
	var atlas := AtlasTexture.new()
	atlas.atlas = full
	atlas.region = Rect2(ratio.position * size, ratio.size * size)
	return atlas


## K-2 좌측 목록용 "얼굴 중심 정사각 썸네일" — 우선순위: ① face_neutral.png
## ② full.png에서 얼굴 비율 크롭 ③ 둘 다 없으면 null(호출하는 쪽이 기존 도형
## 플레이스홀더로 폴백).
static func load_face_thumb(character_id: String) -> Texture2D:
	var face := load_face(character_id, "neutral")
	if face != null:
		return face
	return load_face_crop(character_id)
