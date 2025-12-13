extends SceneTree

func _init():
	print("Running Persistence Test...")
	
	# 1. Setup Mock Data
	var original_unit = UnitInstance.new()
	original_unit.definition = load("res://resources/units/dolores.tres") # Assuming this exists or just using generic
	original_unit.max_hp = 10
	original_unit.hp = 10
	original_unit.attack = 2
	
	# Simulate adding to player team
	GameData.player_team = [original_unit]
	
	print("Original Stats: HP=", original_unit.hp, " Attack=", original_unit.attack)
	
	# 2. Simulate Battle Setup (Logic from battle_arena.gd)
	var battle_queue: Array[UnitInstance] = []
	for unit in GameData.player_team:
		battle_queue.append(unit.duplicate())
		
	# 3. Modify Battle Version
	var battle_unit = battle_queue[0]
	battle_unit.hp -= 5
	battle_unit.attack += 50
	
	print("Battle Unit Stats Modded: HP=", battle_unit.hp, " Attack=", battle_unit.attack)
	
	# 4. Verify Original is Unchanged
	var passed = true
	if original_unit.hp != 10:
		print("FAIL: Original HP changed to ", original_unit.hp)
		passed = false
	current_attack = original_unit.attack
	if current_attack != 2: # Use variable to avoid parser confusion if needed
		print("FAIL: Original Attack changed to ", current_attack)
		passed = false
		
	if passed:
		print("SUCCESS: Original unit preserved.")
	else:
		print("FAILURE: Persistence bug exists.")
		
	quit()

var current_attack: int
