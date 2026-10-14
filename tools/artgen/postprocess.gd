extends SceneTree
## tools/artgen/postprocess.gd — OpenAI 이미지 API 응답(JSON, b64_json)을 풀어서
## docs/art/ART_RESOURCES.md 규격으로 후처리한 후보 PNG를 만든다.
##   full : 보이는 영역 기준 세로 1303px로 맞춰 1181x1332 캔버스 중앙 배치
##   face : 768x768
##   icon : 256x256 원본 + 128x128 게임용(_128)
## 사용: godot --headless --script postprocess.gd -- <response.json 또는 이미지 파일(.png/.jpg/.webp)> <kind> <out_dir>
## 이미지 파일 입력(ChatGPT에서 직접 받은 파일, ingest.sh)일 때 배경이 불투명하면 테두리와 이어진
## 단색 배경을 자동으로 지운다(full/face만 — 아이콘은 배경까지 그림의 일부라 그대로 둔다).

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



## 배경이 불투명하면(투명 픽셀이 거의 없으면) 이미지 테두리에서 시작해, 테두리 색과
## 비슷한(허용 오차 TOL) 픽셀을 이어서 지운다. 캐릭터 안쪽의 흰색은 테두리와 이어져
## 있지 않으면 남는다. 경계는 1px 반투명으로 부드럽게 처리.
const TOL := 0.10

func _remove_flat_background(img: Image) -> bool:
	var w := img.get_width(); var h := img.get_height()
	var d := img.get_data()
	var transparent := 0
	for i in range(0, w * h, 37):
		if d[i * 4 + 3] < 200: transparent += 1
	if transparent > (w * h / 37) / 50:
		return false  # 이미 투명 배경
	# 테두리 평균색
	var acc := Vector3.ZERO; var n := 0
	for x in w:
		for y in [0, h - 1]:
			var c := img.get_pixel(x, y); acc += Vector3(c.r, c.g, c.b); n += 1
	for y in h:
		for x in [0, w - 1]:
			var c := img.get_pixel(x, y); acc += Vector3(c.r, c.g, c.b); n += 1
	var bg := acc / n
	var visited := PackedByteArray(); visited.resize(w * h)
	var stack := PackedInt32Array()
	for x in w:
		stack.append(x); stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w); stack.append(y * w + w - 1)
	var removed := 0
	while stack.size() > 0:
		var p := stack[stack.size() - 1]; stack.remove_at(stack.size() - 1)
		if visited[p] == 1: continue
		visited[p] = 1
		var x := p % w; var y := p / w
		var c := img.get_pixel(x, y)
		if Vector3(c.r, c.g, c.b).distance_to(bg) > TOL: continue
		img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0)); removed += 1
		if x > 0: stack.append(p - 1)
		if x < w - 1: stack.append(p + 1)
		if y > 0: stack.append(p - w)
		if y < h - 1: stack.append(p + w)
	# 남은 픽셀 중 지운 픽셀과 맞닿은 것은 반투명으로(계단 완화)
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c := img.get_pixel(x, y)
			if c.a == 0.0: continue
			if img.get_pixel(x - 1, y).a == 0.0 or img.get_pixel(x + 1, y).a == 0.0 or img.get_pixel(x, y - 1).a == 0.0 or img.get_pixel(x, y + 1).a == 0.0:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.6))
	print("[post] 단색 배경 제거: ", removed, "px (배경색 ", Color(bg.x, bg.y, bg.z).to_html(false), ")")
	return true


func _handle(img: Image, kind: String, out_dir: String, i: int, from_file: bool) -> void:
	img.convert(Image.FORMAT_RGBA8)
	img.save_png("%s/raw_%d.png" % [out_dir, i])
	if from_file and kind != "icon":
		_remove_flat_background(img)
	match kind:
		"full":
			_fit_full(img).save_png("%s/candidate_%d.png" % [out_dir, i])
		"face":
			var s := minf(768.0 / img.get_width(), 768.0 / img.get_height())
			var part := img.duplicate() as Image
			part.resize(int(img.get_width() * s), int(img.get_height() * s), Image.INTERPOLATE_LANCZOS)
			var out := Image.create(768, 768, false, Image.FORMAT_RGBA8)
			out.fill(Color(0, 0, 0, 0))
			out.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), (Vector2i(768, 768) - part.get_size()) / 2)
			out.save_png("%s/candidate_%d.png" % [out_dir, i])
		"icon":
			# 정사각이 아니면 가운데 정사각으로 자른다
			var m := mini(img.get_width(), img.get_height())
			img = img.get_region(Rect2i((img.get_width() - m) / 2, (img.get_height() - m) / 2, m, m))
			img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
			img.save_png("%s/candidate_%d.png" % [out_dir, i])
			var small := img.duplicate() as Image
			small.resize(128, 128, Image.INTERPOLATE_LANCZOS)
			small.save_png("%s/candidate_%d_128.png" % [out_dir, i])
	print("[post] 후보 ", i, " 저장 (", kind, ")")


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src: String = a[0]; var kind: String = a[1]; var out_dir: String = a[2]
	var ext := src.get_extension().to_lower()
	if ext in ["png", "jpg", "jpeg", "webp"]:
		var img := Image.load_from_file(src)
		if img == null:
			print("[post] ERROR 이미지 로드 실패: ", src); quit(1); return
		_handle(img, kind, out_dir, 1, true)
		quit(); return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(src))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		print("[post] ERROR 응답에 data가 없음: ", str(parsed).left(500))
		quit(1); return
	var i := 0
	for item in parsed["data"]:
		i += 1
		var img := Image.new()
		if img.load_png_from_buffer(Marshalls.base64_to_raw(item.get("b64_json", ""))) != OK:
			print("[post] ERROR 후보 ", i, " PNG 디코드 실패"); continue
		_handle(img, kind, out_dir, i, false)
	quit()
