extends Node3D
class_name AfterimageEmitter

@export var meshes: Array[MeshInstance3D] = []	# coloque aqui todas as meshes que sofrerão afterimage
@export var afterimage_count: int = 4			# quantos ghosts serão criados por dash
@export var afterimage_spacing: float = 0.05	# intervalo entre cada ghost
@export var fade_duration: float = 0.3			# quanto tempo cada ghost leva pra sumir
@export var color: Color = Color(0.3, 0.6, 1.0)	# cor do afterimage

var afterimage_shader := preload("uid://d3f47jysqm7uy")


func spawn_afterimages() -> void:
	if meshes.is_empty():
		return
	
	var tween := create_tween()
	
	for i in afterimage_count:
		tween.tween_callback(_spawn_single_afterimage).set_delay(afterimage_spacing * i)


func _spawn_single_afterimage() -> void:
	for mesh in meshes:
		if mesh == null:
			continue
		
		var ghost := MeshInstance3D.new()
		
		# copia a mesh
		ghost.mesh = mesh.mesh
		
		# IMPORTANTÍSSIMO: copiar a pose atual via skeleton
		ghost.skeleton = mesh.skeleton
		
		# posição/orientação global congelada
		ghost.global_transform = mesh.global_transform
		
		# aplica material de fade
		var mat := ShaderMaterial.new()
		mat.shader = afterimage_shader
		mat.set_shader_parameter("fade", 1.0)
		mat.set_shader_parameter("color", color)
		ghost.material_override = mat
		
		# adiciona à cena
		get_tree().current_scene.add_child(ghost)
		
		# tween de fade + remoção
		var t := ghost.create_tween()
		t.tween_property(mat, "shader_parameter/fade", 0.0, fade_duration)
		t.finished.connect(ghost.queue_free)
