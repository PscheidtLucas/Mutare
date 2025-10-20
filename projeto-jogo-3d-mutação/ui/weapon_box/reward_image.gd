extends TextureRect

@export var weapon_box: WeaponBox

func _ready() -> void:
	if weapon_box and not weapon_box.update_labels.is_connected(_on_update_image):
		weapon_box.update_labels.connect(_on_update_image)
	

func _on_update_image(weapon_config: RangedWeaponConfig) -> void:
	texture = weapon_config.image
