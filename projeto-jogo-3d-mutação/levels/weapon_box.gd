extends VBoxContainer

var weapon = null
const PISTOLA_SCENE = preload("res://test_scene/pistol_test.tscn")

func _on_button_pressed() -> void:
	#TODO arrumar tudo isso aqui
	GlobalSignals.weapon_selected.emit(PISTOLA_SCENE)
	PlayerManager.equipped_weapons.append(PISTOLA_SCENE)
	get_tree().paused = false
	get_tree().reload_current_scene()
