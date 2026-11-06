extends SceneTree
## tools/artgen/shadow_lift.gd — 너무 어두워 형태가 묻히는 '그림자' 몬스터를 다시 그리지 않고 보정(2026-11-06, rs18).
## 1) 어두운 몸 픽셀(명도 < vmax, 금장식·밝은 눈·불꽃 제외)의 명도를 V' = lo + (1-lo)*V^g 로 들어 올림 → 순서(명암 관계)는 유지, 형태 구분이 살아남.
## 2) 림 라이트: 흰 배경과 맞닿은 몸 가장자리 rim px 안쪽을 rim_color 쪽으로 밝힘(가장자리일수록 강하게).
## 사용: godot --headless --script shadow_lift.gd -- <입력(흰 배경)> <출력> <lo> <g> <rim px> <rim 강도> [vmax=0.55]
##   rim 색은 픽셀마다 원래 색조를 유지하고 명도·채도만 올린다(보라는 보라, 청록은 청록 림).

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var lo := float(a[2]); var g := float(a[3]); var rim := int(a[4]); var rk := float(a[5])
	var vmax := float(a[6]) if a.size() > 6 else 0.55
	var W := img.get_width(); var H := img.get_height()
	var src := img.duplicate() as Image
	# 배경 판정: 거의 흰색
	var bg := PackedByteArray(); bg.resize(W * H)
	for y in H:
		for x in W:
			var c := src.get_pixel(x, y)
			if c.v > 0.93 and c.s < 0.08: bg[y * W + x] = 1
	# 배경까지의 거리(체스판 거리, rim 이내만)
	# 2패스 체스판 거리 변환(배경=0)
	var dist := PackedInt32Array(); dist.resize(W * H)
	for i in W * H: dist[i] = 0 if bg[i] == 1 else 9999
	for y in H:
		for x in W:
			var i := y * W + x
			if dist[i] == 0: continue
			var m := dist[i]
			if x > 0: m = mini(m, dist[i - 1] + 1)
			if y > 0:
				m = mini(m, dist[i - W] + 1)
				if x > 0: m = mini(m, dist[i - W - 1] + 1)
				if x < W - 1: m = mini(m, dist[i - W + 1] + 1)
			dist[i] = m
	for y in range(H - 1, -1, -1):
		for x in range(W - 1, -1, -1):
			var i := y * W + x
			if dist[i] == 0: continue
			var m := dist[i]
			if x < W - 1: m = mini(m, dist[i + 1] + 1)
			if y < H - 1:
				m = mini(m, dist[i + W] + 1)
				if x < W - 1: m = mini(m, dist[i + W + 1] + 1)
				if x > 0: m = mini(m, dist[i + W - 1] + 1)
			dist[i] = m
	# 3) 국소 대비(클래리티): V += ck*(V - 박스블러(V, cr)) — 머리·팔·옷 경계의 명암 차를 키워 형태를 구분
	var ck := float(a[7]) if a.size() > 7 else 0.0
	var cr := int(a[8]) if a.size() > 8 else 12
	# 몸 픽셀(배경·금장식·밝은 부분 제외)만 평균에 넣는다 → 외곽선·장식 주변에 검은 테두리가 생기지 않음
	var integ := PackedFloat64Array(); integ.resize((W + 1) * (H + 1))
	var cnt := PackedFloat64Array(); cnt.resize((W + 1) * (H + 1))
	for y in H:
		var row := 0.0; var rn := 0.0
		for x in W:
			var c := src.get_pixel(x, y)
			var gold := c.h > 0.06 and c.h < 0.17 and c.s > 0.35 and c.v > 0.45
			if bg[y * W + x] == 0 and not gold and c.v < vmax: row += c.v; rn += 1.0
			integ[(y + 1) * (W + 1) + x + 1] = integ[y * (W + 1) + x + 1] + row
			cnt[(y + 1) * (W + 1) + x + 1] = cnt[y * (W + 1) + x + 1] + rn
	for y in H:
		for x in W:
			if bg[y * W + x] == 1: continue
			var c := src.get_pixel(x, y)
			if ck > 0.0 and c.v < vmax:
				var x0 := maxi(x - cr, 0); var x1 := mini(x + cr + 1, W); var y0 := maxi(y - cr, 0); var y1 := mini(y + cr + 1, H)
				var sm := integ[y1 * (W + 1) + x1] - integ[y0 * (W + 1) + x1] - integ[y1 * (W + 1) + x0] + integ[y0 * (W + 1) + x0]
				var n := cnt[y1 * (W + 1) + x1] - cnt[y0 * (W + 1) + x1] - cnt[y1 * (W + 1) + x0] + cnt[y0 * (W + 1) + x0]
				var mean := sm / maxf(n, 1.0)
				c = Color.from_hsv(c.h, c.s, clampf(c.v + ck * (c.v - mean), 0.0, vmax - 0.001), c.a)
			var gold := c.h > 0.06 and c.h < 0.17 and c.s > 0.35 and c.v > 0.45
			if gold or c.v >= vmax: continue
			var nv := vmax * (lo + (1.0 - lo) * pow(c.v / vmax, g))  # v=vmax에서 연속
			# 채도 없는 어두운 픽셀(입속·선)은 올리면 회색 '구멍'처럼 보임 → 거의 그대로 둔다(rs19 이빨 사이 구멍 원인)
			nv = lerpf(c.v, nv, smoothstep(0.12, 0.3, c.s))
			var ns := c.s
			var d := dist[y * W + x]
			if d <= rim:
				var t := rk * (1.0 - float(d - 1) / rim)
				nv = lerpf(nv, minf(nv + 0.35, 0.9), t)
				ns = lerpf(ns, minf(ns + 0.15, 0.8), t)
			img.set_pixel(x, y, Color.from_hsv(c.h, ns, nv, c.a))
	img.save_png(a[1])
	quit()
