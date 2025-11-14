extends Node
class_name CheatCodeManager

var normal_speed := 1.0
var cheat_speed := 50.0

func _process(delta: float) -> void:
	
	if Input.is_key_pressed(KEY_L):
		Engine.time_scale = cheat_speed
		PlayerManager.player.is_cheating = true
	else:
		Engine.time_scale = normal_speed
		PlayerManager.player.is_cheating = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_button"):
		get_tree().reload_current_scene()
