# LongRangeWeapon.gd (versão atualizada com suas preferências)
class_name BaseWeapon
extends Node3D

# A única propriedade que precisamos. Todo o resto virá daqui.
@export var config: RangedWeaponConfig

# A flag para dizer à bala quem é o "dono" da arma.
@export var is_player_weapon: bool = false

# É importante ter um nó filho (Node3D) na ponta da arma para ser o Muzzle.
@onready var muzzle: Node3D = %Muzzle
var cooldown_timer: Timer = null

func _ready() -> void:
	if not is_player_weapon:
		config_timer()
	if not config:
		push_error("Arma '%s' não tem um RangedWeaponConfig definido!" % name)
		set_process(false)
		return
	
	# Instancia o modelo 3D da arma que está no config
	if config.model:
		var model_instance = config.model.instantiate()
		add_child(model_instance)

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

func roll_stats()-> void: #chamado no equipe weapon do player, no inicio da partida
	if config:
		config.roll_stats()
		print("condig stats (D,F,A): ", config.damage, config.fire_rate, config.accuracy)
		config_timer()
	else:
		printerr("config não encontrado na hora de dar roll stats")


func config_timer() -> void:
	# Configura o timer com base no fire_rate do config
	cooldown_timer = Timer.new()
	add_child(cooldown_timer)
	var time_to_fire = 1.0 / config.fire_rate
	cooldown_timer.start(time_to_fire)
	cooldown_timer.timeout.connect(_fire)
