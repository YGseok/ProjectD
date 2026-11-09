extends SceneTree
## tools/artgen/scale_part.gd — 그림의 한 부분(원 마스크 ∩ x 범위·y 범위)만 중심 기준으로 확대해 원본 위에 덮는다(아머 고블린 메이스 머리, 2026-11-09).
## 별 모양처럼 중심에서 뻗은 형태는 확대본이 원본을 다 덮으므로 원래 자리를 지울 필요가 없다.
## 사용: godot --headless --script scale_part.gd -- <입력> <출력> <cx> <cy> <r> <배율> <xmin> <xmax> <ymin> <ymax> [위 가시 꼭짓점 y] [기울기]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var img := src.duplicate() as Image
	var c := Vector2(float(a[2]), float(a[3])); var r := float(a[4]); var k := float(a[5])
	var xmin := float(a[6]); var xmax := float(a[7]); var ymin := float(a[8]); var ymax := float(a[9])
	var W := src.get_width(); var H := src.get_height()
	var R := int(r * k) + 2
	for y in range(maxi(0, int(c.y) - R), mini(H, int(c.y) + R)):
		for x in range(maxi(0, int(c.x) - R), mini(W, int(c.x) + R)):
			var q := c + (Vector2(x, y) - c) / k
			if q.distance_to(c) > r or q.x < xmin or q.x > xmax or q.y > ymax: continue
			if q.y < ymin:
				# ymin 위쪽은 꼭짓점(ax, apex_y)에서 내려오는 삼각형(위 가시)만 허용
				if a.size() <= 11 or q.y < float(a[10]) or absf(q.x - c.x) > (q.y - float(a[10])) * float(a[11]): continue
			var x0 := int(q.x); var y0 := int(q.y); var fx := q.x - x0; var fy := q.y - y0
			var p := src.get_pixel(x0, y0).lerp(src.get_pixel(x0 + 1, y0), fx).lerp(src.get_pixel(x0, y0 + 1).lerp(src.get_pixel(x0 + 1, y0 + 1), fx), fy)
			if p.a < 0.02: continue
			var b := img.get_pixel(x, y)
			var oa := p.a + b.a * (1.0 - p.a)
			img.set_pixel(x, y, Color((p.r * p.a + b.r * b.a * (1 - p.a)) / oa, (p.g * p.a + b.g * b.a * (1 - p.a)) / oa, (p.b * p.a + b.b * b.a * (1 - p.a)) / oa, oa))
	img.save_png(a[1])
	quit()
