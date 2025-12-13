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
	var file_name = unit.definition.id if unit.definition else unit.unit_name.to_lower().replace(" ", "")
	
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
			print("Character texture not found for: ", unit.unit_name)
	
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
	# Lunge forward (assuming 'forward' depends on flip)
	var forward_dir = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	
	tween.tween_property(sprite, "position", original_pos + (forward_dir * 50), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", original_pos, 0.2)


func play_hit_anim() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Shake
	var original_pos = sprite.position
	var shake_offset = Vector2(10, 0)
	tween.parallel().tween_property(sprite, "position", original_pos + shake_offset, 0.05)
	tween.chain().tween_property(sprite, "position", original_pos - shake_offset, 0.05)
	tween.chain().tween_property(sprite, "position", original_pos, 0.05)


func play_ability_vfx(color: Color = Color.GOLD) -> void:
	var tween = create_tween()
	# Flash color
	tween.tween_property(sprite, "modulate", color, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


