extends TextureButton

var reroll_cost: int = 5

@export var reroll_price_label: Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_pressed() -> void:
	print("pressed")
	var can_buy := DnaManager.try_spend_dna(reroll_cost)
	if can_buy:
		## Comprou o reroll, devemos aumentar o preço!
		increase_reroll_price()
		## Emitir sinal de do_reroll para o RweardManagerScreen cuidar do reroll
		GameEvents.do_reroll.emit()

func increase_reroll_price() -> void:
	reroll_cost = int(ceil(reroll_cost * 1.11))
	reroll_price_label.text = str(reroll_cost)
