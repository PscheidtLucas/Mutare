extends MarginContainer

@export var weapon_box: WeaponBox

var weapon_ui_image: Node

func _ready() -> void:
	GameEvents.weapon_selected.connect(func(weapon_config) -> void:
		if weapon_ui_image != null:
			weapon_ui_image.queue_free()
		)
	if weapon_box and not weapon_box.update_labels.is_connected(_on_update_weapon):
		weapon_box.update_labels.connect(_on_update_weapon)

func _on_update_weapon(weapon_config: RangedWeaponConfig) -> void:
	var weapon_ui_scene_path : String = weapon_config.ui_scene_uid
	
	var packed := CacheUIScenes.get_scene(weapon_ui_scene_path)
	var instance : Control = packed.instantiate()

	add_child(instance)
	weapon_ui_image = instance
