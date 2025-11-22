class_name EvoPopupLabel
extends Label

@export var fade_duration: float = 1.5
@export var float_distance: float = 150.0

# Quanto tempo entre o spawn de cada label (ex.: 0.4s)
@export var spawn_delay_step: float = 0.4

# Quanto descer por "degrau" (ex.: 20px)
@export var vertical_step: float = 22.0


func setup_and_animate(pos: Vector2, text_content: String, delay: float = 0.0) -> void:
	modulate.a = 0.0
	text = text_content

	# Delay inicial para spawn
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	scale = Vector2.ZERO

	reset_size()
	await get_tree().process_frame

	# Centraliza
	global_position = pos - (size / 2.0)


	# ----------------------------------------------------------------------
	# Cálculo do deslocamento vertical baseado no delay
	# ----------------------------------------------------------------------
	var final_step_index : float = delay / spawn_delay_step
	var final_y_offset : float = final_step_index * vertical_step
	
	# Posição final real onde cada label deve "estacionar"
	var base_target_y : float = global_position.y - float_distance
	var final_target_y : float = base_target_y + final_y_offset


	# ----------------------------------------------------------------------
	# TWEEN DE ENTRADA (Pop + Subida)
	# ----------------------------------------------------------------------
	var t_in = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	t_in.tween_property(self, "scale", Vector2.ONE, 0.3)
	t_in.tween_property(self, "modulate:a", 1.0, 0.2)

	# Subida inicial até mais ou menos a zona final (sem frear ainda)
	t_in.tween_property(self, "global_position:y", final_target_y, fade_duration).set_trans(Tween.TRANS_CUBIC)


	# ----------------------------------------------------------------------
	# TWEEN DE FREIADA (leve amortecimento no final)
	# ----------------------------------------------------------------------
	var t_brake = t_in.chain().set_parallel(false)  # começa após entrada

	t_brake.tween_property(
		self,
		"global_position:y",
		final_target_y,  # passa um pouco
		3.0
	).set_ease(Tween.EASE_OUT)



	# ----------------------------------------------------------------------
	# TWEEN DE SAÍDA ( fade)
	# ----------------------------------------------------------------------
	var t_out = t_brake.chain().set_parallel(false)

	# Drift lento (opcional)

	# Fade depois de 3 segundos parado
	t_out.tween_property(self, "modulate:a", 0.0, 1.5)

	t_out.chain().tween_callback(queue_free)
