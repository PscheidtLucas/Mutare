class_name Player extends CharacterBody3D

@export var max_health := 5
var health := max_health
@onready var cube_mesh: MeshInstance3D = $CubeMesh
@export var rotation_speed := 180.0 # graus por segundo

@export var max_speed: float = 200.0
@export var acc: float = 1300.0
@export var deceleration: float = 1200.0
@export var max_fall_speed: float = 300.0

@export_category("Jump")
@export_range(0.5, 4.0) var _jump_height := 1.5
@export_range(0.1, 1.5) var _jump_time_to_peak := 0.32
@export_range(0.1, 1.5) var _jump_time_to_descent := 0.24
@export_range(0.5, 4.0) var _horiz_dist_jump := 2.0
@export_range(1.0, 50.0) var _jump_cut_divider := 3.3

@export_category("Double Jump")
@export var max_jumps: int = 1
@export_range(0.5, 4.0) var _double_jump_height := 1.0
@export_range(0.1, 1.5) var _double_jump_time_to_peak := 0.24
@export_range(0.1, 1.5) var _double_jump_time_to_descent := 0.19

@onready var jump_speed : float = _calculate_jump_speed(_jump_height, _jump_time_to_peak)
@onready var jump_gravity : float = _calculate_jump_gravity(_jump_height, _jump_time_to_peak)
@onready var fall_gravity := _calculate_fall_gravity(_jump_height, _jump_time_to_descent)
@onready var horiz_speed_jump := _calculate_jump_horiz_speed(_horiz_dist_jump, _jump_time_to_peak, _jump_time_to_descent)

@onready var double_jump_speed : float = _calculate_jump_speed(_double_jump_height, _double_jump_time_to_peak)
@onready var double_jump_gravity : float = _calculate_jump_gravity(_double_jump_height, _double_jump_time_to_peak)
@onready var double_jump_fall_gravity := _calculate_fall_gravity(_double_jump_height, _double_jump_time_to_descent)

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
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("rotation_left"):
		cube_mesh.rotate_y(deg_to_rad(rotation_speed * delta))
	elif Input.is_action_pressed("rotation_right"):
		cube_mesh.rotate_y(deg_to_rad(-rotation_speed * delta))

func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		die()
		
func die() -> void:
	GlobalSignals.player_died.emit()
