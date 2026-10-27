extends SceneTree
## [대형 기획 17] S-0 재작업 — "전"/"후" 비교 이미지(<화면>_compare.png) 생성 도구.
##
## compare_view.gd(실제 창을 띄워 캡처)로 먼저 만들어봤지만, 이 환경의 디스플레이가
## 2592x760처럼 넓은 창을 띄우지 못해(요청해도 1280x720으로 다시 clamp되는 것을
## 실측 확인) 창 기반 캡처로는 두 1280x720 이미지를 원본 크기 그대로 나란히 놓을 수
## 없었다. 이 스크립트는 mockup_postprocess.gd와 같은 "창 없는 순수 Image API"
## 방식이라 캔버스 크기에 디스플레이 제약을 받지 않는다 — "전"/"후" 글자는
## label_render.gd가 1280x720(이 환경에서 안정적으로 캡처되는 유일한 창 크기)으로
## 미리 그려둔 조각을 그대로 붙여넣는다(새 텍스트 렌더링 경로를 만들지 않음).
##
## 사용법:
##   godot4 --headless --script code/qa/mockup_compare.gd -- \
##     <before.png> <after.png> <label_before.png> <label_after.png> <out.png>

const IMG_W := 1280
const IMG_H := 720
const GAP := 32
const TOP_PAD := 56


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 5:
		print("usage: godot4 --headless --script code/qa/mockup_compare.gd -- <before> <after> <label_before> <label_after> <out>")
		quit(1)
		return

	var before := _load(args[0])
	var after := _load(args[1])
	var label_before := _load(args[2])
	var label_after := _load(args[3])
	var out_path := args[4]

	if before == null or after == null:
		print("load error for before/after images")
		quit(1)
		return

	var canvas_w := IMG_W * 2 + GAP
	var canvas_h := IMG_H + TOP_PAD
	var canvas := Image.create(canvas_w, canvas_h, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.04, 0.04, 0.05, 1.0))

	canvas.blit_rect(before, Rect2i(Vector2i.ZERO, before.get_size()), Vector2i(0, TOP_PAD))
	canvas.blit_rect(after, Rect2i(Vector2i.ZERO, after.get_size()), Vector2i(IMG_W + GAP, TOP_PAD))
	if label_before != null:
		canvas.blit_rect(label_before, Rect2i(Vector2i.ZERO, label_before.get_size()), Vector2i(16, 8))
	if label_after != null:
		canvas.blit_rect(label_after, Rect2i(Vector2i.ZERO, label_after.get_size()), Vector2i(IMG_W + GAP + 16, 8))

	var err := canvas.save_png(out_path)
	if err != OK:
		print("save error: ", err)
		quit(1)
		return
	print("saved: ", out_path)
	quit(0)


func _load(path: String) -> Image:
	var img := Image.new()
	if img.load(path) != OK:
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img
