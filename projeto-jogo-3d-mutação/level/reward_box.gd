class_name RewardBox extends MarginContainer

var reward = null
const PISTOLA_SCENE = preload("uid://b7jx3gi1kdegw")

func _on_button_pressed() -> void:
	#TODO arrumar tudo isso aqui
	GameEvents.weapon_selected.emit(PISTOLA_SCENE)
	PlayerManager.equipped_weapons.append(PISTOLA_SCENE)
	get_tree().paused = false
	get_tree().reload_current_scene()
