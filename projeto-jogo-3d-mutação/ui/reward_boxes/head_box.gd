class_name HeadBox extends MarginContainer

var reward = null
var head_config_generated : HeadRewardConfig # passada pelo reward screen quando o sinal wave survived é emitido

@export var select_button: Button
@export var reward_screen: RewardManager

# 4 possíveis stats em um item:
@onready var margin_container_1: MarginContainer = %MarginContainer1
@onready var margin_container_2: MarginContainer = %MarginContainer2
@onready var margin_container_3: MarginContainer = %MarginContainer3
@onready var margin_container_4: MarginContainer = %MarginContainer4

#signal update_labels(weapon_config: RewardConfig) ## Emitido aqui para atualizar as weapon_stats_label e também as imagens das armas no ImageContainer

func _ready() -> void:
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
		
	reward_screen.heads_configured.connect(_on_heads_configured)
	## Quando esse sinal é chamado, weapon_config já foi settado, emitido no RewardScreen

func _on_heads_configured() -> void:
	if head_config_generated == null:
		return
	configure_stat_labels()
	#update_labels.emit(head_config_generated)

func _on_select_button_pressed() -> void:
	GameEvents.head_selected.emit(head_config_generated)
	get_tree().paused = false
	
	GameEvents.wave_started.emit() 

func configure_stat_labels() -> void:
	var buffs := head_config_generated.array_of_buffs
	var margin_containers := [
		margin_container_1,
		margin_container_2,
		margin_container_3,
		margin_container_4
	]
	
	var stat_names := PlayerStats.BuffableStats.keys()
	
	for i in range(margin_containers.size()):
		var container : MarginContainer = margin_containers[i]
		container.visible = false
		
		if i < buffs.size():
			var buff : StatBuff = buffs[i]
			container.visible = true
			
			var name_label: Label = container.get_child(0)
			var value_label: Label = container.get_child(1)
			
			var buff_name : String = stat_names[buff.stat].capitalize().replace("_", " ")
			
			# Calcula o valor para exibir
			var display_value := buff.buff_amount
			if buff.buff_type == StatBuff.BuffType.MULTIPLY:
				# Transforma multiplicadores diretos (ex: 0.1 = 10%) em porcentagens corretas
				display_value = buff.buff_amount * 100.0
			else:
				display_value = buff.buff_amount
			
			# Define o sinal (+ ou -)
			var _sign := "+"
			if display_value < 0.0:
				_sign = "-"
			
			# Valor absoluto e arredondado
			var abs_value = abs(display_value)
			var rounded_value = snapped(abs_value, 0.1)
			
			# Adiciona '%' se for multiplicativo
			var suffix := ""
			if buff.buff_type == StatBuff.BuffType.MULTIPLY:
				suffix = "%"
			
			# Monta o texto final
			var final_value := "%s%.1f%s" % [_sign, rounded_value, suffix]
			
			name_label.text = buff_name
			value_label.text = final_value
