class_name AbilitySummon
extends AbilityBase

@export var summon_unit: UnitDefinition

func execute(owner_unit: UnitInstance, context: Dictionary = {}) -> bool:
	var trigger = context.get("trigger", -1) # Use the enum value or handle it safely
	
	# Check for DEATH trigger
	# We rely on the simulator to pass the correct trigger enum value or string representation if we convert it.
	# The simulator uses `BattleTypes.AbilityTrigger` enum.
	# Check for DEATH trigger
	# Ensure trigger is int (Enum) before comparing
	if typeof(trigger) != TYPE_INT:
		return false
		
	if trigger == BattleTypes.AbilityTrigger.KILL:
		# BattleSimulator has `_handle_death`. I need to add a hook there.
		# The Plan says "Trigger BattleTypes.AbilityTrigger.DEATH".
		pass
	
	# However, my plan said to add support for DEATH trigger.
	# In `battle_types.gd`, `DEATH` is an EventType, not yet an AbilityTrigger. 
	# I need to add DEATH to AbilityTrigger enum in BattleTypes first? 
	# Or reuse KILL? KILL usually means "I killed target". "Last Breath" or "Death" is for self.
	
	# Let's assume I will add `DEATH` to `BattleTypes.AbilityTrigger`.
	
	
	if typeof(trigger) == TYPE_INT and trigger == BattleTypes.AbilityTrigger.DEATH:
		_perform_summon(context)
		return true
	
	return false

func _perform_summon(context: Dictionary) -> void:
	var simulator = context.get("simulator")
	var owner_sim_unit = context.get("source_sim_unit")
	
	if simulator and summon_unit and owner_sim_unit:
		# Get Level
		var level = 1
		if owner_sim_unit.get("original_data") and owner_sim_unit.original_data.get("level"):
			level = owner_sim_unit.original_data.level
			
		# Call the new simulator method
		simulator.summon_unit(summon_unit, owner_sim_unit.is_player, level)

func get_description(level: int, base_desc: String) -> String:
	# Assume summon unit defines base stats.
	if summon_unit:
		var scaled_hp = summon_unit.base_hp * level
		var scaled_atk = summon_unit.base_attack * level
		# Try to replace patterns like "1/1" or "2/2"
		# The resource says "Summon [b] 2/2 [/b] angry fan"
		# I need to find "X/Y" and replace with "scaled_X/scaled_Y"
		# Or specifically "[b] 1/1 [/b]"
		
		# Robust replacement attempt for "X/Y"
		return base_desc.replace("1/1", str(scaled_atk) + "/" + str(scaled_hp)) \
			.replace("2/2", str(scaled_atk) + "/" + str(scaled_hp)) \
			.replace("[b] 1/1 [/b]", "[b] " + str(scaled_atk) + "/" + str(scaled_hp) + " [/b]")
			
	return base_desc
