extends SceneTree
## tools/artgen/spider_compose.gd — 독거미: 확정 상체(rs36)는 절대 다시 그리지 않고, 다리·배(거미 몸통)만 다른 판(rs45)에서 가져와 합친다(2026-11-06, rs49).
## 두 판은 같은 캔버스·같은 위치(정렬 오프셋 0,0 확인).
## 규칙: (1) y < top_y 또는 상체 다각형 안 → A(상체 원본)
##       (2) 경계 구역(허리띠·고리 근처) → 두 판 모두 피부면 A, B가 허리띠/고리(피부 아님)면 B
##       (3) 나머지 → B. 경계는 mask 를 r px 상자 흐림으로 섞는다.
## 사용: godot --headless --script spider_compose.gd -- <A 상체 원본> <B 다리 판> <출력> [마스크 미리보기 출력]

const TOP_Y := 390
# 상체 영역(머리카락·팔·몸통). 배(거미 몸통) 왼쪽 가장자리와 다리 무릎을 피해서 잡음.
const BODY := [Vector2(0, 390), Vector2(690, 390), Vector2(665, 520), Vector2(610, 600), Vector2(580, 650),
	Vector2(560, 640), Vector2(520, 650), Vector2(230, 640), Vector2(0, 625)]
const ZONE := Rect2i(225, 600, 380, 200)
const FEATHER := 3

func _skin(c: Color) -> bool:
	return c.a > 0.5 and c.h > 0.015 and c.h < 0.11 and c.s > 0.3 and c.v > 0.42

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var A := Image.load_from_file(a[0]); A.convert(Image.FORMAT_RGBA8)
	var B := Image.load_from_file(a[1]); B.convert(Image.FORMAT_RGBA8)
	var W := A.get_width(); var H := A.get_height()
	var poly := PackedVector2Array(BODY)
	var m := PackedFloat32Array(); m.resize(W * H)
	for y in H:
		for x in W:
			var v := 0.0
			if y < TOP_Y or Geometry2D.is_point_in_polygon(Vector2(x, y), poly): v = 1.0
			if ZONE.has_point(Vector2i(x, y)):
				var ca := A.get_pixel(x, y); var cb := B.get_pixel(x, y)
				if _skin(cb) and _skin(ca): v = 1.0
				elif not _skin(cb): v = 0.0 if y > 640 else v
			m[y * W + x] = v
	# 상자 흐림으로 경계 섞기
	var mb := m.duplicate()
	for y in H:
		for x in W:
			var s := 0.0; var n := 0
			for dy in range(-FEATHER, FEATHER + 1):
				for dx in range(-FEATHER, FEATHER + 1):
					var xx := clampi(x + dx, 0, W - 1); var yy := clampi(y + dy, 0, H - 1)
					s += m[yy * W + xx]; n += 1
			mb[y * W + x] = s / n
	var o := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			o.set_pixel(x, y, B.get_pixel(x, y).lerp(A.get_pixel(x, y), mb[y * W + x]))
	o.save_png(a[2])
	if a.size() > 3:
		var pv := Image.create(W, H, false, Image.FORMAT_RGBA8)
		for y in H:
			for x in W:
				var c := o.get_pixel(x, y); var k := mb[y * W + x]
				pv.set_pixel(x, y, Color(c.r * 0.6 + 0.4 * k, c.g * 0.6, c.b * 0.6 + 0.4 * (1.0 - k), 1))
		pv.save_png(a[3])
	quit()
