extends Node

@export var children: Array[Node3D]
@export var parent: Node3D

func _process(delta: float) -> void:
	for child in children:
		child.global_position = parent.global_position + Vector3(0, 1, 0)
