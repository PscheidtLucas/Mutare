extends Node

@onready var p: Player = get_parent()
@onready var state_chart: StateChart = $StateChart

var input_dir: Vector2
var move_dir: Vector3

func _physics_process(delta: float) -> void:
	# Input WASD (em espaço 2D lógico)daw
	var dir_hor := Input.get_axis("move_left", "move_right")
	var dir_ver := Input.get_axis("move_up", "move_down")
	input_dir = Vector2(dir_hor, dir_ver).normalized()
	
	# Rotaciona o vetor em 45° para alinhar ao grid isométrico
	if input_dir != Vector2.ZERO:
		var rotated := input_dir.rotated(-PI / 4) # -45 graus
		move_dir = Vector3(rotated.x, 0, rotated.y).normalized()
	else:
		move_dir = Vector3.ZERO
	
	# Aplica movimento
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
	#p.velocity.y += 15

func _on_jump_state_physics_processing(delta: float) -> void:
	p.velocity.y -= p.jump_gravity * delta
	if p.velocity.y <= 0:
		state_chart.send_event("started_falling")

func _on_fall_state_physics_processing(delta: float) -> void:
	p.velocity.y -= p.fall_gravity * delta
	if p.velocity.y <= p.max_fall_speed:
		p.velocity.y = p.max_fall_speed
	if p.is_on_floor():
		state_chart.send_event("touched_ground")
