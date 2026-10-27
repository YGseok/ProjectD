extends SceneTree
## tools/artgen/bg_strict.gd — 흰 배경 위의 창백한 캐릭터용 배경 제거. postprocess.gd의 "밝은 무채색" 기준은
## 흰 피부·흰 옷까지 같이 지우므로, 테두리에서 이어진 거의 순백(모든 채널 > T, 기본 0.965)만 지운다.
## 사용: godot --headless --script bg_strict.gd -- <입력> <출력> [T]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var T := float(a[2]) if a.size() > 2 else 0.965
	var w := img.get_width(); var h := img.get_height()
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
		if minf(c.r, minf(c.g, c.b)) <= T: continue
		img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if y > 0: stack.append(p - w)
		if y < h - 1: stack.append(p + w)
	img.save_png(a[1])
	quit()
