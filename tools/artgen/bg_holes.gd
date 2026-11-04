extends SceneTree
## tools/artgen/bg_holes.gd — 테두리와 이어지지 않은 "갇힌" 흰 배경(머리카락 사이 틈 등)까지 투명하게 지운다.
## bg_strict.gd는 테두리에서 이어진 흰색만 지워서, 곱슬머리 고리 안쪽의 흰 배경이 남는다.
## 거의 순백(모든 채널 > T) 덩어리 중 min_px 이상인 것만 지우고, 보호 사각형(주사위 눈·하이라이트 등) 안은 건드리지 않는다.
## 사용: godot --headless --script bg_holes.gd -- <입력> <출력> [T=0.94] [min_px=40] [보호 x y w h]...

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var t := float(a[2]) if a.size() > 2 else 0.94
	var mn := int(a[3]) if a.size() > 3 else 40
	var keep := []
	var i := 4
	while i + 3 < a.size():
		keep.append(Rect2i(int(a[i]), int(a[i + 1]), int(a[i + 2]), int(a[i + 3]))); i += 4
	var W := img.get_width(); var H := img.get_height()
	var white := PackedByteArray(); white.resize(W * H)
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			white[y * W + x] = 1 if (c.a > 0.5 and c.r > t and c.g > t and c.b > t) else 0
	var seen := PackedByteArray(); seen.resize(W * H)
	var n := 0
	for s in W * H:
		if seen[s] == 1 or white[s] == 0: continue
		var comp := PackedInt32Array(); var st := PackedInt32Array([s]); seen[s] = 1
		var protected := false
		while st.size() > 0:
			var p := st[st.size() - 1]; st.remove_at(st.size() - 1); comp.append(p)
			var x := p % W; var y := p / W
			for r in keep:
				if r.has_point(Vector2i(x, y)): protected = true
			for q in [p - 1 if x > 0 else -1, p + 1 if x < W - 1 else -1, p - W if y > 0 else -1, p + W if y < H - 1 else -1]:
				if q >= 0 and seen[q] == 0 and white[q] == 1:
					seen[q] = 1; st.append(q)
		if protected or comp.size() < mn: continue
		for p in comp: img.set_pixel(p % W, p / W, Color(0, 0, 0, 0))
		n += comp.size()
	print("[bg_holes] ", n, "px")
	img.save_png(a[1])
	quit()
