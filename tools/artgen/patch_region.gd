extends SceneTree
## tools/artgen/patch_region.gd — 부분 수정 합성: GPT가 "그 부분만" 고친 편집본에서 지정한 영역만 잘라 기준본에 붙인다
## (GPT 편집은 그림 전체를 다시 그려 다른 부위가 조금씩 바뀌므로). 두 그림의 어긋남은 기준 영역에서 ±R px 탐색으로 맞추고,
## 붙이는 경계는 F px 폭으로 부드럽게 섞는다.
## 사용: godot --headless --script patch_region.gd -- <기준본> <편집본> <출력> <x> <y> <w> <h> [F=24] [R=24]
##   x,y,w,h = 편집본에서 가져올 영역(기준본 좌표). 어긋남 탐색은 그 영역을 둘러싼 띠(폭 40px)에서 한다.

func _diff(a: Image, b: Image, r: Rect2i, dx: int, dy: int) -> float:
	var s := 0.0; var n := 0
	var bw := b.get_width(); var bh := b.get_height()
	for y in range(r.position.y, r.end.y, 3):
		for x in range(r.position.x, r.end.x, 3):
			var inner := x >= r.position.x + 40 and x < r.end.x - 40 and y >= r.position.y + 40 and y < r.end.y - 40
			if inner: continue
			var bx := x + dx; var by := y + dy
			if bx < 0 or by < 0 or bx >= bw or by >= bh: continue
			var ca := a.get_pixel(x, y); var cb := b.get_pixel(bx, by)
			s += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b); n += 1
	return s / maxi(n, 1)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var base := Image.load_from_file(a[0]); base.convert(Image.FORMAT_RGBA8)
	var edit := Image.load_from_file(a[1]); edit.convert(Image.FORMAT_RGBA8)
	var r := Rect2i(int(a[3]), int(a[4]), int(a[5]), int(a[6]))
	var F := int(a[7]) if a.size() > 7 else 24
	var R := int(a[8]) if a.size() > 8 else 24
	var ring := r.grow(40).intersection(Rect2i(Vector2i.ZERO, base.get_size()))
	var best := INF; var bd := Vector2i.ZERO
	for dy in range(-R, R + 1, 2):
		for dx in range(-R, R + 1, 2):
			var d := _diff(base, edit, ring, dx, dy)
			if d < best: best = d; bd = Vector2i(dx, dy)
	print("[patch] offset ", bd, " diff ", best)
	var out := base.duplicate() as Image
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var ex := x + bd.x; var ey := y + bd.y
			if ex < 0 or ey < 0 or ex >= edit.get_width() or ey >= edit.get_height(): continue
			var edge := mini(mini(x - r.position.x, r.end.x - 1 - x), mini(y - r.position.y, r.end.y - 1 - y))
			var t := clampf(float(edge) / F, 0.0, 1.0)
			out.set_pixel(x, y, base.get_pixel(x, y).lerp(edit.get_pixel(ex, ey), t))
	out.save_png(a[2])
	quit()
