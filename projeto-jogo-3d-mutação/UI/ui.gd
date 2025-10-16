class_name UI extends CanvasLayer

@onready var level_timer: Timer = %LevelTimer
@onready var time_left_label: Label = %TimeLeftLabel

@onready var reward_manager: Control = %RewardManager

@onready var lose_label: Label = %LoseLabel
@onready var restart_button: Button = %RestartButton

@onready var health_ui: Label = %HealthUI

@export var nodes_to_hide_in_start: Array[Control]

func _ready() -> void:
	health_ui.text = "HP: " + str(PlayerManager.player.health)
	for node in nodes_to_hide_in_start:
		node.hide()
	
	GameEvents.wave_survived.connect(on_wave_survived)
	GameEvents.player_died.connect(on_player_lost)
	GameEvents.player_took_damage.connect(_on_player_took_damage)
	
	level_timer.timeout.connect(on_level_timer_timeout)
	
	# Atualiza o timer a cada segundo
	update_time_display()

func _process(delta: float) -> void:
	# Atualiza o display do tempo restante a cada frame
	if level_timer.time_left > 0:
		update_time_display()

func update_time_display() -> void:
	var time_remaining = int(level_timer.time_left)
	time_left_label.text = str(time_remaining)

# Manages what happens with UI elements when player finishes a wave (wins)
func on_wave_survived() -> void:
	# Pausa toda a árvore de cenas
	get_tree().paused = true
	
	reward_manager.show()
	# Mostra UI de vitória
	time_left_label.hide()

# Manages what happens with UI elements when player dies
func on_player_lost() -> void:
	get_tree().paused = true
	
	level_timer.stop()
	time_left_label.hide()
	lose_label.show()
	restart_button.show()

func _on_player_took_damage() -> void:
	health_ui.text = "HP: " + str(PlayerManager.player.health)

func on_level_timer_timeout() -> void:
	GameEvents.wave_survived.emit()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
