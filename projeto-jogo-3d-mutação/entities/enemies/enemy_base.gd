class_name Enemy
extends CharacterBody3D

enum State { IDLE, CHASE, JUMPING }
var current_state: State = State.CHASE

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

const PATH_UPDATE_INTERVAL := 0.5    # tempo mínimo entre updates de path para este agente
const TARGET_UPDATE_DIST := 0.5      # só atualiza target se o player se mover > isso
var path_update_accum: float = 0.0
var path_update_offset: float = 0.0    # offset aleatório pra desincronizar updates
var last_target_position: Vector3 = Vector3.INF

func _ready() -> void:
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

	configure_weapon_stats()

func configure_weapon_stats() -> void:
	for weapon_node: BaseWeapon in array_of_weapons_nodes:
		weapon_node.config.roll_stats()
		print("dano do inimigo: ", weapon_node.config.damage)

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

	_look_at_player()
	move_and_slide()
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
				player.take_damage(collision_damage)
				
				# Paramos o loop, só queremos um knockback por frame
				break


## Estados da IA

func _idle_state():
	navigation_agent_3d.set_velocity(Vector3.ZERO)

func _chase_state(delta: float):
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

	# Usar o next_path_position toda physics frame (recomendado)
	var next_path_position = navigation_agent_3d.get_next_path_position()
	# Se navigation_agent não tem caminho válido, get_next_path_position pode retornar sua posição atual;
	# verifique para evitar divisão por zero
	if next_path_position == Vector3.ZERO and navigation_agent_3d.is_navigation_finished():
		navigation_agent_3d.set_velocity(Vector3.ZERO)
		return

	# --- INÍCIO DA MODIFICAÇÃO ---
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

func take_damage(damage: float) -> void:
	print ("enemy taking ", damage, " damage!")
	health -= damage
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
