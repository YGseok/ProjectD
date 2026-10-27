extends SceneTree
## tools/artgen/crop_patch.gd — 일부분만 GPT에 고쳐 받기 위한 잘라내기/되붙이기.
## (전신을 보내면 GPT가 전체를 다시 그리거나 정책에 막히므로, 고칠 부위만 잘라 크게 보내고 결과를 원래 자리에 붙인다)
## 잘라내기: godot --headless --script crop_patch.gd -- crop <기준본> <출력> <x> <y> <w> <h> <배율>
## 되붙이기: godot --headless --script crop_patch.gd -- paste <기준본> <편집 조각> <출력> <x> <y> <w> <h> [경계 섞기 px=16]
##   편집 조각은 크기와 상관없이 w×h로 줄여 붙이고, 가장자리 F px는 기준본과 부드럽게 섞는다.

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var base := Image.load_from_file(a[1]); base.convert(Image.FORMAT_RGBA8)
	if a[0] == "crop":
		var r := Rect2i(int(a[3]), int(a[4]), int(a[5]), int(a[6]))
		var c := base.get_region(r)
		c.resize(r.size.x * int(a[7]), r.size.y * int(a[7]), Image.INTERPOLATE_LANCZOS)
		c.save_png(a[2])
	else:
		var piece := Image.load_from_file(a[2]); piece.convert(Image.FORMAT_RGBA8)
		var r := Rect2i(int(a[4]), int(a[5]), int(a[6]), int(a[7]))
		var F := int(a[8]) if a.size() > 8 else 16
		piece.resize(r.size.x, r.size.y, Image.INTERPOLATE_LANCZOS)
		for y in r.size.y:
			for x in r.size.x:
				var edge := mini(mini(x, r.size.x - 1 - x), mini(y, r.size.y - 1 - y))
				var t := clampf(float(edge) / F, 0.0, 1.0)
				var p := r.position + Vector2i(x, y)
				base.set_pixel(p.x, p.y, base.get_pixel(p.x, p.y).lerp(piece.get_pixel(x, y), t))
		base.save_png(a[3])
	quit()
