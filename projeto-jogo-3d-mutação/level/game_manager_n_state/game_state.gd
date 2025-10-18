class_name GameState extends Resource

@export var wave_number: int = 1

@export var time_left: float = 0.0

func increase_wave_numb() -> void:
	wave_number += 1

func reset_wave_numer() -> void:
	wave_number = 1
