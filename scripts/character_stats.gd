# character_stats.gd
# Database of character statistics

class_name CharacterStats
extends RefCounted

# Stats for each character: {hp, attack, cost}
const STATS: Dictionary = {
	"gonzales": {
		"display_name": "Gonzales",
		"hp": 3, "attack": 4, "cost": 3, "tier": 2,
		"unit_class": "Striker", "faction": "Los Técnicos", "heel_face": "Heel",
		"ability_name": "Entrance", "ability_description": "Gives [b] +1/+2[/b] to all [b]Garage[/b] tier units while entering the ring."
	},
	"dolores": {
		"display_name": "Dolores",
		"hp": 2, "attack": 2, "cost": 3, "tier": 1,
		"unit_class": "Technician", "faction": "Las Flores", "heel_face": "Face",
		"ability_name": "Entrance", "ability_description": "Gains [b] +1/+1[/b] while entering the ring."
	},
	"marco": {
		"display_name": "Marco",
		"hp": 2, "attack": 3, "cost": 3, "tier": 1,
		"unit_class": "Striker", "faction": "Los Técnicos", "heel_face": "Heel",
		"ability_name": "Pinfall", "ability_description": "Gains [b]+1/+1[/b] after defeating the enemy"
	},
	"eljaguarro": {
		"display_name": "El Jaguarro",
		"hp": 3, "attack": 6, "cost": 3, "tier": 3,
		"unit_class": "High Flyer", "faction": "Los Rudos", "heel_face": "Heel",
		"ability_name": "Entrance", "ability_description": "Deal [b] 4 [/b] damage to current enemy while entering the ring."
	},
	"eltorro": {
		"display_name": "El Torro",
		"hp": 6, "attack": 1, "cost": 3, "tier": 3,
		"unit_class": "Power House", "faction": "Los Rudos", "heel_face": "Face",
		"ability_name": "Combo", "ability_description": "Gains [b] +1 attack [/b] while attacking the enemy"
	},
}

static func get_stats(character_name: String) -> Dictionary:
	var key = character_name.to_lower().replace(" ", "")
	if STATS.has(key):
		return STATS[key]
	# Default stats
	return {
		"hp": 1, "attack": 1, "cost": 3, "tier": 1,
		"unit_class": "Rookie", "faction": "Independent", "heel_face": "Face",
		"ability_name": "Training Hit", "ability_description": "A basic training move."
	}
