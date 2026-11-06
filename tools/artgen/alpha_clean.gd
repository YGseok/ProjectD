extends SceneTree
## tools/artgen/alpha_clean.gd — 합성 뒤 남은 투명도 찌꺼기 정리(독거미 rs49, 2026-11-06).
## 1) min_px 보다 작은 떨어진 점(알파 > 0.1 덩어리)을 지움  2) 사각형 안 알파 < lo 픽셀은 지우고, lo~1 사이는 불투명으로(뿌연 테두리 제거)
## 사용: godot --headless --script alpha_clean.gd -- <입력> <출력> <min_px> [x y w h lo [fill hex]]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var W := img.get_width(); var H := img.get_height(); var mn := int(a[2])
	if a.size() > 7:
		# 바깥 배경 = 그림 테두리에서 알파 < 0.5 픽셀로 이어지는 영역. 사각형 안에서 바깥과 안 이어진 반투명·투명 구멍은
		# 몸 안쪽(배 밑 얼룩)이므로 불투명하게(색이 없으면 fill 색). 바깥과 이어진 알파 < lo 는 지움.
		var r := Rect2i(int(a[3]), int(a[4]), int(a[5]), int(a[6])); var lo := float(a[7])
		var fillc := Color(a[8]) if a.size() > 8 else Color("3a1a1f")
		var outside := PackedByteArray(); outside.resize(W * H)
		var st := []
		for x in W:
			st.append(Vector2i(x, 0)); st.append(Vector2i(x, H - 1))
		for y in H:
			st.append(Vector2i(0, y)); st.append(Vector2i(W - 1, y))
		while st.size() > 0:
			var p: Vector2i = st.pop_back()
			if p.x < 0 or p.y < 0 or p.x >= W or p.y >= H: continue
			if outside[p.y * W + p.x] == 1 or img.get_pixel(p.x, p.y).a >= 0.5: continue
			outside[p.y * W + p.x] = 1
			st.append(p + Vector2i(1, 0)); st.append(p + Vector2i(-1, 0)); st.append(p + Vector2i(0, 1)); st.append(p + Vector2i(0, -1))
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := img.get_pixel(x, y)
				if c.a >= 1.0: continue
				if outside[y * W + x] == 1:
					if c.a < lo: img.set_pixel(x, y, Color(0, 0, 0, 0))
				else:
					img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a > 0.3 else Color(fillc.r, fillc.g, fillc.b, 1.0))
	var lab := PackedInt32Array(); lab.resize(W * H); lab.fill(-1)
	var n := 0
	for sy in H:
		for sx in W:
			if lab[sy * W + sx] != -1 or img.get_pixel(sx, sy).a <= 0.1: continue
			var stack := [Vector2i(sx, sy)]; var comp := []; lab[sy * W + sx] = n
			while stack.size() > 0:
				var p: Vector2i = stack.pop_back(); comp.append(p)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + d
					if q.x < 0 or q.y < 0 or q.x >= W or q.y >= H: continue
					if lab[q.y * W + q.x] != -1 or img.get_pixel(q.x, q.y).a <= 0.1: continue
					lab[q.y * W + q.x] = n; stack.append(q)
			if comp.size() < mn:
				for p in comp: img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
			n += 1
	img.save_png(a[1])
	quit()
