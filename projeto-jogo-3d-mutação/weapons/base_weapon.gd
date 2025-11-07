# Base weapon, usada para player e inimigos, nao precisa saber de stats de dano pq as bullets ja sabem
class_name BaseWeapon
extends Node3D

# A única propriedade que precisamos. Todo o resto virá daqui.
@export var config: RangedWeaponConfig

# A flag para dizer à bala quem é o "dono" da arma.
@export var is_player_weapon: bool = false

# É importante ter um nó filho (Node3D) na ponta da arma para ser o Muzzle.
@onready var muzzle: Node3D = %Muzzle
var cooldown_timer: Timer = null

signal shot_emitted # Para animar armas

func _ready() -> void:
	call_deferred("config_timer")
	call_deferred("check_config")
	

func _fire() -> void:
	if not config or not config.bullet_scene:
		return

	var base_forward := -muzzle.global_transform.basis.x.normalized()
	var num := config.number_of_projectiles
	var spread_angles := _calculate_spread_angles(num, config.accuracy)

	for angle_deg in spread_angles:
		var projectile := config.bullet_scene.instantiate() as Bullet
		get_tree().current_scene.add_child(projectile)
		
		var final_dir := base_forward.rotated(Vector3.UP, deg_to_rad(angle_deg))
		projectile.initialize(muzzle.global_position, final_dir, config, is_player_weapon)
	
	shot_emitted.emit()

func _calculate_spread_angles(num: int, accuracy: float) -> Array[float]:
	const MAX_SPREAD_ANGLE := 90.0
	var total_spread := (1.0 - clampf(accuracy, 0.0, 1.0)) * MAX_SPREAD_ANGLE
	var angles: Array[float] = []

	for i in range(num):
		var angle := randf_range(-total_spread, total_spread)
		angles.append(angle)

	# Se só há um projétil, ainda adiciona leve aleatoriedade
	if num == 1:
		angles[0] = randf_range(-total_spread, total_spread)

	return angles

func config_timer() -> void:
	# Configura o timer com base no fire_rate do config
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	var time_to_fire: float
	if is_player_weapon:
		if PlayerManager.player == null:
			return
		var player_stats = PlayerManager.player.stats as PlayerStats
		var updated_fire_rate = config.fire_rate * (1 + player_stats.fire_rate_increase)
	
		time_to_fire = 1.0 / updated_fire_rate
	else:
		time_to_fire = 1.0 / config.fire_rate
	cooldown_timer.start(time_to_fire)
	cooldown_timer.timeout.connect(_fire)
	if is_player_weapon:
		print("TIME CONFIGURED, tempo para atirar: ", time_to_fire)
		print("Config fire rate: ", config.fire_rate)
		print("Config dano: ", config.damage)
		print("Config de range:", config.range)

func check_config() -> void:
	if not config:
		push_error("Arma '%s' não tem um RangedWeaponConfig definido!" % name)
		set_process(false)
