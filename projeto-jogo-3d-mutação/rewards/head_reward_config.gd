class_name HeadRewardConfig extends RewardConfig

@export var scene_uid: String
@export var ui_scene: String
@export var array_of_buffs: Array[StatBuff]


func roll_stats(damage_scale: float = 1.0) -> void:
	for stat: StatBuff in array_of_buffs:
		stat.buff_amount = randf_range(stat.min_buff_amount, stat.max_buff_amount)
