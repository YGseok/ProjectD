extends SceneTree
## tools/artgen/leg_move.gd — 다리 하나를 다각형으로 떼어 내 옮긴다(독거미 rs49, 2026-11-06). GPT가 다시 그리지 않으므로 얼굴·톤이 안 바뀜.
## 1) 다각형 안 픽셀을 떼어 낸 층으로 저장  2) 원래 자리는 상하좌우로 가장 가까운 다각형 밖 픽셀로 채움(허리띠·배·투명 배경이 이어짐)
## 3) 떼어 낸 층을 (dx,dy)만큼 옮겨 '뒤에' 깐다(현재 그림이 위). → 뿌리가 다른 다리의 고리 뒤에서 나오는 것처럼 보임
## 4) (선택) 배 밑면의 반투명 회색 얼룩을 불투명 어두운 배 색으로 채움: belly 사각형 x y w h
## 사용: godot --headless --script leg_move.gd -- <입력> <출력> <dx> <dy> "<다리 다각형>" [배 x y w h] ["<투명으로 둘 다각형>"] [채움 단색 hex] ["<옮길 층 다각형>"]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var dx := int(a[2]); var dy := int(a[3])
	var pts := PackedVector2Array()
	for p in a[4].split(" ", false):
		var xy := p.split(",")
		pts.append(Vector2(float(xy[0]), float(xy[1])))
	var W := img.get_width(); var H := img.get_height()
	var src := img.duplicate() as Image
	var inside := PackedByteArray(); inside.resize(W * H)
	# a[11] = 옮길 층만의 다각형(선택). 없으면 지울 다각형과 같음. 고리 테두리 같은 조각이 딸려 오지 않게 따로 줄 수 있음
	var lp := pts
	if a.size() > 11:
		lp = PackedVector2Array()
		for p in a[11].split(" ", false):
			var xy := p.split(",")
			lp.append(Vector2(float(xy[0]), float(xy[1])))
	var layer := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), pts): inside[y * W + x] = 1
			if Geometry2D.is_point_in_polygon(Vector2(x, y), lp):
				var c := src.get_pixel(x, y)
				# 반투명·회색 테두리 찌꺼기는 층에서 뺌
				if c.a > 0.6 and not (c.s < 0.2 and c.v > 0.5): layer.set_pixel(x, y, c)
	# 지울 영역은 외곽선까지 포함되도록 DIL px 넓힌다(떼어 낸 층에는 원래 다각형만)
	const DIL := 5
	var er := inside.duplicate()
	for y in H:
		for x in W:
			if inside[y * W + x] == 0: continue
			for oy in range(-DIL, DIL + 1):
				for ox in range(-DIL, DIL + 1):
					var xx := x + ox; var yy := y + oy
					if xx >= 0 and yy >= 0 and xx < W and yy < H: er[yy * W + xx] = 1
	# 원래 자리 채우기: 8방향 가장 가까운 밖 픽셀을 거리 역수로 섞음(줄무늬 방지). 알파는 0/1로 정리
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	for y in H:
		for x in W:
			if er[y * W + x] == 0: continue
			var acc := Color(0, 0, 0, 0); var wsum := 0.0; var asum := 0.0
			for d in dirs:
				var k := 1
				while true:
					var xx: int = x + d.x * k; var yy: int = y + d.y * k
					if xx < 0 or yy < 0 or xx >= W or yy >= H: k = -1; break
					if er[yy * W + xx] == 0: break
					k += 1
				if k < 0: continue
				var c := src.get_pixel(x + d.x * k, y + d.y * k)
				var w := 1.0 / float(k * k)
				asum += c.a * w; wsum += w
				if c.a > 0.5: acc += Color(c.r, c.g, c.b, 1.0) * w
			if wsum == 0.0: img.set_pixel(x, y, Color(0, 0, 0, 0)); continue
			var al := asum / wsum
			if a.size() > 10: img.set_pixel(x, y, Color(a[10]))  # 단색 모드: 구멍 없이 채우고, 비울 곳은 아래 다각형으로
			elif al < 0.5 or acc.a == 0.0: img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif false: img.set_pixel(x, y, Color(a[10]))  # 셀 화풍: 번진 색 대신 단색
			else: img.set_pixel(x, y, Color(acc.r / acc.a, acc.g / acc.a, acc.b / acc.a, 1.0))
	# (선택) 지운 자리 중 몸 밖이어야 할 부분은 투명으로: a[9] = 다각형 "x,y x,y ..." (지운 영역 안만)
	if a.size() > 9:
		var cp := PackedVector2Array()
		for p in a[9].split(" ", false):
			var xy := p.split(",")
			cp.append(Vector2(float(xy[0]), float(xy[1])))
		for y in H:
			for x in W:
				if er[y * W + x] == 1 and Geometry2D.is_point_in_polygon(Vector2(x, y), cp): img.set_pixel(x, y, Color(0, 0, 0, 0))
	# 배 밑면 얼룩 → 불투명: 색은 맞는데 반투명(알파 0.6~0.75)이라 밝은 배경이 비쳐 회색 얼룩처럼 보였음.
	# 사각형 안에서 반경 3px 안에 완전 투명 픽셀이 없는(=배경과 맞닿지 않은) 반투명 픽셀은 알파 1로.
	if a.size() > 8:
		var br := Rect2i(int(a[5]), int(a[6]), int(a[7]), int(a[8]))
		var snap := img.duplicate() as Image
		for y in range(br.position.y, br.end.y):
			for x in range(br.position.x, br.end.x):
				var c := snap.get_pixel(x, y)
				if c.a <= 0.03 or c.a >= 0.99: continue
				var edge := false
				for oy in range(-3, 4):
					for ox in range(-3, 4):
						if snap.get_pixel(clampi(x + ox, 0, W - 1), clampi(y + oy, 0, H - 1)).a < 0.02: edge = true
				if not edge: img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	# 옮긴 층을 뒤에 깔기
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var lx := x - dx; var ly := y - dy
			var under := Color(0, 0, 0, 0)
			if lx >= 0 and ly >= 0 and lx < W and ly < H: under = layer.get_pixel(lx, ly)
			var top := img.get_pixel(x, y)
			# top over under
			var oa := top.a + under.a * (1.0 - top.a)
			if oa <= 0.0: out.set_pixel(x, y, Color(0, 0, 0, 0)); continue
			var r := (top.r * top.a + under.r * under.a * (1.0 - top.a)) / oa
			var g := (top.g * top.a + under.g * under.a * (1.0 - top.a)) / oa
			var b := (top.b * top.a + under.b * under.a * (1.0 - top.a)) / oa
			out.set_pixel(x, y, Color(r, g, b, oa))
	out.save_png(a[1])
	quit()
