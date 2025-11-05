class_name PlayerStats
extends Resource

signal stats_changed

# --- Stats base ---
@export var max_health: float = 100.0
@export var hp5: float = 0.0 # Health regen a cada 5s
@export var damage_increase: float = 0.0
@export var speed_increase: float = 0.0
@export var crit_chance_increase: float = 0.0
@export var crit_damage_increase: float = 0.0
@export var fire_rate_increase: float = 0.0
@export var collect_area_increase: float = 0.0
@export var knockback_force_increase: float = 0.0
@export var damage_reduction := 0.0

var health: float = 100.0 :
	set(value):
		health = clamp(value, 0.0, max_health)
		stats_changed.emit()
	get:
		return health

# -----------------------------
# MÉTODOS DE ALTERAÇÃO SEGURA
# -----------------------------

func reset_health() -> void:
	health = max_health
	stats_changed.emit()

## Já tem no script do player:
#func take_damage(amount: float) -> void:
	#health = max(0.0, health - amount)
	#stats_changed.emit()

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

func change_damage_reduction(delta: float) -> void:
	damage_reduction = damage_reduction + delta
	stats_changed.emit()

# Utilitário opcional (reset completo)
func reset_all() -> void:
	max_health = 100.0
	hp5 = 0.0
	damage_increase = 0.0
	speed_increase = 0.0
	crit_chance_increase = 0.0
	crit_damage_increase = 0.0
	fire_rate_increase = 0.0
	collect_area_increase = 0.0
	knockback_force_increase = 0.0
	reset_health()
	stats_changed.emit()
