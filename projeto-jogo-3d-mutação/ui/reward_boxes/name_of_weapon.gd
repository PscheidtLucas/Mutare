extends Label

@export var reward_box: MarginContainer

func _ready() -> void:
	if reward_box and not reward_box.update_labels.is_connected(_on_update_reward_name):
		reward_box.update_labels.connect(_on_update_reward_name)

func _on_update_reward_name(reward_config: RewardConfig) -> void:
	text = reward_config.name
