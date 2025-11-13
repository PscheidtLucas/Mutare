class_name InventoryManager extends GridContainer

@export var weapon_slots: Array[WeaponSlot]

@export var head_slots: Array[HeadSlot]

# Este contador agora é PRIVADO do gerenciador.
var weapons_equipped_counter := 1

var head_equipped_counter := 1

func _ready() -> void:
	GameEvents.evolution_completed.connect(_on_evolution_completed)
	# O Gerenciador é o ÚNICO que se conecta ao sinal.
	GameEvents.weapon_selected.connect(_on_weapon_selected)
	GameEvents.head_selected.connect(_on_head_selected)

func _on_evolution_completed() -> void:
	weapons_equipped_counter = 1
	head_equipped_counter = 1

func _on_weapon_selected(weapon_cfg: RangedWeaponConfig):
	# Procura pelo slot que tem o número correspondente ao contador atual
	for slot in weapon_slots:
		if slot.slot_number == weapons_equipped_counter:
			# Encontramos o slot correto!
			slot.equip_weapon(weapon_cfg)
			
			# Incrementa o contador DEPOIS que a arma foi equipada.
			weapons_equipped_counter += 1
			
			# Para de procurar, pois já equipamos a arma.
			return 
	
	printerr("Nenhum slot disponível com o número: ", weapons_equipped_counter)

func _on_head_selected(head_cfg: HeadRewardConfig) -> void:
	for slot in head_slots:
		if slot.slot_number == head_equipped_counter:
			# Encontramos o slot correto!
			slot.equip_head(head_cfg)
			
			# Incrementa o contador DEPOIS que a arma foi equipada.
			head_equipped_counter += 1
			
			# Para de procurar, pois já equipamos a arma.
			return 
	
	printerr("Nenhum slot disponível com o número: ", head_equipped_counter)
