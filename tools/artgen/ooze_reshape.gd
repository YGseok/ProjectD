extends SceneTree
## tools/artgen/ooze_reshape.gd — 점액 군주 뒤쪽 덩어리를 "엉덩이 두 짝"이 아니라 은근한 한 줄 체형 곡선으로 다시 칠한다.
## GPT·Grok이 정책으로 막아서 로컬로 처리(2026-11-05, 사용자 빨간 선 가이드 기준). b42 candidate_fix(1181×1332) 좌표 전용.
##  - T(x): 바깥 점액 윗선 — 허리에서 살짝 내려앉았다가 한 번 낮게 오르고 오른쪽으로 길게 완만하게 내려감
##  - H(x): 점액층 아래 몸의 힙 곡선(은은한 선 하나), 그 아래 몸 색, 아래쪽에 그림자 한 톤
##  - 주사위·보석 픽셀(색으로 판별)은 보호, x<760은 원본 유지(윗선만 내림), 760~800에서 원본과 섞음
## 사용: godot --headless --script ooze_reshape.gd -- <입력> <출력>

const RIM := Color("b1f680")
const LAYER := Color("62d258")
const GLOSS := Color("cbfa91")
const BODY := Color("4bc259")
const LINE := Color("34a752")
const SHADE := Color("29a253")
const DRIP := Color("74d95a")
const DIE := Rect2i(836, 578, 82, 80)
const GEM := Rect2i(944, 728, 64, 104)
var src: Image

func _curve(pts: Array, x0: int, x1: int) -> Dictionary:
	var out := {}
	for i in pts.size() - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]; var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]; var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		for k in 200:
			var t := k / 200.0
			var v := 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)
			out[int(round(v.x))] = v.y
	for x in range(x0, x1 + 1):
		if not out.has(x): out[x] = out.get(x - 1, 0.0)
	return out

## 주사위(진한 초록 몸통·노란 눈)와 보석(주황·금색)만 보호 — 사각형 전체를 막으면 배경이 네모로 남는다
func _prot1(x: int, y: int) -> bool:
	var c := src.get_pixel(x, y)
	if DIE.has_point(Vector2i(x, y)):
		return c.s > 0.8 or c.v < 0.58 or (c.h > 0.08 and c.h < 0.18 and c.s > 0.3)
	if GEM.has_point(Vector2i(x, y)):
		return c.h < 0.2 and c.s > 0.25 and c.r > c.g * 0.75
	return false

## 1px 넓혀서 가장자리 반투명 픽셀까지 지킨다
func _prot(x: int, y: int) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if _prot1(x + dx, y + dy): return true
	return false

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	src = Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var img := src.duplicate() as Image
	var T := _curve([Vector2(560, 489), Vector2(590, 536), Vector2(600, 548), Vector2(620, 568), Vector2(650, 593), Vector2(690, 610), Vector2(730, 606), Vector2(765, 590),
		Vector2(820, 568), Vector2(871, 560), Vector2(930, 566), Vector2(975, 584), Vector2(1015, 614),
		Vector2(1055, 652), Vector2(1100, 698), Vector2(1140, 735), Vector2(1170, 760)], 560, 1170)
	var H := _curve([Vector2(700, 640), Vector2(760, 618), Vector2(810, 604), Vector2(860, 600), Vector2(905, 606),
		Vector2(950, 626), Vector2(985, 648), Vector2(1040, 678), Vector2(1100, 714), Vector2(1150, 752)], 700, 1150)
	var S := _curve([Vector2(700, 792), Vector2(780, 774), Vector2(860, 754), Vector2(930, 734), Vector2(990, 718),
		Vector2(1050, 712), Vector2(1150, 766)], 700, 1150)
	var B := _curve([Vector2(700, 808), Vector2(780, 806), Vector2(860, 802), Vector2(930, 792), Vector2(1000, 778),
		Vector2(1060, 766), Vector2(1110, 760), Vector2(1150, 764)], 700, 1150)
	for x in range(600, 1150):
		var t: float = T[x]
		var w_dip := 1.0
		var old_top := 9999
		for y in range(520, 820):
			if src.get_pixel(x, y).a > 0.5: old_top = y; break
		# 1) 새 윗선 위는 지운다
		for y in range(530, int(t)):
			if _prot(x, y): continue
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * (1.0 - w_dip)))
		# 2) 윤곽 림(빛 받는 밝은 테)
		for y in range(int(t), int(t) + 4):
			if _prot(x, y): continue
			var c := RIM
			if y == int(t): c.a = 1.0 - (t - floor(t))
			var base := img.get_pixel(x, y)
			img.set_pixel(x, y, base.lerp(c, w_dip) if base.a > 0.5 else Color(c.r, c.g, c.b, c.a * w_dip))
		# 3) 760 오른쪽은 몸 전체를 다시 칠함(왼쪽은 원본, 윗선이 원래보다 높아진 틈만 채움)
		var w := clampf((x - 760) / 40.0, 0.0, 1.0)
		if w <= 0.0:
			for y in range(int(t) + 4, mini(old_top + 3, 820)):
				img.set_pixel(x, y, LAYER)
			continue
		var h: float = H[x]; var s: float = S[x]; var b: float = B[x]
		for y in range(int(t) + 4, int(b) + 6):
			if _prot(x, y): continue
			var c: Color
			if y < h - 1.5: c = LAYER
			elif y < h + 1.5: c = LINE
			elif y < s - 2.0: c = BODY
			elif y < s + 2.0: c = BODY.lerp(SHADE, 0.5)
			else: c = SHADE
			var gx := (x - 875) / 75.0; var gy := (y - (t + 15.0)) / 4.5
			if gx * gx + gy * gy < 1.0: c = GLOSS
			var hx := (x - 850) / 80.0; var hy := (y - (h + 26.0)) / 9.0
			if hx * hx + hy * hy < 1.0: c = c.lerp(GLOSS, 0.35)
			var ww := w
			if y > b: ww *= clampf((b + 6.0 - y) / 6.0, 0.0, 1.0)  # 아래 원본 그림자로 섞기
			if y < old_top: ww = 1.0
			var o := src.get_pixel(x, y)
			img.set_pixel(x, y, o.lerp(c, ww) if o.a > 0.5 else Color(c.r, c.g, c.b, ww))
	# 주사위 아래 그림자
	for y in range(648, 670):
		for x in range(836, 922):
			var dx := (x - 878) / 42.0; var dy := (y - 657) / 9.0
			if dx * dx + dy * dy < 1.0 and not _prot(x, y):
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(LINE, 0.35))
	# 점액층에서 흘러내리는 방울
	# 모양: 위는 점액층에 넓게 붙고, 가운데가 잘록, 끝은 둥근 방울(원본 방울처럼 밝은 몸·진한 테·하이라이트)
	for d in []:  # 방울은 작게 보면 네모 조각처럼 보여 뺌(2026-11-05)
		var cx: int = d[0]; var ln: int = d[1]; var r: int = d[2]
		var y0 := int(H[cx]) - 4
		var by := y0 + ln
		for y in range(y0, by + r + 3):
			for x in range(cx - r * 2, cx + r * 2 + 1):
				if _prot(x, y): continue
				var dist: float
				if y < by:
					var u := float(y - y0) / ln
					var hw := r * (1.25 - 0.45 * u)
					dist = absf(x - cx) - hw
				else:
					dist = Vector2(x - cx, y - by).length() - r
				var o := img.get_pixel(x, y)
				if dist < -2.0: img.set_pixel(x, y, DRIP)
				elif dist < 0.0 and y > y0 + 4: img.set_pixel(x, y, LINE)
				elif dist < 1.0 and y > y0 + 4: img.set_pixel(x, y, o.lerp(LINE, 1.0 - dist))
		for y in range(by - 4, by + 4):
			for x in range(cx - 8, cx):
				if Vector2((x - (cx - 4)) / 1.0, (y - (by - 1)) / 1.6).length() < 3.0: img.set_pixel(x, y, GLOSS)
	img.save_png(a[1])
	quit()
