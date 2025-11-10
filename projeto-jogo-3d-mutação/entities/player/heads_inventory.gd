class_name HeadsInventory extends Node3D

@export var player_stats: PlayerStats

func _ready() -> void:
	GameEvents.head_selected.connect(equip)

func equip(head_config: HeadRewardConfig) -> void:
	print("equiping head on player, head config: ", head_config)
	var head_sceane : PackedScene = load(head_config.scene_uid)
	var instance := head_sceane.instantiate() 
	for node in get_children():
		if node.get_child_count() != 0:
			continue
		node.add_child(instance)
		for buff: StatBuff in head_config.array_of_buffs:
			player_stats.add_buff(buff)
		print("Buffs no player stats: ", player_stats.stat_buffs)
		break
	
	player_stats.setup_stats()
