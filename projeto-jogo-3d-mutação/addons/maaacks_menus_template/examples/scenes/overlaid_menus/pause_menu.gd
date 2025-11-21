@tool
extends OverlaidMenu
@export var options_packed_scene : PackedScene
@export_file("*.tscn") var main_menu_scene_path : String
@export var toggle_action : String = "ui_cancel"
var popup_open : Node
var _ignore_first_cancel : bool = false
var _is_open : bool = false
var _options_menu_instance : Node = null

const PAUSE_SOUND = preload("uid://blg54fhime6pm")
const RESUME_SOUND = preload("uid://f1co62b0cehg")

func get_main_menu_scene_path() -> String:
	if main_menu_scene_path.is_empty():
		return AppConfig.main_menu_scene_path
	return main_menu_scene_path

func close_popup() -> void:
	if popup_open != null:
		popup_open.hide()
		popup_open = null

func _disable_focus() -> void:
	for child in %MenuButtons.get_children():
		if child is Control:
			child.focus_mode = FOCUS_NONE

func _enable_focus() -> void:
	for child in %MenuButtons.get_children():
		if child is Control:
			child.focus_mode = FOCUS_ALL

func _load_scene(scene_path: String) -> void:
	_scene_tree.paused = false
	SceneLoader.load_scene(scene_path)

func open_options_menu() -> void:
	var options_scene := options_packed_scene.instantiate()
	_options_menu_instance = options_scene
	get_parent().add_child(options_scene)
	_disable_focus.call_deferred()
	await options_scene.tree_exiting
	_options_menu_instance = null
	_enable_focus.call_deferred()

func _handle_cancel_input() -> void:
	if _ignore_first_cancel:
		_ignore_first_cancel = false
		return
	if popup_open != null:
		close_popup()
	else:
		close()

func _hide_exit_for_web() -> void:
	if OS.has_feature("web"):
		%ExitButton.hide()

func _hide_options_if_unset() -> void:
	if options_packed_scene == null:
		%OptionsButton.hide()

func _hide_main_menu_if_unset() -> void:
	if get_main_menu_scene_path().is_empty():
		%MainMenuButton.hide()

func _ready() -> void:
	_hide_exit_for_web()
	_hide_options_if_unset()
	_hide_main_menu_if_unset()
	if Input.is_action_pressed("ui_cancel"):
		_ignore_first_cancel = true
	hide()
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released(toggle_action):
		if not _is_open:
			_open_menu()
		else:
			_handle_cancel_input()
		get_viewport().set_input_as_handled()

func _open_menu() -> void:
	AudioManager.set_music_paused(true)
	AudioManager.play_sfx(PAUSE_SOUND, 5)
	
	show()
	process_mode = PROCESS_MODE_ALWAYS
	_scene_tree.paused = true
	if makes_mouse_visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_is_open = true

func close() -> void:
	AudioManager.set_music_paused(false)
	AudioManager.play_sfx(RESUME_SOUND, 10)
	
	_is_open = false
	hide()
	
	# Fecha o menu de opções se estiver aberto
	if _options_menu_instance != null and is_instance_valid(_options_menu_instance):
		_options_menu_instance.queue_free()
		_options_menu_instance = null
	
	process_mode = PROCESS_MODE_INHERIT
	_scene_tree.paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_restart_button_pressed() -> void:
	%ConfirmRestart.popup_centered()
	popup_open = %ConfirmRestart

func _on_options_button_pressed() -> void:
	open_options_menu()

func _on_main_menu_button_pressed() -> void:
	%ConfirmMainMenu.popup_centered()
	popup_open = %ConfirmMainMenu

func _on_exit_button_pressed() -> void:
	%ConfirmExit.popup_centered()
	popup_open = %ConfirmExit

func _on_confirm_restart_confirmed() -> void:
	SceneLoader.reload_current_scene()

func _on_confirm_main_menu_confirmed() -> void:
	_load_scene(get_main_menu_scene_path())

func _on_confirm_exit_confirmed() -> void:
	get_tree().quit()
