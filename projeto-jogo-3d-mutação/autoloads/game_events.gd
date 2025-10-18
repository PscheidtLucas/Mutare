extends Node

signal wave_started # emitido no weaponBox ao selecionar uma arma, usado para avisar o game manager e spawn q começou
signal wave_survived # stars on wave 1

signal player_died
signal player_took_damage
signal weapon_selected #emitido no weaponBox, usado no player para passar a arma equipada
