class_name AbilityBuffSelf
extends AbilityBase

@export var trigger_type: BattleTypes.AbilityTrigger
@export_enum("attack", "max_hp") var stat_name: String = "attack"
@export var amount: int = 1

func execute(_owner: UnitInstance, context: Dictionary = {}) -> bool:
	var current_trigger = context.get("trigger")
	
	# Safety Check: If trigger is not matching the expect type (Int vs String), fail early
	if typeof(current_trigger) != TYPE_INT:
		return false
		
	if current_trigger != trigger_type:
		return false
		
	var source_sim_unit = context.get("source_sim_unit")
	if not source_sim_unit:
		return false
		
	if stat_name == "attack":
		source_sim_unit.attack += amount
		return true
	elif stat_name == "max_hp":
		source_sim_unit.max_hp += amount
		source_sim_unit.hp += amount
		return true
		
	return false
