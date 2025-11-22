extends Label
class_name WaveAnnouncer

@export var game_state: GameState

func _ready() -> void:
	visible = false
	# Conecta ao sinal global
	GameEvents.wave_started.connect(_on_wave_started)

func _on_wave_started() -> void:
	# AQUI ESTÁ O FILTRO:
	# get_wave_in_cycle() retorna 1 nas waves: 1, 11, 21, 31...
	if game_state.get_wave_in_cycle() == 1:
		
		# OPCIONAL: Se você NÃO quiser que apareça na primeiríssima wave do jogo (Wave 1),
		# descomente a linha abaixo:
		if game_state.wave_number == 1: 
			show_announcement(true) 
			return
		
		show_announcement()

func show_announcement(is_first_wave:= false) -> void:
	# 1. Configura o Texto
	# Como o wave_in_cycle é sempre 1 aqui, podemos mostrar apenas o Ciclo ou Cycle Start
	var cycle = game_state.cycle_number
	
	# Exemplo de texto: "CICLO 2 INICIADO" ou "ZONA DE PERIGO 2"
	if is_first_wave: text = "Cycle %d" % cycle + " Started"
	else: text = "Cycle %d " % cycle + " Started\nEnemies Got Stronger!"
	# 2. Prepara posições
	var viewport_height = get_viewport_rect().size.y
	var start_y = -size.y 
	var target_y = 120 # 1/3 da tela
	var end_y = viewport_height + size.y
	
	position.y = start_y
	visible = true
	
	# 3. Animação (Tween)
	var tween = create_tween()
	
	# Desce rápido para 1/3 da tela (0.5s) com efeito elástico
	tween.tween_property(self, "position:y", target_y, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Espera 4 segundos
	tween.tween_interval(2.0)
	
	# Sai rápido por baixo (0.5s)
	tween.tween_property(self, "position:y", end_y, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Esconde no final
	tween.tween_callback(func(): visible = false)
