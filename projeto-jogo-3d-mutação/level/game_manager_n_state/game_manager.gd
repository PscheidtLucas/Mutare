class_name GameManager extends Node
# TODO: 
# Arrumar o escalonamento da dificuldade e o process

@export var game_state: GameState

var wave_timer : Timer
var wave_starting_duration := 50.0


func _ready() -> void:
	game_state.reset_wave_number()
	GameEvents.wave_started.connect(on_wave_started)
	GameEvents.wave_survived.connect(on_wave_survived)
	GameEvents.player_died.connect(on_player_lost)
	
	wave_timer = Timer.new()
	wave_timer.wait_time = wave_starting_duration
	wave_timer.one_shot = true
	wave_timer.timeout.connect(on_level_timer_timeout)
	add_child(wave_timer)
	
	get_tree().set_deferred("paused", true)


func _process(_delta: float) -> void:
	if wave_timer.is_stopped():
		return
	game_state.time_left = int(get_time_left())
	

## Jogador conseguiu sobreviver ao tempo total da wave, agora devemos ver se deve já ir para a próxima ou habilitar a tela de evolução com cycle_cleared (sinal presente no GameEvents)
func on_level_timer_timeout() -> void:
	if PlayerManager.player.is_alive():
		check_if_cycle_ended()


func check_if_cycle_ended() -> void:
	if game_state.is_end_of_cycle():
		## Se sim, significa que estamos na wave 10, 20, 30... (Abre a tela de evolução para o jogador)
		GameEvents.cycle_cleared.emit()
		
		game_state.increase_wave_numb()
		
		get_tree().set_deferred("paused", true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		##  É uma wave normal, (1-9), (11-19)...
		game_state.increase_wave_numb()
		GameEvents.wave_survived.emit() ## Wave survived também é emitido no EvolveButtonManager, após uma evolução ser concluída
		

func on_wave_started():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	wave_timer.start()

func on_wave_survived():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_time_left() -> float:
	return wave_timer.time_left

func on_player_lost() -> void:
	wave_timer.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
