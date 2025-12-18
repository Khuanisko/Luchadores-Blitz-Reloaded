extends Control
	
@onready var label: Label = $Label
@onready var background: TextureRect = $Background
@onready var result_label: Label = $UILayer/ResultLabel
@onready var fighters_container: Node2D = $FightersContainer
@onready var hp_label: Label = $UILayer/HUD/HPContainer/HPLabel
@onready var wins_label: Label = $UILayer/HUD/WinsContainer/WinsLabel
@onready var round_label: Label = $UILayer/HUD/RoundContainer/RoundLabel
@onready var speed_button: Button = $UILayer/SpeedButton
@onready var player_manager_icon: TextureRect = $UILayer/PlayerManagerIcon
@onready var enemy_manager_icon: TextureRect = $UILayer/EnemyManagerIcon

const FIGHTER_SCENE = preload("res://scenes/battle/fighter.tscn")
const FLOATING_TEXT_SCENE = preload("res://scenes/vfx/floating_text.tscn")

# Visualizer State
var _active_fighters: Dictionary = {} # Maps unit_id (int) -> Node2D
var _simulation_result: BattleSimulator.BattleResult
var playback_speed: float = 1.0

# Constants for positioning (keep same as before)
const LEFT_SPAWN = Vector2(500, 650)
const RIGHT_SPAWN = Vector2(1420, 650)
const LEFT_COMBAT = Vector2(700, 650)
const RIGHT_COMBAT = Vector2(1220, 650)

func _ready() -> void:
	_setup_battle()
	_update_hud()
	_setup_manager_icons()
	
	if speed_button:
		speed_button.pressed.connect(_on_speed_button_pressed)
		speed_button.text = "Speed: 1x"
		
	# Intro animation
	if label:
		label.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_property(label, "modulate:a", 0.0, 2.0)
		tween.tween_callback(label.hide)

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _setup_battle() -> void:
	# 1. Run Simulation
	var sim = BattleSimulator.new()
	print("Running deterministic simulation...")
	_simulation_result = sim.simulate(GameData.player_team, GameData.enemy_team)
	print("Simulation complete. Steps: ", _simulation_result.log.size())
	print("Winner: ", BattleTypes.Winner.keys()[_simulation_result.winner])
	
	# DEBUG: Print all steps
	print("\n--- BATTLE LOG ---")
	for i in range(_simulation_result.log.size()):
		var event = _simulation_result.log[i]
		var type_name = BattleTypes.EventType.keys()[event.type]
		print("Step %d: [%s] %s" % [i, type_name, str(event)])
	print("------------------\n")
	
	# 2. Start Playback
	_play_battle_log()

func _play_battle_log() -> void:
	# Wait a bit before starting
	await _wait(1.0)
	
	for event in _simulation_result.log:
		await _process_event(event)

	await _wait(1.0)
	_show_round_result(_simulation_result.winner)

func _process_event(event: Dictionary) -> void:
	var type = event.type
	
	match type:
		BattleTypes.EventType.ROUND_START:
			pass # Just logic marker
			
		BattleTypes.EventType.SPAWN_UNIT:
			await _handle_spawn(event)
			
		BattleTypes.EventType.ABILITY_TRIGGER:
			await _handle_ability_trigger(event)
			
		BattleTypes.EventType.ATTACK:
			await _handle_attack(event)
			
		BattleTypes.EventType.DAMAGE:
			await _handle_damage(event)
			
		BattleTypes.EventType.DEATH:
			await _handle_death(event)
			
		BattleTypes.EventType.ROUND_END:
			pass # End handled by loop finish

func _handle_spawn(event: Dictionary) -> void:
	var unit_id = event.unit_id
	var is_player = event.is_player
	# create_sim_unit doesn't give us the full display data in the event, 
	# but we need it.
	# The simulator uses original units. We need to find the definition.
	# Or, since we track IDs, we can map back? 
	# SimUnit structure had `definition` and `original_data`.
	# But we only have the log here.
	# FIX: Simulator logs should probably contain essential visual data OR we query the Sim.
	# The event has "unit_name". We can recreate a dummy visual or find it.
	# Better: Use the name/ID to load the sprite.
	
	var fighter = FIGHTER_SCENE.instantiate()
	fighters_container.add_child(fighter)
	_active_fighters[unit_id] = fighter
	
	# Visual Setup
	# We need a dummy UnitInstance or modify Fighter to take raw data.
	# Existing Fighter.setup takes UnitInstance.
	# Let's reconstruct a temporary UnitInstance for the visual.
	var dummy_instance = UnitInstance.new()
	# We need to load definition by Name to get the sprite correctly using Fighter logic
	# Fighter logic: `unit.definition.id` OR `unit.unit_name` fallback.
	# The event gives us `unit_name`.
	dummy_instance.definition = UnitDefinition.new()
	dummy_instance.definition.unit_name = event.unit_name
	if "definition_id" in event:
		dummy_instance.definition.id = event.definition_id
	
	# Initial HP/ATK from event
	dummy_instance.hp = event.hp
	dummy_instance.max_hp = event.max_hp
	dummy_instance.attack = event.attack
	
	fighter.setup(dummy_instance)
	
	# Pos
	if is_player:
		fighter.position = LEFT_SPAWN
		fighter.set_facing_left(false)
	else:
		fighter.position = RIGHT_SPAWN
		fighter.set_facing_left(true)
		
	# Animate Entrance (Move nicely to combat pos?)
	# Or just spawn at spawn point. The combat loop moves them.
	# In Sim, they fight immediately after spawn checks.
	# We should move them to center if they are the fighters.
	
	await get_tree().create_timer(0.3).timeout
	
	# Move to combat pos if they are the active frontliners?
	# In Sim, as soon as they spawn they become the fighter.
	var target_pos = LEFT_COMBAT if is_player else RIGHT_COMBAT
	var tween = create_tween()
	tween.tween_property(fighter, "position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

func _handle_attack(event: Dictionary) -> void:
	var source_id = event.source
	var target_id = event.target
	
	var source_node = _active_fighters.get(source_id)
	var target_node = _active_fighters.get(target_id)
	
	if source_node and target_node:
		source_node.play_attack_anim(target_node.position)
		# Don't await full anim here maybe? 
		# If we wait, it feels turned based. 
		# If we don't, it feels simultaneous.
		# Let's wait a tiny bit to stagger start if simultaneous
		await get_tree().create_timer(0.1).timeout

func _handle_damage(event: Dictionary) -> void:
	var target_id = event.target
	var amount = event.amount
	var new_hp = event.new_hp
	
	var node = _active_fighters.get(target_id)
	if node:
		node.play_hurt_visuals()
		# Update visual stats
		# Fighter node expects UnitInstance to hold values.
		# We need to manually update the labels since we are driving this externally.
		if node.hp_label:
			node.hp_label.text = str(new_hp)
		
		# Spawn Floating Text
		var float_txt = FLOATING_TEXT_SCENE.instantiate()
		add_child(float_txt) # Add to Arena, not Unit
		float_txt.global_position = node.global_position
		float_txt.setup(amount, Color.RED)
		
		# Wait for hit impact
		await get_tree().create_timer(0.2).timeout

func _handle_death(event: Dictionary) -> void:
	var unit_id = event.unit_id
	var node = _active_fighters.get(unit_id)
	
	if node:
		# Play death anim? 
		# Just fade out or pop for now
		var tween = create_tween()
		tween.tween_property(node, "modulate:a", 0.0, 0.3)
		await tween.finished
		node.queue_free()
		_active_fighters.erase(unit_id)

func _handle_ability_trigger(event: Dictionary) -> void:
	var source_id = event.source
	var node = _active_fighters.get(source_id)
	if node:
		var color = Color.GOLD
		# Simple mapping for VFX based on logic we saw in old arena
		match event.trigger:
			BattleTypes.AbilityTrigger.ENTRANCE: color = Color.GOLD
			BattleTypes.AbilityTrigger.ATTACK: color = Color.RED
			BattleTypes.AbilityTrigger.KILL: color = Color.GREEN
			
		node.play_ability_vfx(color)
		
		# Show Ability Name?
		# var ability_name = event.ability_name
		# Could pop up text
		
		await get_tree().create_timer(0.5).timeout

func _show_round_result(winner: BattleTypes.Winner) -> void:
	var text = ""
	var color = Color.WHITE
	
	match winner:
		BattleTypes.Winner.PLAYER:
			text = "ROUND WON"
			color = Color.GREEN
			GameData.player_wins += 1
		BattleTypes.Winner.ENEMY:
			text = "ROUND LOST"
			color = Color.RED
			GameData.player_lives -= 1
		BattleTypes.Winner.DRAW:
			text = "DRAW"
			color = Color.WHITE
			
	GameData.current_round += 1
	_update_hud()
	
	# Game Over Checks (Sim matches GameData logic?)
	# Wait, Sim calculates winner of the ROUND.
	# Game Over (Wins >= 10 or Lives <= 0) is Meta-Game logic.
	# We handle it here.
	
	var game_over = false
	if GameData.player_wins >= 10:
		text = "YOU ARE THE WORLD CHAMPION"
		color = Color.GOLD
		game_over = true
	elif GameData.player_lives <= 0:
		text = "YOU LOST"
		color = Color.RED
		game_over = true
		
	if result_label:
		result_label.text = text
		result_label.add_theme_color_override("font_color", color)
		result_label.visible = true
		
	var wait_time = 4.0 if game_over else 2.0
	await get_tree().create_timer(wait_time).timeout
	
	if game_over:
		# Reset
		GameData.player_lives = 5
		GameData.player_wins = 0
		GameData.current_round = 1
		GameData.player_team.clear()
	
	get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")

func _update_hud() -> void:
	if hp_label:
		hp_label.text = str(GameData.player_lives)
	if wins_label:
		wins_label.text = str(GameData.player_wins)
	if round_label:
		round_label.text = str(GameData.current_round)

func _on_speed_button_pressed() -> void:
	if playback_speed == 1.0:
		playback_speed = 2.0
	elif playback_speed == 2.0:
		playback_speed = 10.0
	else:
		playback_speed = 1.0
		
	Engine.time_scale = playback_speed
	
	if speed_button:
		speed_button.text = "Speed: %sx" % str(playback_speed)

# Helper for speed-based delay
func _wait(seconds: float) -> void:
	# With Engine.time_scale, we don't need manual division
	await get_tree().create_timer(seconds).timeout


func _setup_manager_icons() -> void:
	if player_manager_icon and GameData.selected_manager:
		if GameData.selected_manager.button_icon:
			player_manager_icon.texture = GameData.selected_manager.button_icon
		player_manager_icon.visible = true
	elif player_manager_icon:
		player_manager_icon.visible = false
	
	if enemy_manager_icon and GameData.enemy_manager:
		if GameData.enemy_manager.button_icon:
			enemy_manager_icon.texture = GameData.enemy_manager.button_icon
		enemy_manager_icon.visible = true
	elif enemy_manager_icon:
		enemy_manager_icon.visible = false
