extends SceneTree
## tools/artgen/curve_shade.gd — 곡선 아래쪽 초록 점액 픽셀만 부드럽게 어둡게(또는 밝게) 해서 굴곡·음영을 살린다.
## 새로 그리지 않고 원본 픽셀의 명도만 바꾸므로 질감·방울·광택이 그대로 남는다(점액 군주 b44, 2026-11-05).
## 곡선은 점 여러 개(catmull-rom), 곡선 아래 feather px에 걸쳐 효과가 0→1, ylim 아래는 건드리지 않음(바닥 점액 보호),
## 주사위·보석(초록 아님)은 색상 범위로 제외.
## 사용: godot --headless --script curve_shade.gd -- <입력> <출력> <배율(0.88=어둡게, 1.1=밝게)> <feather> <ylim> <x y>...

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var k := float(a[2]); var fe := float(a[3]); var ylim := float(a[4])
	var p := []
	var i := 5
	while i + 1 < a.size(): p.append(Vector2(float(a[i]), float(a[i + 1]))); i += 2
	var cy := {}
	for s in p.size() - 1:
		var p0: Vector2 = p[maxi(s - 1, 0)]; var p1: Vector2 = p[s]; var p2: Vector2 = p[s + 1]; var p3: Vector2 = p[mini(s + 2, p.size() - 1)]
		for n in 400:
			var t := n / 400.0
			var v := 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
			cy[int(round(v.x))] = v.y
	var x0 := int(p[0].x); var x1 := int(p[p.size() - 1].x)
	for x in range(x0, x1 + 1):
		if not cy.has(x): continue
		var ex := minf(float(x - x0), float(x1 - x)) / 30.0  # 양 끝도 부드럽게
		ex = clampf(ex, 0.0, 1.0)
		for y in range(int(cy[x]), int(ylim)):
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.h < 0.2 or c.h > 0.48 or c.s < 0.25: continue
			var f := clampf((y - cy[x]) / fe, 0.0, 1.0) * ex
			f *= clampf((ylim - y) / 20.0, 0.0, 1.0)
			var d := Color(c.r * k, c.g * k, c.b * k, c.a) if k < 1.0 else c.lerp(Color(1, 1, 0.85, c.a), k - 1.0)
			img.set_pixel(x, y, c.lerp(d, f))
	img.save_png(a[1])
	quit()
