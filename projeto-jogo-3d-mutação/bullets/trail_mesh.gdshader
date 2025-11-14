shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform vec4 trail_color : source_color = vec4(1.0, 0.6, 0.2, 1.0);
uniform float width : hint_range(0.01, 2.0) = 0.35;
uniform float fade_length : hint_range(0.1, 5.0) = 1.6;
uniform float scroll_speed : hint_range(0.0, 10.0) = 4.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.25;
uniform sampler2D noise_tex : source_color;

// opcional: deixa o rastro mais suave (0 = linear, 1 = curva suave)
uniform float smoothness : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	// uv.y = comprimento do trail
	// uv.x = largura do trail
	float u = UV.x;
	float v = UV.y;

	float scroll = fract(v - TIME * scroll_speed);

	// noise para distorcer o rastro um pouco
	float n = texture(noise_tex, vec2(u * 2.0, v * 2.0 + TIME)).r * noise_strength;

	// fade para o fundo do rastro
	float tail = clamp(1.0 - (v * fade_length), 0.0, 1.0);

	// suavização opcional
	if (smoothness > 0.0) {
		tail = pow(tail, mix(1.0, 2.5, smoothness));
	}

	// bordas da largura
	float edge = smoothstep(1.0, 1.0 - width, abs(u * 2.0 - 1.0));

	vec4 final_color = trail_color;
	final_color.a *= tail * edge;
	final_color.rgb += n;

	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
