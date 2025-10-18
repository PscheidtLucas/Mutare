class_name WeaponStatsLabel extends Label

enum StatType { 
	DAMAGE, 
	PROJ_COUNT, 
	FIRE_RATE, 
	ACCURACY, 
	PROJ_SPEED, 
	RANGE, 
	TRAN_BONUS 
}

@export var weapon_box: WeaponBox # Precisamos acessar weapon box para conectar o sinal que indica quandoa atualizar as labels

@export var stat_type: StatType

func _ready() -> void:
	weapon_box.update_labels.connect(on_update_labels)

func on_update_labels() -> void:
	pass
