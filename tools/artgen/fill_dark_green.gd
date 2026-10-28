extends SceneTree
## tools/artgen/fill_dark_green.gd — 점액 몸의 짙은 초록 영역이 "속이 빈 내부"처럼 읽히는 문제를 로컬로 고친다.
## 초록 계열이면서 어두운 픽셀(명도 < V0)을 같은 색조의 중간 명도로 끌어올려, 몸이 꽉 찬 젤리로 보이게 한다.
## 상대적 명암은 유지(원래 명도를 [0, V0] → [V1, V2]로 사상). 선(아주 어두운 무채색)은 건드리지 않는다.
## 사용: godot --headless --script fill_dark_green.gd -- <입력> <출력> [V0=0.5] [V1=0.48] [V2=0.66]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var V0 := float(a[2]) if a.size() > 2 else 0.5
	var V1 := float(a[3]) if a.size() > 3 else 0.48
	var V2 := float(a[4]) if a.size() > 4 else 0.66
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5: continue
			if c.h < 0.22 or c.h > 0.48 or c.s < 0.25: continue   # 초록 계열만
			if c.v >= V0: continue
			var v := lerpf(V1, V2, c.v / V0)
			img.set_pixel(x, y, Color.from_hsv(lerpf(c.h, 0.33, 0.7), clampf(c.s, 0.45, 0.7), v, c.a)); n += 1   # 색조는 몸의 밝은 초록 쪽으로
	print("[fill_dark_green] ", n, "px")
	img.save_png(a[1])
	quit()
