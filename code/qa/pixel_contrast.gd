extends SceneTree
## 시각 설계 기준 문서([대형 기획 17] S-0) 작업용 1회성 측정 도구.
##
## 캡처된 QA 스크린샷(PNG) 위의 작은 사각 영역 두 개(보통 "글자" 영역과 "배경" 영역)의
## 평균 색을 구해 WCAG 2.0 상대 휘도/대비비를 계산해 출력한다. CharacterTheme.
## relative_luminance()/contrast_ratio()와 완전히 같은 공식(코드 색상표가 아니라 실제
## 렌더된 픽셀을 측정하기 위해 독립적으로 재구현 — 계산식 자체는 WCAG 2.0 표준이라
## CharacterTheme와 100% 동일해야 함).
##
## 사용법:
##   godot4 --headless --script code/qa/pixel_contrast.gd -- <png_path> <x,y,w,h,label> [...]
## 라벨이 "text:"로 시작하면 "글자" 그룹, "bg:"로 시작하면 "배경" 그룹으로 모아 마지막에
## text/bg 쌍마다 대비비를 함께 계산해 출력한다(같은 접두어 뒤 이름이 같으면 짝).
## 예: text:button1,100,20,10,10  bg:button1,100,5,10,10

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: godot4 --headless --script code/qa/pixel_contrast.gd -- <png_path> <x,y,w,h,label> [...]")
		print("   or: godot4 --headless --script code/qa/pixel_contrast.gd -- --rgb <r,g,b,r,g,b,label> [...]")
		quit(1)
		return

	if args[0] == "--rgb":
		# 캡처 없이 소스 코드의 색 상수(StyleBoxFlat/Label font_color 등)끼리 바로 대비비를
		# 계산할 때 쓴다 — CharacterTheme.contrast_ratio()와 동일한 WCAG 공식.
		for i in range(1, args.size()):
			var parts := args[i].split(",")
			if parts.size() < 7:
				print("skip (need r,g,b,r,g,b,label): ", args[i])
				continue
			var c1 := Color(float(parts[0]), float(parts[1]), float(parts[2]))
			var c2 := Color(float(parts[3]), float(parts[4]), float(parts[5]))
			var label: String = parts[6]
			var l1 := _relative_luminance(c1)
			var l2 := _relative_luminance(c2)
			var lighter: float = max(l1, l2)
			var darker: float = min(l1, l2)
			var ratio: float = (lighter + 0.05) / (darker + 0.05)
			print("%s: c1=%s c2=%s ratio=%.2f:1 %s" % [label, c1, c2, ratio, "(PASS >=4.5)" if ratio >= 4.5 else "(FAIL <4.5)"])
		quit(0)
		return

	var path := args[0]
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		print("load error: ", err, " path=", path)
		quit(1)
		return

	var results := {}
	for i in range(1, args.size()):
		var spec: String = args[i]
		var parts := spec.split(",")
		if parts.size() < 5:
			print("skip (need x,y,w,h,label): ", spec)
			continue
		var x := int(parts[0])
		var y := int(parts[1])
		var w := int(parts[2])
		var h := int(parts[3])
		var label: String = parts[4]
		var avg := _avg_color(img, x, y, w, h)
		var avg_lum := _relative_luminance(avg)
		var extreme := _extreme_luminance(img, x, y, w, h)
		# text 영역은 안티앨리어싱 때문에 평균이 실제 글자 색보다 어둡게 나오므로
		# "가장 밝은 픽셀"(글자 중심부 — 어두운 바탕에 밝은 글자 전제)을 글자색으로 쓴다.
		# bg 영역은 "가장 어두운 픽셀"(장식/빛 번짐이 섞이지 않은 순수 배경)을 배경색으로 쓴다.
		var sample_lum: float = extreme["max"] if label.begins_with("text:") else extreme["min"]
		results[label] = {"avg": avg, "lum": avg_lum, "sample_lum": sample_lum}
		print("%s rect=(%d,%d,%d,%d) avg_rgb=(%.3f,%.3f,%.3f) avg_luminance=%.4f sample_luminance=%.4f min=%.4f max=%.4f" % [label, x, y, w, h, avg.r, avg.g, avg.b, avg_lum, sample_lum, extreme["min"], extreme["max"]])
		if label.begins_with("local:"):
			var ratio: float = (extreme["max"] + 0.05) / (extreme["min"] + 0.05)
			print(">>> contrast[%s] (글자 최대밝기 vs 그 상자 안 최소밝기) = %.2f : 1 %s" % [label.substr(6), ratio, "(PASS >=4.5)" if ratio >= 4.5 else "(FAIL <4.5)"])

	# text:<name> / bg:<name> 짝 자동 대비비 계산 (sample_luminance 기준 — 실제 글자/배경에
	# 더 가까운 극값 사용)
	for label in results.keys():
		if label.begins_with("text:"):
			var name: String = label.substr(5)
			var bg_label := "bg:" + name
			if results.has(bg_label):
				var l1: float = results[label]["sample_lum"]
				var l2: float = results[bg_label]["sample_lum"]
				var lighter: float = max(l1, l2)
				var darker: float = min(l1, l2)
				var ratio: float = (lighter + 0.05) / (darker + 0.05)
				print(">>> contrast[%s] = %.2f : 1 %s" % [name, ratio, "(PASS >=4.5)" if ratio >= 4.5 else "(FAIL <4.5)"])

	quit(0)


func _avg_color(img: Image, x: int, y: int, w: int, h: int) -> Color:
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var a := 0.0
	var count := 0
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx < 0 or yy < 0 or xx >= img.get_width() or yy >= img.get_height():
				continue
			var c := img.get_pixel(xx, yy)
			r += c.r
			g += c.g
			b += c.b
			a += c.a
			count += 1
	if count == 0:
		return Color(0, 0, 0, 0)
	return Color(r / count, g / count, b / count, a / count)


## rect 안에서 가장 밝은/가장 어두운 픽셀의 상대 휘도(각각 min/max 키)를 돌려준다.
func _extreme_luminance(img: Image, x: int, y: int, w: int, h: int) -> Dictionary:
	var lo := 1.0
	var hi := 0.0
	var found := false
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx < 0 or yy < 0 or xx >= img.get_width() or yy >= img.get_height():
				continue
			var lum := _relative_luminance(img.get_pixel(xx, yy))
			lo = min(lo, lum)
			hi = max(hi, lum)
			found = true
	if not found:
		return {"min": 0.0, "max": 0.0}
	return {"min": lo, "max": hi}


func _linearize(c: float) -> float:
	if c <= 0.03928:
		return c / 12.92
	return pow((c + 0.055) / 1.055, 2.4)


func _relative_luminance(c: Color) -> float:
	return 0.2126 * _linearize(c.r) + 0.7152 * _linearize(c.g) + 0.0722 * _linearize(c.b)
