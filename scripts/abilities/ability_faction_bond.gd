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
	match effect_type:
		EffectType.BUFF_SELF:
			owner_unit.max_hp += amount
			owner_unit.hp += amount
			print("Faction Bond (Buff): %s gained +%d HP" % [owner_unit.unit_name, amount])
			
		EffectType.GAIN_GOLD:
			GameData.gain_gold(amount)
			print("Faction Bond (Gold): Gained +%d Gold" % amount)
