class_name Enemy
extends CharacterBody3D

enum State { IDLE, CHASE, JUMPING }
var current_state: State = State.CHASE

@export var health := 3.0
var player: Player = null
var chase_cooldown_timer: Timer # O Timer será criado e atribuído no _ready

@export var move_speed: float = 3.0

@export_group("Jump")
@export var jump_duration: float = 0.8
@export var jump_height: float = 3.0
@export var jump_pause: float = 0.5

@onready var jump_progress: float = 0.0
@onready var ray_cast_3d: RayCast3D = %RayCast3D

var jump_start_position: Vector3
var jump_target_position: Vector3

@onready var navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D

func _ready() -> void:
	player = PlayerManager.player
	navigation_agent_3d.link_reached.connect(_on_link_reached)
	navigation_agent_3d.max_speed = move_speed
	
	# --- MUDANÇA: Cria e configura o Timer de cooldown via código ---
	chase_cooldown_timer = Timer.new()
	chase_cooldown_timer.one_shot = true # Garante que o timer pare após disparar uma vez
	add_child(chase_cooldown_timer) # Adiciona o timer à cena para que ele funcione
	chase_cooldown_timer.timeout.connect(_on_chase_cooldown_timeout)

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
			_chase_state()

	_look_at_player()
	move_and_slide()

## Estados da IA

func _idle_state():
	navigation_agent_3d.set_velocity(Vector3.ZERO)

func _chase_state():
	if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider() == player:
		current_state = State.IDLE
		chase_cooldown_timer.start(2.0) # Opcionalmente, podemos passar o tempo aqui
		return

	navigation_agent_3d.target_position = player.global_position
	var next_path_position = navigation_agent_3d.get_next_path_position()
	var desired_velocity = global_position.direction_to(next_path_position) * move_speed
	navigation_agent_3d.set_velocity(desired_velocity)

func _jumping_state():
	var new_pos = jump_start_position.lerp(jump_target_position, jump_progress)
	var arc = 4.0 * jump_height * jump_progress * (1.0 - jump_progress)
	new_pos.y += arc
	global_position = new_pos

## Funções de Navegação e Combate

func _on_chase_cooldown_timeout():
	if current_state == State.IDLE and not (ray_cast_3d.is_colliding() and ray_cast_3d.get_collider() == player):
		current_state = State.CHASE
	else:
		chase_cooldown_timer.start(2)

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
