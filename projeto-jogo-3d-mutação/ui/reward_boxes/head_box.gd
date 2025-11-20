class_name HeadBox
extends MarginContainer

const HOVER_MAIN_MENU_1 = preload("uid://c7kbf7cgampxm")
const START_JINGLE = preload("uid://8r8dgcyjjqe3")

signal update_labels

var reward = null
var head_config_generated: HeadRewardConfig # passada pelo reward screen quando o sinal wave survived é emitido

@export var select_button: Button
@export var reward_screen: RewardManager

@onready var margin_container_1: MarginContainer = %MarginContainer1
@onready var margin_container_2: MarginContainer = %MarginContainer2
@onready var margin_container_3: MarginContainer = %MarginContainer3
@onready var margin_container_4: MarginContainer = %MarginContainer4
@onready var rating_value: Label = %RatingValue

func _ready() -> void:
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
	reward_screen.heads_configured.connect(_on_heads_configured)

func _on_heads_configured() -> void:
	if head_config_generated == null:
		return
	configure_stat_labels()

func _on_select_button_pressed() -> void:
	AudioManager.play_sfx(START_JINGLE, 10)
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
		var container: MarginContainer = margin_containers[i]
		container.visible = false
		
		if i < buffs.size():
			var buff: StatBuff = buffs[i]
			container.visible = true
			
			var name_label: Label = container.get_child(0)
			var value_label: Label = container.get_child(1)
			
			var buff_name: String = stat_names[buff.stat].capitalize().replace("_", " ")
			
			var display_value := buff.buff_amount
			if buff.buff_type == StatBuff.BuffType.MULTIPLY:
				display_value = buff.buff_amount * 100.0
			
			var _sign := "+"
			if display_value < 0.0:
				_sign = "-"
			
			var abs_value = abs(display_value)
			var rounded_value = snapped(abs_value, 0.1)
			
			var suffix := ""
			if buff.buff_type == StatBuff.BuffType.MULTIPLY:
				suffix = "%"
			
			var final_value := "%s%.1f%s" % [_sign, rounded_value, suffix]
			name_label.text = buff_name
			value_label.text = final_value
	
	var rating := calculate_head_rating(buffs)
	rating_value.text = str(rating)
	update_labels.emit(head_config_generated)


func calculate_head_rating(buffs: Array[StatBuff]) -> int:
	if buffs.is_empty():
		return 60
	
	var total_score := 0.0
	
	for buff in buffs:
		var min_val := buff.min_buff_amount
		var max_val := buff.max_buff_amount
		
		# Normaliza o valor atual (entre min e max) para 0-1
		var t : float = (buff.buff_amount - min_val) / max(0.0001, (max_val - min_val))
		t = clamp(t, 0.0, 1.0)
		
		total_score += t
	
	var avg_score := total_score / buffs.size()
	
	# Converte média para faixa 50–100
	var rating := int(50.0 + avg_score * 40.0)
	
	return rating


func _on_select_button_mouse_entered() -> void:
	AudioManager.play_sfx(HOVER_MAIN_MENU_1)
