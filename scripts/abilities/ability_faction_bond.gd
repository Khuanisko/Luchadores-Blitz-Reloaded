class_name FactionBondAbility
extends AbilityBase

enum EffectType { BUFF_SELF, GAIN_GOLD }

@export var required_faction: String = ""
@export var effect_type: EffectType = EffectType.BUFF_SELF
@export var amount: int = 1

func execute(owner_unit: UnitInstance, context: Dictionary = {}) -> bool:
	var bought_unit = context.get("bought_unit") as UnitInstance
	if not bought_unit:
		return false
		
	# Check Faction Match
	if bought_unit.faction == required_faction:
		_apply_effect(owner_unit)
		return true
	
	return false

func _apply_effect(owner_unit: UnitInstance) -> void:
	var scaled_amount = amount * owner_unit.level
	
	match effect_type:
		EffectType.BUFF_SELF:
			owner_unit.max_hp += scaled_amount
			owner_unit.hp += scaled_amount
			print("Faction Bond (Buff): %s gained +%d HP" % [owner_unit.unit_name, scaled_amount])
			
		EffectType.GAIN_GOLD:
			GameData.gain_gold(scaled_amount)
			print("Faction Bond (Gold): Gained +%d Gold" % scaled_amount)

func get_description(level: int, base_desc: String) -> String:
	var scaled_amount = amount * level
	
	# Explicit replacement based on known patterns in resources (Gonzales, Don Pedro)
	# Gonzales: "Gains [b] +1 [/b] health"
	# Don Pedro: "Gain 1 gold"
	
	return base_desc.replace("[b] +" + str(amount) + " [/b]", "[b] +" + str(scaled_amount) + " [/b]") \
		.replace("[b] " + str(amount) + " [/b]", "[b] " + str(scaled_amount) + " [/b]") \
		.replace("Gain " + str(amount) + " gold", "Gain " + str(scaled_amount) + " gold")
