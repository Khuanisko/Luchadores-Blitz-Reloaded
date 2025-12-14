class_name PrizeFighterAbility
extends AbilityBase

@export var health_bonus: int = 1

func execute(owner_unit: UnitInstance, context: Dictionary = {}) -> void:
	var trigger = context.get("trigger", "")
	
	if trigger == "gold_earned":
		_apply_effect(owner_unit)

func _apply_effect(owner_unit: UnitInstance) -> void:
	owner_unit.max_hp += health_bonus
	owner_unit.hp += health_bonus
	print("Prize Fighter Triggered: %s gains +%d HP" % [owner_unit.unit_name, health_bonus])
