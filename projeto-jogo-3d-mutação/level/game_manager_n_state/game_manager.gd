class_name GameManager extends Node

const JOGO_MUTARE = preload("uid://bvfuj7sx36s5f")
const MENU_MUTARE = preload("uid://cpm1ksmrdh5ca")

@export var game_state: GameState

var wave_timer : Timer
var wave_starting_duration := 50.0

func _ready() -> void:
	DnaManager.current_dna = 0
	AudioManager.set_music_paused(false)
	AudioManager.play_music(MENU_MUTARE)
	game_state.cycle_number = 0
	game_state.reset_wave_number()
	
	GameEvents.wave_started.connect(on_wave_started)
	GameEvents.wave_survived.connect(on_wave_survived)
	GameEvents.player_died.connect(on_player_lost)
	
	# --- CORREÇÃO 1: Crie o Timer UMA VEZ SÓ aqui ---
	wave_timer = Timer.new()
	wave_timer.one_shot = true
	wave_timer.timeout.connect(on_level_timer_timeout)
	add_child(wave_timer)
	# ------------------------------------------------
	
	get_tree().set_deferred("paused", true)

# --- CORREÇÃO 2: Função add_and_setup_wave_timer REMOVIDA (não é mais necessária) ---

func calculate_total_wave_duration() -> float:
	match game_state.get_wave_in_cycle():
		1: return 20.0
		2: return 22.5
		3: return 25.0
		4: return 27.5
		5: return 30.0
		6: return 32.5
		7: return 35.0
		8: return 37.5
		9: return 40.0
		10: return 45.0
	return 50.0

func _process(_delta: float) -> void:
	# Segurança extra para não crashar se o timer não estiver rodando
	if wave_timer and not wave_timer.is_stopped():
		game_state.time_left = int(wave_timer.time_left)

func on_level_timer_timeout() -> void:
	# --- CORREÇÃO 3: NUNCA use queue_free() aqui ---
	# O timer para sozinho porque é one_shot. Deixe ele vivo para a próxima wave.
	if PlayerManager.player.is_alive():
		check_if_cycle_ended()

func check_if_cycle_ended() -> void:
	AudioManager.play_music(MENU_MUTARE)
	if game_state.is_end_of_cycle():
		GameEvents.cycle_cleared.emit()
		game_state.increase_wave_numb()
		get_tree().set_deferred("paused", true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		game_state.increase_wave_numb()
		GameEvents.wave_survived.emit()

func on_wave_started():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.play_music(JOGO_MUTARE)
	
	# --- CORREÇÃO 4: Apenas atualize o tempo e dê Start ---
	var new_duration = calculate_total_wave_duration()
	wave_timer.wait_time = new_duration
	wave_timer.start()
	print("Nova wave iniciada. Duração: ", new_duration)
	# ------------------------------------------------------

func on_wave_survived():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_time_left() -> float:
	if wave_timer:
		return wave_timer.time_left
	return 0.0

func on_player_lost() -> void:
	if wave_timer:
		wave_timer.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
