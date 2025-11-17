class_name HeadRewardConfig extends RewardConfig

@export var name: String
@export var scene_uid: String
@export var array_of_buffs: Array[StatBuff]
@export var image: Texture2D

func roll_stats(damage_scale: float = 1.0) -> void:
	for stat: StatBuff in array_of_buffs:
		stat.buff_amount = randf_range(stat.min_buff_amount, stat.max_buff_amount)
	perma_buff_amount = randf_range(perma_buff_percent_min, perma_buff_percent_max)
	perma_buff_type = PermaBuffType.values().pick_random()
	
