class_name UI extends CanvasLayer
const MY_MAIN_MENU = preload("uid://c6k5nnpbypshi")
@export var player_stats : PlayerStats
@export var game_state: GameState
@onready var time_left_label: Label = %TimeLeftLabel
@onready var reward_manager_screen: RewardManager = %RewardManagerScreen
@onready var wave_number_container: MarginContainer = %WaveNumberContainer
@onready var game_over_anchor: Control = %GameOverAnchor
@onready var health_ui: Label = %HealthUI
@export var nodes_to_hide_in_start: Array[Control]

var last_time_value: int = -1
var countdown_tween: Tween

func _ready() -> void:
	game_over_anchor.hide()
	if player_stats:
		health_ui.text = str("%0.0f" % (player_stats.health))
	for node in nodes_to_hide_in_start:
		node.hide()
	
	GameEvents.wave_survived.connect(on_wave_survived)
	GameEvents.player_died.connect(on_player_lost)
	player_stats.health_changed.connect(_on_player_health_changed)
	GameEvents.wave_started.connect(on_wave_started)
	
	update_time_display()

func _process(delta: float) -> void:
	update_time_display()

func update_time_display() -> void:
	var time_remaining = int(game_state.time_left)
	time_left_label.text = str(time_remaining)
	
	# Detecta quando o tempo muda e aplica o tween nos segundos 3, 2, 1 e 0
	if time_remaining != last_time_value:
		last_time_value = time_remaining
		
		if time_remaining >= 0 and time_remaining <= 3:
			apply_countdown_tween()

func apply_countdown_tween() -> void:
	# Cancela o tween anterior se existir
	if countdown_tween:
		countdown_tween.kill()
	
	# Reseta a escala para o valor original
	time_left_label.scale = Vector2.ONE
	
	# Cria um novo tween
	countdown_tween = create_tween()
	countdown_tween.set_ease(Tween.EASE_OUT)
	countdown_tween.set_trans(Tween.TRANS_BOUNCE)
	
	# Escala para 2x em 0.3 segundos
	countdown_tween.tween_property(time_left_label, "scale", Vector2(2.0, 2.0), 0.3)
	# Volta para o tamanho original em 0.4 segundos
	countdown_tween.tween_property(time_left_label, "scale", Vector2.ONE, 0.4)

func on_wave_survived() -> void:
	get_tree().set_deferred("paused", true)
	for node in nodes_to_hide_in_start:
		node.hide()
	
	# Reseta o controle do countdown
	reset_countdown()

func on_wave_started() -> void:
	for node in nodes_to_hide_in_start:
		node.show()
	
	# Reseta o countdown para a nova wave
	reset_countdown()

func reset_countdown() -> void:
	# Cancela qualquer tween ativo
	if countdown_tween:
		countdown_tween.kill()
	
	# Reseta a escala da label
	time_left_label.scale = Vector2.ONE
	
	# Reseta o controle de tempo
	last_time_value = -1
	
const GAME_OVER_SOUND = preload("uid://dyjb8bpxucnk5")
func on_player_lost() -> void:
	AudioManager.play_sfx(GAME_OVER_SOUND, 5)
	AudioManager.set_music_paused(true)
	get_tree().set_deferred("paused", true)
	
	wave_number_container.hide()
	time_left_label.hide()
	game_over_anchor.show()
	
	# Limpa o tween quando o jogador perde
	reset_countdown()

func _on_player_health_changed() -> void:
	health_ui.text = str("%0.0f" % (player_stats.health)) 

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(MY_MAIN_MENU)
