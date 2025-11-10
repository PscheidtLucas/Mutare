class_name PlayerStats
extends Resource

# ideias de stats: dodge chance, +1 bullet chance, poison chance, burn chance...

## O nome do buff aqui tem q ser o mesmo que aparece em current stats porem upper case, para utilizar sem problemas em recalculate stats
enum BuffableStats {
	MAX_HEALTH,
	HP5,
	DAMAGE_INCREASE,
	SPEED_INCREASE,
	CRIT_CHANCE,
	CRIT_DAMAGE_INCREASE,
	FIRE_RATE_INCREASE,
	COLLECT_AREA_INCREASE,
	DAMAGE_REDUCTION_PERC,
	}

signal health_changed

## BASE STATS -> para resetar os current stats para esses, basta dar clear no array de buffs
@export var b_max_health: float = 100.0
@export var b_hp5: float = 0.0 # Health regen a cada 5s
@export var b_damage_increase: float = 0.0
@export var b_speed_increase: float = 0.0
@export var b_crit_chance: float = 0.0
@export var b_crit_damage: float = 1.0 # 1.0 = 100% de dano ao acertar um crítico
@export var b_fire_rate_increase: float = 0.0
@export var b_collect_area_increase: float = 0.0
@export var b_damage_reduction_perc := 0.0

## CURRENT STATS
var max_health: float = 100.0
var hp5: float = 0.0 # Health regen a cada 5s
var damage_increase: float = 0.0
var speed_increase: float = 0.0
var crit_chance: float = 0.0
var crit_damage: float = 0.0 
var fire_rate_increase: float = 0.0
var collect_area_increase: float = 0.0
var damage_reduction_perc := 0.0

var health: float = 100.0 :
	set(value):
		health = clamp(value, 0.0, max_health)
		health_changed.emit()
	get:
		return health

## Buffs devem ser sempre adicionados e removidos nesse array quando o jogador pega um item que dá esse buff
var stat_buffs: Array[StatBuff] =[]

## Init acontece antes do ajuste das varáveis exportadas!! Por isso precisamos de  call_deferred
func _init() -> void:
	setup_stats.call_deferred()

func setup_stats() -> void:
	recalculate_stats()
	health = max_health

func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()

func remove_buff(buff: StatBuff) -> void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()


func recalculate_stats() -> void:
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

	## Preparar acumuladores
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for stat_name in BuffableStats.keys():
		stat_multipliers[stat_name] = 1.0
		stat_addends[stat_name] = 0.0

	## Acumula buffs
	for buff: StatBuff in stat_buffs:
		var stat_name : String = BuffableStats.keys()[buff.stat]
		match buff.buff_type:
			StatBuff.BuffType.ADD:
				stat_addends[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				stat_multipliers[stat_name] += buff.buff_amount
				# evita multiplicadores absurdos (limite opcional)
				if stat_multipliers[stat_name] < -1.0:
					stat_multipliers[stat_name] = -1.0

	## Aplica buffs sobre os BASE stats (tratamento explícito das bases)
	for stat_name in BuffableStats.keys():
		var cur_property_name: String = str(stat_name).to_lower()

		# pega explicitamente o base_val correspondente (evita chamadas dinâmicas que podem falhar)
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
			"CRIT_DAMAGE_INCREASE":
				base_val = b_crit_damage
			"FIRE_RATE_INCREASE":
				base_val = b_fire_rate_increase
			"COLLECT_AREA_INCREASE":
				base_val = b_collect_area_increase
			"DAMAGE_REDUCTION_PERC":
				base_val = b_damage_reduction_perc
			_:
				base_val = 0.0

		var mult: float = stat_multipliers[stat_name]
		var add: float = stat_addends[stat_name]

		var new_value: float = 0.0
		if base_val == 0.0:
			# Se a base é zero, interpreta multiplicador como "delta absoluto": (mult - 1.0)
			new_value = add
			if mult != 1.0:
				new_value += (mult - 1.0)
		else:
			# comportamento normal: base * mult + add
			new_value = base_val * mult + add

		set(cur_property_name, new_value)
