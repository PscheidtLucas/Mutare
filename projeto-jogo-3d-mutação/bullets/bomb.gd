class_name Bomb extends RigidBody3D

var bomb_damage := 1 # pode ser reescrito pela arma
var time_to_explode := 1.8
# Nodes for the explosion effect
@onready var debris: GPUParticles3D = $Debris
@onready var smoke: GPUParticles3D = $Smoke
@onready var fire: GPUParticles3D = $Fire
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionSound

@onready var explosion_area_3d: Area3D = $ExplosionArea3D
@onready var navigation_obstacle_3d: NavigationObstacle3D = $NavigationObstacle3D
@onready var explosion_timer: Timer = $ExplosionTimer

@export var array_of_meshes : Array[MeshInstance3D]

func _ready() -> void:
	explosion_timer.start(time_to_explode)
	explosion_timer.one_shot = true
	explosion_timer.timeout.connect(explode)

func explode():
	hide_mashes()
	cause_damage()
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	navigation_obstacle_3d.avoidance_enabled = false
	explosion_sound.play()
	await get_tree().create_timer(2).timeout
	queue_free()

func cause_damage():
	await get_tree().physics_frame
	for body in explosion_area_3d.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(bomb_damage) 
	await get_tree().create_timer(0.1).timeout
	explosion_area_3d.monitoring = false

func hide_mashes()->void:
	for mesh in array_of_meshes:
		mesh.hide()
