extends SceneTree
## tools/artgen/head_shrink.gd — 머리만 작게(그림자 rs22, 2026-11-09). GPT로 비율을 고치면 표정·자세·주사위까지 바뀌어서 로컬 변형으로 처리.
## 기준점 A(턱 아래 목) 쪽으로 머리를 배율 s로 끌어당기는 핀치 변형. 효과 가중치 w는 머리 중심 H에서 1, 반경 r1 밖으로 갈수록 0(r2에서 0).
## 출력 p 의 원본 위치 = A + (p - A) / s_eff,  s_eff = lerp(1, s, w(p)). 원본이 배경/금지 사각형 안이면 배경색.
## 사용: godot --headless --script head_shrink.gd -- <입력> <출력> <Ax> <Ay> <Hx> <Hy> <s> <r1> <r2> [금지 타원의 외접 사각형 x y w h] [bg hex]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var img := src.duplicate() as Image
	var A := Vector2(float(a[2]), float(a[3])); var Hc := Vector2(float(a[4]), float(a[5]))
	var s := float(a[6]); var r1 := float(a[7]); var r2 := float(a[8])
	var ban := Rect2i()
	if a.size() > 12: ban = Rect2i(int(a[9]), int(a[10]), int(a[11]), int(a[12]))
	var bg := Color(a[13]) if a.size() > 13 else Color.WHITE
	var W := src.get_width(); var H := src.get_height()
	for y in range(maxi(0, int(Hc.y - r2)), mini(H, int(Hc.y + r2) + 1)):
		for x in range(maxi(0, int(Hc.x - r2)), mini(W, int(Hc.x + r2) + 1)):
			var p := Vector2(x, y)
			# 금지 사각형 안: 불꽃(밝거나 진한 비금색) 픽셀은 그대로 둠
			if _inban(ban, Vector2(x, y)): continue
			var d := p.distance_to(Hc)
			if d >= r2: continue
			var w := 1.0 - smoothstep(r1, r2, d)
			# 기준점 아래(몸 쪽)는 거의 건드리지 않음
			if y > A.y: w *= 1.0 - smoothstep(A.y, A.y + 60.0, float(y))
			if w <= 0.001: continue
			var se := lerpf(1.0, s, w)
			var q := A + (p - A) / se
			var c := bg
			if q.x >= 0 and q.y >= 0 and q.x < W - 1 and q.y < H - 1:
				# 쌍선형 샘플
				var x0 := int(q.x); var y0 := int(q.y); var fx := q.x - x0; var fy := q.y - y0
				var c00 := src.get_pixel(x0, y0); var c10 := src.get_pixel(x0 + 1, y0)
				var c01 := src.get_pixel(x0, y0 + 1); var c11 := src.get_pixel(x0 + 1, y0 + 1)
				c = c00.lerp(c10, fx).lerp(c01.lerp(c11, fx), fy)
				# 금지 사각형(불꽃·주사위) 안의 밝은 불꽃 색은 끌려오지 않게 배경으로
				if _inban(ban, q) and _glow(c): c = bg
			img.set_pixel(x, y, c)
	img.save_png(a[1])
	quit()

func _glow(c: Color) -> bool:
	var gold := c.h > 0.06 and c.h < 0.17
	return c.s > 0.3 and (c.v > 0.62 or c.s > 0.55) and not gold

# 금지 영역은 사각형에 내접하는 타원(불꽃+주사위 덩어리 모양)
func _inban(b: Rect2i, p: Vector2) -> bool:
	if b.size.x <= 0: return false
	var c := Vector2(b.position) + Vector2(b.size) / 2.0
	var d := (p - c) / (Vector2(b.size) / 2.0)
	return d.length() <= 1.0
