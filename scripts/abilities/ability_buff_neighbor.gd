class_name AbilityBuffNeighbor
extends AbilityBase

enum BuffType { ATTACK, HP }
enum Target { NEXT_UNIT, PREVIOUS_UNIT } # Usually Next Unit behind in line

@export var buff_type: BuffType = BuffType.ATTACK
@export var amount: int = 1
@export var target_type: Target = Target.NEXT_UNIT

func execute(_owner: UnitInstance, context: Dictionary = {}) -> bool:
	var trigger = context.get("trigger", -1)
	
	# Only run on correct trigger. For Pinfall, it's ON_KO (killer)
	# But make it flexible if we want ability to trigger on START etc?
	# For now check specific trigger or rely on context. 
	# Let's check trigger if provided.
	
	if typeof(trigger) != TYPE_INT:
		return false
		
	if trigger == BattleTypes.AbilityTrigger.ON_KO:
		return _apply_buff(context)
		
	return false

func _apply_buff(context: Dictionary) -> bool:
	var simulator = context.get("simulator")
	var source_sim_unit = context.get("source_sim_unit")
	
	if not simulator or not source_sim_unit:
		return false
		
	# Find neighbor
	var neighbor = _find_neighbor(simulator, source_sim_unit)
	if neighbor:
		# Scale with Level
		var level = 1
		if source_sim_unit.get("original_data") and source_sim_unit.original_data.get("level"):
			level = source_sim_unit.original_data.level
		
		var scaled_amount = amount * level
		
		if buff_type == BuffType.ATTACK:
			neighbor.attack += scaled_amount
		elif buff_type == BuffType.HP:
			neighbor.max_hp += scaled_amount
			neighbor.hp += scaled_amount
		return true
		
	return false

func get_description(level: int, base_desc: String) -> String:
	var scaled_amount = amount * level
	
	# Explicit replacement for Perro Rabioso: "Give +1 attack"
	return base_desc.replace("+" + str(amount) + " attack", "+" + str(scaled_amount) + " attack") \
		.replace("[b] +" + str(amount) + " [/b]", "[b] +" + str(scaled_amount) + " [/b]")

func _find_neighbor(simulator, source_unit) -> Object: # Returns SimUnit
	var queue = simulator._player_queue if source_unit.is_player else simulator._enemy_queue
	
	if queue.is_empty():
		return null
		
	if target_type == Target.NEXT_UNIT:
		# "Next Unit" in the context of a line usually means the one BEHIND you.
		# Since source_unit is the active Fighter (not in queue), the "Next" is the ONE AT THE FRONT of the queue.
		# Queue logic: pop_back() gets fighter. So back() is the front of the line.
		return queue.back()
		
	return null
