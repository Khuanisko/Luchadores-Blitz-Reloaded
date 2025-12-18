class_name AbilityPromotor
extends ManagerAbilityBase

# The Promotor: Hype Man
# Summoned units get +1/+1 (and +1 Max HP implicitly)

func execute_on_summon(unit_instance, battle_sim) -> void:
	# unit_instance is of type UnitInstance
	# We just modify its stats
	
	unit_instance.max_hp += 1
	unit_instance.hp += 1
	unit_instance.attack += 1
	
	# We might want to log this?
	# Original code didn't log explicitly, just modified values.
