extends SceneTree
## tools/artgen/beast_tone.gd — 광란의 마수 로컬 색 보정(형태 변경 없음): 피부만 짙게, 주사위만 퍼스널 컬러(와인색)로.
## 피부는 색 범위만으로는 발톱·해골·털끝이 같이 잡혀서, 피부 위 시드에서 비슷한 색으로 이어진 영역만 칠한다.
## 사용: godot --headless --script beast_tone.gd -- <입력> <출력> [피부 명도 배율=0.76]

const DICE := Rect2i(252, 442, 52, 52)    # 주사위 영역(원본 1024×1536 기준)
const SEEDS := [Vector2i(370, 500), Vector2i(370, 540), Vector2i(510, 620), Vector2i(440, 750),
	Vector2i(770, 630), Vector2i(760, 840), Vector2i(225, 372)]
const TOL := 0.13

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var k := float(a[2]) if a.size() > 2 else 0.76
	var w := img.get_width(); var h := img.get_height()
	var seen := PackedByteArray(); seen.resize(w * h)
	var src := img.duplicate() as Image
	for sd in SEEDS:
		var c0: Color = src.get_pixelv(sd)
		var ref := Vector3(c0.r, c0.g, c0.b)
		var stack := PackedInt32Array([sd.y * w + sd.x])
		while stack.size() > 0:
			var p := stack[stack.size() - 1]; stack.remove_at(stack.size() - 1)
			if seen[p] == 1: continue
			var x := p % w; var y := p / w
			var c := src.get_pixel(x, y)
			if c.a < 0.5 or Vector3(c.r, c.g, c.b).distance_to(ref) > TOL: continue
			seen[p] = 1
			img.set_pixel(x, y, Color.from_hsv(c.h - 0.012, minf(c.s * 1.3, 0.8), c.v * k, c.a))
			if x > 0: stack.append(p - 1)
			if x < w - 1: stack.append(p + 1)
			if y > 0: stack.append(p - w)
			if y < h - 1: stack.append(p + w)
	for y in range(DICE.position.y, DICE.end.y):
		for x in range(DICE.position.x, DICE.end.x):
			var c := src.get_pixel(x, y)
			if c.s > 0.62 and c.v > 0.62 and (c.h < 0.03 or c.h > 0.96):
				img.set_pixel(x, y, Color.from_hsv(0.955, 0.72, 0.42 + c.v * 0.12, c.a))
	img.save_png(a[1])
	quit()
