extends SceneTree
## tools/artgen/priest_scars.gd — 심연의 사제 로컬 수정(디자인 유지용): GPT 재생성 없이
##  (1) 옷 중앙 패널의 눈 문양 블록과 그 위 빈 패널 블록을 맞바꿔 문양을 복부 쪽으로 올리고,
##  (2) 피부 위에만 X자 흉터를 그린다(피부 = 불투명·밝고 채도 낮은 픽셀).
## 사용: godot --headless --script priest_scars.gd -- <입력> <출력>

const PANEL_X := Vector2i(362, 470)       # 옷 중앙 패널 가로 범위(원본 1024×1536 기준)
const EMBLEM := Vector2i(838, 990)        # 눈 문양 프레임 y 범위
const TARGET_Y := 605                     # 옮길 위치(복부)
const PLAIN_Y := 680                      # 빈 패널 한 줄을 샘플할 y

# [중심 x, 중심 y, 반길이, 회전(도)] — 원본 좌표
const SCARS := [
	[350, 400, 20, 8], [470, 420, 18, -10], [455, 330, 14, 0],
	[510, 585, 22, 12],
	[325, 715, 24, -6], [340, 850, 22, 10], [318, 910, 18, -14],
	[548, 752, 22, 5], [620, 790, 26, -8], [600, 905, 24, 14], [640, 925, 22, -4], [672, 950, 20, 20], [710, 1075, 22, -10],
	[315, 1100, 20, 6], [325, 1160, 16, -12], [742, 1140, 15, 0],
]

func _skin(c: Color) -> bool:
	return c.a > 0.9 and c.v > 0.78 and c.s < 0.16


func _stroke(img: Image, mask: Image, p0: Vector2, p1: Vector2, bend: float) -> void:
	var n := int(p0.distance_to(p1) * 2.0)
	var nrm := (p1 - p0).orthogonal().normalized()
	for i in n + 1:
		var t := float(i) / n
		var p := p0.lerp(p1, t) + nrm * bend * sin(t * PI)
		var w := 1.5 * sin(t * PI) + 0.5   # 가운데가 굵고 끝이 가는 상처(기존 흉터 굵기에 맞춤)
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var q := Vector2i(int(p.x) + dx, int(p.y) + dy)
				if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height(): continue
				if mask.get_pixel(q.x, q.y).r < 0.5: continue
				var d := Vector2(dx, dy).length()
				var base := img.get_pixel(q.x, q.y)
				if d <= w:
					img.set_pixel(q.x, q.y, base.lerp(Color(0.66, 0.16, 0.24, 1), clampf(1.2 - d / (w + 0.01) * 0.4, 0.0, 0.92)))
				elif d <= w + 1.0:
					img.set_pixel(q.x, q.y, base.lerp(Color(0.86, 0.55, 0.62, 1), 0.25))


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	# (1) 눈 문양 프레임을 복부로 옮기고, 원래 자리는 빈 패널 한 줄을 반복해 메운다
	var w := PANEL_X.y - PANEL_X.x
	var h := EMBLEM.y - EMBLEM.x
	var emblem := img.get_region(Rect2i(PANEL_X.x, EMBLEM.x, w, h))
	var row := img.get_region(Rect2i(PANEL_X.x, PLAIN_Y, w, 1))
	for y in range(EMBLEM.x, EMBLEM.y):
		img.blit_rect(row, Rect2i(0, 0, w, 1), Vector2i(PANEL_X.x, y))
	img.blit_rect(emblem, Rect2i(0, 0, w, h), Vector2i(PANEL_X.x, TARGET_Y))
	# (2) 피부 마스크(흉터를 그리기 전 상태 기준)
	var mask := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_L8)
	for y in img.get_height():
		for x in img.get_width():
			mask.set_pixel(x, y, Color.WHITE if _skin(img.get_pixel(x, y)) else Color.BLACK)
	for s in SCARS:
		var c := Vector2(s[0], s[1]); var r: float = s[2]; var rot := deg_to_rad(float(s[3]))
		var d1 := Vector2(r, r).rotated(rot); var d2 := Vector2(r, -r).rotated(rot)
		_stroke(img, mask, c - d1, c + d1, r * 0.12)
		_stroke(img, mask, c - d2, c + d2, -r * 0.1)
	img.save_png(a[1])
	quit()
