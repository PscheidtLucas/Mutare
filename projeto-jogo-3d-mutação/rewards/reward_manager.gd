class_name RewardManager extends Control

@export var first_select_button: Button

@export var weapon_templates: Array[RangedWeaponConfig]
@export var meelee_templates: Array
@export var heads_templates: Array
@export var legs_templates: Array

@export var options_container: VBoxContainer

enum RewardType {LONG_RANGE, MELEE, HEAD, LEG}
var type: RewardType

var damage_scale := 1.0
var num_choices := 3

var weapon_index := 1 #Usado no sinal weapon added, vai de 1 a 4

signal weapons_configured() # Emitido aqui para os weapon Boxes e saberem quando a arma gerada já estiver settada

func _ready() -> void:
	GameEvents.wave_survived.connect(on_wave_survived)
	GameEvents.weapon_selected.connect(on_weapon_selected)
	
	call_deferred("wave_0_config")

func wave_0_config() -> void:
	on_wave_survived()

func on_wave_survived() -> void:
	show()
	var index = 0
	var generated_weapons : Array = generate_rewards(RewardType.LONG_RANGE) ## TODO: Arrumar isso aqui para gerar o tipo de recompensa certo de acordo com o número da wave que é passado, e atualizar o número da wave também
	for weapon_box: WeaponBox in options_container.get_children():
		weapon_box.weapon_config_generated = generated_weapons[index]
		index += 1
	weapons_configured.emit()
	
	first_select_button.grab_focus()
	
func on_weapon_selected(weapon_config) -> void:
	hide()

## Chamada dentro de on_wave_survived, gera as recompensas de forma procedural:
func generate_rewards(type_of_reward: RewardType) -> Array[RewardConfig]:
	print("generating rewards")
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
