class_name AbilityOpeningBell
extends AbilityBase

@export var amount: int = 2

func execute(_owner: UnitInstance, context: Dictionary = {}) -> bool:
	# Check trigger
	var current_trigger = context.get("trigger")
	if typeof(current_trigger) != TYPE_INT:
		return false
		
	if current_trigger != BattleTypes.AbilityTrigger.START_OF_BATTLE:
		return false
		
	var simulator = context.get("simulator")
	var source_sim_unit = context.get("source_sim_unit")
	
	if not simulator or not source_sim_unit:
		return false
		
	# Logic: Buff unit at front of line (which is queue.back())
	# We use the public API we just added
	var queue = simulator.get_team_queue(source_sim_unit.is_player)
	if not queue:
		return false
	
	if queue.is_empty():
		return false
		
	var front_unit = queue.back()
	
	# Don't buff self if self is at front (Marco logic)
	if source_sim_unit != front_unit:
		front_unit.max_hp += amount
		front_unit.hp += amount
		return true
		
	return false
