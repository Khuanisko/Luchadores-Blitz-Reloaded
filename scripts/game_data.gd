extends Node

# Game state for HUD
var player_lives: int = 5
var player_wins: int = 0
var current_round: int = 1
var selected_manager: ManagerDefinition


var player_team: Array[UnitInstance] = []
var enemy_team: Array[UnitInstance] = []



const STARTING_GOLD: int = 1000
var gold: int = STARTING_GOLD
signal gold_changed(new_amount: int)
signal gold_earned(amount: int)
signal unit_purchased(unit: UnitInstance)

func gain_gold(amount: int) -> void:
	if amount <= 0: return
	gold += amount
	gold_changed.emit(gold)
	gold_earned.emit(amount)

func spend_gold(amount: int) -> void:
	if amount <= 0: return
	gold -= amount
	gold_changed.emit(gold)

func reset_gold() -> void:
	gold = STARTING_GOLD
	gold_changed.emit(gold)

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
		if unit:
			enemy_team.append(unit)


func _create_unit(unit_name: String) -> UnitInstance:
	var file_name = unit_name.to_lower().replace(" ", "")
	# Handle special mappings if needed, but snake_case usually works or simplified
	# "El Torro" -> "eltorro" matches the .tres file name I created
	
	var path = "res://resources/units/" + file_name + ".tres"
	if ResourceLoader.exists(path):
		var definition = load(path) as UnitDefinition
		var unit = UnitInstance.new(definition)
		return unit
	else:
		print("Unit resource not found: ", path)
		return null
