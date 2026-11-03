extends SceneTree
## tools/artgen/skin_tone.gd — 피부(skin_shift.gd와 같은 판정)를 다른 계열의 색으로 바꾼다(형태·명암 구조 유지).
## 색조는 지정값으로, 채도는 원래 채도 비율을 유지한 채 목표 채도로, 명도는 배율 k로. 피부 톤 비교 시안용.
## 사용: godot --headless --script skin_tone.gd -- <입력> <출력> <색조> <채도> <명도 배율>

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var th := float(a[2]); var ts := float(a[3]); var k := float(a[4])
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.h < 0.015 or c.h > 0.075 or c.s < 0.42 or c.v < 0.35: continue
			img.set_pixel(x, y, Color.from_hsv(th, clampf(ts * c.s / 0.62, 0.0, 0.95), c.v * k, c.a))
	img.save_png(a[1])
	quit()
