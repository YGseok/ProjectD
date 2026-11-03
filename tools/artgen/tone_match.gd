extends SceneTree
## tools/artgen/tone_match.gd — 지정 사각형 안에서 기준 피부색보다 밝은 피부색 픽셀만 기준 톤으로 끌어내린다
## (부분 합성 후 남은 밝은 피부 조각 정리용). 색조가 피부 범위(살구~갈색)이고 기준보다 밝은 픽셀만 대상.
## 사용: godot --headless --script tone_match.gd -- <입력> <출력> <x> <y> <w> <h> <기준 x> <기준 y>

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var r := Rect2i(int(a[2]), int(a[3]), int(a[4]), int(a[5]))
	var ref := img.get_pixel(int(a[6]), int(a[7]))
	var n := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.h < 0.015 or c.h > 0.1 or c.s < 0.25: continue
			if c.v <= ref.v + 0.03: continue
			img.set_pixel(x, y, Color.from_hsv(ref.h, maxf(c.s, ref.s), ref.v + (c.v - ref.v) * 0.15, c.a)); n += 1
	print("[tone_match] ", n, "px")
	img.save_png(a[1])
	quit()
