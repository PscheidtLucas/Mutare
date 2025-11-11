extends Control

@export var search_depth : int = 1
@export var enabled : bool = false
@export var null_focus_enabled : bool = true
@export var joypad_enabled : bool = true
@export var mouse_hidden_enabled : bool = true

@export var lock : bool = false :
	set(value):
		var value_changed : bool = lock != value
		lock = value
		if value_changed and not lock:
			update_focus()

var _using_mouse := true
var _pending_focus_request := false


func _focus_first_search(control_node : Control, levels : int = 1) -> bool:
	if control_node == null or !control_node.is_visible_in_tree():
		return false
	if control_node.focus_mode == FOCUS_ALL:
		control_node.grab_focus()
		if control_node is ItemList:
			control_node.select(0)
		return true
	if levels < 1:
		return false
	for child in control_node.get_children():
		if _focus_first_search(child, levels - 1):
			return true
	return false


func focus_first() -> void:
	_focus_first_search(self, search_depth)


func update_focus() -> void:
	if lock:
		return
	if _is_visible_and_should_capture():
		focus_first()


func _should_capture_focus() -> bool:
	return enabled or \
	(get_viewport().gui_get_focus_owner() == null and null_focus_enabled) or \
	(Input.get_connected_joypads().size() > 0 and joypad_enabled) or \
	(Input.mouse_mode not in [Input.MOUSE_MODE_VISIBLE, Input.MOUSE_MODE_CONFINED] and mouse_hidden_enabled)


func _is_visible_and_should_capture() -> bool:
	return is_visible_in_tree() and _should_capture_focus()


func _on_visibility_changed() -> void:
	if !_using_mouse:
		call_deferred("update_focus")


func _ready() -> void:
	if is_inside_tree():
		connect("visibility_changed", _on_visibility_changed)
		set_process_input(true)
		_update_mouse_mode()


func _input(event: InputEvent) -> void:
	var previous_using_mouse := _using_mouse

	# Detecta uso de mouse
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_using_mouse = true

	# Detecta uso de controle ou setas (retorna foco se não houver)
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion or \
		event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		_using_mouse = false
		if get_viewport().gui_get_focus_owner() == null and is_visible_in_tree():
			if !_pending_focus_request:
				_pending_focus_request = true
				call_deferred("_deferred_focus_first")

	# Caso tenha mudado o modo de input, atualiza comportamento
	if previous_using_mouse != _using_mouse:
		_update_mouse_mode()

		# Remove foco se passou a usar mouse
		if _using_mouse:
			_clear_focus()
		# Restaura foco se voltou pro controle
		else:
			if get_viewport().gui_get_focus_owner() == null and is_visible_in_tree():
				call_deferred("focus_first")


func _deferred_focus_first() -> void: 
	_pending_focus_request = false
	focus_first()


func _update_mouse_mode() -> void:
	if _using_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _clear_focus() -> void:
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
