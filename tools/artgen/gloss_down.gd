extends SceneTree
## tools/artgen/gloss_down.gd — 너무 쨍하고 광택이 강한 그림을 게임 화풍 쪽으로 누른다(점액 군주 b50, 2026-11-05).
## 색조 hmin~hmax 픽셀: 채도 ×ks, 명도 ×kv. 광택(채도 낮고 밝은 픽셀)은 주변 기본색 쪽으로 kg만큼 섞어 약하게.
## 광택 판정: s < gs 이고 v > gv, 그리고 초록 계열이거나 거의 흰색. 주변 기본색 = 반경 r 안의 광택 아닌 초록 픽셀 평균.
## 사용: godot --headless --script gloss_down.gd -- <입력(투명 배경)> <출력> <hmin> <hmax> <ks> <kv> <kg> [gs=0.45] [gv=0.85] [r=6]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var hmin := float(a[2]); var hmax := float(a[3]); var ks := float(a[4]); var kv := float(a[5]); var kg := float(a[6])
	var gs := float(a[7]) if a.size() > 7 else 0.45
	var gv := float(a[8]) if a.size() > 8 else 0.85
	var R := int(a[9]) if a.size() > 9 else 6
	var W := img.get_width(); var H := img.get_height()
	var src := img.duplicate() as Image
	var gl := PackedByteArray(); gl.resize(W * H)
	for y in H:
		for x in W:
			var c := src.get_pixel(x, y)
			if c.a < 0.5: continue
			var greenish := c.h > hmin and c.h < hmax
			if c.s < gs and c.v > gv and (greenish or c.s < 0.12):
				# 금장식(왕관·보석) 옆의 흰 픽셀은 광택이 아니라 장식 일부 → 제외
				var near_gold := false
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						var d := src.get_pixel(clampi(x + dx, 0, W - 1), clampi(y + dy, 0, H - 1))
						if d.a > 0.5 and d.h > 0.06 and d.h < 0.17 and d.s > 0.35: near_gold = true
				if not near_gold: gl[y * W + x] = 1
	for y in H:
		for x in W:
			var c := src.get_pixel(x, y)
			if c.a < 0.05: continue
			if gl[y * W + x] == 1:
				# 광택 픽셀: 주변 기본 초록과 섞기(듬성듬성 샘플)
				var acc := Color(0, 0, 0, 0); var n := 0
				for dy in range(-R, R + 1, 2):
					for dx in range(-R, R + 1, 2):
						var xx := clampi(x + dx, 0, W - 1); var yy := clampi(y + dy, 0, H - 1)
						if gl[yy * W + xx] == 1: continue
						var d := src.get_pixel(xx, yy)
						if d.a > 0.5 and d.h > hmin and d.h < hmax: acc += d; n += 1
				if n == 0:
					# 큰 광택 덩어리 안쪽: 반경을 넓혀 한 번 더
					for dy in range(-R * 3, R * 3 + 1, 3):
						for dx in range(-R * 3, R * 3 + 1, 3):
							var xx := clampi(x + dx, 0, W - 1); var yy := clampi(y + dy, 0, H - 1)
							if gl[yy * W + xx] == 1: continue
							var d := src.get_pixel(xx, yy)
							if d.a > 0.5 and d.h > hmin and d.h < hmax: acc += d; n += 1
				if n > 0:
					var base := acc / n
					var nc := c.lerp(base.lightened(0.25), kg)
					c = Color(nc.r, nc.g, nc.b, c.a)
			if c.h > hmin and c.h < hmax and c.s > 0.2:
				c = Color.from_hsv(c.h, c.s * ks, c.v * kv, c.a)
			img.set_pixel(x, y, c)
	img.save_png(a[1])
	quit()
