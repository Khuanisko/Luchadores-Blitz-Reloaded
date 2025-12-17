extends PanelContainer

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var quote_label: RichTextLabel = $MarginContainer/VBoxContainer/QuoteLabel
@onready var quote_separator: HSeparator = $MarginContainer/VBoxContainer/HSeparator
@onready var ability_label: Label = $MarginContainer/VBoxContainer/AbilityLabel

func _ready() -> void:
	# WAŻNE: Nie używamy hide(), tylko alpha = 0
	modulate.a = 0 
	visible = true 
	
	z_index = 4096 # Maksymalna warstwa
	top_level = true
	
	# Fix kotwic (zapobiega rozciąganiu do ekranu)
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)

func show_manager(definition: ManagerDefinition, show_quote: bool = true) -> void:
	# 1. Ustawiamy przeźroczystość na 0 (Niewidzialny, ale aktywny)
	modulate.a = 0
	
	# 2. Wypełnij dane
	name_label.text = definition.manager_name
	if show_quote:
		quote_label.text = "[center][i]" + definition.quote + "[/i][/center]"
		quote_label.visible = true
		quote_separator.visible = true
	else:
		quote_label.visible = false
		quote_separator.visible = false
	ability_label.text = definition.ability_description
	
	# 3. PROCEDURA RESETU
	
	# Przenosimy tooltip poza ekran na czas obliczeń (dla bezpieczeństwa)
	global_position = Vector2(-3000, -3000)
	
	# Resetujemy Label
	quote_label.fit_content = false
	quote_label.custom_minimum_size.y = 0
	
	# Zgniatamy kontener
	custom_minimum_size.y = 0
	size = Vector2(220, 0)
	
	# Czekamy klatkę (Silnik liczy layout, bo visible=true!)
	await get_tree().process_frame
	
	# Włączamy fit_content
	quote_label.fit_content = true
	
	# Czekamy klatkę na przeliczenie wysokości
	await get_tree().process_frame
	
	# Finalny reset rozmiaru
	reset_size()
	
	# 4. POKAZANIE
	# Ustawiamy pozycję
	global_position = get_global_mouse_position() + Vector2(20, 20)
	
	# Przywracamy widoczność (Alpha = 1)
	modulate.a = 1