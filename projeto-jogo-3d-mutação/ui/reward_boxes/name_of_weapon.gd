extends Label

@export var weapon_box: WeaponBox

func _ready() -> void:
	if weapon_box and not weapon_box.update_labels.is_connected(_on_update_weapon_name):
		weapon_box.update_labels.connect(_on_update_weapon_name)

func _on_update_weapon_name(weapon_config: RangedWeaponConfig) -> void:
	text = weapon_config.name
