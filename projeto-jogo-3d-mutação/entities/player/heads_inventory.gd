class_name HeadsInventory extends Node3D

@export var player_stats: PlayerStats

func _ready() -> void:
	GameEvents.head_selected.connect(equip)

## Chamado no player
func equip(head_config: HeadRewardConfig) -> void:
	print("equiping head on player, head config: ", head_config)
	var head_sceane : PackedScene = load(head_config.scene_uid)
	var instance := head_sceane.instantiate() as HeadGeneral
	for node in get_children():
		if node.get_child_count() != 0:
			continue
		node.add_child(instance)
		instance.config = head_config
		for buff: StatBuff in head_config.array_of_buffs:
			player_stats.add_buff(buff)
			print("Adicionando buff: ", buff.resource_name)
			
		print("Buffs no player stats: ", player_stats.stat_buffs)
		break
	
	player_stats.setup_stats()

## Chamado no Player
func convert_heads_to_perma_buff() -> void:
	for child in get_children():
		var head: HeadGeneral = child.get_child(0)
		player_stats.add_permanent_buff_from_reward(head.config)
		head.queue_free()
