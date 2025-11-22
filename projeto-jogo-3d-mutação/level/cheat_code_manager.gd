extends Node
class_name CheatCodeManager

## Se verdadeiro, cheats só funcionam quando rodando de dentro da Godot (F5).
## Se falso, cheats funcionam na build final exportada (.exe/.apk).
@export var should_run_only_in_editor: bool = true

var normal_speed := 1.0
var cheat_speed := 50.0

func _ready() -> void:
	# OS.has_feature("editor") retorna true se você estiver rodando o jogo pelo editor.
	# Retorna false se for uma build exportada.
	if should_run_only_in_editor and not OS.has_feature("editor"):
		# Desativa o _process e o _input deste script para economizar recursos
		set_process(false)
		set_process_input(false)
		
		# Opcional: Se esse nó não faz mais nada além de cheats, 
		# você pode deletá-lo da memória com:
		# queue_free()

func _process(delta: float) -> void:
	# Este código agora só roda se a verificação no _ready permitir
	if Input.is_key_pressed(KEY_L):
		Engine.time_scale = cheat_speed
		# Adicionei uma verificação de segurança caso o player não esteja pronto
		if PlayerManager.player:
			PlayerManager.player.is_cheating = true
	else:
		Engine.time_scale = normal_speed
		if PlayerManager.player:
			PlayerManager.player.is_cheating = false

func _input(event: InputEvent) -> void:
	# Este código também será desativado pelo set_process_input(false)
	if event.is_action_pressed("restart_button"):
		get_tree().reload_current_scene()
