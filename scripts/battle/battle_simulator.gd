class_name BattleSimulator
extends RefCounted

# Result Structure
class BattleResult:
	var winner: BattleTypes.Winner = BattleTypes.Winner.NONE
	var log: Array[Dictionary] = []
	var rounds_survived: int = 0

# Data structures for simulation
class SimUnit:
	var original_data: UnitInstance
	var hp: int
	var max_hp: int
	var attack: int
	var id: int # Unique ID for this battle instance to track in logs
	var is_player: bool
	var definition: UnitDefinition # Quick access
	var is_summon: bool = false
	
	func _init(unit: UnitInstance, _id: int, _is_player: bool, _is_summon: bool = false):
		original_data = unit
		hp = unit.hp
		max_hp = unit.max_hp
		attack = unit.attack
		id = _id
		is_player = _is_player
		definition = unit.definition


# State
var _unit_id_counter: int = 0
var _battle_log: Array[Dictionary] = []
var _player_queue: Array[SimUnit] = []
var _enemy_queue: Array[SimUnit] = []
var _player_fighter: SimUnit = null
var _enemy_fighter: SimUnit = null

# --- Public API ---

func get_team_queue(is_player: bool) -> Array:
	return _player_queue if is_player else _enemy_queue

func get_active_fighter(is_player: bool) -> SimUnit:
	return _player_fighter if is_player else _enemy_fighter

func apply_damage(target: SimUnit, amount: int, source: SimUnit) -> void:
	_apply_damage(target, amount, source)

func check_spawn(is_player: bool) -> SimUnit:
	return _check_spawn(is_player)

func handle_death(unit: SimUnit) -> void:
	_handle_death(unit)

func log_ability_trigger(trigger: BattleTypes.AbilityTrigger, source_id: int, ability_name: String) -> void:
	_log({
		"type": BattleTypes.EventType.ABILITY_TRIGGER,
		"trigger": trigger,
		"source": source_id,
		"ability_name": ability_name
	})

func simulate(player_team: Array[UnitInstance], enemy_team: Array[UnitInstance]) -> BattleResult:
	_reset()
	
	# Prepare queues (deep copy for simulation state)
	# Note: We process queues from back (pop_back) or front? 
	# GameData seems to treat them as arrays. Usually front unit fights first?
	# In Arena code: player_queue.pop_back(). So valid index 0 is at back of line?
	# Let's verify Arena logic: `player_queue = [] ... append(...) ... pop_back()`.
	# Append adds to end. Pop_back takes from end. So index N is first fighter.
	
	for unit in player_team:
		_player_queue.append(_create_sim_unit(unit, true))
		
	for unit in enemy_team:
		_enemy_queue.append(_create_sim_unit(unit, false))
		
	var result = BattleResult.new()
	
	_log({ "type": BattleTypes.EventType.ROUND_START })
	
	# 0. Start of Battle Triggers (Opening Bell etc.)
	_resolve_start_of_battle()
	
	# Main Battle Loop
	var max_loops = 100 # Safety break
	var loop_count = 0
	
	while loop_count < max_loops:
		loop_count += 1
		
		# 1. Spawn Step
		# 1. Spawn Step
		var p_spawned = _check_spawn(true)
		var e_spawned = _check_spawn(false)
		
		# Resolving ON_TAG_IN (Entrance) Triggers
		# Collect triggers from newly spawned units
		if p_spawned or e_spawned:
			var tag_triggers = []
			
			if p_spawned:
				# Opponent is _enemy_fighter (could be newly spawned)
				# Check legacy Entrance if needed, or use ON_TAG_IN directly
				_try_ability(BattleTypes.AbilityTrigger.ENTRANCE, p_spawned, _enemy_fighter) # Legacy check
				if _calculate_ability_trigger_potential(p_spawned, BattleTypes.AbilityTrigger.ON_TAG_IN):
					tag_triggers.append({"source": p_spawned, "target": _enemy_fighter})
					
			if e_spawned:
				_try_ability(BattleTypes.AbilityTrigger.ENTRANCE, e_spawned, _player_fighter) # Legacy check
				if _calculate_ability_trigger_potential(e_spawned, BattleTypes.AbilityTrigger.ON_TAG_IN):
					tag_triggers.append({"source": e_spawned, "target": _player_fighter})
			
			# Sort simultaneous triggers by Attack Descending, then Random
			if tag_triggers.size() > 1:
				tag_triggers.sort_custom(func(a, b):
					var a_atk = a.source.attack
					var b_atk = b.source.attack
					if a_atk != b_atk:
						return a_atk > b_atk
					return randf() > 0.5
				)
				
			for t in tag_triggers:
				_try_ability(BattleTypes.AbilityTrigger.ON_TAG_IN, t.source, t.target)
				
		# Fix Zombie Bug: Check for deaths immediately after Entrance abilities
		if _player_fighter and _player_fighter.hp <= 0:
			_handle_death(_player_fighter)
		if _enemy_fighter and _enemy_fighter.hp <= 0:
			_handle_death(_enemy_fighter)
		
		# 2. Check Win Condition immediately after potential spawns
		var status = _check_winner()
		if status != BattleTypes.Winner.NONE:
			result.winner = status
			break
			
		# 3. Combat Step
		if _player_fighter and _enemy_fighter:
			_resolve_combat_round()
			
		# 4. Check Win Condition after combat (deaths)
		status = _check_winner()
		if status != BattleTypes.Winner.NONE:
			result.winner = status
			break
			
	result.log = _battle_log
	_log({ "type": BattleTypes.EventType.ROUND_END, "winner": result.winner })
	return result

	return result

func _resolve_start_of_battle():
	# Manager Start of Battle Abilities (Strategy Pattern)
	var managers_to_act = []
	
	if GameData.selected_manager and GameData.selected_manager.ability_script:
		managers_to_act.append({"manager": GameData.selected_manager, "is_player": true})
		
	if GameData.enemy_manager and GameData.enemy_manager.ability_script:
		managers_to_act.append({"manager": GameData.enemy_manager, "is_player": false})
	
	# Randomize order if multiple managers have abilities (fairness for mirror matches)
	if managers_to_act.size() > 1:
		managers_to_act.shuffle()
		
	for entry in managers_to_act:
		var mgr = entry.manager
		# Safety check as requested
		if mgr.ability_script:
			# Instantiate the script
			var ability = mgr.ability_script.new()
			if ability.has_method("execute_start_of_battle"):
				ability.execute_start_of_battle(self, entry.is_player)
	
	var triggers = []
	
	# Collect from Player Queue
	for unit in _player_queue:
		if unit.definition and unit.definition.ability_resource:
			triggers.append({ "unit": unit, "attack": unit.attack, "tie": randf() })
			
	# Collect from Enemy Queue
	for unit in _enemy_queue:
		if unit.definition and unit.definition.ability_resource:
			triggers.append({ "unit": unit, "attack": unit.attack, "tie": randf() })
			
	# Sort: Attack Descending, then Random Tie-breaker
	triggers.sort_custom(func(a, b):
		if a.attack != b.attack:
			return a.attack > b.attack # Higher attack first
		return a.tie > b.tie # Random check
	)
	
	# Execute
	for t in triggers:
		_try_ability(BattleTypes.AbilityTrigger.START_OF_BATTLE, t.unit, null)

# --- Internal Logic ---

func _reset():
	_unit_id_counter = 0
	_battle_log.clear()
	_player_queue.clear()
	_enemy_queue.clear()
	_player_fighter = null
	_enemy_fighter = null

func _create_sim_unit(unit: UnitInstance, is_player: bool, is_summon: bool = false) -> SimUnit:
	var sim = SimUnit.new(unit, _unit_id_counter, is_player, is_summon)
	_unit_id_counter += 1
	return sim

func _log(event: Dictionary):
	_battle_log.append(event)

func _check_spawn(is_player: bool) -> SimUnit:
	var fighter = _player_fighter if is_player else _enemy_fighter
	
	if fighter == null:
		var queue = _player_queue if is_player else _enemy_queue
		if not queue.is_empty():
			# Spawn next unit
			var next_unit = queue.pop_back()
			if is_player: _player_fighter = next_unit
			else: _enemy_fighter = next_unit
			
			_log({
				"type": BattleTypes.EventType.SPAWN_UNIT,
				"unit_id": next_unit.id,
				"is_player": is_player,
				"unit_name": next_unit.original_data.unit_name,
				"definition_id": next_unit.definition.id if next_unit.definition else "",
				"hp": next_unit.hp,
				"max_hp": next_unit.max_hp,
				"attack": next_unit.attack
			})
			
			return next_unit
	return null

func _check_winner() -> BattleTypes.Winner:
	var p_active = _player_fighter != null
	var p_queue = not _player_queue.is_empty()
	var p_alive = p_active or p_queue
	
	var e_active = _enemy_fighter != null
	var e_queue = not _enemy_queue.is_empty()
	var e_alive = e_active or e_queue
	
	if not p_alive and not e_alive:
		return BattleTypes.Winner.DRAW
		
	if not p_alive:
		# Enemy Wins
		# If Enemy has no active fighter (only queue), wait for spawn
		if not e_active and e_queue:
			return BattleTypes.Winner.NONE
		return BattleTypes.Winner.ENEMY
		
	if not e_alive:
		# Player Wins
		# If Player has no active fighter (only queue), wait for spawn
		if not p_active and p_queue:
			return BattleTypes.Winner.NONE
		return BattleTypes.Winner.PLAYER
		
	return BattleTypes.Winner.NONE

func _resolve_combat_round():
	# Simultaneous attacks
	var p = _player_fighter
	var e = _enemy_fighter
	
	# 1. Triggers before attack (if any)
	_try_ability(BattleTypes.AbilityTrigger.ATTACK, p, e)
	_try_ability(BattleTypes.AbilityTrigger.ATTACK, e, p)
	
	# 2. Deal Damage
	# Log attacks
	_log({ "type": BattleTypes.EventType.ATTACK, "source": p.id, "target": e.id })
	_log({ "type": BattleTypes.EventType.ATTACK, "source": e.id, "target": p.id })
	
	var p_dmg = p.attack
	var e_dmg = e.attack
	
	_apply_damage(e, p_dmg, p)
	_apply_damage(p, e_dmg, e)
	
	# 3. Check Deaths
	var p_dead = p.hp <= 0
	var e_dead = e.hp <= 0
	
	# Independent checks to handle Double KO
	if e_dead:
		_try_ability(BattleTypes.AbilityTrigger.KILL, p, e)
		_try_ability(BattleTypes.AbilityTrigger.ON_KO, p, e)
		
	if p_dead:
		_try_ability(BattleTypes.AbilityTrigger.KILL, e, p)
		_try_ability(BattleTypes.AbilityTrigger.ON_KO, e, p)
		
	if p_dead: _handle_death(p)
	if e_dead: _handle_death(e)

func _apply_damage(target: SimUnit, amount: int, source: SimUnit):
	target.hp -= amount
	_log({
		"type": BattleTypes.EventType.DAMAGE,
		"target": target.id,
		"amount": amount,
		"new_hp": target.hp,
		"source": source.id if source else -1
	})
	
	_check_payback_triggers(target)

func _check_payback_triggers(victim: SimUnit):
	# Payback triggers for the unit directly BEHIND the victim
	var queue = _player_queue if victim.is_player else _enemy_queue
	var active_fighter = _player_fighter if victim.is_player else _enemy_fighter
	
	var friend_behind: SimUnit = null
	
	# Case 1: Victim is the active fighter - check queue front
	if victim == active_fighter:
		if not queue.is_empty():
			friend_behind = queue.back()
	else:
		# Case 2: Victim is in the queue (e.g. David King's Opening Bell)
		var victim_index = queue.find(victim)
		if victim_index > 0:
			# Unit behind is at lower index (queue goes [..., behind, victim] where victim is at back)
			friend_behind = queue[victim_index - 1]
	
	if friend_behind and friend_behind != victim:
		_try_ability(BattleTypes.AbilityTrigger.FRIEND_TOOK_DAMAGE, friend_behind, victim)

func _handle_death(unit: SimUnit):
	# Trigger "DEATH" abilities (e.g. pinned summon) BEFORE clearing the fighter/queue slot
	_try_ability(BattleTypes.AbilityTrigger.DEATH, unit, null)
	
	# Clear fighter slot if this was the active fighter
	if unit == _player_fighter:
		_player_fighter = null
	elif unit == _enemy_fighter:
		_enemy_fighter = null
	
	# Also remove from queue if unit was killed while in queue (e.g. David King Opening Bell)
	var queue = _player_queue if unit.is_player else _enemy_queue
	var idx = queue.find(unit)
	if idx >= 0:
		queue.remove_at(idx)
		
	_log({ "type": BattleTypes.EventType.DEATH, "unit_id": unit.id })


# --- Ability System (Simplified for Sim) ---


func _try_ability(trigger: BattleTypes.AbilityTrigger, source: SimUnit, target: SimUnit):
	if source == null: return
	
	var definition = source.definition
	var success = false
	var ability_log = {
		"type": BattleTypes.EventType.ABILITY_TRIGGER,
		"trigger": trigger,
		"source": source.id,
		"ability_name": definition.ability_name if definition else "Unknown"
	}
	
		# 1. Execute Script-Based Ability (Resource)
	if definition and definition.ability_resource:
		# ... (Existing native ability execution)
		var context = {
			"trigger": trigger,
			"simulator": self,
			"source_sim_unit": source,
			"target_sim_unit": target,
			"ability_log": ability_log
		}
		if definition.ability_resource.execute(source.original_data, context):
			success = true

	# 2. Execute Temporary Abilities (from Items)
	if source.original_data and not source.original_data.temporary_abilities.is_empty():
		for temp_ability in source.original_data.temporary_abilities:
			var context = {
				"trigger": trigger,
				"simulator": self,
				"source_sim_unit": source,
				"target_sim_unit": target, 
				"ability_log": ability_log
			}
			# Note: We share the same ability log entry type, maybe we should differentiate?
			# For now, if any succeed, we log the trigger event
			if temp_ability.execute(source.original_data, context):
				success = true
	
	if success:
		_log(ability_log)

func summon_unit(definition: UnitDefinition, is_player: bool, level: int = 1) -> void:
	# Create a temporary UnitInstance for the summon
	var instance = UnitInstance.new()
	instance.definition = definition
	
	# Scale stats with level: Base + (Level - 1)
	# Level 1: Base + 0
	# Level 2: Base + 1
	var stat_bonus = level - 1
	instance.max_hp = definition.base_hp + stat_bonus
	instance.hp = instance.max_hp
	instance.attack = definition.base_attack + stat_bonus
	
	# Manager Summon Abilities (Strategy Pattern)
	var manager = GameData.selected_manager if is_player else GameData.enemy_manager
	if manager and manager.ability_script:
		var ability = manager.ability_script.new()
		if ability.has_method("execute_on_summon"):
			ability.execute_on_summon(instance, self)
	
	instance.unit_name = definition.unit_name
	instance.level = level # Set level for new unit too (might affect its own abilities if it had any)
	
	var sim_unit = _create_sim_unit(instance, is_player, true)
	
	var queue = _player_queue if is_player else _enemy_queue
	
	# Logic: "Spawn in empty place or right after".
	# If fighter slot is empty (after death), it will be filled by spawn check from queue.
	# So we just need to put it at the FRONT of the queue so it's picked next.
	# Queue is [Back ... Front]. So we append to end.
	
	queue.append(sim_unit)
	
	# We rely on _check_spawn to pick it up and log SPAWN_UNIT.
	# BUT, if we want an immediate effect or log that it was summoned, we can query.
	# Actually, the user requirement: "When unit dies, insert new one... before removing corpse or right after."
	# We called this inside _handle_death, so corpse is still assigned but about to be nullified.
	# The next loop of simulation will call _check_spawn.
	# _check_spawn pops from back of queue.
	# So appending here puts it at the front of the line. Correct.

func _calculate_ability_trigger_potential(unit: SimUnit, trigger: BattleTypes.AbilityTrigger) -> bool:
	var has_native = unit.definition and unit.definition.ability_resource
	var has_temp = unit.original_data and not unit.original_data.temporary_abilities.is_empty()
	
	if not has_native and not has_temp:
		return false
	return true
