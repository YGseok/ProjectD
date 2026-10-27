extends SceneTree
## [대형 기획 17] S-0 1단계 "사람 눈 검증"용 1회성 이미지 후처리 도구.
##
## "전/후" 1280x720 캡처를 640x360로 줄인 버전(작게 봤을 때도 1순위가 읽히는지)과,
## 흐리게 만든 버전(눈을 가늘게 뜬 효과 — 위계가 보이는지)을 만든다. ImageMagick/PIL이
## 이 환경에 없어 Godot Image API로 직접 구현 — 흐림은 박스 블러를 여러 번 겹쳐
## 가우시안에 근사한다.
##
## 사용법:
##   godot4 --headless --script code/qa/mockup_postprocess.gd -- <png_path> [<png_path> ...]
## 각 <png_path>마다 같은 폴더에 "<name>_640.png"(축소)와 "<name>_blur.png"(흐림,
## 1280x720 유지)를 만든다.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		print("usage: godot4 --headless --script code/qa/mockup_postprocess.gd -- <png_path> [...]")
		quit(1)
		return
	for path in args:
		_process_one(path)
	quit(0)


func _process_one(path: String) -> void:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		print("load error: ", err, " path=", path)
		return
	var base := path.get_basename()

	var small := img.duplicate()
	small.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	small.save_png(base + "_640.png")
	print("saved: ", base, "_640.png")

	var blurred := _box_blur_approx_gaussian(img)
	blurred.save_png(base + "_blur.png")
	print("saved: ", base, "_blur.png")


## 다운스케일 -> 업스케일을 여러 단계 거치면(각 단계가 평균을 내므로) 가우시안 흐림과
## 비슷한 결과가 난다 — Godot Image에 블러 필터가 없어 쓰는 근사법("눈을 가늘게 뜬
## 효과"가 목적이라 엄밀한 가우시안일 필요는 없음, 큰 덩어리 형태/색 분포만 보존되면 됨).
func _box_blur_approx_gaussian(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var work := img.duplicate()
	work.convert(Image.FORMAT_RGBA8)
	# 1280x720 -> 80x45 -> 1280x720: 16배 축소 후 재확대로 강한 흐림.
	work.resize(max(1, w / 16), max(1, h / 16), Image.INTERPOLATE_BILINEAR)
	work.resize(w, h, Image.INTERPOLATE_BILINEAR)
	return work
