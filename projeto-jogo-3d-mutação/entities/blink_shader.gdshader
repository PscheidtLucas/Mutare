shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_back, unshaded;

// Quão forte o flash está (0 = nada, 1 = totalmente branco)
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Como estamos em blend_add, quando ALBEDO é preto (0,0,0), não adiciona nada
	// Quando é branco (1,1,1), adiciona branco por cima
	
	// Multiplica branco pelo hit_flash
	// hit_flash = 0 -> ALBEDO = (0,0,0) -> não adiciona nada (invisível)
	// hit_flash = 1 -> ALBEDO = (1,1,1) -> adiciona branco total
	ALBEDO = vec3(hit_flash);
	
	// Alpha controla a visibilidade do overlay
	ALPHA = hit_flash;
}