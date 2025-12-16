class_name AbilityDamageEntrance
extends AbilityBase

@export var damage: int = 1

func execute(_owner: UnitInstance, context: Dictionary = {}) -> bool:
	var trigger = context.get("trigger", -1)
	
	if typeof(trigger) != TYPE_INT:
		return false
		
	if trigger == BattleTypes.AbilityTrigger.ON_TAG_IN:
		return _apply_damage(context)
		
	return false

func _apply_damage(context: Dictionary) -> bool:
	var simulator = context.get("simulator")
	var target_sim_unit = context.get("target_sim_unit")
	var source_sim_unit = context.get("source_sim_unit")
	
	if not simulator or not target_sim_unit or not source_sim_unit:
		# If no target (empty board), nothing happens
		return false
		
	# Fix Log Order: Trigger MUST appear before Damage.
	# We manually log the 'ability_log' from context here.
	var ability_log = context.get("ability_log", {})
	if not ability_log.is_empty():
		simulator._log(ability_log)
		
	# Deal damage directly
	# Scale with Level: Multi-hit
	var level = 1
	if source_sim_unit.get("original_data") and source_sim_unit.original_data.get("level"):
		level = source_sim_unit.original_data.level
		
	# Loop for multi-hit
	for i in range(level):
		# Determine target for this hit
		var current_target = simulator.get_active_fighter(!source_sim_unit.is_player)
		
		# If current target is dead (HP <= 0), look for next unit in queue
		if not current_target or current_target.hp <= 0:
			var queue = simulator.get_team_queue(!source_sim_unit.is_player)
			if queue and not queue.is_empty():
				current_target = queue.back() # Front of line
				
		if current_target and current_target.hp > 0:
			simulator._apply_damage(current_target, damage, source_sim_unit)
			
	# Return false to avoid double logging
	return false

func get_description(level: int, base_desc: String) -> String:
	# Show number of hits if > 1
	if level > 1:
		return base_desc + " (x" + str(level) + ")"
	return base_desc
