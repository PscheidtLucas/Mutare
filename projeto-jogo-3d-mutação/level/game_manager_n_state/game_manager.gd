class_name GameManager extends Node
# TODO: Arrumar o jogador começando sem arma, arrumar que quando o nível termina o jogador recebe a arma mas ela nao atira, arrumar que 
# quando o jogador aperta para selecionar uma arma, os inimigos continuam todos onde estao (ou deixar assim, checar com o dimitri),
# arrumar erro do spawn enemy, tem q adicionar call defeered na hora de add child, o spawn de inimigos fica bem absurdo a partir da segunda wave
Lembrete
@export var game_state: GameState

var wave_timer : Timer
var wave_starting_duration := 50.0


func _ready() -> void:
	GameEvents.wave_started.connect(on_wave_started)
	GameEvents.player_died.connect(on_player_lost)
	
	wave_timer = Timer.new()
	wave_timer.wait_time = wave_starting_duration
	wave_timer.one_shot = true
	wave_timer.timeout.connect(on_level_timer_timeout)
	add_child(wave_timer)
	wave_timer.start()

func _process(delta: float) -> void:
	if wave_timer.is_stopped():
		return
	game_state.time_left = int(get_time_left())

func on_level_timer_timeout() -> void:
	if PlayerManager.player.is_alive():
		game_state.increase_wave_numb()
		GameEvents.wave_survived.emit()

func on_wave_started():
	wave_timer.start()

func get_time_left() -> float:
	return wave_timer.time_left

func on_player_lost() -> void:
	wave_timer.stop()
