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
	
	func _init(unit: UnitInstance, _id: int, _is_player: bool):
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
	
	# Main Battle Loop
	var max_loops = 100 # Safety break
	var loop_count = 0
	
	while loop_count < max_loops:
		loop_count += 1
		
		# 1. Spawn Step
		var p_spawned = _check_spawn(true)
		var e_spawned = _check_spawn(false)
		
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

# --- Internal Logic ---

func _reset():
	_unit_id_counter = 0
	_battle_log.clear()
	_player_queue.clear()
	_enemy_queue.clear()
	_player_fighter = null
	_enemy_fighter = null

func _create_sim_unit(unit: UnitInstance, is_player: bool) -> SimUnit:
	var sim = SimUnit.new(unit, _unit_id_counter, is_player)
	_unit_id_counter += 1
	return sim

func _log(event: Dictionary):
	_battle_log.append(event)

func _check_spawn(is_player: bool) -> bool:
	var fighter = _player_fighter if is_player else _enemy_fighter
	
	if fighter == null:
		var queue = _player_queue if is_player else _enemy_queue
		if not queue.is_empty():
			# Spawn next unit
			var next_unit = queue.pop_back() # Matches current arena stack logic
			if is_player: _player_fighter = next_unit
			else: _enemy_fighter = next_unit
			
			_log({
				"type": BattleTypes.EventType.SPAWN_UNIT,
				"unit_id": next_unit.id,
				"is_player": is_player,
				"unit_name": next_unit.original_data.unit_name,
				"hp": next_unit.hp,
				"max_hp": next_unit.max_hp,
				"attack": next_unit.attack
			})
			
			# Trigger Entrance Ability
			# Opponent is the current fighter of other side (can be null if empty)
			var opponent = _enemy_fighter if is_player else _player_fighter
			_try_ability(BattleTypes.AbilityTrigger.ENTRANCE, next_unit, opponent)
			return true
	return false

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
	
	if p_dead and not e_dead:
		_try_ability(BattleTypes.AbilityTrigger.KILL, e, p)
	if e_dead and not p_dead:
		_try_ability(BattleTypes.AbilityTrigger.KILL, p, e)
		
	if p_dead: _handle_death(p)
	if e_dead: _handle_death(e)

func _apply_damage(target: SimUnit, amount: int, source: SimUnit):
	target.hp -= amount
	_log({
		"type": BattleTypes.EventType.DAMAGE,
		"target": target.id,
		"amount": amount,
		"new_hp": target.hp,
		"source": source.id # Attribution
	})

func _handle_death(unit: SimUnit):
	if unit == _player_fighter:
		_player_fighter = null
	elif unit == _enemy_fighter:
		_enemy_fighter = null
		
	_log({ "type": BattleTypes.EventType.DEATH, "unit_id": unit.id })


# --- Ability System (Simplified for Sim) ---

func _try_ability(trigger: BattleTypes.AbilityTrigger, source: SimUnit, target: SimUnit):
	if source == null: return
	
	var name = source.original_data.unit_name
	var definition = source.definition
	var success = false
	var ability_log = {
		"type": BattleTypes.EventType.ABILITY_TRIGGER,
		"trigger": trigger,
		"source": source.id,
		"ability_name": definition.ability_name if definition else "Unknown"
	}
	
	# Hardcoded logic mirroring 'battle_arena.gd'
	# In the future, this should be moved to a robust Effect System or Strategy Pattern
	
	match trigger:

		BattleTypes.AbilityTrigger.ENTRANCE:
			if name == "Gonzales":
				# Buff allies in Garage tier
				# var queue = _player_queue if source.is_player else _enemy_queue
				# Note: queue contains units waiting to spawn
				# The source just spawned, so it's not in the queue anymore.
				# What about units already on board? None, because it's 1v1.
				
				# Buff units in queue
				# var count = 0
				# for ally in queue:
				# 	if ally.definition and ally.definition.tier == 2:
				# 		ally.attack += 1
				# 		ally.hp += 2
				# 		ally.max_hp += 2
				# 		count += 1
				# if count > 0: success = true
				pass

			elif name == "Dolores":
				# Self Buff
				# source.attack += 1
				# source.hp += 1
				# source.max_hp += 1
				# success = true
				pass
				
			elif name == "El Jaguarro":
				if target:
					# Deal 4 dmg
					# _apply_damage(target, 4, source)
					# success = true
					pass
					
		BattleTypes.AbilityTrigger.ATTACK:
			if name == "El Torro":
				# +1 Attack
				# source.attack += 1
				# success = true
				pass
				
		BattleTypes.AbilityTrigger.KILL:
			if name == "Marco":
				# +1/+1
				# source.attack += 1
				# source.hp += 1
				# source.max_hp += 1
				# success = true
				pass
	
	if success:
		_log(ability_log)
