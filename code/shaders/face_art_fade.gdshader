shader_type canvas_item;

// [미니 기획 ART-2] 상반신 표정 컷(원화)이 가슴께에서 끊긴 정사각 텍스처라, 그대로
// 쓰면 아래쪽이 일직선으로 뚝 잘린 것처럼 보인다(INBOX ART-2, qa_out/
// art1b_novice_after_exchange.png). 텍스처 아래 fade_start~1.0 구간만 알파를
// 0까지 줄여 배경(퍼스널 컬러 배경/비네트)에 자연스럽게 녹아들게 한다.
uniform float fade_start : hint_range(0.0, 1.0) = 0.76;

// [미니 기획 ART-1c-3] 몬스터 쪽 크롭(full.png 상반신 크롭/face_* 컷 둘 다)은 플레이어
// 표정 컷과 달리 위·좌·우 가장자리가 직선으로 딱 잘려 사각형 상자처럼 보인다는 피드백
// (qa_out/art1c3_fallen_commander_before.png에서 확인) — 머리카락/망토/연기처럼 넓게
// 퍼진 몬스터(공허의 눈, 망령, 보스들)일수록 두드러진다. side_fade/top_fade 기본값을
// 0.0으로 둬 플레이어 쪽(값을 설정하지 않는 기존 호출부)은 기존 동작이 완전히 그대로
// 보존되고, 몬스터 쪽만 ShaderMaterial.set_shader_parameter()로 값을 켠다
// (monster_portrait_placeholder.gd의 _ensure_face_rect() 참고).
uniform float side_fade : hint_range(0.0, 0.5) = 0.0;
uniform float top_fade : hint_range(0.0, 0.5) = 0.0;

void fragment() {
	// [미니 기획 ART-1c-4] COLOR는 fragment() 진입 시점에 이미 "정점색 * 노드 modulate/
	// self_modulate"가 들어있다(Godot 기본 파이프라인) — 커스텀 fragment()가 COLOR를
	// 텍스처 샘플만으로 덮어쓰면 이 곱셈이 통째로 사라진다. 지금까지는 이 셰이더를 쓰는
	// 노드(_face_rect)가 modulate를 건드리지 않아(기본값 흰색 불투명) 안 드러났지만,
	// 외곽 글로우(_glow_rect)가 modulate로 색/알파(0.25~0.4)를 주면서 실제로 무시되는
	// 버그가 발견됐다(렌더 테스트: 기대 알파 0.32인데 실측 1.000). tex_color에 COLOR를
	// 곱해 Godot 기본 동작을 그대로 보존한다 — modulate를 안 쓰는 기존 호출부(기본값
	// 흰색 불투명)는 곱해도 항등원이라 결과가 완전히 그대로다.
	vec4 tex_color = texture(TEXTURE, UV) * COLOR;
	float fade_bottom = 1.0 - smoothstep(fade_start, 1.0, UV.y);
	float fade_top = top_fade > 0.0 ? smoothstep(0.0, top_fade, UV.y) : 1.0;
	float fade_left = side_fade > 0.0 ? smoothstep(0.0, side_fade, UV.x) : 1.0;
	float fade_right = side_fade > 0.0 ? smoothstep(0.0, side_fade, 1.0 - UV.x) : 1.0;
	float fade = fade_bottom * fade_top * fade_left * fade_right;
	COLOR = vec4(tex_color.rgb, tex_color.a * fade);
}
