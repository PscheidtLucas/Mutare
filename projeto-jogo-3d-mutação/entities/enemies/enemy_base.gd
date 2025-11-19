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
	#navigation_agent_3d.velocity_computed.connect(_on_navigation_agent_3d_velocity_computed)
	raycast_check_interval = 0.3 + 0.1 * randf()
	set_max_slides(3)
	path_update_offset = randf_range(0.0, PATH_UPDATE_INTERVAL)
	GameEvents.wave_survived.connect(die)
	
	if array_of_weapons_nodes.is_empty():
		printerr("Array de armas do inimigo ", self, "está vazio!")
	
	player = PlayerManager.player
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
	#print("total enemies spawned: ", enemy_count)

func create_and_configure_label(damage: float, is_crit: bool = false) -> void:
	var label_3d := Label3D.new()
	
	var rand_angle := randf() * TAU
	var radius := sqrt(randf()) * label_appear_radius

	var offset := Vector3(
		radius * cos(rand_angle),
		0.0,
		radius * sin(rand_angle)
	)
	
	
	GameEvents.wave_survived.connect(label_3d.queue_free)
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
	t.finished.connect(func () -> void:
		if label: label.queue_free())


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
	
	move_and_slide()
	manage_knockback(delta)

func manage_knockback(_delta: float) -> void:
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
	velocity = Vector3.ZERO

var raycast_check_accum: float = 0.0
var raycast_check_interval := 0.0 ## atualizado no ready

func _chase_state(delta: float):
	# 1. RAYCAST CHECK (dessincronizado)
	raycast_check_accum += delta
	if raycast_check_accum >= raycast_check_interval:
		raycast_check_accum = 0.0
		ray_cast_3d.force_raycast_update()
		if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider() == player:
			current_state = State.IDLE
			chase_cooldown_timer.start(2.0)
			return

	# 2. PATH UPDATE (dessincronizado)
	path_update_accum += delta
	if path_update_accum >= PATH_UPDATE_INTERVAL:
		path_update_accum = 0.0
		
		# Só atualiza se o player se moveu
		var player_moved_enough := false
		if last_target_position == Vector3.INF:
			player_moved_enough = true
		else:
			var dist = last_target_position.distance_to(player.global_position)
			player_moved_enough = dist >= TARGET_UPDATE_DIST
		
		if player_moved_enough:
			navigation_agent_3d.target_position = player.global_position
			last_target_position = player.global_position

	# 3. MOVIMENTO SIMPLES
	# Se chegou no destino, para
	if navigation_agent_3d.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	
	# Pega próxima posição do caminho
	var next_pos := navigation_agent_3d.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	direction.y = 0.0  # Mantém no plano
	
	# Ajusta velocidade baseado em distância
	var dist_to_player := global_position.distance_to(player.global_position)
	var speed := move_speed * 1.5 if dist_to_player > speedy_distance else move_speed
	
	# Aplica velocidade
	velocity = direction * speed

func _jumping_state():
	var new_pos = jump_start_position.lerp(jump_target_position, jump_progress)
	var arc = 4.0 * jump_height * jump_progress * (1.0 - jump_progress)
	new_pos.y += arc
	global_position = new_pos

## Funções de Navegação e Combate

func _on_chase_cooldown_timeout():
	# Força update do raycast antes de checar
	ray_cast_3d.force_raycast_update()
	
	# Só fica IDLE se AINDA está vendo o player
	if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider() == player:
		# Player ainda está na mira, reinicia timer
		chase_cooldown_timer.start(2.0)
	else:
		# Player saiu da mira, volta pro chase
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
	spawn_dna_drop()
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
	flash_tween.tween_property(mat, "shader_parameter/hit_flash", 0.0, 0.15)

@export_group("DNA")
@export var dna_scene: PackedScene # Arraste a cena do DnaMoney.tscn para cá no Inspetor
func spawn_dna_drop() -> void:
	if dna_scene == null:
		return

	var dna_instance = dna_scene.instantiate() as RigidBody3D
	
	get_tree().current_scene.add_child(dna_instance)
	dna_instance.global_position = global_position + Vector3(0, 1.5, 0)
	
	# Cálculo da direção
	var random_angle := randf() * TAU
	var throw_direction := Vector3(sin(random_angle), 0, cos(random_angle))
	
	# Forças
	var horizontal_force := 6.0
	var vertical_force := 6.0
	
	# Multiplicar pela massa garante que o empurrão funcione independente do peso configurado
	var final_impulse = (throw_direction * horizontal_force) + (Vector3.UP * vertical_force)
	dna_instance.apply_central_impulse(final_impulse * dna_instance.mass)
	
