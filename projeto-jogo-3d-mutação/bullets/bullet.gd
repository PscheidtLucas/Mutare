class_name Bullet extends Area3D

@export var player_stats : PlayerStats = null
@export var destroy_at_first: bool = true
var velocity: Vector3 = Vector3.ZERO
var was_shot_from_player: bool = false
var damage: float = 1.0
var _config: RangedWeaponConfig = null
var lifetime_timer: float = 0.0
var max_lifetime: float = 5.0
var is_pooled: bool = false  # Flag para saber se veio do pool

var original_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	if was_shot_from_player:
		GameEvents.wave_survived.connect(_destroy)

func reset() -> void:
	velocity = Vector3.ZERO
	damage = 1.0
	lifetime_timer = 0.0
	max_lifetime = 0.0

func _physics_process(delta: float) -> void:
	global_translate(velocity * delta)
	
	lifetime_timer += delta
	if lifetime_timer >= max_lifetime:
		_destroy()
		return
	
	if global_position.length_squared() > 10000:
		_destroy()

func initialize(start_position: Vector3, direction: Vector3, config: RangedWeaponConfig, shot_from_player: bool):
	reset()
	self.global_position = start_position
	self.velocity = direction * config.projectile_speed
	self.damage = config.damage
	_config = config
	self.was_shot_from_player = shot_from_player
	self.is_pooled = not shot_from_player  # Inimigos usam pool
	look_at(global_position + direction, Vector3.UP)
	
	max_lifetime = config.range / config.projectile_speed
	lifetime_timer = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if was_shot_from_player:
			return
		increase_enemy_damage_bullet_based_on_cycle()
		if body.has_method("take_damage"):
			body.take_damage(Damage.new(damage, false))
		_destroy()
		return
	
	if body is Enemy:
		if not was_shot_from_player:
			return
		calc_player_damage()
		var is_crit : bool = is_crit_damage()
		body.take_damage(Damage.new(damage, is_crit))
		if destroy_at_first:
			_destroy()
		return
	
	_destroy()

# === FUNÇÃO UNIFICADA DE DESTRUIÇÃO ===
func _destroy() -> void:
	if is_pooled:
		BulletPool.return_bullet(self)
	else:
		queue_free()

func calc_player_damage() -> void:
	if not player_stats:
		return
	damage *= (1 + player_stats.damage_increase)

func is_crit_damage() -> bool:
	if player_stats and player_stats.crit_chance > 0.0:
		if randf() < player_stats.crit_chance:
			damage *= (1 + player_stats.crit_damage)
			return true
	return false

func increase_enemy_damage_bullet_based_on_cycle() -> void:
	damage = min(damage * pow(1.5, GameState.cycle_number - 1), 49)
