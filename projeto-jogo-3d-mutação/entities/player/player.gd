class_name Player extends CharacterBody3D

# Câmera do player
## TODO NERFAR O DASH -> COLOCAR BARRA DE STAMINA SÓ PRO DASH 
@export var stats: PlayerStats

var dead:= false
var is_cheating: bool = false
var target_camera_y_angle := 0
var camera_rotation_speed := 10.0

@export var fall_off_percent_damage: float = 0.2

@onready var cubo_frame: Node3D = %CuboFrame
@export var rotation_speed := 180.0 # graus por segundo

@export var max_speed: float = 200.0
@export var acc: float = 1300.0
@export var deceleration: float = 1200.0
@export var max_fall_speed: float = 300.0

@export_category("Jump")
@export_range(0.5, 20.0) var _jump_height := 1.5
@export_range(0.1, 1.5) var _jump_time_to_peak := 0.32
@export_range(0.1, 1.5) var _jump_time_to_descent := 0.24
@export_range(0.5, 4.0) var _horiz_dist_jump := 2.0
@export_range(1.0, 50.0) var _jump_cut_divider := 3.3

@export_category("Double Jump")
@export var max_jumps: int = 1
@export_range(0.5, 4.0) var _double_jump_height := 1.0
@export_range(0.1, 1.5) var _double_jump_time_to_peak := 0.24
@export_range(0.1, 1.5) var _double_jump_time_to_descent := 0.19

@export_category("Dash")
@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 0.5

@onready var jump_speed : float = _calculate_jump_speed(_jump_height, _jump_time_to_peak)
@onready var jump_gravity : float = _calculate_jump_gravity(_jump_height, _jump_time_to_peak)
@onready var fall_gravity := _calculate_fall_gravity(_jump_height, _jump_time_to_descent)
@onready var horiz_speed_jump := _calculate_jump_horiz_speed(_horiz_dist_jump, _jump_time_to_peak, _jump_time_to_descent)

@onready var double_jump_speed : float = _calculate_jump_speed(_double_jump_height, _double_jump_time_to_peak)
@onready var double_jump_gravity : float = _calculate_jump_gravity(_double_jump_height, _double_jump_time_to_peak)
@onready var double_jump_fall_gravity := _calculate_fall_gravity(_double_jump_height, _double_jump_time_to_descent)
@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D
@onready var camera_anchor: Node3D = %CameraAnchor

@export var positions_for_weapons : Array[Marker3D]

@onready var starting_global_pos: Vector3 
var starting_target_camera_y : float

func _calculate_jump_speed(height: float, time_to_peak: float) -> float:
	return(2.0 * height) / time_to_peak
	
func _calculate_jump_gravity(height: float, time_to_peak: float) -> float:
	return(2.0 * height) / pow(time_to_peak, 2.0)
	
func _calculate_fall_gravity(height: float, time_to_descent: float) -> float:
	return(2.0 * height) / pow(time_to_descent, 2.0)
	
func _calculate_jump_horiz_speed(dist: float, time_to_peak: float, 
		time_to_descent: float) -> float:
	return dist / (time_to_peak + time_to_descent)
	

func _ready() -> void:
	set_deferred("starting_global_pos", global_position)
	print("starting pos: ", starting_global_pos)
	starting_target_camera_y = target_camera_y_angle
	PlayerManager.player = self
	
	GameEvents.player_fell_off.connect(func() -> void:
		print("emitiu player fell off")
		take_damage(stats.max_health * fall_off_percent_damage)
		reset_player()  
		)
	GameEvents.wave_survived.connect(func()-> void:
		print("emitiu wave survived")
		reset_player() )
		
	GameEvents.weapon_selected.connect(equip)

func reset_player() -> void:
	print("reseting player position to: ", starting_global_pos)
	global_position = starting_global_pos
	target_camera_y_angle = starting_target_camera_y
	
#func _physics_process(delta: float) -> void:
	#if Input.is_action_pressed("rotation_left"):
		#cubo_frame.rotate_y(deg_to_rad(rotation_speed * delta))
	#elif Input.is_action_pressed("rotation_right"):
		#cubo_frame.rotate_y(deg_to_rad(-rotation_speed * delta))
		
func _physics_process(delta: float) -> void:
	var total_rotation := 0.0
	
	# Controle por teclas
	if Input.is_action_pressed("rotation_left"):
		total_rotation += rotation_speed * delta
	elif Input.is_action_pressed("rotation_right"):
		total_rotation -= rotation_speed * delta
	

	if total_rotation != 0.0:
		cubo_frame.rotate_y(deg_to_rad(total_rotation))


func _process(delta: float) -> void:
	camera_anchor.rotation.y = lerp_angle(camera_anchor.rotation.y, deg_to_rad(target_camera_y_angle), delta * camera_rotation_speed)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("rotate_camera_left"):
		target_camera_y_angle += 90
	elif Input.is_action_just_pressed("rotate_camera_right"):
		target_camera_y_angle -= 90

func equip(weapon_config: RangedWeaponConfig) -> void:
	print("equiping weapons on player")
	var weapon_sceane : PackedScene = load(weapon_config.scene_uid)
	var instance := weapon_sceane.instantiate() as BaseWeapon
	for node in positions_for_weapons:
		if node.get_child_count() != 0:
			continue
		instance.is_player_weapon = true
		node.add_child(instance)
		instance.config = weapon_config
		break

func take_damage(damage: float) -> void:
	if is_alive() == false:
		return
	if is_cheating == true:
		return
	stats.health -= damage
	GameEvents.player_took_damage.emit()
	if stats.health <= 0:
		stats.health = 0
		die()
		
		
func die() -> void:
	dead = true
	GameEvents.player_died.emit()
	set_physics_process(false)
	set_process(false)
	#hide() #TODO 

# Esta função recebe o impulso calculado pelo inimigo
func apply_knockback(knockback_velocity: Vector3):
	# Simplesmente definimos a velocidade do player para o impulso.
	# O seu _physics_process normal (com gravidade, input, etc.)
	# vai assumir o controle no próximo frame, mas o impulso
	# inicial do knockback será aplicado.
	velocity = knockback_velocity

func is_alive() -> bool:
	if dead:
		return false
	else:
		return true
