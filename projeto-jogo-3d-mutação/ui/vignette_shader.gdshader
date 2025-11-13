shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float radius    : hint_range(0.0, 1.0) = 0.6;  // onde começa a borda escurecida
uniform float softness  : hint_range(0.001, 0.5) = 0.25; // largura da transição

void fragment() {
	// UV é 0..1 cobrindo o ColorRect — confiável e independente da resolução
	vec2 d = UV - vec2(0.5);
	float dist = length(d); // distância do centro (0..~0.7 dependendo do aspect)
	// smoothstep(edge0, edge1, x): 0 quando x <= edge0, 1 quando x >= edge1
	float vign = smoothstep(radius - softness, radius, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vign * intensity);
}
