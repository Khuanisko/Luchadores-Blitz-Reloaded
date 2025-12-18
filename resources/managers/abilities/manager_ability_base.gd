class_name ManagerAbilityBase
extends Resource

## Virtual Methods - Override these in concrete classes

# Called at the very start of battle
# battle_sim: The BattleSimulator instance
# is_player: True if this manager belongs to the player, False if enemy
func execute_start_of_battle(battle_sim, is_player: bool) -> void:
	pass

# Called when a unit is summoned
# unit_instance: The UnitInstance being summoned (or SimUnit logic if applicable, but Summon usually happens on UnitInstance creation time in original logic)
# Actually, in BattleSimulator `summon_unit`, it works on `UnitInstance` before creating `SimUnit`.
# So `unit_instance` is `UnitInstance`.
# battle_sim: BattleSimulator instance (if needed for context)
func execute_on_summon(unit_instance, battle_sim) -> void:
	pass

# Called at the start of a shop round
# shop_node: The Shop scene root node
func execute_shop_round_start(shop_node) -> void:
	pass
