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
	
	# SCALING: Use definition level if available, or try to get from source unit
	var level = 1
	if source_sim_unit.get("original_data") and source_sim_unit.original_data.get("level"):
		level = source_sim_unit.original_data.level
	
	var scaled_amount = amount * level
		
	if stat_name == "attack":
		source_sim_unit.attack += scaled_amount
		return true
	elif stat_name == "max_hp":
		source_sim_unit.max_hp += scaled_amount
		source_sim_unit.hp += scaled_amount
		return true
		
	return false

func get_description(level: int, base_desc: String) -> String:
	var scaled_amount = amount * level
	return base_desc.replace("[b] +" + str(amount) + " [/b]", "[b] +" + str(scaled_amount) + " [/b]") \
		.replace("[b] " + str(amount) + " [/b]", "[b] " + str(scaled_amount) + " [/b]")
