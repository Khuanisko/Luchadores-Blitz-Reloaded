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

var player_queue: Array[UnitData] = []
var enemy_queue: Array[UnitData] = []

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
	
	_spawn_next_player_unit()
	_spawn_next_enemy_unit()
	
	# Start battle loop after a short delay
	await get_tree().create_timer(1.5).timeout
	_start_combat_round()


func _spawn_next_player_unit() -> void:
	if player_fighter != null: return # Already have one
	
	var unit_data = player_queue.pop_back()
	if unit_data:
		player_fighter = FIGHTER_SCENE.instantiate()
		fighters_container.add_child(player_fighter)
		player_fighter.setup(unit_data)
		player_fighter.position = LEFT_SPAWN
		player_fighter.set_facing_left(false) # Face Right


func _spawn_next_enemy_unit() -> void:
	if enemy_fighter != null: return
	
	var unit_data = enemy_queue.pop_back()
	if unit_data:
		enemy_fighter = FIGHTER_SCENE.instantiate()
		fighters_container.add_child(enemy_fighter)
		enemy_fighter.setup(unit_data)
		enemy_fighter.position = RIGHT_SPAWN
		enemy_fighter.set_facing_left(true) # Face Left


func _start_combat_round() -> void:
	is_battle_active = true
	_battle_loop()


func _battle_loop() -> void:
	if not is_battle_active: return
	
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
	if enemy_fighter == null:
		_spawn_next_enemy_unit()
		
	# Wait for spawns
	if player_fighter == null or enemy_fighter == null:
		# If we still lack a fighter and queues are checked above, it means one side ran out.
		# But the win check is at the top. So we should re-loop to catch the win condition.
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
			
			var p_atk = player_fighter.unit_data.attack
			var e_atk = enemy_fighter.unit_data.attack
			
			player_fighter.unit_data.hp -= e_atk
			enemy_fighter.unit_data.hp -= p_atk
			
			# Update HP/ATK display
			player_fighter.update_stats_display()
			enemy_fighter.update_stats_display()
			
			# Check Deaths
			var p_dead = player_fighter.unit_data.hp <= 0
			var e_dead = enemy_fighter.unit_data.hp <= 0
			
			if p_dead:
				player_fighter.queue_free()
				player_fighter = null
			
			if e_dead:
				enemy_fighter.queue_free()
				enemy_fighter = null
	
	# Step back to spawn positions (prevents overlapping on next attack)
	# Only do step back if at least one fighter survived
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
	
	if result_label:
		result_label.text = text
		result_label.add_theme_color_override("font_color", color)
		result_label.visible = true
		
		# Fade out logic (wait then fade then change scene)
		await get_tree().create_timer(2.0).timeout
		
		# Check if game over (no lives left)
		if GameData.player_lives <= 0:
			# TODO: Could add game over scene here
			GameData.player_lives = 10
			GameData.player_wins = 0
			GameData.current_round = 1
		
		# Return to shop
		get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")


func _update_hud() -> void:
	if hp_label:
		hp_label.text = str(GameData.player_lives)
	if wins_label:
		wins_label.text = str(GameData.player_wins)
	if round_label:
		round_label.text = str(GameData.current_round)
