extends SceneTree
## tools/artgen/quad_split.gd — 2×2로 그린 스킬 아이콘 시트를 네 칸으로 자르고, 칸마다 바깥 여백(시트 배경색)을
## 걷어낸 정사각 아이콘을 256(원본 보관용)과 128(게임용)으로 저장한다. 순서: 왼쪽 위, 오른쪽 위, 왼쪽 아래, 오른쪽 아래.
## 사용: godot --headless --script quad_split.gd -- <시트 png> <id1> <id2> <id3> <id4> <out256 dir> <out128 dir>
##   id가 "-"면 그 칸은 건너뛴다.

func _bbox(img: Image, r: Rect2i, bg: Color) -> Rect2i:
	var minx := r.end.x; var maxx := r.position.x - 1; var miny := r.end.y; var maxy := r.position.y - 1
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := img.get_pixel(x, y)
			if Vector3(c.r - bg.r, c.g - bg.g, c.b - bg.b).length() > 0.12:
				minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
	if maxx < minx:
		return r
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var ids := [a[1], a[2], a[3], a[4]]
	var d256: String = a[5]; var d128: String = a[6]
	var w := img.get_width(); var h := img.get_height()
	var bg := img.get_pixel(2, 2)
	var cells := [Rect2i(0, 0, w / 2, h / 2), Rect2i(w / 2, 0, w - w / 2, h / 2),
		Rect2i(0, h / 2, w / 2, h - h / 2), Rect2i(w / 2, h / 2, w - w / 2, h - h / 2)]
	for i in 4:
		if ids[i] == "-": continue
		var b := _bbox(img, cells[i], bg)
		var s := maxi(b.size.x, b.size.y)
		var sq := Rect2i(b.get_center().x - s / 2, b.get_center().y - s / 2, s, s).intersection(Rect2i(0, 0, w, h))
		var icon := img.get_region(sq)
		icon.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		icon.save_png("%s/%s_256.png" % [d256, ids[i]])
		icon.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		icon.save_png("%s/%s.png" % [d128, ids[i]])
		print("[quad] ", ids[i], " ", b)
	quit()
