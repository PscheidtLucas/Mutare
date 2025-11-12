class_name EvolveButtonManager extends Control

@onready var evolve_button_bottom: Button = %EvolveButtonBottom
@onready var evolve_button: Button = %EvolveButton
@export var animation_player: AnimationPlayer 


func _ready() -> void:
	pass # Replace with function body.


func _on_evolve_button_bottom_pressed() -> void:
	print("pressed")
	if animation_player.current_animation == "evolve_pressed":
		print("returning early")
		return
	if animation_player.is_playing() == false:
		print("deveria tocar a animacao")
		animation_player.play("evolve_pressed")
