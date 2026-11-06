extends SceneTree
## tools/artgen/leg_guide.gd — 거미 다리 구조도(독거미, 2026-11-06). 원화를 흐리게 깔고 8개 다리를 뿌리→무릎→끝 선으로 그린다.
## 가까운 쪽 다리 = 빨강 굵은 실선(몸 앞에 보임), 먼 쪽 다리 = 하늘색 가는 선(몸 뒤, 몸에 가리는 구간은 점선), 뿌리 = 노란 점, 무릎 = 흰 점.
## 사용: godot --headless --script leg_guide.gd -- <원화> <출력>
const NEAR := [[Vector2(300,790),Vector2(170,700),Vector2(40,1150)],[Vector2(370,815),Vector2(330,735),Vector2(330,1160)],[Vector2(455,815),Vector2(560,735),Vector2(690,1150)],[Vector2(535,800),Vector2(770,690),Vector2(1040,1110)]]
const FAR := [[Vector2(310,740),Vector2(210,650),Vector2(40,960)],[Vector2(390,735),Vector2(300,640),Vector2(190,1010)],[Vector2(560,735),Vector2(720,640),Vector2(860,1020)],[Vector2(620,730),Vector2(950,650),Vector2(1150,1040)]]
var img: Image
func _disc(c: Vector2, r: float, col: Color) -> void:
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			if Vector2(x, y).distance_to(c) <= r and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height(): img.set_pixel(x, y, col)
func _seg(a: Vector2, b: Vector2, w: float, col: Color, dash: bool) -> void:
	var n := int(a.distance_to(b))
	for i in n:
		if dash and (i / 14) % 2 == 1: continue
		_disc(a.lerp(b, float(i) / n), w, col)
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	img = Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(0.08, 0.08, 0.1).lerp(c, 0.35 * c.a))
	for L in FAR:
		_seg(L[0], L[1], 4, Color(0.3, 0.8, 1.0), true)
		_seg(L[1], L[2], 4, Color(0.3, 0.8, 1.0), false)
		_disc(L[0], 9, Color(1, 0.85, 0.1)); _disc(L[1], 7, Color.WHITE)
	for L in NEAR:
		_seg(L[0], L[1], 8, Color(1, 0.15, 0.2), false)
		_seg(L[1], L[2], 8, Color(1, 0.15, 0.2), false)
		_disc(L[0], 11, Color(1, 0.85, 0.1)); _disc(L[1], 8, Color.WHITE)
	img.save_png(a[1]); quit()
