extends SceneTree
## tools/artgen/hue_swap.gd — 사각형 안의 특정 색조 픽셀(예: 분홍 혀)을 기준 픽셀 색조·채도로 바꾸고 명도 관계는 유지(점액 군주 혀를 몸 색으로, 2026-11-05).
## 대상: 색조가 hlo 이상 또는 hhi 이하(빨강~분홍 걸침), 채도 0.2 이상. 명도는 대상 평균 대비 비율로 기준 명도에 맞춤.
## 사용: godot --headless --script hue_swap.gd -- <입력> <출력> <x> <y> <w> <h> <hlo> <hhi> <기준 x> <기준 y>
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var r := Rect2i(int(a[2]), int(a[3]), int(a[4]), int(a[5])); var hlo := float(a[6]); var hhi := float(a[7])
	var ref := img.get_pixel(int(a[8]), int(a[9]))
	var sel := []; var vs := 0.0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := img.get_pixel(x, y)
			if c.a > 0.3 and c.s > 0.08 and (c.h >= hlo or c.h <= hhi): sel.append(Vector2i(x, y)); vs += c.v
	if sel.is_empty(): quit(); return
	var mv := vs / sel.size()
	for p in sel:
		var c := img.get_pixel(p.x, p.y)
		var v := clampf(ref.v * c.v / mv, 0.0, 1.0)
		img.set_pixel(p.x, p.y, Color.from_hsv(ref.h, ref.s * 0.9, v, c.a))
	print(sel.size())
	img.save_png(a[1]); quit()
