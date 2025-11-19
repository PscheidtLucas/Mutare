extends MarginContainer

@export var dna_amount_label : Label


func _ready() -> void:
	GameEvents.dna_balance_changed.connect(_on_dna_balance_change)


func _on_dna_balance_change(new_amount: int) -> void:
	dna_amount_label.text = str(new_amount)
	
