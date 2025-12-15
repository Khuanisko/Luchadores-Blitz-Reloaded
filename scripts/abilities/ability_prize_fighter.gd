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
	owner_unit.max_hp += health_bonus
	owner_unit.hp += health_bonus
	print("Prize Fighter Triggered: %s gains +%d HP" % [owner_unit.unit_name, health_bonus])
