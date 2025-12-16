extends PanelContainer

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var quote_label: RichTextLabel = $MarginContainer/VBoxContainer/QuoteLabel
@onready var ability_label: Label = $MarginContainer/VBoxContainer/AbilityLabel

func show_manager(definition: ManagerDefinition) -> void:
	name_label.text = definition.manager_name
	
	# Format quote with italics
	quote_label.text = "[center][i]" + definition.quote + "[/i][/center]"
	
	ability_label.text = definition.ability_description
	
	visible = true
	reset_size()

func _ready() -> void:
	# Ensure started hidden
	hide()
	z_index = 100
	custom_minimum_size = Vector2(220, 0)


