extends MarginContainer

@export var headbox: HeadBox

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D


func _ready() -> void:
	if headbox and not headbox.update_labels.is_connected(_on_update_head):
		headbox.update_labels.connect(_on_update_head)

func _on_update_head(head_config: HeadRewardConfig) -> void:
	var sprite_frames : SpriteFrames = head_config.sprite_frames
	if sprite_frames == null:
		return
	animated_sprite_2d.sprite_frames = sprite_frames
	animated_sprite_2d.sprite_frames.set_animation_speed("default", 14)
	animated_sprite_2d.play()
