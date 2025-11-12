class_name EvoMarginContainer
extends MarginContainer

@export var weapon_box: WeaponBox
@onready var number_value_label: Label = %NumberValueLabel
@onready var bonus_word_1: Label = %BonusWord1
@onready var bonus_word_2: Label = %BonusWord2


func _ready() -> void:
	weapon_box.update_labels.connect(_on_weapon_selected)


func _on_weapon_selected(weapon_config: RewardConfig) -> void:
	print("weapon selected, weapon config no evoMargin: ", weapon_config)
	if weapon_config == null or not (weapon_config is RangedWeaponConfig):
		_hide_all()
		return

	var ranged_config := weapon_config as RangedWeaponConfig
	var buff_type := ranged_config.perma_buff_type
	var buff_amount := ranged_config.perma_buff_amount

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
		RewardConfig.PermaBuffType.RANGE:
			_set_bonus_words("RANGE")
		RewardConfig.PermaBuffType.ACCURACY:
			_set_bonus_words("ACC")
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
