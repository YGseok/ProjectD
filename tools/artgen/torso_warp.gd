extends SceneTree
## tools/artgen/torso_warp.gd — 상반신 허리(맨 배)를 짧고 두툼하게 하는 로컬 변형(독거미 허리 피드백, GPT 재생성은 차이가 미미).
##  (1) 세로: yt~yj(배) 구간을 d px 짧게 누르고, 그만큼 yj~yb(아래 몸) 구간을 늘려 메운다. yt·yb는 고정.
##      몸통 띠(cx ± hw)에서 최대, 바깥 hw*0.5 동안 0으로 줄어 머리카락·다리 쪽은 거의 그대로.
##  (2) 가로: 허리 높이(yt~yj)에서 cx 기준으로 최대 widen 배 넓힌다(가운데 높이에서 최대, 위아래 0).
## 사용: godot --headless --script torso_warp.gd -- <입력> <출력> <cx> <hw> <yt> <yj> <yb> <d> <widen>

func _w(x: float, cx: float, hw: float) -> float:
	var t := absf(x - cx)
	if t <= hw: return 1.0
	if t >= hw * 1.5: return 0.0
	return 0.5 + 0.5 * cos(PI * (t - hw) / (hw * 0.5))


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var cx := float(a[2]); var hw := float(a[3]); var yt := float(a[4]); var yj := float(a[5]); var yb := float(a[6])
	var dmax := float(a[7]); var widen := float(a[8])
	var W := src.get_width(); var H := src.get_height()
	var mid := src.duplicate() as Image
	for x in W:
		var d := dmax * _w(x, cx, hw)
		if d < 0.01: continue
		var m := yj - d
		for y in range(int(yt), int(yb)):
			var oy: float
			if y < m: oy = yt + (y - yt) * (yj - yt) / (m - yt)
			else: oy = yj + (y - m) * (yb - yj) / (yb - m)
			var y0 := clampi(int(floor(oy)), 0, H - 2); var t := oy - y0
			mid.set_pixel(x, y, src.get_pixel(x, y0).lerp(src.get_pixel(x, y0 + 1), t))
	var out := mid.duplicate() as Image
	var r := hw * 1.5
	for y in range(int(yt), int(yj)):
		var wy := sin(PI * (y - yt) / (yj - yt))
		for x in range(int(cx - r), int(cx + r)):
			var dx := float(x) - cx
			var g := 0.5 + 0.5 * cos(PI * absf(dx) / r)
			var ox := x - (widen - 1.0) * wy * dx * g
			var x0 := clampi(int(floor(ox)), 0, W - 2); var t := ox - x0
			out.set_pixel(x, y, mid.get_pixel(x0, y).lerp(mid.get_pixel(x0 + 1, y), t))
	out.save_png(a[1])
	quit()
