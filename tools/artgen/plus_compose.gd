extends SceneTree
## tools/artgen/plus_compose.gd — 스킬 아이콘 위에 "+" 강화판 오버레이(금테 + 별 배지)를 얹어
## <skill_id>_plus 아이콘을 만든다. 오버레이의 크로마키 녹색(#00FF00 근처)은 투명 처리.
## 사용: godot --headless --script plus_compose.gd -- <overlay png> <base 256 png> <출력 256> <출력 128>

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var ov := Image.load_from_file(a[0]); ov.convert(Image.FORMAT_RGBA8)
	for y in ov.get_height():
		for x in ov.get_width():
			var c := ov.get_pixel(x, y)
			if c.g > 0.6 and c.r < 0.45 and c.b < 0.45:
				ov.set_pixel(x, y, Color(0, 0, 0, 0))
	ov.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	var base := Image.load_from_file(a[1]); base.convert(Image.FORMAT_RGBA8)
	base.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	base.blend_rect(ov, Rect2i(0, 0, 256, 256), Vector2i.ZERO)
	base.save_png(a[2])
	var s := base.duplicate() as Image
	s.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	s.save_png(a[3])
	print("[plus] ", a[2].get_file())
	quit()
