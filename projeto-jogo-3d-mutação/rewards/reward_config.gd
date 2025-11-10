class_name RewardConfig extends Resource

enum RewardType {LONG_RANGE, MELEE, HEAD, LEG}
@export var type: RewardType

# Buff permanente que é concedido ao jogador ao transceder para um novo mapa, cada item terá um buff permanente gerado aleatório
enum PermaBuffType {DAMAGE, FIRE_RATE, MOVE_SPEED, RANGE, ACCURACY, HP_REGEN, MAX_HP, CRIT_CHANCE, CRIT_DAMAGE}
@export var perma_buff_type: PermaBuffType
@export var perma_buff_percent_min: float
@export var perma_buff_percent_max: float

var perma_buff_amount: float

func roll_stats(damage_scale: float) -> void:
	pass 

#func calc_perma_buff() -> void: 
	#perma_buff_amount = randf_range(perma_buff_percent_min, perma_buff_percent_max)
	#perma_buff_type = PermaBuffType.values().pick_random()
	#print("perma buff amount: ", perma_buff_amount)
	#print("perma buff type: ", perma_buff_type)
