class_name FadeInOutBlack
extends ColorRect

signal fade_in_finished
signal fade_out_finished

@export var fade_in_duration: float = 0.6
@export var fade_out_duration: float = 0.6

var _tween: Tween

func _ready() -> void:
	color.a = 1.0  # Começa totalmente preto (fade-in implícito)
	fade_out()      # Remove se quiser controlar manualmente


func fade_in() -> void:
	_cancel_tween()
	_tween = create_tween()
	_tween.tween_property(self, "color:a", 1.0, fade_in_duration)
	_tween.finished.connect(func(): fade_in_finished.emit())


func fade_out() -> void:
	color = Color.BLACK
	_cancel_tween()
	_tween = create_tween()
	_tween.tween_property(self, "color:a", 0.0, fade_out_duration)
	_tween.finished.connect(func(): fade_out_finished.emit())


func _cancel_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
