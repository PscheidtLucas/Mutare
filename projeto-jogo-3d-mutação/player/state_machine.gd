extends Node

@onready var p: Player = get_parent()
@onready var state_chart: StateChart = $StateChart
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var camera_anchor: Node3D = %CameraAnchor

var should_fall := true # usado para impedir que o personagem caia enquanto está no dash
var input_dir: Vector2
var move_dir: Vector3


#region Built-in methods
func _ready() -> void:
	dash_cooldown_timer.wait_time = p.dash_cooldown
	
	state_chart.set_expression_property("player_alive", true) # usado em ToFall, ToGround, ToJump
	state_chart.set_expression_property("dash_cd_reseted", true) # usado em ToDash
	GlobalSignals.player_died.connect(_on_player_died)
	
#endregion

#region Movement State Machine
func _on_movement_state_physics_processing(delta: float) -> void:
	## Input WASD
	var dir_hor := Input.get_axis("move_left", "move_right")
	var dir_ver := Input.get_axis("move_up", "move_down")
	input_dir = Vector2(dir_hor, dir_ver).normalized()
	
	## Rotaciona o vetor em 45° para alinhar ao grid isométrico, e depois rotaciona em relação a camera
	if input_dir != Vector2.ZERO:
		var rotated_iso := input_dir.rotated(-PI / 4) ## -45 graus
		var rotated_camera := rotated_iso.rotated((-camera_anchor.rotation.y))
		move_dir = Vector3(rotated_camera.x, 0, rotated_camera.y).normalized()
	else:
		move_dir = Vector3.ZERO
	
	## Aplica movimento
	var target_velocity = move_dir * p.max_speed
	if target_velocity == Vector3.ZERO:
		p.velocity.x = move_toward(p.velocity.x, 0, p.deceleration)
		p.velocity.z = move_toward(p.velocity.z, 0, p.deceleration)
	else:
		p.velocity.x = move_toward(p.velocity.x, target_velocity.x, p.acc)
		p.velocity.z = move_toward(p.velocity.z, target_velocity.z, p.acc)

	p.move_and_slide()

func _on_ground_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		state_chart.send_event("jump_pressed")
	if p.is_on_floor() == false:
		state_chart.send_event("started_falling")

func _on_jump_state_entered() -> void:
	p.velocity.y += p.jump_speed

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
	state_chart.set_expression_property("dash_cd_reseted", false)
	dash_cooldown_timer.start()
	should_fall = false
	
	## Pega a direção do movimento atual
	var dash_direction = move_dir
	if dash_direction == Vector3.ZERO:
		dash_direction = -p.global_transform.basis.z
	p.velocity = dash_direction.normalized() * p.dash_speed

	## O timer agora deve enviar um evento para voltar ao estado "None"
	var dash_timer = get_tree().create_timer(p.dash_duration)
	dash_timer.timeout.connect(state_chart.send_event.bind("dash_finished"))

func _on_none_state_entered() -> void:
	should_fall = true
	
#endregion


func _on_dash_cooldown_timer_timeout() -> void:
	state_chart.set_expression_property("dash_cd_reseted", true)

func _on_player_died() -> void:
	state_chart.set_expression_property("player_alive", false)
	set_physics_process(false)
	set_process(false)
