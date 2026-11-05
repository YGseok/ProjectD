extends SceneTree
## tools/artgen/line_redraw.gd — 피부 위 구불구불한 음영 선을 지우고 매끈한 곡선으로 다시 긋는다(거미 rs33 왼쪽 복근 선, 2026-11-05).
## 지우기: rect 안에서 줄마다 피부보다 어두운 픽셀을 그 줄 양끝 피부색 사이 보간으로 채움.
## 긋기: catmull-rom 점들 따라 폭 w, 원래 선 색에 가까운 어두운 피부색(배율 k)을 가운데 진하고 가장자리 옅게.
## 사용: godot --headless --script line_redraw.gd -- <입력> <출력> <x> <y> <w> <h> <폭> <배율> <x y>...

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var r := Rect2i(int(a[2]), int(a[3]), int(a[4]), int(a[5]))
	var lw := float(a[6]); var k := float(a[7])
	for y in range(r.position.y, r.end.y):
		var l := img.get_pixel(r.position.x, y); var rr := img.get_pixel(r.end.x - 1, y)
		for x in range(r.position.x, r.end.x):
			var t := float(x - r.position.x) / float(r.size.x - 1)
			var base := l.lerp(rr, t)
			var c := img.get_pixel(x, y)
			if c.v < base.v - 0.015: img.set_pixel(x, y, base)
	# 지운 자리 세로로 살짝 평균(줄무늬 방지)
	var ref := img.duplicate() as Image
	for y in range(r.position.y + 2, r.end.y - 2):
		for x in range(r.position.x + 1, r.end.x - 1):
			var acc := Color(0, 0, 0, 0)
			for dy in range(-2, 3): acc += ref.get_pixel(x, y + dy)
			img.set_pixel(x, y, acc / 5.0)
	var p := []
	var i := 8
	while i + 1 < a.size(): p.append(Vector2(float(a[i]), float(a[i + 1]))); i += 2
	var dist := {}
	for s in p.size() - 1:
		var p0: Vector2 = p[maxi(s - 1, 0)]; var p1: Vector2 = p[s]; var p2: Vector2 = p[s + 1]; var p3: Vector2 = p[mini(s + 2, p.size() - 1)]
		for n in 300:
			var t := n / 300.0
			var v := 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
			var u := (s + t) / float(p.size() - 1)
			var taper := sin(PI * u)  # 양끝 가늘게
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var q := Vector2i(int(v.x) + dx, int(v.y) + dy)
					var d := (Vector2(q) - v).length()
					var f := clampf(1.0 - d / (lw * 0.5 * maxf(taper, 0.25) + 0.5), 0.0, 1.0) * clampf(taper * 1.5, 0.0, 1.0)
					if f > dist.get(q, 0.0): dist[q] = f
	for q in dist:
		var c := img.get_pixel(q.x, q.y)
		var dk := Color(c.r * k, c.g * k * 0.95, c.b * k * 0.95, c.a)
		img.set_pixel(q.x, q.y, c.lerp(dk, dist[q]))
	img.save_png(a[1])
	quit()
