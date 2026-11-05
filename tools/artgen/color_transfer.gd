extends SceneTree
## tools/artgen/color_transfer.gd — 일부만 새 재질로 바뀐 그림에서, 바뀐 부분(A→B)의 색 변화(채널별 평균·표준편차)를 배워
## 나머지 같은 색 계열 픽셀에도 똑같이 적용한다. 점액 군주 b47: 머리만 GPT로 젤리 재질이 되어 몸과 톤이 따로 놀 때(2026-11-05).
## 대상: 색조 범위(hmin~hmax)·채도 0.25 이상 픽셀, 보호 사각형(이미 바뀐 머리) 밖. 보호 사각형 경계 feather px는 섞음.
## 사용: godot --headless --script color_transfer.gd -- <이전 조각 A> <새 조각 B> <대상 그림> <출력> <hmin> <hmax> <강도 0~1> <보호 x y w h> <feather>

func _stats(img: Image, hmin: float, hmax: float) -> Array:
	var s := [0.0, 0.0, 0.0]; var q := [0.0, 0.0, 0.0]; var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.h < hmin or c.h > hmax or c.s < 0.25: continue
			var v := [c.r, c.g, c.b]
			for k in 3: s[k] += v[k]; q[k] += v[k] * v[k]
			n += 1
	var m := []; var sd := []
	for k in 3:
		m.append(s[k] / n); sd.append(sqrt(maxf(q[k] / n - (s[k] / n) * (s[k] / n), 1e-6)))
	return [m, sd]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var A := Image.load_from_file(a[0]); A.convert(Image.FORMAT_RGBA8)
	var B := Image.load_from_file(a[1]); B.convert(Image.FORMAT_RGBA8)
	var img := Image.load_from_file(a[2]); img.convert(Image.FORMAT_RGBA8)
	var hmin := float(a[4]); var hmax := float(a[5]); var st := float(a[6])
	var pr := Rect2i(int(a[7]), int(a[8]), int(a[9]), int(a[10])); var fe := float(a[11])
	var sa := _stats(A, hmin, hmax); var sb := _stats(B, hmin, hmax)
	print("A ", sa, "\nB ", sb)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.05 or c.h < hmin or c.h > hmax or c.s < 0.25: continue
			var dx := minf(x - pr.position.x, pr.end.x - 1 - x); var dy := minf(y - pr.position.y, pr.end.y - 1 - y)
			var inside := clampf(minf(dx, dy) / fe, 0.0, 1.0) if (dx >= 0 and dy >= 0) else 0.0
			var w := st * (1.0 - inside)
			if w <= 0.0: continue
			var v := [c.r, c.g, c.b]; var o := []
			for k in 3:
				o.append(clampf((v[k] - sa[0][k]) / sa[1][k] * sb[1][k] + sb[0][k], 0.0, 1.0))
			img.set_pixel(x, y, c.lerp(Color(o[0], o[1], o[2], c.a), w))
	img.save_png(a[3])
	quit()
