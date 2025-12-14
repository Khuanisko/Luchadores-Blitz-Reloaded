extends SceneTree

# Simple Test Runner for BattleSimulator
func _init():
	print("--- Starting Battle Simulation Test ---")
	
	# Create some dummy definitions
	var marco_def = UnitDefinition.new()
	marco_def.id = "marco"
	marco_def.unit_name = "Marco"
	marco_def.base_attack = 2
	marco_def.base_hp = 3
	marco_def.ability_name = "Test Ability"
	
	var dolores_def = UnitDefinition.new()
	dolores_def.id = "dolores"
	dolores_def.unit_name = "Dolores"
	dolores_def.base_attack = 1
	dolores_def.base_hp = 2
	dolores_def.ability_name = "Test Ability"

	# Create Instances
	var p_unit1 = UnitInstance.new(marco_def)
	var e_unit1 = UnitInstance.new(dolores_def)
	
	var player_team = [p_unit1]
	var enemy_team = [e_unit1]
	
	print("Player Team: ", p_unit1.unit_name, " HP:", p_unit1.hp, " ATK:", p_unit1.attack)
	print("Enemy Team: ", e_unit1.unit_name, " HP:", e_unit1.hp, " ATK:", e_unit1.attack)
	
	var sim = BattleSimulator.new()
	var result = sim.simulate(player_team, enemy_team)
	
	print("\n--- Simulation Complete ---")
	print("Winner: ", BattleTypes.Winner.keys()[result.winner])
	print("Log Events: ", result.log.size())
	
	for event in result.log:
		var type_name = BattleTypes.EventType.keys()[event.type]
		var details = str(event)
		# Clean up dictionary print for readability if needed, or just dump it
		print("[%s] %s" % [type_name, details])
		
	quit()
