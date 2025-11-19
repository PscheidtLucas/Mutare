extends Node

@export var afterimage_emitter: AfterimageEmitter
@export var leg_player: AnimationPlayer
@export var player_mesh: Node3D
var downwords_position := -0.39 ## posicao em y para a mesh se mover para baixo para a animação de andar
var initial_mesh_y: float
var walking_tween: Tween

@export var leg_anchor: Node3D
@export var leg_rotation_smooth_speed: float = 10.0 # quanto maior, mais rápido a perna gira

@onready var p: Player = get_parent()
@onready var state_chart: StateChart = $StateChart
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var camera_anchor: Node3D = %CameraAnchor
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D

var should_fall := true # usado para impedir que o personagem caia enquanto está no dash
var input_dir: Vector2
var move_dir: Vector3


#region Built-in methods
func _ready() -> void:
	dash_cooldown_timer.wait_time = p.dash_cooldown
	
	state_chart.set_expression_property("player_alive", true) # usado em ToFall, ToGround, ToJump
	state_chart.set_expression_property("dash_cd_reseted", true) # usado em ToDash
	GameEvents.player_died.connect(_on_player_died)
	initial_mesh_y = player_mesh.position.y
	animate_cube_frame_walking()
	
#endregion

#region Movement State Machine
func _on_movement_state_physics_processing(delta: float) -> void:
	## Input WASD
	var dir_hor := Input.get_axis("move_left", "move_right")
	var dir_ver := Input.get_axis("move_up", "move_down")
	input_dir = Vector2(dir_hor, dir_ver).normalized()
	
	var was_moving := move_dir != Vector3.ZERO
	
	## Rotaciona o vetor em 45° para alinhar ao grid isométrico, e depois rotaciona em relação a camera
	if input_dir != Vector2.ZERO:
		var rotated_iso := input_dir.rotated(-PI / 4) ## -45 graus
		var rotated_camera := rotated_iso.rotated((-camera_anchor.rotation.y))
		move_dir = Vector3(rotated_camera.x, 0, rotated_camera.y).normalized()
	else:
		move_dir = Vector3.ZERO
	
	var is_moving := move_dir != Vector3.ZERO
	
	if is_moving and not was_moving:
		state_chart.send_event("started_moving")
	elif not is_moving and was_moving:
		state_chart.send_event("stopped_moving")
	
	## Aplica movimento
	var target_velocity = move_dir * p.max_speed * (1 + p.stats.speed_increase)

	if target_velocity == Vector3.ZERO:
		p.velocity.x = move_toward(p.velocity.x, 0, p.deceleration)
		p.velocity.z = move_toward(p.velocity.z, 0, p.deceleration)
	else:
		p.velocity.x = move_toward(p.velocity.x, target_velocity.x, p.acc)
		p.velocity.z = move_toward(p.velocity.z, target_velocity.z, p.acc)
	
	update_leg_rotation(delta)
	p.move_and_slide()

func _on_ground_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		state_chart.send_event("jump_pressed")
	if p.is_on_floor() == false:
		state_chart.send_event("started_falling")

func _on_jump_state_entered() -> void:
	leg_player.play("Jump")
	p.velocity.y += p.jump_speed
	if walking_tween: walking_tween.pause()
	
func _on_jump_state_physics_processing(delta: float) -> void:
	p.velocity.y -= p.jump_gravity * delta
	if p.velocity.y <= 0:
		state_chart.send_event("started_falling")

func _on_fall_state_physics_processing(delta: float) -> void:
	if should_fall:
		p.velocity.y -= p.fall_gravity * delta
		if p.velocity.y <= p.max_fall_speed:
			p.velocity.y = p.max_fall_speed
	if p.is_on_floor():
		state_chart.send_event("touched_ground")
		
#endregion


#region Action State Machine
func _on_actions_state_physics_processing(delta: float) -> void:
	## Se o jogador não estiver apertando nenhuma tecla para dar direção, o dash não acontece
	if Input.is_action_just_pressed("dash") and input_dir != Vector2.ZERO:
		state_chart.send_event("dash_started")

func _on_dash_state_physics_processing(delta: float) -> void:
	p.move_and_slide()

func _on_dash_state_entered() -> void:
	%CollisionShape3D.disabled = true
	collision_shape_3d.position.y += 0.1
	state_chart.set_expression_property("dash_cd_reseted", false)
	dash_cooldown_timer.start()
	should_fall = false
	
	## Pega a direção do movimento atual
	var dash_direction = move_dir
	if dash_direction == Vector3.ZERO:
		dash_direction = -p.global_transform.basis.z
	p.velocity = dash_direction.normalized() * p.dash_speed
	
	afterimage_emitter.spawn_afterimages()
	leg_player.play("Walk", -1, 3)
	
	## O timer agora deve enviar um evento para voltar ao estado "None"
	var dash_timer = get_tree().create_timer(p.dash_duration)
	dash_timer.timeout.connect(state_chart.send_event.bind("dash_finished"))

func _on_dash_state_exited() -> void:
	%CollisionShape3D.disabled = false
	collision_shape_3d.position.y -= 0.1

func _on_none_state_entered() -> void:
	should_fall = true
	
#endregion


func _on_dash_cooldown_timer_timeout() -> void:
	state_chart.set_expression_property("dash_cd_reseted", true)

func _on_player_died() -> void:
	state_chart.set_expression_property("player_alive", false)
	set_physics_process(false)
	set_process(false)

func update_leg_rotation(delta: float) -> void:
	if leg_anchor == null:
		return

	# Se não tem direção de input, não muda (mantém última rotação)
	if move_dir == Vector3.ZERO:
		return

	# ângulo alvo em relação ao eixo Y: atan2(x, z)
	var target_angle := atan2(move_dir.x, move_dir.z) # A+S -> ~0 ; W+D -> ~PI ou -PI

	# ângulo atual
	var current_angle := leg_anchor.rotation.y

	# interpola suavemente entre ângulos (cuida do wrap 180/-180)
	var t = clamp(leg_rotation_smooth_speed * delta, 0.0, 1.0)
	var new_angle := lerp_angle(current_angle, target_angle, t)

	# aplica
	var r := leg_anchor.rotation
	r.y = new_angle
	leg_anchor.rotation = r

func _on_idle_state_entered() -> void:
	leg_player.play("Idle")
	if walking_tween: walking_tween.pause()

func _on_move_state_entered() -> void:
	leg_player.play("Walk")
	if walking_tween: walking_tween.play()

func _on_fall_state_entered() -> void:
	if should_fall:
		leg_player.play("Fall")
	if walking_tween: walking_tween.pause()


func _on_ground_state_entered() -> void:
	if move_dir != Vector3.ZERO:
		state_chart.send_event("started_moving")

func animate_cube_frame_walking() -> void:
	if walking_tween:
		walking_tween.kill()
	
	walking_tween = create_tween()
	walking_tween.set_loops() # Loop infinito
	walking_tween.set_trans(Tween.TRANS_SINE)
	walking_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Passo 1: Move para baixo (posição inicial - constante)
	walking_tween.tween_property(player_mesh, "position:y", initial_mesh_y - downwords_position, 0.15)
	# Passo 2: Move de volta para a posição inicial
	walking_tween.tween_property(player_mesh, "position:y", initial_mesh_y, 0.15)
	
	walking_tween.pause() # Começa pausado para não animar parado
