shader_type canvas_item;

uniform float speed = 0.5;
uniform float distortion_strength = 0.03;
uniform float pulse_strength = 0.1;
uniform vec4 color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	// Amostra base (sem distorção)
	vec4 base_color = texture(TEXTURE, uv);

	// Calcula quão "branco" ou "azul" o pixel é
	float brightness = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
	float blueness = base_color.b - max(base_color.r, base_color.g);

	// Cria uma máscara: 1.0 = protegido (azul/branco), 0.0 = pode distorcer
	float protect_mask = 0.0;
	if (brightness > 0.6 || blueness > 0.1) {
		protect_mask = 1.0;
	}

	// Distorção só onde a máscara permite
	float wave_x = sin(uv.y * 6.0 + t) * 0.02;
	float wave_y = cos(uv.x * 4.0 - t * 1.3) * 0.02;
	vec2 distorted_uv = uv + vec2(wave_x, wave_y) * distortion_strength * (1.0 - protect_mask);

	vec4 tex = texture(TEXTURE, distorted_uv);

	// Pulso dinâmico no fundo (sem afetar partes protegidas)
	float pulse = sin(t * 2.0) * pulse_strength;
	vec3 pulse_color = tex.rgb + pulse * vec3(0.8, 0.3, 0.1) * (1.0 - protect_mask);

	// Resultado final
	COLOR = vec4(pulse_color, tex.a) * color_tint;
}
