extends SceneTree
## tools/artgen/row_stretch.gd — 덩어리 오른쪽 윤곽을 줄마다 가로로 늘여 "툭 떨어지는" 옆선을 완만한 경사로 만든다(원본 픽셀만 사용).
## 각 줄에서 xa~원래 오른쪽 끝(흰 배경 직전)을 xa~목표 끝으로 늘인다. 목표 끝은 (y0,e0)→(y1,e1) 직선,
## 원래 끝보다 왼쪽이면 건드리지 않음. fy0~fy1 구간에서 효과를 0으로 줄여 아래 바닥 점액과 이어지게 한다.
## 점액 군주 b44(2026-11-05): 두 덩어리 이전 b40의 둥근 덩어리를 낮고 길게.
## 사용: godot --headless --script row_stretch.gd -- <입력(흰 배경)> <출력> <xa> <xmax> <y0> <e0> <y1> <e1> <fy0> <fy1>

func _bg(c: Color) -> bool:
	return c.a < 0.5 or (c.r > 0.93 and c.g > 0.93 and c.b > 0.93)

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var img := src.duplicate() as Image
	var xa := int(a[2]); var xmax := int(a[3])
	var y0 := float(a[4]); var e0 := float(a[5]); var y1 := float(a[6]); var e1 := float(a[7])
	var fy0 := float(a[8]); var fy1 := float(a[9])
	var W := src.get_width()
	for y in range(int(y0), int(fy1)):
		var edge := -1
		for x in range(xmax, xa, -1):
			if not _bg(src.get_pixel(x, y)): edge = x; break
		if edge < 0: continue
		var target := e0 + (e1 - e0) * (y - y0) / (y1 - y0)
		var w := 1.0 if y < fy0 else clampf((fy1 - y) / (fy1 - fy0), 0.0, 1.0)
		var ne := edge + (target - edge) * w
		if ne <= edge + 0.5: continue
		var k := float(edge - xa) / float(ne - xa)
		for x in range(xa, mini(int(ne) + 1, W)):
			var sx := xa + (x - xa) * k
			var i0 := int(floor(sx)); var f := sx - i0
			var c := src.get_pixel(i0, y).lerp(src.get_pixel(mini(i0 + 1, W - 1), y), f)
			# 늘어난 끝이 바닥 점액 위에 겹치면 흰 배경 대신 원래 픽셀 유지
			if _bg(c) and not _bg(src.get_pixel(x, y)): continue
			img.set_pixel(x, y, c)
	img.save_png(a[1])
	quit()
