# Base weapon, usada para player e inimigos, nao precisa saber de stats de dano pq as bullets ja sabem
class_name BaseWeapon
extends Node3D

# A única propriedade que precisamos. Todo o resto virá daqui.
@export var config: RangedWeaponConfig

# A flag para dizer à bala quem é o "dono" da arma.
@export var is_player_weapon: bool = false

# É importante ter um nó filho (Node3D) na ponta da arma para ser o Muzzle.
@export var muzzle: Node3D  
var cooldown_timer: Timer = null

signal shot_emitted # Para animar armas

func _ready() -> void:
	if muzzle == null:
		muzzle = get_node_or_null("%Muzzle")
	if muzzle == null:
		printerr("ALERTA: Arma '", name, "' (em ", get_parent().name, ") iniciou SEM MUZZLE configurado!")
	call_deferred("check_config")
	if is_player_weapon:
		GameEvents.wave_started.connect(func():
			config_timer.call_deferred()
		)
	else:
		config_timer.call_deferred()
	

func _fire() -> void:
	if not config or not config.bullet_scene:
		return
	
	var base_forward := -muzzle.global_transform.basis.x.normalized()
	var num := config.number_of_projectiles
	var spread_angles := _calculate_spread_angles(num, config.accuracy)
	
	for angle_deg in spread_angles:
		var projectile: Bullet
		
		if is_player_weapon:
			projectile = config.bullet_scene.instantiate() as Bullet
		else:
			projectile = BulletPool.get_bullet(config.bullet_scene)

		# Garantir que não tenha parent antes de adicionar
		if projectile.get_parent():
			projectile.get_parent().remove_child(projectile)

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
	# calcula tempo entre tiros com segurança
	var time_to_fire: float = 0.0
	if is_player_weapon:
		if PlayerManager.player == null:
			return
		var player_stats := PlayerManager.player.stats as PlayerStats
		var updated_fire_rate := config.fire_rate * (1 + player_stats.fire_rate_increase)
		if updated_fire_rate <= 0.0:
			return
		time_to_fire = 1.0 / updated_fire_rate
	else:
		if config.fire_rate <= 0.0:
			return
		time_to_fire = 1.0 / config.fire_rate

	# cria o timer apenas se ainda não existir
	if cooldown_timer == null:
		cooldown_timer = Timer.new()
		cooldown_timer.one_shot = false
		add_child(cooldown_timer)
		# conecta apenas uma vez
		cooldown_timer.timeout.connect(_fire)

	# atualiza wait_time e (re)inicia
	cooldown_timer.wait_time = time_to_fire
	# restart para garantir fase correta; start() reinicia o contador
	cooldown_timer.start()


func check_config() -> void:
	if not config:
		push_error("Arma '%s' não tem um RangedWeaponConfig definido!" % name)
		set_process(false)
