extends SceneTree
## tools/artgen/beast_tone.gd — 광란의 마수 로컬 색 보정(형태 변경 없음): 피부만 짙게, 주사위만 퍼스널 컬러(와인색)로.
## 피부 = 색 범위(발톱·털끝보다 채도가 높은 살구색) 안에서 큰 덩어리만. 작은 조각은 버리고, 덩어리 안의 작은 틈은 메운다.
## 사용: godot --headless --script beast_tone.gd -- <입력> <출력> [피부 명도 배율=0.76]

const DICE := Rect2i(252, 442, 52, 52)    # 주사위 영역(원본 1024×1536 기준)
const MIN_PART := 1500
const NO_SKIN := [Rect2i(590, 220, 300, 230), Rect2i(10, 810, 360, 270), Rect2i(0, 1240, 1024, 296)]   # 발톱 영역

func _skin(c: Color) -> bool:
	return c.a > 0.5 and c.h > 0.02 and c.h < 0.095 and c.s >= 0.345 and c.s < 0.62 and c.v > 0.58


func _comps(mask: PackedByteArray, w: int, h: int, want: int) -> Array:
	var seen := PackedByteArray(); seen.resize(w * h)
	var out := []
	for s in w * h:
		if seen[s] == 1 or mask[s] != want: continue
		var comp := PackedInt32Array(); var st := PackedInt32Array([s]); seen[s] = 1
		while st.size() > 0:
			var p := st[st.size() - 1]; st.remove_at(st.size() - 1); comp.append(p)
			var x := p % w; var y := p / w
			for q in [p - 1 if x > 0 else -1, p + 1 if x < w - 1 else -1, p - w if y > 0 else -1, p + w if y < h - 1 else -1]:
				if q >= 0 and seen[q] == 0 and mask[q] == want:
					seen[q] = 1; st.append(q)
		out.append(comp)
	return out


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var k := float(a[2]) if a.size() > 2 else 0.76
	var w := img.get_width(); var h := img.get_height()
	var mask := PackedByteArray(); mask.resize(w * h)
	for y in h:
		for x in w:
			var ok := _skin(img.get_pixel(x, y))
			for r in NO_SKIN:
				if r.has_point(Vector2i(x, y)): ok = false
			mask[y * w + x] = 1 if ok else 0
	for comp in _comps(mask, w, h, 1):
		if comp.size() < MIN_PART:
			for p in comp: mask[p] = 0
	for comp in _comps(mask, w, h, 0):      # 피부 안의 작은 틈(홍조·잡티) 메움
		if comp.size() < 60:
			for p in comp:
				var c := img.get_pixel(p % w, p / w)
				if c.s < 0.8 and c.v > 0.5: mask[p] = 1
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if mask[y * w + x] == 0: continue
			var c := src.get_pixel(x, y)
			img.set_pixel(x, y, Color.from_hsv(wrapf(c.h - 0.008, 0.0, 1.0), minf(c.s * 1.3, 0.8), c.v * k, c.a))
	# 경계 1px 완화: 칠한 영역에 맞닿은 밝은 살구빛 테두리도 같이 낮춘다
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			if mask[y * w + x] == 1: continue
			var n: int = mask[y * w + x - 1] + mask[y * w + x + 1] + mask[(y - 1) * w + x] + mask[(y + 1) * w + x]
			if n == 0: continue
			var c := src.get_pixel(x, y)
			if c.h < 0.1 and c.v > 0.6 and c.s > 0.2:
				img.set_pixel(x, y, c.lerp(Color.from_hsv(c.h, minf(c.s * 1.3, 0.8), c.v * k, c.a), 0.7))
	for y in range(DICE.position.y, DICE.end.y):
		for x in range(DICE.position.x, DICE.end.x):
			var c := src.get_pixel(x, y)
			if c.s > 0.62 and c.v > 0.62 and (c.h < 0.03 or c.h > 0.96):
				img.set_pixel(x, y, Color.from_hsv(0.955, 0.72, 0.42 + c.v * 0.12, c.a))
	img.save_png(a[1])
	quit()
