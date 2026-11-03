extends SceneTree
## tools/artgen/priest_fix2.gd — 심연의 사제 v7 방식 재작업(19차 피드백): priest_scars.gd처럼 눈 문양을 복부로 올리되,
##  (1) 흉터는 맨살(얼굴·팔·손·다리)에만 — 옷 위 자리(가슴·허리끈)는 뺐다,
##  (2) 흉터를 팔다리의 축 방향으로 눕히고 축과 수직 방향으로 눌러(감기는 원근) 굽힘을 키워 몸의 결을 따르게,
##  (3) 색은 진한 선 대신 피부 선화에 가까운 짙은 장밋빛 심 + 옅은 분홍 테두리,
##  (4) [hair 옵션] 소매 아래 양끝으로 흘러내리는 굵은 청록 머리 두 가닥을 배경(흰색)으로 지운다 — 잔선이 남아서 기본은 끄고 GPT 크롭 수정으로 처리.
## 사용: godot --headless --script priest_fix2.gd -- <입력(new_abyss_priest/6/strict.png)> <출력> [hair]

const PANEL_X := Vector2i(362, 470)
const EMBLEM := Vector2i(838, 990)
const TARGET_Y := 605
const PLAIN_Y := 680

# [중심 x, 중심 y, 반길이, 팔다리 축 각도(도, 0 = 세로), 눌림 비율]
const SCARS := [
	[455, 330, 12, 20, 0.8],                                   # 목·쇄골
	[150, 228, 14, 35, 0.6], [880, 315, 12, -60, 0.6],         # 팔뚝·손등
	[325, 715, 22, 4, 0.6], [340, 850, 20, -4, 0.6], [318, 910, 17, 6, 0.6],
	[548, 752, 20, -18, 0.6], [620, 790, 24, -22, 0.6], [600, 905, 22, -20, 0.6], [655, 935, 20, -22, 0.6], [710, 1075, 20, -14, 0.6],
	[315, 1100, 18, 2, 0.6], [325, 1160, 14, 2, 0.6], [742, 1140, 14, -10, 0.6],
]
const HAIR_L := Rect2i(0, 420, 270, 900)
const HAIR_R := Rect2i(790, 360, 234, 1000)
const FLAME := Rect2i(885, 500, 115, 115)   # 향로 불꽃(지우지 않음)

func _skin(c: Color) -> bool:
	return c.a > 0.9 and c.v > 0.78 and c.s < 0.16


func _hair(c: Color) -> bool:
	return c.s > 0.4 and c.h > 0.47 and c.h < 0.565 and c.v > 0.25


func _stroke(img: Image, mask: Image, p0: Vector2, p1: Vector2, bend: float) -> void:
	var n := int(p0.distance_to(p1) * 2.0)
	var nrm := (p1 - p0).orthogonal().normalized()
	for i in n + 1:
		var t := float(i) / n
		var p := p0.lerp(p1, t) + nrm * bend * sin(t * PI)
		var w := 1.1 * sin(t * PI) + 0.4
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var q := Vector2i(int(p.x) + dx, int(p.y) + dy)
				if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height(): continue
				if mask.get_pixel(q.x, q.y).r < 0.5: continue
				var d := Vector2(dx, dy).length()
				var base := img.get_pixel(q.x, q.y)
				if d <= w:
					img.set_pixel(q.x, q.y, base.lerp(Color(0.62, 0.27, 0.36, 1), clampf(1.1 - d / (w + 0.01) * 0.5, 0.0, 0.8)))
				elif d <= w + 1.5:
					img.set_pixel(q.x, q.y, base.lerp(Color(0.9, 0.66, 0.7, 1), 0.3))


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var w := PANEL_X.y - PANEL_X.x
	var h := EMBLEM.y - EMBLEM.x
	var emblem := img.get_region(Rect2i(PANEL_X.x, EMBLEM.x, w, h))
	var row := img.get_region(Rect2i(PANEL_X.x, PLAIN_Y, w, 1))
	for y in range(EMBLEM.x, EMBLEM.y):
		img.blit_rect(row, Rect2i(0, 0, w, 1), Vector2i(PANEL_X.x, y))
	img.blit_rect(emblem, Rect2i(0, 0, w, h), Vector2i(PANEL_X.x, TARGET_Y))
	# 머리 가닥: 청록 픽셀을 투명으로 → 그 주변(4px)에 남은 얇은 외곽선·잔점은 열림 연산(침식 2 → 팽창 2)으로 정리
	var W := img.get_width(); var H := img.get_height()
	var gone := PackedByteArray(); gone.resize(W * H)
	var regions := [HAIR_L, HAIR_R] if (a.size() > 2 and a[2] == "hair") else []   # 로컬 제거는 잔선이 남아 기본은 끔(GPT 크롭 수정 사용)
	for r in regions:
		for y in range(r.position.y, mini(r.end.y, H)):
			for x in range(r.position.x, mini(r.end.x, W)):
				var c := img.get_pixel(x, y)
				if FLAME.has_point(Vector2i(x, y)) or c.v > 0.85: continue
				if _hair(c): img.set_pixel(x, y, Color.WHITE); gone[y * W + x] = 1
	var near := PackedByteArray(); near.resize(W * H)
	for y in H:
		for x in W:
			if gone[y * W + x] == 0: continue
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var xx := x + dx; var yy := y + dy
					if xx >= 0 and yy >= 0 and xx < W and yy < H: near[yy * W + xx] = 1
	var op := func(src: PackedByteArray, want: int) -> PackedByteArray:
		var o := src.duplicate()
		for y in range(2, H - 2):
			for x in range(2, W - 2):
				if near[y * W + x] == 0: continue
				var hit := false
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if src[(y + dy) * W + x + dx] == want: hit = true
				if hit: o[y * W + x] = want
		return o
	var solid := PackedByteArray(); solid.resize(W * H)
	for i in W * H: solid[i] = 1 if (img.get_pixel(i % W, i / W).a > 0.5 and (img.get_pixel(i % W, i / W).v < 0.97)) else 0
	var opened: PackedByteArray = op.call(op.call(solid, 0), 1)
	for i in W * H:
		if near[i] == 1 and solid[i] == 1 and opened[i] == 0: img.set_pixel(i % W, i / W, Color.WHITE)
	var mask := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_L8)
	for y in img.get_height():
		for x in img.get_width():
			mask.set_pixel(x, y, Color.WHITE if _skin(img.get_pixel(x, y)) else Color.BLACK)
	for s in SCARS:
		var c := Vector2(s[0], s[1]); var r: float = s[2]; var ax := deg_to_rad(float(s[3])); var k: float = s[4]
		# 팔다리 축 좌표계: u = 축 방향, v = 축에 수직(눌림)
		var u := Vector2(0, 1).rotated(ax); var v := Vector2(1, 0).rotated(ax) * k
		var d1 := u * r * 0.75 + v * r; var d2 := u * r * 0.75 - v * r
		_stroke(img, mask, c - d1, c + d1, r * 0.22)
		_stroke(img, mask, c - d2, c + d2, -r * 0.18)
	img.save_png(a[1])
	quit()
