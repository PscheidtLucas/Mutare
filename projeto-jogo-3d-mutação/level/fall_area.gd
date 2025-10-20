extends Area3D
class_name FallArea

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		GameEvents.player_fell_off.emit()
