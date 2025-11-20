class_name PlayerStats
extends Resource

enum BuffableStats {
	MAX_HEALTH,
	HP5,
	DAMAGE_INCREASE,
	SPEED_INCREASE,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	FIRE_RATE_INCREASE,
	COLLECT_AREA_INCREASE,
	DASH_RECHARGE_SPEED,
}

signal health_changed

## BASE STATS -> para resetar os current stats para esses, basta dar clear no array de buffs
@export var b_max_health: float = 100.0
@export var b_hp5: float = 0.0
@export var b_damage_increase: float = 0.0
@export var b_speed_increase: float = 0.0
@export var b_crit_chance: float = 0.0
@export var b_crit_damage: float = 1.0
@export var b_fire_rate_increase: float = 0.0
@export var b_collect_area_increase: float = 0.0
@export var b_damage_reduction_perc := 0.0
@export var b_range_increase: float = 0.0
@export var b_accuracy_increase: float = 0.0
@export var b_dash_recharge_speed: float = 0.0

## CURRENT STATS
var max_health: float = 100.0
var hp5: float = 0.0
var damage_increase: float = 0.0
var speed_increase: float = 0.0
var crit_chance: float = 0.0
var crit_damage: float = 0.0 
var fire_rate_increase: float = 0.0
var collect_area_increase: float = 0.0
var damage_reduction_perc := 0.0
var range_increase: float = 0.0
var accuracy_increase: float = 0.0
var dash_recharge_speed: float = 0.0

var health: float = 100.0 :
	set(value):
		health = clamp(value, 0.0, max_health)
		health_changed.emit()
	get:
		return health

## Buffs temporários (removidos ao resetar stats)
var stat_buffs: Array[StatBuff] = []

## BUFFS PERMANENTES - persistem entre cenas até o jogador morrer/resetar
var permanent_buffs: Array[StatBuff] = []

func _init() -> void:
	setup_stats.call_deferred()

func setup_stats() -> void:
	print("Setup stats")
	recalculate_stats()

## Adiciona um buff temporário (removido com reset_stats)
func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()

func remove_buff(buff: StatBuff) -> void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()

## Adiciona um buff PERMANENTE (persiste entre cenas)
func add_permanent_buff(buff: StatBuff) -> void:
	permanent_buffs.append(buff)
	recalculate_stats.call_deferred()

## Remove um buff permanente específico
func remove_permanent_buff(buff: StatBuff) -> void:
	permanent_buffs.erase(buff)
	recalculate_stats.call_deferred()

## Adiciona um buff permanente a partir de um RewardConfig
func add_permanent_buff_from_reward(reward: RewardConfig) -> void:
	var buff = StatBuff.new()
	
	# Converte o tipo de buff da recompensa para o enum BuffableStats
	match reward.perma_buff_type:
		RewardConfig.PermaBuffType.DAMAGE:
			buff.stat = BuffableStats.DAMAGE_INCREASE
		RewardConfig.PermaBuffType.FIRE_RATE:
			buff.stat = BuffableStats.FIRE_RATE_INCREASE
		RewardConfig.PermaBuffType.MOVE_SPEED:
			buff.stat = BuffableStats.SPEED_INCREASE
		RewardConfig.PermaBuffType.CRIT_CHANCE:
			buff.stat = BuffableStats.CRIT_CHANCE
		RewardConfig.PermaBuffType.CRIT_DAMAGE:
			buff.stat = BuffableStats.CRIT_DAMAGE
		RewardConfig.PermaBuffType.DASH_RECHARGE_SPEED:
			buff.stat = BuffableStats.DASH_RECHARGE_SPEED
	
	# Usa MULTIPLY para buffs percentuais (0.1 = +10%)
	buff.buff_type = StatBuff.BuffType.MULTIPLY
	buff.buff_amount = reward.perma_buff_amount
	
	add_permanent_buff(buff)

func recalculate_stats() -> void:
	var previous_max_health = max_health
	# reseta current stats para os base
	max_health = b_max_health
	hp5 = b_hp5
	damage_increase = b_damage_increase
	speed_increase = b_speed_increase
	crit_chance = b_crit_chance
	crit_damage = b_crit_damage
	fire_rate_increase = b_fire_rate_increase
	collect_area_increase = b_collect_area_increase
	damage_reduction_perc = b_damage_reduction_perc
	range_increase = b_range_increase
	accuracy_increase = b_accuracy_increase
	dash_recharge_speed = b_dash_recharge_speed

	## Preparar acumuladores
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for stat_name in BuffableStats.keys():
		stat_multipliers[stat_name] = 1.0
		stat_addends[stat_name] = 0.0

	## Acumula buffs TEMPORÁRIOS + PERMANENTES
	var all_buffs = stat_buffs + permanent_buffs
	
	for buff: StatBuff in all_buffs:
		var stat_name : String = BuffableStats.keys()[buff.stat]
		match buff.buff_type:
			StatBuff.BuffType.ADD:
				stat_addends[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				stat_multipliers[stat_name] += buff.buff_amount
				if stat_multipliers[stat_name] < -1.0:
					stat_multipliers[stat_name] = -1.0

	## Aplica buffs sobre os BASE stats
	for stat_name in BuffableStats.keys():
		var cur_property_name: String = str(stat_name).to_lower()

		var base_val: float = 0.0
		match stat_name:
			"MAX_HEALTH":
				base_val = b_max_health
			"HP5":
				base_val = b_hp5
			"DAMAGE_INCREASE":
				base_val = b_damage_increase
			"SPEED_INCREASE":
				base_val = b_speed_increase
			"CRIT_CHANCE":
				base_val = b_crit_chance
			"CRIT_DAMAGE":
				base_val = b_crit_damage
			"FIRE_RATE_INCREASE":
				base_val = b_fire_rate_increase
			"COLLECT_AREA_INCREASE":
				base_val = b_collect_area_increase
			"DAMAGE_REDUCTION_PERC":
				base_val = b_damage_reduction_perc
			"ACCURACY_INCREASE":
				base_val = b_accuracy_increase
			"DASH_RECHARGE_SPEED": 
				base_val = b_dash_recharge_speed
			_:
				base_val = 0.0

		var mult: float = stat_multipliers[stat_name]
		var add: float = stat_addends[stat_name]

		var new_value: float = 0.0
		if base_val <= 0.0001:
			new_value = add
			if mult != 1.0:
				new_value += (mult - 1.0)
		else:
			new_value = base_val * mult + add

		set(cur_property_name, new_value)
	
	max_health = max(max_health, 1.0)
	
	## Lógica para aumentar a vida quando receber um buff de max_health
	var max_health_difference : float = max_health - previous_max_health
	if max_health_difference > 0:
		health += max_health_difference
	# Caso contrário (se perdeu max health), apenas garantimos que a vida atual
	# não fique maior que o novo máximo chamando o setter
	else:
		health = health
	
## Reseta apenas buffs TEMPORÁRIOS (mantém permanentes)
func reset_temporary_buffs() -> void:
	print("Reseting temporary buffs")
	stat_buffs.clear()
	recalculate_stats()
	health = max_health
	health_changed.emit()

## Reseta TUDO incluindo buffs permanentes (quando o jogador morre ou reinicia)
func reset_all_stats() -> void:
	print("Reseting all buffs")
	stat_buffs.clear()
	permanent_buffs.clear()
	recalculate_stats.call_deferred()
	health = max_health
	health_changed.emit()

## Mantém compatibilidade com código antigo
func reset_stats() -> void:
	reset_temporary_buffs()

## Retorna a quantidade total de buffs permanentes por tipo
func get_permanent_buff_count_by_stat(stat_type: BuffableStats) -> int:
	var count = 0
	for buff in permanent_buffs:
		if buff.stat == stat_type:
			count += 1
	return count

## Retorna o valor total acumulado de buffs permanentes para um stat
func get_permanent_buff_total(stat_type: BuffableStats) -> float:
	var total = 0.0
	for buff in permanent_buffs:
		if buff.stat == stat_type:
			total += buff.buff_amount
	return total
