extends SceneTree
## tools/artgen/draw_die.gd — 그림 속 주사위를 정확한 눈금의 주사위로 덮어 그린다(GPT가 눈금을 틀리게 그릴 때).
## 등각 정육면체 3면(윗면 1, 왼면 2, 오른면 3)을 평면 셀 셰이딩으로 그리고 흰 눈을 찍는다.
## 사용: godot --headless --script draw_die.gd -- <입력> <출력> <중심x> <중심y> <한 변 px> <색 hex> [회전도] [눈 색 hex(기본 흰색)]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var c := Vector2(float(a[2]), float(a[3])); var s := float(a[4])
	var base := Color(a[5]); var rot := deg_to_rad(float(a[6]) if a.size() > 6 else 0.0)
	var pip := Color(a[7]) if a.size() > 7 else Color(0.97, 0.94, 0.9)
	var U := Vector2(0, -s).rotated(rot); var R := Vector2(s * 0.87, -s * 0.5).rotated(rot); var L := Vector2(-s * 0.87, -s * 0.5).rotated(rot)
	var B := c - U   # 앞 아래 꼭짓점(c는 앞 위 꼭짓점)
	var faces := [[c, L, R, base.lightened(0.18), 1], [B, L, U, base, 2], [B, R, U, base.darkened(0.25), 3]]
	var pips := {1: [Vector2(0.5, 0.5)], 2: [Vector2(0.27, 0.27), Vector2(0.73, 0.73)], 3: [Vector2(0.25, 0.25), Vector2(0.5, 0.5), Vector2(0.75, 0.75)]}
	var bb := Rect2i(int(c.x - s * 1.6), int(c.y - s * 1.6), int(s * 3.2), int(s * 3.2)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for y in range(bb.position.y, bb.end.y):
		for x in range(bb.position.x, bb.end.x):
			var p := Vector2(x + 0.5, y + 0.5)
			for f in faces:
				var u: Vector2 = f[1]; var v: Vector2 = f[2]
				var m := Transform2D(u, v, f[0]).affine_inverse()
				var q := m * p
				if q.x < 0.0 or q.x > 1.0 or q.y < 0.0 or q.y > 1.0: continue
				var col: Color = f[3]
				var edge := minf(minf(q.x, 1.0 - q.x), minf(q.y, 1.0 - q.y))
				if edge < 0.035: col = base.darkened(0.6)
				for pp in pips[f[4]]:
					if (q - pp).length() < 0.11: col = pip
				img.set_pixel(x, y, col)
				break
	img.save_png(a[1])
	quit()
