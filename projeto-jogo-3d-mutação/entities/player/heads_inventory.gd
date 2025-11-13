class_name HeadsInventory extends Node3D ## Script em um nó filho do Player, responsavel por guardar as cabeças

@export var player_stats: PlayerStats

func _ready() -> void:
	GameEvents.head_selected.connect(equip)

## Chamado no player
func equip(head_config: HeadRewardConfig) -> void:
	var head_sceane : PackedScene = load(head_config.scene_uid)
	var instance := head_sceane.instantiate() as HeadGeneral
	for node in get_children():
		if node.get_child_count() != 0:
			continue
		node.add_child(instance)
		instance.config = head_config
		for buff: StatBuff in head_config.array_of_buffs:
			player_stats.add_buff(buff)
			
		break
	
	player_stats.setup_stats()

## Chamado no Player
func convert_heads_to_perma_buff() -> void:
	print("chamando convert head to perma buffs no heads inventory")
	for child in get_children():
		var head: HeadGeneral = child.get_child(0)
		if head == null or head.config == null:
			printerr("Cabeça identificada como null na hora de converter cabeça em perma buff.")
			return
		player_stats.add_permanent_buff_from_reward(head.config)
		head.queue_free()
