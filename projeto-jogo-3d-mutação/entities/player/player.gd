class_name Player extends CharacterBody3D

# Câmera do player

var dead:= false
var is_cheating: bool = false
var target_camera_y_angle := 0
var camera_rotation_speed := 10.0

@export var max_health := 5
@onready var health := max_health
@onready var cube_mesh: MeshInstance3D = $CubeMesh
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
	PlayerManager.player = self
	
	equip_weapons()
	GameEvents.weapon_selected.connect(equip)
	dead = false
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("rotation_left"):
		cube_mesh.rotate_y(deg_to_rad(rotation_speed * delta))
	elif Input.is_action_pressed("rotation_right"):
		cube_mesh.rotate_y(deg_to_rad(-rotation_speed * delta))

func _process(delta: float) -> void:
	camera_anchor.rotation.y = lerp_angle(camera_anchor.rotation.y, deg_to_rad(target_camera_y_angle), delta * camera_rotation_speed)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("rotate_camera_left"):
		target_camera_y_angle += 90
	elif Input.is_action_just_pressed("rotate_camera_right"):
		target_camera_y_angle -= 90

func equip(weapon_scene: PackedScene) -> void:
	for node in positions_for_weapons:
		if node.get_child_count() != 0:
			continue
		var instance := weapon_scene.instantiate()
		instance.is_player_weapon = true
		node.add_child(instance)
		instance.setup_player_weapon()
		break

func equip_weapons() -> void:
	for weapon in PlayerManager.equipped_weapons:
		equip(weapon)

func take_damage(damage: float) -> void:
	if is_alive() == false:
		return
	if is_cheating == true:
		return
	health -= damage
	GameEvents.player_took_damage.emit()
	if health <= 0:
		die()
		
func die() -> void:
	dead = true
	GameEvents.player_died.emit()
	set_physics_process(false)
	set_process(false)
	#hide() #TODO 


func is_alive() -> bool:
	if dead:
		return false
	else:
		return true
