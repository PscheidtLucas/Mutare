class_name EvolveButtonManager extends Control

const HOVER_MAIN_MENU_1 = preload("uid://c7kbf7cgampxm")

@export var game_state: GameState

@onready var evolve_button_bottom: Button = %EvolveButtonBottom
@onready var evolve_button: Button = %EvolveButton
@export var animation_player: AnimationPlayer 

var evolve_was_pressed := false

func _ready() -> void:
	evolve_was_pressed = false
	evolve_button.pressed.connect(_on_evolve_button_pressed)
	
	animation_player.animation_finished.connect(on_evolution_finished)


func on_evolution_finished(anim_name: String) -> void:
	print("Animation finished!!!")
	if anim_name == "evolve_pressed":
		print("Animation name was evolve pressed? Name: ", anim_name)
		GameEvents.evolution_completed.emit()
		GameEvents.wave_survived.emit()
		evolve_was_pressed = false
		animation_player.play("RESET")

const EVOLVE_PRESSED_SOUND = preload("uid://cggjrjf0m1xip")
func _on_evolve_button_pressed() -> void:
	if evolve_was_pressed:
		return
	
	AudioManager.play_sfx(EVOLVE_PRESSED_SOUND, -10)
	evolve_was_pressed = true
	animate_evolve_button() ## Anima o botão de evolução e envia o sinal "evolution_completed" quando a animação termina
	
	
func animate_evolve_button() -> void:
	if animation_player.is_playing() == false:
		animation_player.play("evolve_pressed")


func _on_evolve_button_mouse_entered() -> void:
	AudioManager.play_sfx(HOVER_MAIN_MENU_1)
