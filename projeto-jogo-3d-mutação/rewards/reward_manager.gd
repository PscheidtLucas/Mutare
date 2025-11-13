class_name RewardManager 
extends Control

## Script responsável tanto por mostrar as recompensas normais quanto por mostrar a tela de evolução

@export var game_state: GameState
@export var first_select_button: Button
@export var first_select_head_button: Button

@export var choices_v_box: VBoxContainer
@export var evolve_button: Button
@export var evolve_manager: EvolveButtonManager

@export var weapon_templates: Array[RangedWeaponConfig]
@export var meelee_templates: Array
@export var heads_templates: Array[HeadRewardConfig]
@export var legs_templates: Array

@export var options_container: VBoxContainer

enum RewardType {LONG_RANGE, MELEE, HEAD, LEG}
var type: RewardType

var damage_scale := 1.0
var num_choices := 3
var weapon_index := 1

signal weapons_configured
signal heads_configured

var wave_num_vs_reward_type: Dictionary = {
	1: "weapon",
	2: "head",
	3: "weapon",
	4: "head",
	5: "weapon",
	6: "head",
	7: "weapon",
	8: "head",
	9: "head",
	10: "head",
}

# --- NOVO BLOCO DE VARIÁVEIS PARA CONTROLE DE INPUT ---
var _using_mouse := true
var _pending_focus_request := false


func _ready() -> void:
	GameEvents.wave_survived.connect(on_wave_survived)
	GameEvents.wave_started.connect(on_wave_started)
	GameEvents.cycle_cleared.connect(on_cycle_cleared)
	
	call_deferred("wave_0_config")

	set_process_input(true)
	_update_mouse_mode()


func wave_0_config() -> void:
	on_wave_survived()

## Lógica que mostra as o botão de evolução e esconde as escolhas de armas
func on_cycle_cleared() -> void:
	show()
	
	choices_v_box.hide()
	evolve_manager.show()

## Chamada das wavez 1-9 no final da wave, chamada na wave 10 depois que a evolução é concluída
func on_wave_survived() -> void:
	show()
	
	## Lógica que mostra as escolhas de armas e garante que o botao de evolve esteja escondido
	choices_v_box.show()
	evolve_manager.hide()
	
	var reward_type := reward_type_based_on_wave()

	match reward_type:
		"weapon":
			var generated_weapons: Array = generate_rewards(RewardType.LONG_RANGE)
			var index := 0
			for child in options_container.get_children():
				if child is WeaponBox:
					child.show()
					child.weapon_config_generated = generated_weapons[index]
					index += 1
				elif child is HeadBox:
					child.hide()
			if !_using_mouse:
				first_select_button.grab_focus()
			weapons_configured.emit()

		"head":
			var generated_heads: Array = generate_rewards(RewardType.HEAD)
			var index := 0
			for child in options_container.get_children():
				if child is HeadBox:
					child.show()
					child.head_config_generated = generated_heads[index]
					index += 1
				elif child is WeaponBox:
					child.hide()
			if !_using_mouse:
				first_select_head_button.grab_focus()
			heads_configured.emit()


func reward_type_based_on_wave() -> String:
	var wave_in_cycle = game_state.get_wave_in_cycle()
	
	if wave_in_cycle <= 10:
		return wave_num_vs_reward_type[game_state.get_wave_in_cycle()]
	printerr("Numero da wave no Reward Screen nao está correto, provavlmente maior q 10 ou a variavel wave in cycle contem erro!")
	return "head"


func on_wave_started() -> void:
	hide()


func generate_rewards(type_of_reward: RewardType) -> Array[RewardConfig]:
	randomize()
	var choices : Array[RewardConfig] = []
	var possible_templates: Array
	match type_of_reward:
		RewardType.LONG_RANGE:
			possible_templates = weapon_templates
		RewardType.MELEE:
			possible_templates = meelee_templates
		RewardType.HEAD:
			possible_templates = heads_templates
		RewardType.LEG:
			possible_templates = legs_templates

	if possible_templates.is_empty():
		push_error("A lista de templates de rewards no RewardManager está vazia! Tipo que está vazio: ", type_of_reward)
		return possible_templates

	var available_templates = possible_templates.duplicate()
	available_templates.shuffle()
	
	for i in range(num_choices):
		var template = available_templates.pick_random()
		var rolled_reward = template.duplicate()
		rolled_reward.roll_stats(damage_scale)
		choices.append(rolled_reward)
		
	return choices


# --- NOVA SEÇÃO DE CONTROLE DE INPUT E FOCUS ---

func _input(event: InputEvent) -> void:
	var previous_using_mouse := _using_mouse

	# Detecta mouse
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_using_mouse = true

	# Detecta controle ou setas (ativa foco se não houver)
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion or \
		event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		_using_mouse = false
		if get_viewport().gui_get_focus_owner() == null and is_visible_in_tree():
			if !_pending_focus_request:
				_pending_focus_request = true
				call_deferred("_deferred_focus_first")

	# Se mudou o modo de input
	if previous_using_mouse != _using_mouse:
		_update_mouse_mode()
		if _using_mouse:
			_clear_focus()
		else:
			if get_viewport().gui_get_focus_owner() == null and is_visible_in_tree():
				call_deferred("_deferred_focus_first")


func _deferred_focus_first() -> void:
	_pending_focus_request = false
	if first_select_button and first_select_button.visible:
		first_select_button.grab_focus()
	elif first_select_head_button and first_select_head_button.visible:
		first_select_head_button.grab_focus()


func _update_mouse_mode() -> void:
	if _using_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _clear_focus() -> void:
	var focused = get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()
