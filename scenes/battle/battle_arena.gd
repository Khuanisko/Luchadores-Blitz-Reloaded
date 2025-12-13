extends Control

@onready var label: Label = $Label
@onready var background: TextureRect = $Background
@onready var result_label: Label = $UILayer/ResultLabel
@onready var fighters_container: Node2D = $FightersContainer
@onready var hp_label: Label = $UILayer/HUD/HPContainer/HPLabel
@onready var wins_label: Label = $UILayer/HUD/WinsContainer/WinsLabel
@onready var round_label: Label = $UILayer/HUD/RoundContainer/RoundLabel

const FIGHTER_SCENE = preload("res://scenes/battle/fighter.tscn")

var player_fighter: Node2D
var enemy_fighter: Node2D

var player_queue: Array[UnitInstance] = []
var enemy_queue: Array[UnitInstance] = []

var is_battle_active: bool = false

# Starting positions
const LEFT_SPAWN = Vector2(500, 650)
const RIGHT_SPAWN = Vector2(1420, 650) # Symmetric
# Combat positions (middle)
const LEFT_COMBAT_POS = Vector2(700, 650)
const RIGHT_COMBAT_POS = Vector2(1220, 650)

func _ready() -> void:
	_setup_battle()
	_update_hud()
	
	# intro label anim
	if label:
		label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_property(label, "modulate:a", 0.0, 2.0)
		tween.tween_callback(label.hide)


func _setup_battle() -> void:
	# Clone global teams to local queues for this battle instance
	player_queue = GameData.player_team.duplicate()
	enemy_queue = GameData.enemy_team.duplicate()
	
	if player_queue.is_empty():
		return
	
	# Spawn INITIAL units without triggering abilities properly yet
	# because opponent might be missing for the first one spawned
	_spawn_next_player_unit(false)
	_spawn_next_enemy_unit(false)
	
	# Start battle loop after a short delay
	await get_tree().create_timer(1.5).timeout
	
	# Now trigger entrance abilities for the starting pair
	# We check existence in case something weird happened, but they should be there
	if player_fighter and enemy_fighter:
		_trigger_abilities(AbilityTrigger.ENTRANCE, player_fighter, enemy_fighter)
		_trigger_abilities(AbilityTrigger.ENTRANCE, enemy_fighter, player_fighter)
		
		# Handle any instant deaths from entrance abilities (e.g. Jaguarro)
		_handle_deaths()
		
	_start_combat_round()


# Constants
enum AbilityTrigger { ENTRANCE, ATTACK, KILL }


func _spawn_next_player_unit(trigger_ability: bool = true) -> void:
	if player_fighter != null: return # Already have one
	
	var unit = player_queue.pop_back()
	if unit:
		player_fighter = FIGHTER_SCENE.instantiate()
		fighters_container.add_child(player_fighter)
		player_fighter.setup(unit)
		player_fighter.position = LEFT_SPAWN
		player_fighter.set_facing_left(false) # Face Right
		
		if trigger_ability:
			# Trigger Entrance Ability (Opponent should exist in mid-battle spawns)
			_trigger_abilities(AbilityTrigger.ENTRANCE, player_fighter, enemy_fighter)


func _spawn_next_enemy_unit(trigger_ability: bool = true) -> void:
	if enemy_fighter != null: return
	
	var unit = enemy_queue.pop_back()
	if unit:
		enemy_fighter = FIGHTER_SCENE.instantiate()
		fighters_container.add_child(enemy_fighter)
		enemy_fighter.setup(unit)
		enemy_fighter.position = RIGHT_SPAWN
		enemy_fighter.set_facing_left(true) # Face Left
		
		if trigger_ability:
			# Trigger Entrance Ability
			_trigger_abilities(AbilityTrigger.ENTRANCE, enemy_fighter, player_fighter)


func _trigger_abilities(trigger: AbilityTrigger, source: Node2D, target: Node2D) -> void:
	if not source or not source.unit_instance: return
	
	var data = source.unit_instance
	var ability_name = data.ability_name.replace(" ", "")
	var trig_happened = false
	
	# Match by Name or specific IDs if we had them. Using name for now.
	match trigger:
		AbilityTrigger.ENTRANCE:
			if data.unit_name == "Gonzales":
				# +1/+2 to all Garage tier units
				trig_happened = true
				source.play_ability_vfx(Color.GOLD)
				
				# Determine which queue belongs to this source
				var allies_queue = player_queue if source == player_fighter else enemy_queue
				
				for ally in allies_queue:
					if ally.tier == 2: # Garage Tier
						ally.attack += 1
						ally.hp += 2
						ally.max_hp += 2
						
			elif data.unit_name == "Dolores":
				# +1/+1 Self
				trig_happened = true
				source.play_ability_vfx(Color.MAGENTA)
				data.attack += 1
				data.hp += 1
				data.max_hp += 1
				source.update_stats_display()
				
			elif data.unit_name == "El Jaguarro":
				# Deal 4 dmg to enemy
				if target:
					trig_happened = true
					source.play_ability_vfx(Color.ORANGE_RED)
					target.play_hit_anim()
					target.unit_instance.hp -= 4
					target.update_stats_display()
					# Note: Death check will happen in main loop or we need to handle it here?
					# The main loop checks for null fighters. Need to clean up here if dead?
					# Better let main loop handle destruction, but we can visually show it.
					
		AbilityTrigger.ATTACK:
			if data.unit_name == "El Torro":
				# +1 Attack
				trig_happened = true
				source.play_ability_vfx(Color.RED)
				data.attack += 1
				source.update_stats_display()
				
		AbilityTrigger.KILL:
			if data.unit_name == "Marco":
				# +1/+1 after kill
				trig_happened = true
				source.play_ability_vfx(Color.GREEN)
				data.attack += 1
				data.hp += 1
				data.max_hp += 1 # Permanent? Assuming yes for autobattler
				source.update_stats_display()

	if trig_happened:
		await get_tree().create_timer(0.5).timeout


func _start_combat_round() -> void:
	is_battle_active = true
	_battle_loop()


func _battle_loop() -> void:
	if not is_battle_active: return
	
	# Quick check for death from Entrance abilities
	_handle_deaths()
	
	# Check Win/Loss Condition
	if player_fighter == null and player_queue.is_empty():
		if enemy_fighter == null and enemy_queue.is_empty():
			_end_game("DRAW", Color.WHITE)
		else:
			_end_game("ROUND LOST", Color.RED)
		return
	elif enemy_fighter == null and enemy_queue.is_empty() and player_fighter != null:
		_end_game("ROUND WON", Color.GREEN)
		return
		
	# Spawn if missing
	if player_fighter == null:
		_spawn_next_player_unit()
		# Re-check death/win in case spawn ability killed someone
		await get_tree().process_frame # Allow UI to update
		_handle_deaths()
		if enemy_fighter == null and enemy_queue.is_empty() and player_fighter != null:
			_end_game("ROUND WON", Color.GREEN)
			return
			
	if enemy_fighter == null:
		_spawn_next_enemy_unit()
		await get_tree().process_frame
		_handle_deaths()
		if player_fighter == null and player_queue.is_empty():
			if enemy_fighter == null and enemy_queue.is_empty(): _end_game("DRAW", Color.WHITE)
			else: _end_game("ROUND LOST", Color.RED)
			return
		
	# Wait for spawns
	if player_fighter == null or enemy_fighter == null:
		# Loop to catch next spawn or win
		await get_tree().process_frame
		_battle_loop()
		return
		
	# Move to combat positions (step forward)
	var tween = create_tween()
	tween.parallel().tween_property(player_fighter, "position", LEFT_COMBAT_POS, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(enemy_fighter, "position", RIGHT_COMBAT_POS, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Attack Phase
	await get_tree().create_timer(0.2).timeout
	
	# Trigger Attack Abilities
	if player_fighter and enemy_fighter:
		_trigger_abilities(AbilityTrigger.ATTACK, player_fighter, enemy_fighter)
		_trigger_abilities(AbilityTrigger.ATTACK, enemy_fighter, player_fighter)
		await get_tree().create_timer(0.3).timeout # Wait for buffs
	
	# Play animations
	if player_fighter and enemy_fighter:
		player_fighter.play_attack_anim(enemy_fighter.position)
		enemy_fighter.play_attack_anim(player_fighter.position)
		
		# Wait for impact
		await get_tree().create_timer(0.2).timeout
		
		# Apply Damage
		if player_fighter and enemy_fighter:
			player_fighter.play_hit_anim()
			enemy_fighter.play_hit_anim()
			
			var p_atk = player_fighter.unit_instance.attack
			var e_atk = enemy_fighter.unit_instance.attack
			
			player_fighter.unit_instance.hp -= e_atk
			enemy_fighter.unit_instance.hp -= p_atk
			
			# Update HP/ATK display
			player_fighter.update_stats_display()
			enemy_fighter.update_stats_display()
			
			# Check Deaths
			var p_died = player_fighter.unit_instance.hp <= 0
			var e_died = enemy_fighter.unit_instance.hp <= 0
			
			# Trigger Kill Abilities
			if p_died and not e_died:
				_trigger_abilities(AbilityTrigger.KILL, enemy_fighter, player_fighter)
			if e_died and not p_died:
				_trigger_abilities(AbilityTrigger.KILL, player_fighter, enemy_fighter)
			
			# Handle removal
			_handle_deaths()
	
	# Step back if survived
	if player_fighter or enemy_fighter:
		await get_tree().create_timer(0.3).timeout
		var step_back_tween = create_tween()
		if player_fighter:
			step_back_tween.parallel().tween_property(player_fighter, "position", LEFT_SPAWN, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		if enemy_fighter:
			step_back_tween.parallel().tween_property(enemy_fighter, "position", RIGHT_SPAWN, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await step_back_tween.finished
				
	# Loop with delay
	await get_tree().create_timer(0.5).timeout
	_battle_loop()


func _handle_deaths() -> void:
	if player_fighter and player_fighter.unit_instance.hp <= 0:
		player_fighter.queue_free()
		player_fighter = null
		
	if enemy_fighter and enemy_fighter.unit_instance.hp <= 0:
		enemy_fighter.queue_free()
		enemy_fighter = null


func _end_game(text: String, color: Color) -> void:
	is_battle_active = false
	
	# Update game state based on result
	if text == "ROUND WON":
		GameData.player_wins += 1
	elif text == "ROUND LOST":
		GameData.player_lives -= 1
	# DRAW: no changes to lives or wins
	
	# Always increment round counter
	GameData.current_round += 1
	
	_update_hud()
	
	# Check Game Over Conditions
	var game_over_text = ""
	var game_over_color = Color.WHITE
	var is_game_over = false
	
	if GameData.player_wins >= 10:
		is_game_over = true
		game_over_text = "YOU ARE THE WORLD CHAMPION"
		game_over_color = Color(1.0, 0.84, 0.0) # Gold
	elif GameData.player_lives <= 0:
		is_game_over = true
		game_over_text = "YOU LOST"
		game_over_color = Color(0.8, 0.1, 0.1) # Red
		
	if result_label:
		# If game over, override the round result text
		if is_game_over:
			result_label.text = game_over_text
			result_label.add_theme_color_override("font_color", game_over_color)
		else:
			result_label.text = text
			result_label.add_theme_color_override("font_color", color)
			
		result_label.visible = true
		
		# Wait time depends on if it's game over (longer wait to read)
		var wait_time = 4.0 if is_game_over else 2.0
		await get_tree().create_timer(wait_time).timeout
		
		if is_game_over:
			# Reset Game
			GameData.player_lives = 5
			GameData.player_wins = 0
			GameData.current_round = 1
			GameData.player_team.clear() # Clear team on reset? Or keep it? Usually hard reset.
			# Let's clear the team for a fresh run
			GameData.player_team.clear()
		
		# Return to shop
		get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")


func _update_hud() -> void:
	if hp_label:
		hp_label.text = str(GameData.player_lives)
	if wins_label:
		wins_label.text = str(GameData.player_wins)
	if round_label:
		round_label.text = str(GameData.current_round)
