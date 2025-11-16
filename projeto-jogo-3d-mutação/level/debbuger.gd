# DebugPhysics.gd (autoload)
extends Node

var frame_count := 0
var physics_frame_count := 0
var last_physics_frame := -1

func _process(delta: float) -> void:
	frame_count += 1

func _physics_process(delta: float) -> void:
	physics_frame_count += 1
	
	# Detecta frames pulados
	var expected_frame = last_physics_frame + 1
	if last_physics_frame >= 0 and physics_frame_count != expected_frame:
		print("❌ PHYSICS PULOU! Esperado: ", expected_frame, " | Real: ", physics_frame_count)
	
	# Detecta delta anormal
	if delta < 0.01 or delta > 0.02:  # Fora do 16ms esperado (60fps)
		print("⚠️ Delta anormal: ", delta * 1000, "ms | Frame: ", physics_frame_count)
	
	last_physics_frame = physics_frame_count
