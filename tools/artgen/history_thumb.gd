extends SceneTree
## tools/artgen/history_thumb.gd — 디자인 이력(위키 기록용) 보관을 위해 시안 이미지를 높이 N px로 줄여 저장한다.
## 사용: godot --headless --script history_thumb.gd -- <높이> <입력1> <출력1> [<입력2> <출력2> ...]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var h := int(a[0])
	var i := 1
	while i + 1 < a.size():
		var img := Image.load_from_file(a[i])
		if img != null and not img.is_empty():
			img.convert(Image.FORMAT_RGBA8)
			var w := int(round(img.get_width() * float(h) / img.get_height()))
			img.resize(w, h, Image.INTERPOLATE_LANCZOS)
			img.save_png(a[i + 1])
		i += 2
	quit()
