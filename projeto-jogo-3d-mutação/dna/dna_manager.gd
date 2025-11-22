class_name DnaManager extends Node

static var current_dna: int = 0

func _ready() -> void:
	GameEvents.player_collected_dna.connect(_on_dna_collected)
	

func _on_dna_collected() -> void:
	current_dna += 1
	GameEvents.dna_balance_changed.emit(current_dna)


static func try_spend_dna(amount: int) -> bool:
	if current_dna >= amount:
		current_dna -= amount
		GameEvents.dna_balance_changed.emit(current_dna)
		return true
	else:
		return false
	
