extends SceneTree

func _init():
	print("Running Pinned Ability Test...")
	
	# 1. Load Units
	var dave_def = load("res://resources/units/littledave.tres")
	if not dave_def:
		print("FAIL: Could not load Little Dave")
		quit()
		return

	var enemy_def = load("res://resources/units/gonzales.tres") # Assume Gonzales exists and is strong enough
	if not enemy_def:
		# Fallback to creating a dummy strong enemy
		enemy_def = UnitDefinition.new()
		enemy_def.unit_name = "Strong Dummy"
		enemy_def.base_hp = 10
		enemy_def.base_attack = 10
	
	# 2. Create Instances
	# Little Dave (Player)
	var dave_inst = UnitInstance.new()
	dave_inst.definition = dave_def
	dave_inst.hp = 1 # Weak, ensuring death
	dave_inst.max_hp = 1
	dave_inst.attack = 1
	
	# Enemy (Enemy Team)
	var enemy_inst = UnitInstance.new()
	enemy_inst.definition = enemy_def
	enemy_inst.hp = 10
	enemy_inst.max_hp = 10
	enemy_inst.attack = 10 # One shot kill
	
	var player_team = [dave_inst]
	var enemy_team = [enemy_inst]
	
	# 3. specific check: Ensure Dave has the ability resource
	if dave_def.ability_resource == null:
		print("FAIL: Little Dave has no ability resource assigned!")
	else:
		print("Little Dave has ability resource: ", dave_def.ability_resource)
	
	# 4. Run Simulation
	var sim = BattleSimulator.new()
	var result = sim.simulate(player_team, enemy_team)
	
	print("Sim Log Size: ", result.log.size())
	
	# 5. Analyze Log
	var found_death = false
	var found_summon = false
	var death_idx = -1
	
	for i in range(result.log.size()):
		var event = result.log[i]
		var type = event.type
		
		# Log types are Enums (int). We compare values.
		# BattleTypes.EventType.DEATH (5)
		# BattleTypes.EventType.SPAWN_UNIT (1)
		
		if type == BattleTypes.EventType.DEATH:
			if event.unit_name == "Little Dave" or (event.has("unit_id") and event.unit_id == 0): # First unit id usually 0
				print("Step ", i, ": Dave Died.")
				found_death = true
				death_idx = i
				
		if type == BattleTypes.EventType.SPAWN_UNIT:
			if event.unit_name == "Angry Fan":
				print("Step ", i, ": Angry Fan Spawned!")
				found_summon = true
				if death_idx != -1 and i > death_idx:
					# This is fine if it happens after death in log order, 
					# or before?
					# Logic: _handle_death -> _try_ability(DEATH) -> summon -> log(SPAWN) -> log(DEATH)
					# Wait, _handle_death logs DEATH at the END of the function.
					# And we invoke ability BEFORE logging DEATH.
					# So SPAWN should appear BEFORE DEATH in the log?
					# Let's check `battle_simulator.gd`:
					# func _handle_death(unit):
					#    _try_ability(DEATH...) -> calls summon -> logs SPAWN
					#    _log(DEATH)
					# So SPAWN should be BEFORE DEATH log event.
					pass
				elif death_idx == -1:
					# Spawned before death log? Yes, expected.
					pass
					
	if found_summon:
		print("SUCCESS: Angry Fan was summoned.")
	else:
		print("FAILURE: Angry Fan was NOT summoned.")
		# Debug print entire log
		for e in result.log:
			print(e)
			
	quit()
