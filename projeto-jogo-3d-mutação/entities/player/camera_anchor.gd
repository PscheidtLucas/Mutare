extends Node3D

var shake_strength := 0.75
var shake_time := 0.15
var original_pos: Vector3
var shaking := false
var original_rot: Vector3


func _ready() -> void:
	GameEvents.explosion.connect(shake_explosion)
	original_pos = position
	original_rot = rotation

func shake():
	if shaking:
		return
	shaking = true
	original_pos = position
	var t := create_tween()

	for i in 4:
		var x = random_with_min(shake_strength * 0.4, shake_strength)
		var y = random_with_min(shake_strength * 0.4, shake_strength)

		var target_pos := original_pos + Vector3(x, y, 0)
		t.tween_property(self, "position", target_pos, shake_time / 4)

	t.tween_property(self, "position", original_pos, shake_time / 4)
	t.finished.connect(func(): shaking = false)

func random_with_min(min_abs: float, max_abs: float) -> float:
	var v = randf_range(-max_abs, max_abs)
	if abs(v) < min_abs:
		v = sign(v) * min_abs
	return v

func shake_explosion(strength: float = 0.40, duration: float = 0.17):
	shaking = true
	original_pos = position
	original_rot = rotation

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)

	var steps := 10
	var step_duration := duration / steps

	for i in steps:
		var decay := 1.0 - float(i) / steps
		var s := strength * decay

		var offset_x := randf_range(-s, s)
		var offset_y := randf_range(-s, s)

		# movimento no espaço local, sempre visível
		var local_offset = (transform.basis.x * offset_x) + (transform.basis.y * offset_y)

		t.tween_property(self, "position", original_pos + local_offset, step_duration)

	# volta ao original no final
	t.tween_property(self, "position", original_pos, step_duration)

	t.finished.connect(func(): shaking = false)
