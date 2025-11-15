class_name Enemy 
extends CharacterBody3D

static var enemy_count := 0

@export var mesh_enemy: MeshInstance3D
@export var label_height := 3.9

const label_appear_radius := 0.9

enum State { IDLE, CHASE, JUMPING }
var current_state: State = State.CHASE

const CYCLE_HP_SCALE = 1.20    # 12% mais vida por ciclo

@export var speedy_distance : float = 15.0
@export var array_of_weapons_nodes : Array[BaseWeapon]
@export var health := 3.0
var player: Player = null
var chase_cooldown_timer: Timer # O Timer será criado e atribuído no _ready

@export var move_speed: float = 3.0
@export var knockback_force: float = 20.0
@export var collision_damage: float = 10.0

@export_group("Jump")
@export var jump_duration: float = 0.8
@export var jump_height: float = 3.0
@export var jump_pause: float = 0.5

@onready var jump_progress: float = 0.0
@onready var ray_cast_3d: RayCast3D = %RayCast3D

var jump_start_position: Vector3
var jump_target_position: Vector3

@onready var navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D

const PATH_UPDATE_INTERVAL := 1.2    # tempo mínimo entre updates de path para este agente
const TARGET_UPDATE_DIST := 1.5      # só atualiza target se o player se mover > isso
var path_update_accum: float = 0.0
var path_update_offset: float = 0.0    # offset aleatório pra desincronizar updates
var last_target_position: Vector3 = Vector3.INF

func _ready() -> void:
	set_max_slides(3)
	path_update_offset = randf_range(0.0, PATH_UPDATE_INTERVAL)
	GameEvents.wave_survived.connect(die)
	
	if array_of_weapons_nodes.is_empty():
		printerr("Array de armas do inimigo ", self, "está vazio!")
	
	player = PlayerManager.player
	navigation_agent_3d.link_reached.connect(_on_link_reached)
	navigation_agent_3d.max_speed = move_speed

	chase_cooldown_timer = Timer.new()
	chase_cooldown_timer.one_shot = true # Garante que o timer pare após disparar uma vez
	add_child(chase_cooldown_timer) # Adiciona o timer à cena para que ele funcione
	chase_cooldown_timer.timeout.connect(_on_chase_cooldown_timeout)
	
	if mesh_enemy.material_overlay == null:
		var shader_mat := ShaderMaterial.new()
		shader_mat.shader = preload("uid://bnpb3ajryxvro")
		mesh_enemy.material_overlay = shader_mat
	
	configure_weapon_stats()
	enemy_count += 1
	print("total enemies spawned: ", enemy_count)

func create_and_configure_label(damage: float, is_crit: bool = false) -> void:
	var label_3d := Label3D.new()
	
	var rand_angle := randf() * TAU
	var radius := sqrt(randf()) * label_appear_radius

	var offset := Vector3(
		radius * cos(rand_angle),
		0.0,
		radius * sin(rand_angle)
	)

	get_tree().current_scene.add_child(label_3d)

	label_3d.text = str(int(damage))
	label_3d.global_position = global_position + Vector3(0, label_height, 0) + offset
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.outline_size = 50

	label_3d.no_depth_test = true
	
	if is_crit:
		label_3d.font_size = 150
		label_3d.modulate = Color(1.0, 0.855, 0.13, 1.0)
	else:
		label_3d.font_size = 85
	tween_in_then_out_label(label_3d)

func tween_in_then_out_label(label: Label3D) -> void:
	label.scale = Vector3.ZERO
	label.modulate.a = 1.0   # garante alpha inicial

	var t := label.create_tween()

	# Tween IN — escala pop rápido (0.12s)
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", Vector3.ONE, 0.12)
	
	# Tween OUT — fade usando *modulate* (0.20s)
	var out_color := label.modulate
	out_color.a = 0.0

	t.tween_property(label, "modulate", out_color, 0.20).set_delay(0.3) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	t.parallel()
	t.tween_property(label, "outline_modulate", out_color, 0.2).set_delay(0.3) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
		
	# limpa a label no final
	t.finished.connect(label.queue_free)


func configure_weapon_stats() -> void:
	for weapon_node: BaseWeapon in array_of_weapons_nodes:
		weapon_node.config.roll_stats()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	if current_state == State.JUMPING:
		_jumping_state()
		return
		
	match current_state:
		State.IDLE:
			_idle_state()
		State.CHASE:
			_chase_state(delta)

	var to_player = player.global_position - global_position
	to_player.y = 0.0

	if to_player.length_squared() > 0.01:
		var target_rot = atan2(-to_player.x, -to_player.z)
		rotation.y = target_rot
	
	var collision : KinematicCollision3D = move_and_collide(velocity * delta)
	if collision:
		var collider: Object = collision.get_collider()
		if collider is CharacterBody3D:
			velocity = velocity.slide(collision.get_normal())
	manage_knockback(delta)

func manage_knockback(delta: float) -> void:
	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		var collision = get_slide_collision(i)
		if collision == null:
			continue
			
		# Verificamos se o corpo que colidimos é o player
		if collision.get_collider() == player:
			# Verificamos se o player tem a função de tomar knockback
			if player.has_method("apply_knockback"):
				
				# Calculamos a direção (do inimigo PARA o player)
				var direction = (player.global_position - global_position)
				direction.y = 0.5 # Damos um leve "pop" para cima
				direction = direction.normalized()
				
				# Chamamos a função no player, passando o impulso
				player.apply_knockback(direction * knockback_force)
				player.take_damage(Damage.new(collision_damage))
				
				# Paramos o loop, só queremos um knockback por frame
				break

## Estados da IA

func _idle_state():
	navigation_agent_3d.set_velocity(Vector3.ZERO)

var raycast_check_accum: float = 0.0
const RAYCAST_CHECK_INTERVAL := 0.3
func _chase_state(delta: float):
	raycast_check_accum += delta
	if raycast_check_accum >= RAYCAST_CHECK_INTERVAL:
		raycast_check_accum = 0.0
	# se o raycast vê o player, para e starta cooldown (o raycast é barato)
		if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider() == player:
			current_state = State.IDLE
			chase_cooldown_timer.start(2.0)
			return

	# --- Otimização central: NÃO setar target toda vez ---
	# acumulador com offset pra dessincronizar
	path_update_accum += delta
	if path_update_accum + path_update_offset >= PATH_UPDATE_INTERVAL:
		path_update_accum = 0.0
		# Só setar novo target se o player se moveu o suficiente do último target
		var dist_to_last_target: float
		if last_target_position == Vector3.INF:
			dist_to_last_target = 99999.0
		else:
			dist_to_last_target = last_target_position.distance_to(player.global_position)
		if dist_to_last_target >= TARGET_UPDATE_DIST:
			# set_target_position evita múltiplas queries se for igual; usamos property também ok
			navigation_agent_3d.target_position = player.global_position
			last_target_position = player.global_position
	## TESTE1 
	if navigation_agent_3d.is_navigation_finished():
		navigation_agent_3d.set_velocity(Vector3.ZERO)
		return

	var next_path_position = navigation_agent_3d.get_next_path_position()
	# Se navigation_agent não tem caminho válido, get_next_path_position pode retornar sua posição atual;
	# verifique para evitar divisão por zero
	if next_path_position == Vector3.ZERO and navigation_agent_3d.is_navigation_finished():
		navigation_agent_3d.set_velocity(Vector3.ZERO)
		return

	var current_move_speed = move_speed # Velocidade base
	var dist_to_player = global_position.distance_to(player.global_position)

	if dist_to_player > speedy_distance:
		current_move_speed = move_speed * 1.5 # Dobra a velocidade
	
	# Esta é a correção: atualizar a velocidade MÁXIMA do agente
	navigation_agent_3d.max_speed = current_move_speed
	# --- FIM DA MODIFICAÇÃO ---

	var dir = next_path_position - global_position
	dir.y = 0.0 # mantém no plano, evita subidas/descidas bruscas
	var desired_velocity = dir.normalized() * current_move_speed
	
	if not navigation_agent_3d.avoidance_enabled:
		velocity = desired_velocity
	else:
		navigation_agent_3d.set_velocity(desired_velocity)

func _jumping_state():
	var new_pos = jump_start_position.lerp(jump_target_position, jump_progress)
	var arc = 4.0 * jump_height * jump_progress * (1.0 - jump_progress)
	new_pos.y += arc
	global_position = new_pos

## Funções de Navegação e Combate

func _on_chase_cooldown_timeout():
	# reativa chase somente se o raycast não está vendo o jogador
	if current_state == State.IDLE and not (ray_cast_3d.is_colliding() and ray_cast_3d.get_collider() == player):
		current_state = State.CHASE
	else:
		# reinicia o timer de forma simples (mantém comportamento)
		chase_cooldown_timer.start(2.0)

func _on_link_reached(details: Dictionary) -> void:
	current_state = State.JUMPING
	navigation_agent_3d.set_velocity(Vector3.ZERO)
	
	jump_start_position = global_position
	jump_target_position = details[&"link_exit_position"]
	
	await get_tree().create_timer(jump_pause).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "jump_progress", 1.0, jump_duration).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(_on_jump_finished)

func _on_jump_finished() -> void:
	jump_progress = 0.0
	current_state = State.CHASE

func _look_at_player():
	var to_player = player.global_position - global_position
	to_player.y = 0
	if to_player.length_squared() > 0.01:
		look_at(global_position + to_player, Vector3.UP)

func take_damage(damage_data: Damage) -> void:
	health -= damage_data.amount
	flash_animation()
	create_and_configure_label(damage_data.amount, damage_data.is_crit)
	
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	
func scale_stats_for_cycle(cycle_number: int) -> void:
	# Não faz nada no Ciclo 1
	if cycle_number == 1:
		return

	# Calcula o expoente (Ciclo 2 = 1, Ciclo 3 = 2, ...)
	var scale_level = cycle_number - 1
	health = health * pow(CYCLE_HP_SCALE, scale_level)
	

var flash_tween: Tween = null

func flash_animation() -> void:
	# Garante o overlay
	if not mesh_enemy.material_overlay:
		printerr("no shader indentified on enemy mesh")
		return
	
	var mat: ShaderMaterial = mesh_enemy.material_overlay
	
	# Se já existe tween rolando, mata pra evitar overlap
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	
	# Cria tween novo
	flash_tween = create_tween()
	flash_tween.set_trans(Tween.TRANS_CUBIC)
	flash_tween.set_ease(Tween.EASE_IN)
	mat.set_shader_parameter("hit_flash", 1.0)
	# Sobe o flash rapidamente
	mat.set_shader_parameter("hit_flash", 1.0)
	flash_tween.tween_property(mat, "shader_parameter/hit_flash", 0.0, 0.15)
