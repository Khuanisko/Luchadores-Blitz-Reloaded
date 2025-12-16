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
		# Call the new simulator method
		simulator.summon_unit(summon_unit, owner_sim_unit.is_player)
