class_name StatBuff
extends Resource

## Os nomes MULTIPLY e ADD estao bem errados, significam PERCENTUAL E NAO-PERCENTUAL (pra saber se mostra % ou nao na UI e como faz a conta, se multiplica por 100 ou nao...)
enum BuffType {
	MULTIPLY,
	ADD,
}

@export var stat: PlayerStats.BuffableStats
@export var buff_type: BuffType
@export var min_buff_amount: float
@export var max_buff_amount: float

var buff_amount: float

## Com essa função, para adicionar um buff basta fazer StatBuff.new() em qualquer lugar do projeto!
#func _init(_stat: PlayerStats.BuffableStats, _min_amount: float = 0.0, _max_amount: float = 0.0, _buff_type: StatBuff.BuffType = BuffType.MULTIPLY) -> void:
	#stat = _stat
	#buff_type = _buff_type
	#if _min_amount != 0.0:
		#buff_amount = randf_range(_min_amount, _max_amount)
	#else:
		#buff_amount = randf_range(min_buff_amount, max_buff_amount)
