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
