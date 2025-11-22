class_name VignetteShaderColorRect
extends ColorRect

## Parametros do shader: 
## "shader_parameter/intensity"
## "shader_parameter/radius"
## "shader_parameter/softness"

@export var min_intensity := 0.4	# intensidade quando vida cheia
@export var max_intensity := 1.0	# intensidade quando vida = 0
@export var tween_time := 0.35		# duração do tween

var _current_intensity := 0.4
var _tween: Tween


func _ready() -> void:
	GameEvents.player_health_changed.connect(_on_player_health_changed)
	GameEvents.player_took_damage_or_healed.connect(_force_refresh)
	_on_player_health_changed(100, 100)
	


func _on_player_health_changed(current_health: float, max_health: float) -> void:
	if max_health <= 0.0:
		return

	var life_ratio : float = clamp(current_health / max_health, 0.0, 1.0)
	var target_intensity : float = lerp(max_intensity, min_intensity, life_ratio)

	_start_tween(target_intensity)


func _force_refresh() -> void:
	# caso dano e cura aconteçam quase ao mesmo tempo,
	# garantir que não trava em um tween "velho"
	if _tween:
		_tween.kill()
	_tween = null


func _start_tween(value: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()

	_tween.tween_property(
		material,
		"shader_parameter/intensity",
		value,
		tween_time
	)
