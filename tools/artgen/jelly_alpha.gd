extends SceneTree
## tools/artgen/jelly_alpha.gd — 점액 몸을 젤리처럼 반투명하게(게임 배경이 은은하게 비침). 점액 군주 2026-11-05.
## 초록 점액 픽셀만 알파를 낮추고, 가장자리(배경에서 edge px 이내)·밝은 광택·주사위·보석·왕관(초록 아님)·보호 사각형(얼굴)은 불투명 유지.
## 안쪽일수록 투명(최소 amin), 어두운 톤일수록 조금 더 투명.
## 사용: godot --headless --script jelly_alpha.gd -- <입력(투명 배경)> <출력> <amin=0.72> <edge=14> [보호 x y w h]...

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var amin := float(a[2]); var edge := int(a[3])
	var keep := []
	var i := 4
	while i + 3 < a.size():
		keep.append(Rect2i(int(a[i]), int(a[i + 1]), int(a[i + 2]), int(a[i + 3]))); i += 4
	var W := img.get_width(); var H := img.get_height()
	# 배경까지 거리(체스판 거리, edge까지만)
	var dist := PackedInt32Array(); dist.resize(W * H); dist.fill(edge)
	for y in H:
		for x in W:
			if img.get_pixel(x, y).a < 0.5: dist[y * W + x] = 0
	for it in edge:
		var nd := dist.duplicate()
		for y in range(1, H - 1):
			for x in range(1, W - 1):
				var p := y * W + x
				var m := mini(mini(dist[p - 1], dist[p + 1]), mini(dist[p - W], dist[p + W])) + 1
				if m < nd[p]: nd[p] = m
		dist = nd
	var out := img.duplicate() as Image
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			if c.a < 0.5: continue
			if c.h < 0.17 or c.h > 0.5 or c.s < 0.3: continue  # 초록 아님(금·주사위 눈·혀 등)
			if c.s > 0.85 and c.v < 0.6: continue  # 진한 초록 주사위 몸
			if c.v > 0.9 and c.s < 0.5: continue  # 광택
			# 보호 사각형(얼굴)은 가장자리 24px에 걸쳐 부드럽게 불투명으로(네모 경계가 보이지 않게)
			var pk := 0.0
			for r in keep:
				var dx := minf(x - r.position.x, r.end.x - 1 - x); var dy := minf(y - r.position.y, r.end.y - 1 - y)
				var d := minf(dx, dy)
				if d >= 0.0: pk = maxf(pk, clampf(d / 24.0, 0.0, 1.0))
			var e := float(dist[y * W + x]) / edge
			var al := lerpf(1.0, amin, e)
			al -= (0.8 - clampf(c.v, 0.5, 0.8)) * 0.1 * e  # 어두운 속은 조금 더 비침
			al = lerpf(al, 1.0, pk)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, clampf(al, 0.0, 1.0) * c.a))
	out.save_png(a[1])
	quit()
