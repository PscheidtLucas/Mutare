class_name RewardManager extends Control

@export var game_state: GameState
@export var first_select_button: Button  #first select weapon button
@export var first_select_head_button: Button

@export var weapon_templates: Array[RangedWeaponConfig]
@export var meelee_templates: Array
@export var heads_templates: Array[HeadRewardConfig]
@export var legs_templates: Array

@export var options_container: VBoxContainer

enum RewardType {LONG_RANGE, MELEE, HEAD, LEG}
var type: RewardType

var damage_scale := 1.0
var num_choices := 3

var weapon_index := 1 #Usado no sinal weapon added, vai de 1 a 4

signal weapons_configured() # Emitido aqui para os weapon Boxes e saberem quando a arma gerada já estiver settada

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

func _ready() -> void:
	GameEvents.wave_survived.connect(on_wave_survived)
	GameEvents.wave_started.connect(on_wave_started)
	
	call_deferred("wave_0_config")

func wave_0_config() -> void:
	on_wave_survived()

func on_wave_survived() -> void:
	show()
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
			
			first_select_head_button.grab_focus()
			heads_configured.emit()
	


func reward_type_based_on_wave() -> String:
	return wave_num_vs_reward_type[game_state.wave_number] 


func on_wave_started() -> void:
	hide()

## Chamada dentro de on_wave_survived, gera as recompensas de forma procedural:
func generate_rewards(type_of_reward: RewardType) -> Array[RewardConfig]:
	randomize()
	var choices : Array[RewardConfig] = []
	var possible_templates: Array # possibilidades de templates para ser rolado e aparecer nas 3 choices
	match type_of_reward:
		RewardType.LONG_RANGE:
			possible_templates = weapon_templates
		RewardType.MELEE:
			possible_templates = meelee_templates
		RewardType.HEAD:
			possible_templates = heads_templates
		RewardType.LEG:
			possible_templates = legs_templates

	# Garante que temos armas para escolher
	if possible_templates.is_empty():
		push_error("A lista de templates de rewards no RewardManager está vazia! Tipo que está vazio: ", type_of_reward)
		return possible_templates

	# Sorteia 3 armas (ou menos, se não houver 3 templates diferentes)
	var available_templates = possible_templates.duplicate() # Copia para poder embaralhar
	available_templates.shuffle()
	
	for i in range(num_choices):
		var template = available_templates.pick_random()
		
		# 1. DUPLICAR! O passo mais importante para não modificar o arquivo original.
		var rolled_reward = template.duplicate()
		
		# 2. ROLAR OS STATS! A mágica procedural acontece aqui.
		rolled_reward.roll_stats(damage_scale) 
		
		# 3. Adiciona a arma com stats rolados à lista de escolhas
		choices.append(rolled_reward)
		
	return choices
