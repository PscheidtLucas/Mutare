class_name Bullet extends Area3D

@export var player_stats : PlayerStats = null
@export var destroy_at_first: bool = true
var velocity: Vector3 = Vector3.ZERO
var was_shot_from_player: bool = false
var damage: float = 1.0
var _config: RangedWeaponConfig = null
var lifetime_timer: float = 0.0
var max_lifetime: float = 0.0 ## Nao ta fazendo porra nenhuma
var is_pooled: bool = false  # Flag para saber se veio do pool

var original_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)


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
	
	if was_shot_from_player:
		GameEvents.wave_survived.connect(_destroy)

var has_calculated_damage := false
var final_damage := 0.0
var final_is_crit := false

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

		# Calcula o dano apenas no primeiro inimigo
		if not has_calculated_damage:
			calc_final_damage_once()
			has_calculated_damage = true

		body.take_damage(Damage.new(final_damage, final_is_crit))

		if destroy_at_first:
			_destroy()
		else:
			reduce_damage_for_next_target()
		return

	_destroy()


func calc_final_damage_once() -> void:
	# Multiplicadores do player são aplicados apenas uma vez
	final_damage = damage

	if player_stats:
		final_damage *= (1 + player_stats.damage_increase)

	# Só aplica crítico uma única vez
	if player_stats and player_stats.crit_chance > 0.0:
		if randf() < player_stats.crit_chance:
			final_damage *= (1 + player_stats.crit_damage)
			final_is_crit = true
		else:
			final_is_crit = false
	
	# Define o valor mínimo absoluto para essa bala específica
	damage_floor_value = final_damage * min_damage_percent

# Redução de 20% a cada hit (0.2)
@export var pierce_reduction_percent: float = 0.2 
# O dano nunca cairá abaixo de 20% do dano inicial (0.2)
@export var min_damage_percent: float = 0.2
var damage_floor_value: float = 0.0 # Variável interna para guardar o valor mínimo
func reduce_damage_for_next_target() -> void:
	# Reduz o dano atual pela porcentagem definida (ex: 100 * (1 - 0.2) = 80)
	var new_damage = final_damage * (1.0 - pierce_reduction_percent)
	
	# Garante que não fique menor que o piso calculado
	final_damage = max(new_damage, damage_floor_value)
	
	# Opcional: Debug para ver acontecendo
	# print("Bullet pierced! New damage: ", final_damage)


# === FUNÇÃO UNIFICADA DE DESTRUIÇÃO ===
func _destroy() -> void:
	
	if is_pooled:
		BulletPool.return_bullet(self)
	else:
		visible = false
		queue_free()


func increase_enemy_damage_bullet_based_on_cycle() -> void:
	damage = min(damage * pow(1.5, GameState.cycle_number - 1), 49)
