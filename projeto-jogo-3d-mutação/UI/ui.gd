class_name UI extends CanvasLayer

@onready var level_timer: Timer = %LevelTimer
@onready var time_left_label: Label = %TimeLeftLabel
@onready var win_label: Label = %WinLabel
@onready var restart_button: Button = %RestartButton
@export var nodes_to_hide_in_start: Array[Control]

func _ready() -> void:
	for node in nodes_to_hide_in_start:
		node.hide()
	
	GlobalSignals.wave_survived.connect(on_wave_survived)
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

func on_wave_survived() -> void:
	# Pausa toda a árvore de cenas
	get_tree().paused = true
	
	# Mostra UI de vitória
	time_left_label.hide()
	win_label.show()
	restart_button.show()

func on_level_timer_timeout() -> void:
	GlobalSignals.wave_survived.emit()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
