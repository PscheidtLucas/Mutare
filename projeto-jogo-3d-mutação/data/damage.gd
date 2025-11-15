class_name Damage extends Resource

var amount : float = 1.0
var is_crit : bool = false

func _init(_amount: float = 1.0, _is_crit: bool = false) -> void:
	amount = _amount
	is_crit = _is_crit
