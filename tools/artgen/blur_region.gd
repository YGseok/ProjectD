extends SceneTree
## tools/artgen/blur_region.gd — 지정한 타원 영역만 흐리게(안개처럼 경계를 녹임). 가장자리는 부드럽게 섞는다.
## GPT 재생성 없이 "이 부분만 뿌옇게" 수정할 때 사용(예: 그림자의 가슴 옷 경계).
## 사용: godot --headless --script blur_region.gd -- <입력> <출력> <cx> <cy> <rx> <ry> [반경=6] [반복=3]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var c := Vector2(float(a[2]), float(a[3])); var r := Vector2(float(a[4]), float(a[5]))
	var R := int(a[6]) if a.size() > 6 else 6
	var N := int(a[7]) if a.size() > 7 else 3
	var rect := Rect2i(int(c.x - r.x) - R, int(c.y - r.y) - R, int(r.x * 2) + R * 2, int(r.y * 2) + R * 2).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var src := img.get_region(rect)
	var w := src.get_width(); var h := src.get_height()
	for it in N:
		var tmp := src.duplicate() as Image
		for y in h:
			for x in w:
				var acc := Color(0, 0, 0, 0); var n := 0
				for dx in range(-R, R + 1, 2):
					var xx := clampi(x + dx, 0, w - 1)
					acc += src.get_pixel(xx, y); n += 1
				tmp.set_pixel(x, y, acc / n)
		for y in h:
			for x in w:
				var acc := Color(0, 0, 0, 0); var n := 0
				for dy in range(-R, R + 1, 2):
					var yy := clampi(y + dy, 0, h - 1)
					acc += tmp.get_pixel(x, yy); n += 1
				src.set_pixel(x, y, acc / n)
	for y in h:
		for x in w:
			var p := Vector2(rect.position.x + x, rect.position.y + y)
			var d := ((p - c) / r).length()
			var t := clampf((1.0 - d) / 0.35, 0.0, 1.0)
			if t <= 0.0: continue
			var o := img.get_pixel(int(p.x), int(p.y))
			img.set_pixel(int(p.x), int(p.y), o.lerp(src.get_pixel(x, y), t))
	img.save_png(a[1])
	quit()
