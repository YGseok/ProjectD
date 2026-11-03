extends SceneTree
## tools/artgen/pinch_down.gd — 윤곽선 일부를 아래로 눌러 잘록하게 만드는 로컬 변형(liquify 비슷하게).
## x0~x1 구간에서 yt~yb 사이 내용을 아래로 최대 d px 밀어 넣는다(가운데가 가장 깊고 양끝은 0, yb는 고정).
## 비게 된 위쪽은 배경색(bg hex, 기본 흰색)으로 채운다. GPT가 체형 수정 요청을 막을 때 사용(점액 군주 허리).
## 사용: godot --headless --script pinch_down.gd -- <입력> <출력> <x0> <x1> <yt> <yb> <d> [bg hex]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var img := src.duplicate() as Image
	var x0 := int(a[2]); var x1 := int(a[3]); var yt := float(a[4]); var yb := float(a[5]); var dmax := float(a[6])
	var bg := Color(a[7]) if a.size() > 7 else Color.WHITE
	var h := yb - yt
	for x in range(x0, x1):
		var d := dmax * pow(sin(PI * float(x - x0) / float(x1 - x0)), 1.5)
		for y in range(int(yt), int(yb)):
			# new = old + d * (yb - old) / h  →  old = (new - d*yb/h) / (1 - d/h)
			var oy := (float(y) - d * yb / h) / (1.0 - d / h)
			if oy < yt: img.set_pixel(x, y, src.get_pixel(x, int(yt)) if src.get_pixel(x, int(yt)).a < 0.5 else bg); continue
			var y0 := int(floor(oy)); var t := oy - y0
			img.set_pixel(x, y, src.get_pixel(x, y0).lerp(src.get_pixel(x, mini(y0 + 1, src.get_height() - 1)), t))
	img.save_png(a[1])
	quit()
