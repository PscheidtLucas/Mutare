class_name EvoMarginContainer
extends MarginContainer

@export var reward_box: MarginContainer
@onready var number_value_label: Label = %NumberValueLabel
@onready var bonus_word_1: Label = %BonusWord1
@onready var bonus_word_2: Label = %BonusWord2


func _ready() -> void:
	reward_box.update_labels.connect(_on_reward_selected)


func _on_reward_selected(reward_config: RewardConfig) -> void:
	if reward_config == null or not (reward_config is RewardConfig):
		_hide_all()
		return

	var buff_type := reward_config.perma_buff_type
	var buff_amount := reward_config.perma_buff_amount

	# Se não há bônus ativo, esconde tudo
	if buff_amount <= 0.0:
		_hide_all()
		return

	# Define se o bônus é percentual ou absoluto
	var is_percentual := true

	number_value_label.show()

	if is_percentual:
		number_value_label.text = "+%.1f%%" % (buff_amount * 100.0)
	else:
		# Exibe valor absoluto, sem % — arredondado se for float
		number_value_label.text = "+%.1f" % buff_amount

	# Define as palavras conforme o tipo do buff
	match buff_type:
		RewardConfig.PermaBuffType.DAMAGE:
			_set_bonus_words("DMG")
		RewardConfig.PermaBuffType.FIRE_RATE:
			_set_bonus_words("FIRE", "RATE")
		RewardConfig.PermaBuffType.MOVE_SPEED:
			_set_bonus_words("MOVE", "SPD")
		#RewardConfig.PermaBuffType.HP_REGEN:
			#_set_bonus_words("HP5")
		#RewardConfig.PermaBuffType.MAX_HP:
			#_set_bonus_words("MAX", "HP")
		RewardConfig.PermaBuffType.CRIT_CHANCE:
			_set_bonus_words("CRIT", "CHNC")
		RewardConfig.PermaBuffType.CRIT_DAMAGE:
			_set_bonus_words("CRIT", "DMG")
		_:
			_hide_all()


func _set_bonus_words(word1: String, word2: String = "") -> void:
	bonus_word_1.text = word1
	bonus_word_1.show()

	if word2 != "":
		bonus_word_2.text = word2
		bonus_word_2.show()
	else:
		bonus_word_2.hide()


func _hide_all() -> void:
	number_value_label.text = ""
	bonus_word_1.text = ""
	bonus_word_2.text = ""
	bonus_word_1.hide()
	bonus_word_2.hide()
	number_value_label.hide()
