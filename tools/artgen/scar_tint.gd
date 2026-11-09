extends SceneTree
## tools/artgen/scar_tint.gd — 상처(어두운 붉은 갈라짐)만 다른 색조로 바꾼다(공허의 눈: 안쪽에 공허가 열린 상처라 푸른색, 2026-11-09).
## 대상: 타원 안, 붉은 색조(h<0.07 또는 h>0.9), 채도 > smin, 명도 < vmax. 피부(채도 낮고 밝음)와 경계 픽셀은 채도 비례로 부드럽게 섞음.
## 사용: godot --headless --script scar_tint.gd -- <입력> <출력> <cx> <cy> <rx> <ry> <새 색조 0~1> [smin=0.3] [vmax=0.75] [채도 배율=1.1] [명도 배율=1.0]
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var c := Vector2(float(a[2]), float(a[3])); var r := Vector2(float(a[4]), float(a[5])); var nh := float(a[6])
	var smin := float(a[7]) if a.size() > 7 else 0.3
	var vmax := float(a[8]) if a.size() > 8 else 0.75
	var ks := float(a[9]) if a.size() > 9 else 1.1
	var kv := float(a[10]) if a.size() > 10 else 1.0
	for y in range(int(c.y - r.y), int(c.y + r.y)):
		for x in range(int(c.x - r.x), int(c.x + r.x)):
			if ((Vector2(x, y) - c) / r).length() > 1.0: continue
			var p := img.get_pixel(x, y)
			if not (p.h < 0.07 or p.h > 0.9) or p.v >= vmax: continue
			var w := smoothstep(smin - 0.08, smin + 0.08, p.s) * (1.0 - smoothstep(vmax - 0.1, vmax, p.v))
			if w <= 0.0: continue
			var q := Color.from_hsv(nh, clampf(p.s * ks, 0, 1), clampf(p.v * kv, 0, 1), p.a)
			img.set_pixel(x, y, p.lerp(q, w))
	img.save_png(a[1]); quit()
