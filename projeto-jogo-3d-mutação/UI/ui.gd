class_name UI extends CanvasLayer


@export var player_stats : PlayerStats
@export var game_state: GameState

@onready var time_left_label: Label = %TimeLeftLabel
@onready var reward_manager_screen: RewardManager = %RewardManagerScreen

@onready var lose_label: Label = %LoseLabel
@onready var restart_button: Button = %RestartButton

@onready var health_ui: Label = %HealthUI

@export var nodes_to_hide_in_start: Array[Control]

func _ready() -> void:
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
	# Atualiza o display do tempo restante a cada frame
	update_time_display()

func update_time_display() -> void:
	var time_remaining = int(game_state.time_left)
	time_left_label.text = str(time_remaining)

# Manages what happens with UI elements when player finishes a wave (wins)
func on_wave_survived() -> void:
	# Pausa toda a árvore de cenas
	get_tree().paused = true
	time_left_label.hide()

func on_wave_started() -> void:
	for node in nodes_to_hide_in_start:
		node.show()

# Manages what happens with UI elements when player dies # TODO Nada disso acontece acredito eu, colocar pra 5 de vida pra testar
func on_player_lost() -> void:
	get_tree().paused = true
	
	time_left_label.hide()
	lose_label.show()
	restart_button.show()

func _on_player_health_changed() -> void:
	health_ui.text = str("%0.0f" % (player_stats.health)) 

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
