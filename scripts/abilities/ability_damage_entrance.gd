class_name AbilityDamageEntrance
extends AbilityBase

@export var damage: int = 1

func execute(_owner: UnitInstance, context: Dictionary = {}) -> bool:
	var trigger = context.get("trigger", -1)
	
	if typeof(trigger) == TYPE_INT and trigger == BattleTypes.AbilityTrigger.ON_TAG_IN:
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
	simulator._apply_damage(target_sim_unit, damage, source_sim_unit)
	# print("Entrance Ability: %s dealt %d damage to %s" % [source_sim_unit.original_data.unit_name, damage, target_sim_unit.original_data.unit_name])
	
	# Return false so _try_ability doesn't log it again!
	return false
