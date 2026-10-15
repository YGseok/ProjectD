extends SceneTree
## tools/artgen/icon_fit.gd — 시트에서 잘라낸 스킬 아이콘 한 칸을 규격으로 맞춘다.
## 보이는 영역(알파>25)만 잘라 정사각으로 늘려 256(원본 보관용)과 128(게임용)을 만든다.
## 사용: godot --headless --script icon_fit.gd -- <입력 png> <출력 256 png> <출력 128 png>

func _vis(img: Image) -> Rect2i:
	var d := img.get_data(); var w := img.get_width(); var h := img.get_height()
	var minx := w; var maxx := -1; var miny := h; var maxy := -1
	for y in h:
		for x in w:
			if d[(y * w + x) * 4 + 3] > 25:
				minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	img = img.get_region(_vis(img))
	img.resize(256, 256, Image.INTERPOLATE_LANCZOS)   # 칸이 거의 정사각이라 살짝 늘리는 정도
	img.save_png(a[1])
	var s := img.duplicate() as Image
	s.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	s.save_png(a[2])
	print("[icon] ", a[1].get_file())
	quit()
