extends SceneTree
## tools/artgen/fur_recolor.gd — 붉은 털·머리(퍼스널 컬러)만 지정 색조로 돌린다(형태 변경 없음).
## 대상 = 색조 0.90~1.0 또는 0~0.015, 채도 ≥ 0.45 인 픽셀. 얼굴(눈·입 안) 보호용 제외 사각형을 줄 수 있다.
## GPT가 광란의 마수의 퍼스널 컬러(짙은 자주)를 다시 빨강으로 그릴 때 사용.
## 사용: godot --headless --script fur_recolor.gd -- <입력> <출력> <색조> <명도 배율> [제외 x y w h]...

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var hue := float(a[2]); var kv := float(a[3])
	var exs := []
	var i := 4
	while i + 3 < a.size():
		exs.append(Rect2i(int(a[i]), int(a[i + 1]), int(a[i + 2]), int(a[i + 3]))); i += 4
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.s < 0.45 or (c.h > 0.015 and c.h < 0.90): continue
			var skip := false
			for r in exs:
				if r.has_point(Vector2i(x, y)): skip = true
			if skip: continue
			img.set_pixel(x, y, Color.from_hsv(hue, minf(c.s * 0.92, 0.9), c.v * kv, c.a))
	img.save_png(a[1])
	quit()
