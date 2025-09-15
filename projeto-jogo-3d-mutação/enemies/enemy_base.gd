class_name Enemy
extends CharacterBody3D

var health := 3
var player: Player = null

var cube_material: StandardMaterial3D

@export var move_speed: float = 3.0
@export var stop_distance: float = 14.0

@onready var cube_mesh: MeshInstance3D = $CubeMesh
@onready var shot_timer: Timer = $ShotTimer

func _ready() -> void:
	player = PlayerManager.player
	cube_material = cube_mesh.get_surface_override_material(0)
	cube_material.emission_energy_multiplier = 7.0
	
func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	var to_player := player.global_transform.origin - global_transform.origin
	var distance := to_player.length()
	
	# Movimento
	if distance > stop_distance:
		var direction := to_player.normalized()
		velocity = direction * move_speed
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()
	
	# CORREÇÃO: Rotaciona o inimigo inteiro apenas no eixo Y
	to_player.y = 0.0
	if to_player.length() > 0.01:
		var target_position = global_transform.origin + to_player
		look_at(target_position, Vector3.UP)

func take_damage(damage: int) -> void:
	health -= damage
	# Lógica para o cubo perder brilho conforme toma dano
	cube_material.emission_energy_multiplier = max(0.0, cube_material.emission_energy_multiplier - 0.5)
	
	if health <= 0:
		die()

func die() -> void:
	queue_free()
