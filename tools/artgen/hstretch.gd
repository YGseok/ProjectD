extends SceneTree
## tools/artgen/hstretch.gd — 지정 줄 범위에서 xa~xb 구간을 xa~xb2로 고르게 가로로 늘인다(원본 픽셀만 사용).
## 둥근 덩어리를 넓고 낮게, 오른쪽 옆선 경사를 완만하게 만들 때(점액 군주 b44, 2026-11-05). row_stretch는 줄마다 끝을 끌어서
## 흘러내림 방울이 뿔처럼 늘어나 폐기 — 여기서는 모든 줄을 같은 배율로 늘여 모양이 유지된다.
## fy0~fy1 구간에서 배율을 1로 줄여 아래 바닥 점액과 이어지게 한다. 늘어난 결과가 배경이면 원래 픽셀을 유지.
## 사용: godot --headless --script hstretch.gd -- <입력(흰 배경)> <출력> <xa> <xb> <xb2> <y0> <fy0> <fy1>

func _bg(c: Color) -> bool:
	return c.a < 0.5 or (c.r > 0.93 and c.g > 0.93 and c.b > 0.93)

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var img := src.duplicate() as Image
	var xa := float(a[2]); var xb := float(a[3]); var xb2 := float(a[4])
	var y0 := int(a[5]); var fy0 := float(a[6]); var fy1 := float(a[7])
	var W := src.get_width()
	for y in range(y0, int(fy1)):
		var w := 1.0 if y < fy0 else clampf((fy1 - y) / (fy1 - fy0), 0.0, 1.0)
		w = w * w * (3.0 - 2.0 * w)
		var e := lerpf(xb, xb2, w)
		var k := (xb - xa) / (e - xa)
		for x in range(int(xa), mini(int(xb2) + 1, W)):
			if x > e: continue  # 늘어난 끝 바깥은 원본 그대로(바닥 점액 줄에서 끊김 없음)
			var sx := xa + (x - xa) * k
			if sx >= W - 1: continue
			var i0 := int(floor(sx)); var f := sx - i0
			var c := src.get_pixel(i0, y).lerp(src.get_pixel(i0 + 1, y), f)
			if _bg(c) and not _bg(src.get_pixel(x, y)): continue
			img.set_pixel(x, y, c)
	img.save_png(a[1])
	quit()
