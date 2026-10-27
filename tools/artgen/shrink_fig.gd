extends SceneTree
## tools/artgen/shrink_fig.gd — 규격 캔버스(1181×1332)는 그대로 두고 그림만 배율 S로 줄여 아래·가운데에 맞춰 놓는다.
## 같은 화면 배율에서 몸집이 작아 보여야 하는 몬스터용(예: 심연의 아이 키 2/3). 사용: -- <입력> <출력> <S>

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var img := Image.load_from_file(a[0]); img.convert(Image.FORMAT_RGBA8)
	var s := float(a[2])
	var w := img.get_width(); var h := img.get_height()
	var small := img.duplicate() as Image
	small.resize(int(w * s), int(h * s), Image.INTERPOLATE_LANCZOS)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blit_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), Vector2i((w - small.get_width()) / 2, h - small.get_height()))
	out.save_png(a[1])
	quit()
