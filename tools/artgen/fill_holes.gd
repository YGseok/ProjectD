extends SceneTree
## tools/artgen/fill_holes.gd — 흰 배경으로 받은 원화에서, 테두리와 이어지지 않아 postprocess가 못 지운 순백(s<0.05, v>0.95) 덩어리를
## 투명으로 지운다(찢긴 망토 구멍 등). 캐릭터 옷의 흰색이 순백이면 같이 지워지므로 몬스터·소품 위주로 쓰고, 꼭 어두운 배경 미리보기로 확인.
## 사용: godot --headless --script fill_holes.gd -- <입력 png> <출력 png> <최소 덩어리 px(예: 60)>
func _initialize():
	var a := OS.get_cmdline_user_args(); var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width(); var h := img.get_height(); var MIN := int(a[2])
	var seen := PackedByteArray(); seen.resize(w * h); var n := 0; var comps := 0
	for start in w * h:
		if seen[start] == 1: continue
		var c := img.get_pixel(start % w, start / w)
		if c.a < 0.5 or not (c.s < 0.05 and c.v > 0.95): continue
		var stack := PackedInt32Array([start]); seen[start] = 1; var comp := PackedInt32Array()
		while stack.size() > 0:
			var p := stack[stack.size() - 1]; stack.remove_at(stack.size() - 1); comp.append(p)
			var x := p % w; var y := p / w
			for q in [p - 1 if x > 0 else -1, p + 1 if x < w - 1 else -1, p - w if y > 0 else -1, p + w if y < h - 1 else -1]:
				if q < 0 or seen[q] == 1: continue
				var qc := img.get_pixel(q % w, q / w)
				if qc.a >= 0.5 and qc.s < 0.05 and qc.v > 0.95:
					seen[q] = 1; stack.append(q)
		if comp.size() >= MIN:
			comps += 1; n += comp.size()
			for p in comp: img.set_pixel(p % w, p / w, Color(1, 1, 1, 0))
	img.save_png(a[1]); print("[holes] removed ", comps, " comps, ", n, " px"); quit()
