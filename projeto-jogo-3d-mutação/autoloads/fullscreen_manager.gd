extends Node
## Autoload para gerenciar o toggle de fullscreen com F11
## Funciona em conjunto com AppSettings sem conflitos

func _ready() -> void:
	# Garante que o autoload está sempre ativo
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# Detecta quando F11 é pressionada
	if event is InputEventKey:
		if event.keycode == KEY_F11 and event.pressed and not event.echo:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()

func _toggle_fullscreen() -> void:
	var window : Window = get_tree().root
	var is_currently_fullscreen : bool = AppSettings.is_fullscreen(window)
	
	# Inverte o estado atual
	var new_fullscreen_state : bool = not is_currently_fullscreen
	
	# Usa o AppSettings para manter consistência
	AppSettings.set_fullscreen_enabled(new_fullscreen_state, window)
	
	# Salva no config
	PlayerConfig.set_config(AppSettings.VIDEO_SECTION, AppSettings.FULLSCREEN, new_fullscreen_state)
	
	# Se saiu do fullscreen, restaura a resolução salva
	if not new_fullscreen_state:
		var saved_resolution : Vector2i = AppSettings.get_resolution(window)
		if saved_resolution.x > 0 and saved_resolution.y > 0:
			AppSettings.set_resolution(saved_resolution, window, false)
