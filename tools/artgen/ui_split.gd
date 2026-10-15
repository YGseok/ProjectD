extends SceneTree
## tools/artgen/ui_split.gd — UI 프레임 이미지를 목표 크기로 줄이고, 마젠타(#FF00FF)로 칠한
## 장식 부분을 ACCENT 레이어(흰색+알파)로, 나머지를 무채색 BASE 레이어로 분리한다
## (docs/art/ART_RESOURCES.md 3-6 "BASE/ACCENT 분리 방법").
## 사용: godot --headless --script ui_split.gd -- <입력 png> <WxH> <out_dir> [mode]
##   mode: split(기본) — base/accent 분리 / plain — 크기만 맞춤(아이콘·배지 등)
## 출력: candidate_base.png, candidate_accent.png(+ split일 때), preview.png(어두운 배경 + 청록 착색 예시 + 2배 늘린 9-slice 시험)

func _magenta(c: Color) -> float:
	return clampf((minf(c.r, c.b) - c.g - 0.15) / 0.45, 0.0, 1.0)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var wh := a[1].split("x"); var W := int(wh[0]); var H := int(wh[1])
	var out_dir: String = a[2]
	var mode: String = a[3] if a.size() > 3 else "split"
	# 보이는 영역만 잘라 목표 크기로
	_remove_outer_bg(img)
	var used := _visible_rect(img)   # get_used_rect()는 알파 1~2짜리 잔여 픽셀까지 잡아서 너무 넓다
	if used.size.x > 0:
		img = img.get_region(used)
	img = _fit_trim(img, W, H)
	if mode == "plain":
		img.save_png(out_dir + "/candidate.png")
		_preview(img, null, out_dir); quit(); return
	var base := img.duplicate() as Image
	var accent := Image.create(W, H, false, Image.FORMAT_RGBA8)
	accent.fill(Color(1, 1, 1, 0))
	var n := 0
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			var m := _magenta(c)
			if m <= 0.0:
				# BASE는 무채색으로 정리(코드 modulate에 안전하게)
				var l := c.get_luminance()
				base.set_pixel(x, y, Color(l, l, l * 1.04, c.a))
				continue
			n += 1
			accent.set_pixel(x, y, Color(1, 1, 1, m * c.a))
			# 장식 아래 BASE는 어두운 중립색으로 메움(장식이 착색돼 올라감)
			var l2 := 0.18
			base.set_pixel(x, y, Color(l2, l2, l2 * 1.05, c.a))
	base.save_png(out_dir + "/candidate_base.png")
	accent.save_png(out_dir + "/candidate_accent.png")
	print("[ui] ", W, "x", H, " accent px=", n)
	_preview(base, accent, out_dir)
	quit()


## 바깥 배경이 불투명 단색(GPT가 검정으로 칠해 오는 경우)이면, 네 테두리에서 이어진 그 색 픽셀을 투명으로 지운다.
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
	var n := 0
	while stack.size() > 0:
		var p := stack[stack.size() - 1]; stack.remove_at(stack.size() - 1)
		if seen[p] == 1: continue
		seen[p] = 1
		var x := p % w; var y := p / w
		var c := img.get_pixel(x, y)
		if Vector3(c.r - bg.r, c.g - bg.g, c.b - bg.b).length() > 0.08: continue
		img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0)); n += 1
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if y > 0: stack.append(p - w)
		if y < h - 1: stack.append(p + w)
	print("[ui] 불투명 바깥 배경 제거: ", n, "px (", bg.to_html(false), ")")


func _visible_rect(img: Image) -> Rect2i:
	var d := img.get_data(); var w := img.get_width(); var h := img.get_height()
	var minx := w; var maxx := -1; var miny := h; var maxy := -1
	for y in h:
		for x in w:
			if d[(y * w + x) * 4 + 3] > 25:
				minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
	if maxx < 0:
		return Rect2i()
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)


## 비율이 목표와 다르면(GPT가 4:1을 6:1로 그리는 등) 찌그러뜨리지 않는다: 비율을 지킨 채 목표를
## 덮도록 줄인 뒤, 남는 축은 가운데(9-slice에서 늘어나는 균일 구간)를 잘라내고 양 끝을 붙인다.
func _fit_trim(img: Image, W: int, H: int) -> Image:
	var s := maxf(float(W) / img.get_width(), float(H) / img.get_height())
	img.resize(maxi(W, int(round(img.get_width() * s))), maxi(H, int(round(img.get_height() * s))), Image.INTERPOLATE_LANCZOS)
	var w := img.get_width(); var h := img.get_height()
	if w == W and h == H:
		return img
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var lw := W / 2; var th := H / 2
	# 네 귀퉁이를 각각 원본 귀퉁이에서 가져와 붙임
	out.blit_rect(img, Rect2i(0, 0, lw, th), Vector2i(0, 0))
	out.blit_rect(img, Rect2i(w - (W - lw), 0, W - lw, th), Vector2i(lw, 0))
	out.blit_rect(img, Rect2i(0, h - (H - th), lw, H - th), Vector2i(0, th))
	out.blit_rect(img, Rect2i(w - (W - lw), h - (H - th), W - lw, H - th), Vector2i(lw, th))
	print("[ui] 비율 보정: ", w, "x", h, " → 가운데를 잘라 ", W, "x", H)
	return out


func _preview(base: Image, accent, out_dir: String) -> void:
	# 원래 크기 + 2배(가로 3배) 늘린 버전(9-slice 아님 — 단순 확대)을 청록 착색으로 미리보기
	var tint := Color("#1FA5A0")
	var comp := base.duplicate() as Image
	if accent != null:
		for y in comp.get_height():
			for x in comp.get_width():
				var ac: Color = accent.get_pixel(x, y)
				if ac.a > 0.0:
					comp.set_pixel(x, y, comp.get_pixel(x, y).lerp(Color(tint.r, tint.g, tint.b, 1.0), ac.a))
	var big := comp.duplicate() as Image
	big.resize(comp.get_width() * 2, comp.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var out := Image.create(comp.get_width() * 3 + 48, comp.get_height() * 2 + 32, false, Image.FORMAT_RGBA8)
	out.fill(Color("#1b1b21"))
	out.blend_rect(comp, Rect2i(Vector2i.ZERO, comp.get_size()), Vector2i(16, 16))
	out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(comp.get_width() + 32, 16))
	out.save_png(out_dir + "/preview.png")
