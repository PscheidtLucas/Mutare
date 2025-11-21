class_name FloatingTextSpawner
extends Node3D

@export var label_appear_radius: float = 1.5
@export var label_height_offset: float = 0.0 # Ajuste isso baseando-se na posição do Nó na cena
@export var font_size_normal: int = 140
@export var font_size_crit: int = 150

func show_value(amount: float, is_heal: bool, is_crit: bool = false) -> void:
	if amount <= 0.0:
		return

	var label_3d := Label3D.new()
	
	# Calcula posição aleatória ao redor
	var rand_angle := randf() * TAU
	var radius := sqrt(randf()) * label_appear_radius
	var offset := Vector3(radius * cos(rand_angle), 0.0, radius * sin(rand_angle))
	
	# Adiciona à cena principal (para não girar com o pai)
	get_tree().current_scene.add_child(label_3d)
	
	# Conecta limpeza automática
	# Tenta conectar ao GameEvents se ele existir no seu projeto, senão usa apenas o tween
	if GameEvents.has_signal("wave_survived"):
		GameEvents.wave_survived.connect(label_3d.queue_free)

	# Configuração Visual
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.outline_size = 50
	label_3d.no_depth_test = true
	
	# Posição inicial (Baseada na posição deste Componente + Offset)
	label_3d.global_position = global_position + Vector3(0, label_height_offset, 0) + offset

	var text_value: String
	if fmod(amount, 1.0) == 0.0:
		text_value = str(int(amount)) # Ex: Mostra "5"
	else:
		text_value = "%.1f" % amount # Ex: Mostra "0.6"

	# Configuração de Texto e Cor
	if is_heal:
		label_3d.text = "+" + text_value
		label_3d.modulate = Color.GREEN
		label_3d.outline_modulate = Color.DARK_GREEN
		label_3d.font_size = font_size_normal
	else:
		label_3d.text = "-" + text_value
		label_3d.modulate = Color.RED
		label_3d.outline_modulate = Color.DARK_RED
		
		if is_crit:
			label_3d.font_size = font_size_crit
			label_3d.modulate = Color(1.0, 0.85, 0.1, 1.0)
		else:
			label_3d.font_size = font_size_normal

	_animate_label(label_3d)

func _animate_label(label: Label3D) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Sobe
	tween.tween_property(label, "position:y", label.position.y + 1.5, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Pop Effect (Escala)
	label.scale = Vector3.ZERO
	tween.tween_property(label, "scale", Vector3.ONE, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Fade Out e Delete
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)
