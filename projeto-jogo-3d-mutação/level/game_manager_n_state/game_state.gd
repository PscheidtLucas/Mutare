class_name GameState extends Resource

@export var wave_number: int = 1
@export var cycle_number: int = 1 # Cycle 1: wave 1-10, Cycle 2: 11-20...
@export var time_left: float = 0.0

signal wave_number_changed


func increase_wave_numb() -> void:
	wave_number += 1
	
	if should_cycle_change():
		increase_cycle()
		
	wave_number_changed.emit()


func reset_wave_numer() -> void:
	wave_number = 1
	cycle_number = 1


func should_cycle_change() -> bool:
	if (wave_number - 1) % 10 == 0:
		return true
	return false


func increase_cycle() -> void:
	@warning_ignore("integer_division")
	cycle_number = ((wave_number - 1) / 10) + 1


# Verifica se estamos no fim de um ciclo (10, 20, 30...)
func is_end_of_cycle() -> bool:
	return wave_number % 10 == 0


# Retorna a wave "relativa" (1-10) para o spawner
func get_wave_in_cycle() -> int:
	var wave_in_cycle = wave_number % 10
	if wave_in_cycle == 0:
		return 10 # Wave 10, 20, 30... devem ser tratadas como 10
	return wave_in_cycle
