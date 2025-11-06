class_name PlayerStats
extends Resource

## O nome do buff aqui tem q ser o mesmo que aparece em current stats porem upper case, para utilizar sem problemas em recalculate stats
enum BuffableStats {
	MAX_HEALTH,
	HP5,
	DAMAGE_INCREASE,
	SPEED_INCREASE,
	CRIT_CHANCE_INCREASE,
	CRIT_DAMAGE_INCREASE,
	FIRE_RATE_INCREASE,
	COLLECT_AREA_INCREASE,
	KNOCKBACK_FORCE_INCREASE,
	DAMAGE_REDUCTION_PERC,
	}

signal stats_changed
signal health_changed(cur_health: int, max_health: int)

## BASE STATS
@export var b_max_health: float = 100.0
@export var b_hp5: float = 0.0 # Health regen a cada 5s
@export var b_damage_increase: float = 0.0
@export var b_speed_increase: float = 0.0
@export var b_crit_chance_increase: float = 0.0
@export var b_crit_damage_increase: float = 0.0
@export var b_fire_rate_increase: float = 0.0
@export var b_collect_area_increase: float = 0.0
@export var b_knockback_force_increase: float = 0.0
@export var b_damage_reduction_perc := 0.0

## CURRENT STATS
var max_health: float = 100.0
var hp5: float = 0.0 # Health regen a cada 5s
var damage_increase: float = 0.0
var speed_increase: float = 0.0
var crit_chance_increase: float = 0.0
var crit_damage_increase: float = 0.0
var fire_rate_increase: float = 0.0
var collect_area_increase: float = 0.0
var knockback_force_increase: float = 0.0
var damage_reduction_perc := 0.0

var health: float = 100.0 :
	set(value):
		health = clamp(value, 0.0, max_health)
		health_changed.emit(health, max_health)
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
	max_health = b_max_health
	hp5 = b_hp5
	damage_increase = b_damage_increase
	speed_increase = b_speed_increase
	crit_chance_increase = b_crit_chance_increase
	crit_damage_increase = b_crit_damage_increase
	fire_rate_increase = b_fire_rate_increase
	collect_area_increase = b_collect_area_increase
	knockback_force_increase = b_knockback_force_increase
	damage_reduction_perc = b_damage_reduction_perc
	
	## Calculando quanto buffar baseado em quais buffs estão no stat_buffs (Array)
	var stat_multipliers: Dictionary = {}
	var stat_addends: Dictionary = {}
	for buff: StatBuff in stat_buffs:
		var stat_name : String = BuffableStats.keys()[buff]
		match buff.BuffType:
			StatBuff.BuffType.ADD:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount
				
				if stat_multipliers[stat_name] < 0.0:
					stat_multipliers[stat_name] = 0.0
	
	## Aplicando buffs:
	for stat_name in stat_multipliers:
		var cur_property_name: String = str(stat_name).to_lower()
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])
	for stat_name in stat_addends:
		var cur_property_name: String = str(stat_name).to_lower()
		set(cur_property_name, get(cur_property_name) + stat_addends[stat_name])

func reset_health_to_full() -> void:
	health = max_health
	stats_changed.emit()

func reset_all() -> void:
	max_health = b_max_health
	health = max_health
	hp5 = b_hp5
	damage_increase = b_damage_increase
	speed_increase = b_speed_increase
	crit_chance_increase = b_crit_chance_increase
	crit_damage_increase = b_crit_damage_increase
	fire_rate_increase = b_fire_rate_increase
	collect_area_increase = b_collect_area_increase
	knockback_force_increase = b_knockback_force_increase
	damage_reduction_perc = b_damage_reduction_perc
	stats_changed.emit()


func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	stats_changed.emit()

func change_max_health(delta: float) -> void:
	max_health = max(1.0, max_health + delta)
	# Ajusta o health atual proporcionalmente ao novo máximo
	health = clamp(health, 0.0, max_health)
	stats_changed.emit()

func change_max_health_percent(percent: float) -> void:
	var increase := max_health * percent
	change_max_health(increase)

func change_hp5(delta: float) -> void:
	hp5 = max(0.0, hp5 + delta)
	stats_changed.emit()

func change_damage(delta: float) -> void:
	damage_increase += delta
	stats_changed.emit()

func change_speed(delta: float) -> void:
	speed_increase += delta
	stats_changed.emit()

func change_crit_chance(delta: float) -> void:
	crit_chance_increase += delta
	stats_changed.emit()

func change_crit_damage(delta: float) -> void:
	crit_damage_increase += delta
	stats_changed.emit()

func change_fire_rate(delta: float) -> void:
	fire_rate_increase += delta
	stats_changed.emit()

func change_collect_area(delta: float) -> void:
	collect_area_increase += delta
	stats_changed.emit()

func change_knockback_force(delta: float) -> void:
	knockback_force_increase = knockback_force_increase + delta
	stats_changed.emit()

func change_damage_reduction_perc(delta: float) -> void:
	damage_reduction_perc = damage_reduction_perc + delta
	stats_changed.emit()
