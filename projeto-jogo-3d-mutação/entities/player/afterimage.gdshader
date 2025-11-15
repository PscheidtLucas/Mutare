shader_type spatial;
render_mode unshaded, cull_back;

uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform vec3 color = vec3(0.3, 0.6, 1.0);

void fragment() {
	ALBEDO = color;
	ALPHA = fade;
}
