extends MarginContainer

@export var weapon_box: WeaponBox

func _ready() -> void:
	if weapon_box and not weapon_box.update_labels.is_connected(_on_update_weapon):
		weapon_box.update_labels.connect(_on_update_weapon)

func _on_update_weapon(weapon_config: RangedWeaponConfig) -> void:
	var weapon_ui_scene_path : String = weapon_config.ui_scene_uid
	var loaded_scene := load(weapon_ui_scene_path)
	var instance : Control = loaded_scene.instantiate()
	add_child(instance)
	instance.set
