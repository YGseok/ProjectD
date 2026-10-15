extends SceneTree
## tools/artgen/sheet_split.gd — 한 장에 여러 개를 세로(또는 가로)로 나란히 그린 시트(버튼 상태 5종 등)를
## 투명한 틈을 기준으로 잘라 part_1.png, part_2.png … 로 저장한다. 바깥 배경이 불투명 단색이면 먼저 지운다.
## 사용: godot --headless --script sheet_split.gd -- <입력 png> <out_dir> [v|h]   (v=위→아래(기본), h=왼쪽→오른쪽)

func _remove_outer_bg(img: Image) -> void:
	var w := img.get_width(); var h := img.get_height()
	var bg := img.get_pixel(0, 0)
	if bg.a < 0.9:
		return
	var seen := PackedByteArray(); seen.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x); stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w); stack.append(y * w + w - 1)
	while stack.size() > 0:
		var p := stack[stack.size() - 1]; stack.remove_at(stack.size() - 1)
		if seen[p] == 1: continue
		seen[p] = 1
		var x := p % w; var y := p / w
		var c := img.get_pixel(x, y)
		if Vector3(c.r - bg.r, c.g - bg.g, c.b - bg.b).length() > 0.08: continue
		img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if y > 0: stack.append(p - w)
		if y < h - 1: stack.append(p + w)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var out_dir: String = a[1]
	var vertical := a.size() < 3 or a[2] != "h"
	_remove_outer_bg(img)
	var w := img.get_width(); var h := img.get_height()
	var d := img.get_data()
	var n := h if vertical else w
	# 줄(또는 열)마다 보이는 픽셀(알파>25) 수
	var filled := PackedInt32Array(); filled.resize(n)
	for y in h:
		for x in w:
			if d[(y * w + x) * 4 + 3] > 25:
				filled[y if vertical else x] += 1
	var min_px := 3   # 잔여 점 몇 개는 틈으로 본다
	var parts := []
	var start := -1
	for i in n + 1:
		var on := i < n and filled[i] > min_px
		if on and start < 0: start = i
		elif not on and start >= 0:
			if i - start > n / 40: parts.append(Vector2i(start, i))
			start = -1
	var k := 0
	for p in parts:
		k += 1
		var r := Rect2i(0, p.x, w, p.y - p.x) if vertical else Rect2i(p.x, 0, p.y - p.x, h)
		img.get_region(r).save_png("%s/part_%d.png" % [out_dir, k])
	print("[sheet] ", k, "개로 분리: ", parts)
	quit()
