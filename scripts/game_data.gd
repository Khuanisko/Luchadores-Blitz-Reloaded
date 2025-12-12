extends Node



var player_team: Array[UnitData] = []
var enemy_team: Array[UnitData] = []

func generate_enemy_team() -> void:
	enemy_team.clear()
	
	var presets = [
		["Marco", "Dolores"],
		["El Torro", "Dolores", "Marco"],
		["El Jaguarro", "Dolores", "El Torro", "Marco", "Gonzales"]
	]
	
	var chosen_preset = presets.pick_random()
	print("Enemy Team Generated: ", chosen_preset)
	
	for unit_name in chosen_preset:
		var unit = _create_unit(unit_name)
		enemy_team.append(unit)


func _create_unit(unit_name: String) -> UnitData:
	var unit = UnitData.new()
	unit.unit_name = unit_name
	
	# Load stats
	var stats = CharacterStats.get_stats(unit_name)
	unit.hp = stats.hp
	unit.max_hp = stats.hp
	unit.attack = stats.attack
	unit.cost = stats.cost
	
	# We don't need texture here as Fighter scene loads it by name
	# But checking for box texture if needed for debugging or future UI
	# skipping texture load for now to keep it lightweight, Fighter loads sprite
	
	return unit
