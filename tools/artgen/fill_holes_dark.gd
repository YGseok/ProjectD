extends SceneTree
## tools/artgen/fill_holes_dark.gd — 검은 배경으로 받은 원화에서 테두리와 이어지지 않아 남은 순흑(v<0.07) 덩어리를 투명으로 지운다
## (활과 몸 사이 등). 사용: godot --headless --script fill_holes_dark.gd -- <입력> <출력> <최소 px(예: 3000)>
func _initialize():
	var a := OS.get_cmdline_user_args(); var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width(); var h := img.get_height(); var MIN := int(a[2])
	var seen := PackedByteArray(); seen.resize(w * h); var n := 0; var comps := 0
	for start in w * h:
		if seen[start] == 1: continue
		var c := img.get_pixel(start % w, start / w)
		if c.a < 0.5 or not (c.v < 0.07): continue
		var stack := PackedInt32Array([start]); seen[start] = 1; var comp := PackedInt32Array()
		while stack.size() > 0:
			var p := stack[stack.size() - 1]; stack.remove_at(stack.size() - 1); comp.append(p)
			var x := p % w; var y := p / w
			for q in [p - 1 if x > 0 else -1, p + 1 if x < w - 1 else -1, p - w if y > 0 else -1, p + w if y < h - 1 else -1]:
				if q < 0 or seen[q] == 1: continue
				var qc := img.get_pixel(q % w, q / w)
				if qc.a >= 0.5 and qc.v < 0.07:
					seen[q] = 1; stack.append(q)
		if comp.size() >= MIN:
			comps += 1; n += comp.size()
			for p in comp: img.set_pixel(p % w, p / w, Color(1, 1, 1, 0))
	img.save_png(a[1]); print("[holes] removed ", comps, " comps, ", n, " px"); quit()
