class_name RewardConfig extends Resource

enum RewardType {LONG_RANGE, MELEE, HEAD, LEG}
@export var type: RewardType

# Buff permanente que é concedido ao jogador ao transceder para um novo mapa, cada item terá um buff permanente gerado aleatório
enum PermaBuffType {DAMAGE, FIRE_RATE, MOVE_SPEED, RANGE, ACCURACY, HP_REGEN, MAX_HP}
@export var perma_buff_type: PermaBuffType
@export var perma_buff_percent_min: float
@export var perma_buff_percent_max: float

var perma_buff_amount: float

func _init() -> void:
	call_deferred("calc_perma_buff")

func calc_perma_buff() -> void:
	perma_buff_amount = randf_range(perma_buff_percent_min, perma_buff_percent_max)
