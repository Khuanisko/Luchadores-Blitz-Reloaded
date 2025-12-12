# unit_tooltip.gd
# Tooltip displaying unit stats on hover

extends PanelContainer

@onready var name_label: Label = $MarginContainer/VBoxContainer/Header/NameLabel
@onready var tier_label: Label = $MarginContainer/VBoxContainer/Header/TierLabel
@onready var cost_label: Label = $MarginContainer/VBoxContainer/Header/CostLabel

@onready var hp_label: Label = $MarginContainer/VBoxContainer/StatsRow/HPContainer/Value
@onready var attack_label: Label = $MarginContainer/VBoxContainer/StatsRow/AttackContainer/Value

@onready var level_label: Label = $MarginContainer/VBoxContainer/StatsRow/LevelInfo/LevelLabel
@onready var xp_label: Label = $MarginContainer/VBoxContainer/StatsRow/LevelInfo/XPLabel

@onready var class_label: Label = $MarginContainer/VBoxContainer/TagsRow/ClassLabel
@onready var faction_label: Label = $MarginContainer/VBoxContainer/TagsRow/FactionLabel
@onready var heel_face_label: Label = $MarginContainer/VBoxContainer/TagsRow/HeelFaceLabel

@onready var ability_name_label: Label = $MarginContainer/VBoxContainer/AbilitySection/AbilityName
@onready var ability_desc_label: RichTextLabel = $MarginContainer/VBoxContainer/AbilitySection/AbilityDesc

func show_unit(unit_data: UnitData) -> void:
	if unit_data == null:
		return
	
	if name_label:
		name_label.text = unit_data.unit_name
		
	if tier_label:
		tier_label.text = unit_data.get_tier_name()
	
	if cost_label:
		cost_label.text = "$" + str(unit_data.cost)

	if hp_label:
		hp_label.text = str(unit_data.hp)
	if attack_label:
		attack_label.text = str(unit_data.attack)
	
	if level_label:
		level_label.text = "Lv " + str(unit_data.level)
	
	if xp_label:
		xp_label.text = "XP: " + str(unit_data.xp) + "/" + str(unit_data.max_xp)
		
	if class_label:
		class_label.text = unit_data.unit_class
	if faction_label:
		faction_label.text = unit_data.faction
	if heel_face_label:
		heel_face_label.text = unit_data.heel_face
		# Color coding for Heel/Face
		if unit_data.heel_face.to_lower() == "face":
			heel_face_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6)) # Green-ish
		else:
			heel_face_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6)) # Red-ish
			
	if ability_name_label:
		ability_name_label.text = unit_data.ability_name
	if ability_desc_label:
		ability_desc_label.text = unit_data.ability_description
	
	visible = true
	
	# Adjust size to fit content immediately
	reset_size()

func hide_tooltip() -> void:
	visible = false
