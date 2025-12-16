class_name PrizeFighterAbility
extends AbilityBase

@export var health_bonus: int = 1

func execute(owner_unit: UnitInstance, context: Dictionary = {}) -> bool:
	var trigger = context.get("trigger", "")
	
	if typeof(trigger) == TYPE_STRING and trigger == "gold_earned":
		_apply_effect(owner_unit)
		return true
	return false

func _apply_effect(owner_unit: UnitInstance) -> void:
	var scaled_bonus = health_bonus * owner_unit.level
	owner_unit.max_hp += scaled_bonus
	owner_unit.hp += scaled_bonus
	print("Prize Fighter Triggered: %s gains +%d HP" % [owner_unit.unit_name, scaled_bonus])

func get_description(level: int, base_desc: String) -> String:
	var scaled_bonus = health_bonus * level
	
	# Explicit replacement for El Barril pattern: "Gain [b]  +1 [/b] Health" (Double space)
	return base_desc.replace("[b]  +" + str(health_bonus) + " [/b]", "[b] +" + str(scaled_bonus) + " [/b]") \
		.replace("[b] +" + str(health_bonus) + " [/b]", "[b] +" + str(scaled_bonus) + " [/b]") \
		.replace("[b] " + str(health_bonus) + " [/b]", "[b] " + str(scaled_bonus) + " [/b]")
