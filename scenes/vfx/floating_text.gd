extends Node2D

@onready var label: Label = $Label

func setup(value: int, color: Color) -> void:
	if label:
		label.text = str(value)
		label.modulate = color
	
	# Visual "Pop"
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	
	# 1. Scale Pop (Elastic)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
	
	# 2. Float Up
	var target_y = position.y - 80
	tween.parallel().tween_property(self, "position:y", target_y, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 3. Fade Out (at end)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.5)
	
	# 4. Cleanup
	tween.chain().tween_callback(queue_free)

func _ready() -> void:
	z_index = 100 # Ensure on top
