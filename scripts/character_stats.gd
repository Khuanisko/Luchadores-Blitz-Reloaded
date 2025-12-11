# character_stats.gd
# Database of character statistics

class_name CharacterStats
extends RefCounted

# Stats for each character: {hp, attack, cost}
const STATS: Dictionary = {
	"Gonzales": {"hp": 4, "attack": 2, "cost": 3},
	"Marco": {"hp": 3, "attack": 3, "cost": 3},
	"Dolores": {"hp": 2, "attack": 4, "cost": 3},
	"El Torro": {"hp": 5, "attack": 2, "cost": 3},
	"El Jaguarro": {"hp": 3, "attack": 5, "cost": 3},
}

static func get_stats(character_name: String) -> Dictionary:
	var key = character_name.to_lower().replace(" ", "")
	if STATS.has(key):
		return STATS[key]
	# Default stats
	return {"hp": 1, "attack": 1, "cost": 3}
