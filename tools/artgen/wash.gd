extends SceneTree
## tools/artgen/wash.gd — 그림 전체 톤을 "옅게" 맞춘다(색은 그대로, 채도↓·명도↑, 진한 외곽선도 함께 옅어짐).
## GPT 재생성본이 원본보다 색감·외곽선이 짙어졌을 때 원본(구울 rs17)의 바랜 느낌으로 되돌리는 용도. 배경(검정/투명)은 그대로.
## 사용: godot --headless --script wash.gd -- <입력> <출력> [채도 배율=0.8] [밝기 혼합=0.18] [바탕 명도 하한=0.06]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var ks := float(a[2]) if a.size() > 2 else 0.8
	var mix := float(a[3]) if a.size() > 3 else 0.18
	var bg := float(a[4]) if a.size() > 4 else 0.06
	var paper := Color(0.95, 0.92, 0.86)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.v < bg: continue
			var d := Color.from_hsv(c.h, c.s * ks, c.v, c.a).lerp(paper, mix)
			d.a = c.a
			img.set_pixel(x, y, d)
	img.save_png(a[1])
	quit()
