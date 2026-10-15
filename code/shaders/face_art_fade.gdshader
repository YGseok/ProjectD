shader_type canvas_item;

// [미니 기획 ART-2] 상반신 표정 컷(원화)이 가슴께에서 끊긴 정사각 텍스처라, 그대로
// 쓰면 아래쪽이 일직선으로 뚝 잘린 것처럼 보인다(INBOX ART-2, qa_out/
// art1b_novice_after_exchange.png). 텍스처 아래 fade_start~1.0 구간만 알파를
// 0까지 줄여 배경(퍼스널 컬러 배경/비네트)에 자연스럽게 녹아들게 한다.
uniform float fade_start : hint_range(0.0, 1.0) = 0.76;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float fade = 1.0 - smoothstep(fade_start, 1.0, UV.y);
	COLOR = vec4(tex_color.rgb, tex_color.a * fade);
}
