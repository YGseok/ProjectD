extends SceneTree
## tools/artgen/postprocess.gd — OpenAI 이미지 API 응답(JSON, b64_json)을 풀어서
## docs/art/ART_RESOURCES.md 규격으로 후처리한 후보 PNG를 만든다.
##   full : 보이는 영역 기준 세로 1303px로 맞춰 1181x1332 캔버스 중앙 배치
##   face : 768x768
##   icon : 256x256 원본 + 128x128 게임용(_128)
## 사용: godot --headless --script postprocess.gd -- <response.json> <kind> <out_dir>

const FULL_W := 1181
const FULL_H := 1332
const FULL_TARGET_H := 1303.0


func _visible_rect(img: Image) -> Rect2i:
	var d := img.get_data(); var w := img.get_width(); var h := img.get_height()
	var minx := w; var maxx := -1; var miny := h; var maxy := -1
	for y in h:
		for x in w:
			if d[(y * w + x) * 4 + 3] > 25:
				minx = min(minx, x); maxx = max(maxx, x); miny = min(miny, y); maxy = max(maxy, y)
	if maxx < 0:
		return Rect2i(0, 0, w, h)
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)


func _fit_full(img: Image) -> Image:
	var vis := _visible_rect(img)
	var s := FULL_TARGET_H / vis.size.y
	if vis.size.x * s > FULL_W - 20:
		s = (FULL_W - 20.0) / vis.size.x
	var part := img.get_region(vis)
	part.resize(maxi(1, int(round(vis.size.x * s))), maxi(1, int(round(vis.size.y * s))), Image.INTERPOLATE_LANCZOS)
	var out := Image.create(FULL_W, FULL_H, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), (Vector2i(FULL_W, FULL_H) - part.get_size()) / 2)
	return out


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var resp_path: String = a[0]; var kind: String = a[1]; var out_dir: String = a[2]
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(resp_path))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		print("[post] ERROR 응답에 data가 없음: ", str(parsed).left(500))
		quit(1); return
	var i := 0
	for item in parsed["data"]:
		i += 1
		var img := Image.new()
		if img.load_png_from_buffer(Marshalls.base64_to_raw(item.get("b64_json", ""))) != OK:
			print("[post] ERROR 후보 ", i, " PNG 디코드 실패"); continue
		img.convert(Image.FORMAT_RGBA8)
		img.save_png("%s/raw_%d.png" % [out_dir, i])
		match kind:
			"full":
				_fit_full(img).save_png("%s/candidate_%d.png" % [out_dir, i])
			"face":
				img.resize(768, 768, Image.INTERPOLATE_LANCZOS)
				img.save_png("%s/candidate_%d.png" % [out_dir, i])
			"icon":
				img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
				img.save_png("%s/candidate_%d.png" % [out_dir, i])
				var small := img.duplicate() as Image
				small.resize(128, 128, Image.INTERPOLATE_LANCZOS)
				small.save_png("%s/candidate_%d_128.png" % [out_dir, i])
		print("[post] 후보 ", i, " 저장 (", kind, ", 원본 ", img.get_size() if kind != "full" else _visible_rect(img).size, ")")
	quit()
