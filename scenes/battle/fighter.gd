extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var stats_container: VBoxContainer = $StatsContainer
@onready var hp_label: Label = $StatsContainer/hp/Label
@onready var attk_label: Label = $StatsContainer/attk/Label

const STATS_OFFSET_LEFT = Vector2(-262, 197)  # Left side (for player)
const STATS_OFFSET_RIGHT = Vector2(186, 197)  # Right side (for enemy)

var unit_instance: UnitInstance

func setup(unit: UnitInstance) -> void:
	unit_instance = unit
	
	# Try to load formatted battle sprite based on ID
	# We expect: assets/sprites/characters/<id>.png
	# UnitInstance definition has 'id' (e.g. "gonzales")
	var file_name = ""
	if unit.definition and not unit.definition.id.is_empty():
		file_name = unit.definition.id
	else:
		file_name = unit.unit_name.to_lower().replace(" ", "")
	
	var texture_path = "res://assets/sprites/characters/" + file_name + ".png"
	
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		# Fallback: try snake_case of name if ID didn't work (legacy support)
		var snake_name = unit.unit_name.to_lower().replace(" ", "_")
		if ResourceLoader.exists("res://assets/sprites/characters/" + snake_name + ".png"):
			sprite.texture = load("res://assets/sprites/characters/" + snake_name + ".png")
		elif unit.unit_texture:
			# Fallback to portrait (box) if nothing else
			sprite.texture = unit.unit_texture
		else:
			print("Character texture not found for: ", unit.unit_name, ". Tried path: ", texture_path)
	
	# Scale is set in scene
	sprite.position = Vector2.ZERO
	
	# Initialize stats display
	update_stats_display()


func set_facing_left(is_left: bool) -> void:
	sprite.flip_h = is_left
	# Position stats on the opposite side of where fighter faces
	# Player faces right -> stats on left
	# Enemy faces left -> stats on right
	if stats_container:
		if is_left:
			# Enemy - stats on right side
			stats_container.position = STATS_OFFSET_RIGHT
		else:
			# Player - stats on left side
			stats_container.position = STATS_OFFSET_LEFT


func update_stats_display() -> void:
	if unit_instance and hp_label and attk_label:
		hp_label.text = str(unit_instance.hp)
		attk_label.text = str(unit_instance.attack)


func play_attack_anim(target_pos: Vector2) -> void:
	var original_pos = sprite.position
	var tween = create_tween()
	# Attack Animation (Refined)
	var forward_dir = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	
	# Phase 1: Wind-up (Pull back slightly)
	tween.tween_property(sprite, "position", original_pos - (forward_dir * 20), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Phase 2: Strike (Fast forward)
	tween.chain().tween_property(sprite, "position", original_pos + (forward_dir * 60), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Phase 3: Return
	tween.chain().tween_property(sprite, "position", original_pos, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func play_hurt_visuals() -> void:
	var tween = create_tween()
	
	# Flash White/Red (High impact)
	sprite.modulate = Color(10, 10, 10) # Over-bright start
	tween.tween_property(sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Shake
	var original_pos = Vector2.ZERO # Usually local 0,0
	if not tween.is_running(): tween = create_tween() # Ensure tween exists if parallel
	
	# Random shake
	for i in range(5):
		var offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
		tween.parallel().tween_property(sprite, "position", original_pos + offset, 0.03)
	
	# Reset
	tween.chain().tween_property(sprite, "position", original_pos, 0.01)


func play_ability_vfx(color: Color = Color.GOLD) -> void:
	var tween = create_tween()
	# Flash color
	tween.tween_property(sprite, "modulate", color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
