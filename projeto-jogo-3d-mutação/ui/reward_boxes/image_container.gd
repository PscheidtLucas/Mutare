extends MarginContainer

@export var weapon_box: WeaponBox

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

func _ready() -> void:
	if weapon_box and not weapon_box.update_labels.is_connected(_on_update_weapon):
		weapon_box.update_labels.connect(_on_update_weapon)

func _on_update_weapon(weapon_config: RangedWeaponConfig) -> void:
	var sprite_frames : SpriteFrames = weapon_config.sprite_frames
	if sprite_frames == null:
		return
	animated_sprite_2d.sprite_frames = sprite_frames
	animated_sprite_2d.sprite_frames.set_animation_speed("default", 14)
	animated_sprite_2d.play()
