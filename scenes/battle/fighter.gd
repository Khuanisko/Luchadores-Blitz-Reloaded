extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var unit_data: UnitData

func setup(data: UnitData) -> void:
	unit_data = data
	
	# Map unit names (from shop/boxes) to character file names
	# Box names: eltorro, eljaguarro -> Unit Names: Eltorro, Eljaguarro
	# Character files: el_torro.png, el_jaguarro.png
	
	var file_name = data.unit_name.to_lower().replace(" ", "_") # default fallback snake_case
	
	# Explicit mapping for tricky cases if snake_case isn't enough
	# "El Torro" -> "el_torro" (handled by default now)
	# "El Jaguarro" -> "el_jaguarro" (handled by default now)
	
	match data.unit_name.to_lower().replace(" ", ""): # Remove spaces for matching without spaces
		"eltorro":
			file_name = "el_torro"
		"eljaguarro":
			file_name = "el_jaguarro"
		"dolores":
			file_name = "Dolores" # Case sensitive match just in case
	
	var texture_path = "res://assets/sprites/characters/" + file_name + ".png"
	
	if not ResourceLoader.exists(texture_path):
		# Try basic lowercase if map failed or wasn't needed
		if ResourceLoader.exists("res://assets/sprites/characters/" + data.unit_name.to_lower() + ".png"):
			texture_path = "res://assets/sprites/characters/" + data.unit_name.to_lower() + ".png"
		# Try original/Capitalized
		elif ResourceLoader.exists("res://assets/sprites/characters/" + data.unit_name + ".png"):
			texture_path = "res://assets/sprites/characters/" + data.unit_name + ".png"

	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		print("Character texture not found: ", texture_path)
		# Fallback to box texture if character not found? Or just a placeholder
		sprite.texture = data.unit_texture 
	
	# Scale is set in scene
	sprite.position = Vector2.ZERO


func set_facing_left(is_left: bool) -> void:
	sprite.flip_h = is_left


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
