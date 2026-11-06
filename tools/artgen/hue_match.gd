extends SceneTree
## tools/artgen/hue_match.gd — 색조 범위(hmin~hmax) 픽셀의 평균 색조·채도·명도를 참고 그림에 맞춘다(형태는 그대로, 색 느낌만).
## 공허의 눈: 잘 됐던 b11 형태에 b14의 푸른 색감 입히기(2026-11-06).
## 사용: godot --headless --script hue_match.gd -- <입력> <참고> <출력> <hmin> <hmax>
func _st(img: Image, h0: float, h1: float) -> Vector3:
	var s := Vector3.ZERO; var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.s > 0.25 and c.v > 0.15 and c.h >= h0 and c.h <= h1: s += Vector3(c.h, c.s, c.v); n += 1
	return s / maxi(n, 1)
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var ref := Image.load_from_file(a[1]); ref.convert(Image.FORMAT_RGBA8)
	var h0 := float(a[3]); var h1 := float(a[4])
	var mi := _st(img, h0, h1); var mr := _st(ref, h0, h1)
	print(mi, " -> ", mr)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.05 or c.s < 0.15 or c.h < h0 - 0.03 or c.h > h1 + 0.03: continue
			var w := clampf((c.s - 0.15) / 0.1, 0.0, 1.0)
			var d := Color.from_hsv(clampf(c.h + mr.x - mi.x, 0, 1), clampf(c.s * mr.y / mi.y, 0, 1), clampf(c.v * mr.z / mi.z, 0, 1), c.a)
			img.set_pixel(x, y, c.lerp(d, w))
	img.save_png(a[2]); quit()
