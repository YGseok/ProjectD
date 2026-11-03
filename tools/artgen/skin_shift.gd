extends SceneTree
## tools/artgen/skin_shift.gd — 형태 변경 없이 피부(살구~갈색, 채도 높은 픽셀)만 명도 배율 k로 낮춘다.
## 크림색 털·발톱(채도 낮음), 붉은 털·입·주사위(색조 0.9~1.0), 금장식(색조 > 0.075)은 범위 밖이라 그대로.
## 새 시안의 피부가 기준본보다 밝을 때 기준본 톤으로 맞추는 용도(광란의 마수 pv3 → b34 톤).
## 사용: godot --headless --script skin_shift.gd -- <입력> <출력> <k> [채도 배율=1.05]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var k := float(a[2]); var ks := float(a[3]) if a.size() > 3 else 1.05
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.h < 0.015 or c.h > 0.075 or c.s < 0.42 or c.v < 0.35: continue
			img.set_pixel(x, y, Color.from_hsv(c.h, minf(c.s * ks, 0.85), c.v * k, c.a)); n += 1
	print("[skin_shift] ", n, "px")
	img.save_png(a[1])
	quit()
