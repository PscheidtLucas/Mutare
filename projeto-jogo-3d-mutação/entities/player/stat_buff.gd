class_name StatBuff
extends Resource

enum BuffType {
	MULTIPLY,
	ADD,
}

@export var stat: PlayerStats.BuffableStats
@export var buff_type: BuffType
@export var buff_amount: float

## Com essa função, para adicionar um buff basta fazer StatBuff.new() em qualquer lugar do projeto!
func _init(_stat: PlayerStats.BuffableStats, _buff_amount: float = 1.0, _buff_type: StatBuff.BuffType = BuffType.MULTIPLY) -> void:
	stat = _stat
	buff_type = _buff_type
	buff_amount = _buff_amount
