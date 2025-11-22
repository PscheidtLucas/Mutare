extends Node

const SAVE_PATH := "user://high_score.tres"
const DEFAULT_RESOURCE := preload("res://data/high_score_resource.tres")

var game_state : GameState = preload("uid://bpsmw37wyl1vp")

var high_score: HighScore

func _ready() -> void:
	GameEvents.player_died.connect(update_highest_wave)
	_load_high_score()

func _load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		high_score = ResourceLoader.load(SAVE_PATH)
	else:
		high_score = DEFAULT_RESOURCE.duplicate()
		save()

func save() -> void: 
	ResourceSaver.save(high_score, SAVE_PATH)

func update_highest_wave() -> void:
	var current_wave:= game_state.wave_number
	if current_wave > high_score.highest_wave:
		high_score.highest_wave = current_wave
		save()
