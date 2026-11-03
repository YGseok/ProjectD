extends SceneTree
## tools/artgen/panel_rebuild.gd — 심연의 사제 옷 중앙 패널을 끊김 없이 재배치한다(priest_scars.gd의 사각 블록 이동 대체).
## 패널(금테 사이)은 아래로 갈수록 살짝 넓어져서, 블록을 통째로 옮기면 금테가 어긋나 "뚝뚝 끊김"이 생겼다.
## 여기서는 출력 줄마다 원본의 어느 줄을 가져올지 정하고, 그 줄의 금테 바깥 가장자리를
## 목적지 줄의 금테 위치에 맞춰 가로로 늘이거나 줄여 붙인다(원본 픽셀만 사용, 새로 그리지 않음).
## 배치(원본 1024×1536 기준): 눈 문양 틀(830~1010) → 605부터, 그 아래 작은 마름모(775~830),
## 남는 구간은 장식 없는 패널(700~775)을 세로로 늘여 채우고, 1010부터는 원본(사슬 장식) 그대로.
## 사용: godot --headless --script panel_rebuild.gd -- <입력(new_abyss_priest/6/strict.png)> <출력>

const X0 := 340; const X1 := 495           # 금테 탐색 범위
const TOP := 605; const END := 1010
const EYE := Vector2i(830, 1010)
const DIA := Vector2i(775, 830)
const PLAIN := Vector2i(700, 775)   # 640~700은 허리띠 아래 V자 주름 그늘이 있어 제외

func _gold(c: Color) -> bool:
	return c.a > 0.5 and c.h > 0.05 and c.h < 0.14 and c.s > 0.28 and c.v > 0.6


func _edges(img: Image, y: int) -> Vector2i:
	var l := -1; var r := -1
	for x in range(X0, X0 + 60):
		if _gold(img.get_pixel(x, y)): l = x; break
	for x in range(X1, X1 - 60, -1):
		if _gold(img.get_pixel(x, y)): r = x; break
	return Vector2i(l, r)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var src := Image.load_from_file(a[0]); src.convert(Image.FORMAT_RGBA8)
	var out := src.duplicate() as Image
	# 줄별 금테 바깥 가장자리 → 21줄 중앙값으로 다듬는다(금테는 위·아래에서 기울기가 달라 직선 하나로는 안 맞고,
	# 줄별 값 그대로는 잡음으로 테두리가 들쭉날쭉해진다)
	var raw := {}
	var last := Vector2i(368, 461)
	for y in range(540, 1160):
		var e := _edges(src, y)
		if e.x < 0 or e.y < 0 or e.y - e.x < 60: e = last
		raw[y] = e; last = e
	var edge := {}
	for y in range(560, 1140):
		var l := []; var r := []
		for k in range(-10, 11):
			l.append(raw[y + k].x); r.append(raw[y + k].y)
		l.sort(); r.sort()
		edge[y] = Vector2i(l[10], r[10])
	# 허리띠·리본에 가린 윗부분(650 위)은 탐지가 흔들리므로 650~760의 기울기로 연장
	var slope := Vector2(edge[760] - edge[650]) / 110.0
	for y in range(560, 650):
		var v := Vector2(edge[650]) + slope * (y - 650)
		edge[y] = Vector2i(roundi(v.x), roundi(v.y))
	# 목적지 줄 → 원본 줄
	var eye_h := EYE.y - EYE.x; var dia_h := DIA.y - DIA.x
	var plain_top := TOP + eye_h + dia_h
	for y in range(TOP, END):
		var s: int
		if y < TOP + eye_h: s = EYE.x + (y - TOP)
		elif y < plain_top: s = DIA.x + (y - TOP - eye_h)
		else: s = PLAIN.x + int(float(y - plain_top) * (PLAIN.y - PLAIN.x) / float(END - plain_top))
		var ed: Vector2i = edge[y]; var es: Vector2i = edge[s]
		var dl := ed.x - 3; var dr := ed.y + 3; var sl := es.x - 3; var sr := es.y + 3
		for x in range(dl, dr + 1):
			var t := float(x - dl) / float(dr - dl)
			var sx := sl + t * (sr - sl)
			var x0 := int(floor(sx)); var f := sx - x0
			out.set_pixel(x, y, src.get_pixel(x0, s).lerp(src.get_pixel(x0 + 1, s), f))
	# 구간이 바뀌는 줄(명암이 달라 가로선이 생김): 금테 안쪽 남색 바탕만 위아래 ±10줄을 세로 평균으로 섞는다(금장식은 그대로)
	var ref := out.duplicate() as Image
	for b in [TOP + eye_h, plain_top, END]:
		for y in range(b - 10, b + 10):
			var ed: Vector2i = edge[y]
			for x in range(ed.x + 12, ed.y - 12):
				if _gold(ref.get_pixel(x, y)): continue
				var acc := Color(0, 0, 0, 0); var n := 0
				for k in range(-10, 11):
					var c := ref.get_pixel(x, y + k)
					if not _gold(c): acc += c; n += 1
				if n > 0: out.set_pixel(x, y, acc / n)
	out.save_png(a[1])
	quit()
