extends Node

#player manager

var player : Player
## Usado na funcao equip_weapons do player para equipar a arma inicial:
var equipped_weapons: Array[PackedScene]= [preload("uid://b7jx3gi1kdegw")]
