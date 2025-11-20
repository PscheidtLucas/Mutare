class_name RewardConfig extends Resource

enum RewardType {LONG_RANGE, MELEE, HEAD, LEG}
@export var type: RewardType

@export var sprite_frames: SpriteFrames

# Buff permanente que é concedido ao jogador ao transceder para um novo mapa, cada item terá um buff permanente gerado aleatório
enum PermaBuffType {DAMAGE, FIRE_RATE, MOVE_SPEED, CRIT_CHANCE, CRIT_DAMAGE, DASH_RECHARGE_SPEED}
@export var perma_buff_type: PermaBuffType
@export var perma_buff_percent_min: float
@export var perma_buff_percent_max: float

var perma_buff_amount: float

func roll_stats(damage_scale: float) -> void:
	pass 
