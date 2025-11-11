class_name CannonBombGun
extends BaseWeapon

@export_group("Cannon Stats")
@export var launch_angle_degrees: float = 60.0 # Ângulo de lançamento em graus
@export var initial_height: float = 1.59 # A altura inicial do canhão (pivot do jogador)

# Gravidade do projeto. Importante para a fórmula.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Constante para o spread máximo, igual ao da BaseWeapon
const MAX_SPREAD_ANGLE := 90.0

# Sobrescrevemos completamente a função _fire.
func _fire() -> void:
	shot_emitted.emit()
	# 1. Verificações básicas
	if not config or not config.bullet_scene:
		printerr("config para o cannon nao configurado!")
		return
	
	# 2. Instancia a bomba
	var projectile := config.bullet_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	if not projectile is Bomb:
		push_error("CannonBombGun (Arma: %s) - A cena da bala '%s' não é um Bomb!" % [name, config.bullet_scene.resource_path])
		projectile.queue_free()
		return
	
	for count in range(config.number_of_projectiles):
		
		var bomb := projectile as Bomb

		# 3. Pega os stats do Recurso 'config'
		var launch_range = config.range
		var accuracy = config.accuracy
		var launch_angle_rad = deg_to_rad(launch_angle_degrees)

		# 4. CÁLCULO DE FÍSICA BALÍSTICA
		# ... (cálculo do 'v' para atingir 'd' a partir de 'h') ...
		var d = launch_range
		var h = initial_height
		var g = gravity
		var cos_angle = cos(launch_angle_rad)
		var sin_2_angle = sin(2 * launch_angle_rad) # sin(2 * θ)

		var denominator = (d * sin_2_angle) + (2 * h * cos_angle * cos_angle)

		if denominator <= 0:
			push_error("Cálculo de alcance inválido para CannonBombGun. Verifique o range, ângulo e altura.")
			projectile.queue_free()
			return

		var projectile_speed_sq = (g * d * d) / denominator
		var projectile_speed = sqrt(projectile_speed_sq)

		# --- AJUDA PARA O SEU TODO (PROBLEMA DO RANGE) ---
		# A fórmula acima é precisa em um vácuo. Se a bomba não atinge o 'range',
		# é quase certeza que o RigidBody3D da 'Bomb.tscn' tem um 'Linear Damp' > 0
		# no Inspector. O 'Linear Damp' age como resistência do ar e freia a bomba.
		# Para a física bater 100%, seu Linear Damp deve ser 0 e Gravity Scale deve ser 1.
		if bomb.linear_damp > 0:
			push_warning("A Bomba '%s' tem Linear Damp > 0. O alcance calculado (%s m) não será atingido." % [bomb.name, d])
		# --- FIM DA AJUDA ---

		# 5. Calcula as velocidades horizontal e vertical
		var horizontal_speed = cos(launch_angle_rad) * projectile_speed
		var vertical_speed = sin(launch_angle_rad) * projectile_speed

		# 6. CALCULA A ACURACY (CORREÇÃO)
		# Calcula o spread máximo (em graus) com base na 'accuracy' (0.0 a 1.0)
		var total_spread := (1.0 - clampf(accuracy, 0.0, 1.0)) * MAX_SPREAD_ANGLE
		# Sorteia um ângulo aleatório dentro do cone de spread
		var random_angle_deg := randf_range(-total_spread, total_spread)

		# 7. Calcula os vetores de velocidade (AGORA COM ACURACY)
		# Começa com a direção base para a frente
		var base_horizontal_dir = -global_transform.basis.x.normalized()
		# Rotaciona a direção horizontal com base na 'accuracy'
		var final_horizontal_dir = base_horizontal_dir.rotated(Vector3.UP, deg_to_rad(random_angle_deg))
		
		# Aplica as velocidades às direções
		var horizontal_velocity = final_horizontal_dir * horizontal_speed
		var vertical_velocity = Vector3.UP * vertical_speed

		# 8. Define a posição inicial e a velocidade da bomba
		bomb.global_position = muzzle.global_position
		bomb.linear_velocity = horizontal_velocity + vertical_velocity
			
		# 9. Passa o 'config' e 'ownership' para a bomba.
		bomb.config = config
		bomb.is_player_weapon = is_player_weapon
