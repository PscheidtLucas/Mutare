extends Node

#player manager

var player : Player
var equipped_weapons: Array[PackedScene]= [preload("res://weapons/pistola/pistola_scene.tscn"), preload("res://weapons/cannon_bomb_gun/cannon_bomb_gun.tscn")]
