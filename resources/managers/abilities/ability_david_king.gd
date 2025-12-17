class_name AbilityDavidKing
extends ManagerAbilityBase

# David King: Opening Bell
# Deals 2 damage to the first enemy unit at the start of battle.

func execute_start_of_battle(battle_sim, is_player: bool) -> void:
	# Logic from BattleSimulator.gd lines 160-180 roughly
	
	# We need access to queues. BattleSimulator needs to expose them or helper methods.
	# "battle_sim" is the `self` from BattleSimulator.
	# BattleSimulator has `get_team_queue(is_player)` and `_check_spawn`.
	
	# Target is the OPPONENT.
	var is_target_player = not is_player
	var target_queue_array = battle_sim.get_team_queue(is_target_player)
	
	if not target_queue_array.is_empty():
		# 1. Spawn target if needed so they are the active fighter
		# We need a way to force spawn or check active fighter.
		# `_check_spawn(is_target_player)` is private `_check_spawn` in Sim.
		# I might need to make it public or use a public wrapper.
		# Let's assume we make `check_spawn` public or use `perform_spawn_check`.
		
		# For now, I'll assume I can call `check_spawn` (I will implement this in Sim).
		battle_sim.check_spawn(is_target_player)
		
		# 2. Get active fighter
		var target_fighter = battle_sim.get_active_fighter(is_target_player)
		
		if target_fighter:
			# 3. Deal Damage
			# "David King Opening Bell"
			battle_sim.apply_damage(target_fighter, 2, null)
			
			# Log it? sim.log(...)
			# The Sim usually logs damage inside apply_damage.
			# But we might want a specific Ability Trigger log.
			# Sim._log is private.
			# `apply_damage` will log the damage.
			# The original code logged an ABILITY_TRIGGER event.
			
			battle_sim.log_ability_trigger(BattleTypes.AbilityTrigger.START_OF_BATTLE, -1, "David King Opening Bell")
			
			# 4. Handle Death
			if target_fighter.hp <= 0:
				battle_sim.handle_death(target_fighter)
