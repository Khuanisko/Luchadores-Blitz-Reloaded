# character_stats.gd
# Database of character statistics

class_name CharacterStats
extends RefCounted

# Stats for each character: {hp, attack, cost}
const STATS: Dictionary = {
	"gonzales": {"hp": 3, "attack": 4, "cost": 3},
	"dolores": {"hp": 2, "attack": 2, "cost": 3},
	"marco": {"hp": 2, "attack": 3, "cost": 3},
	"eljaguarro": {"hp": 3, "attack": 6, "cost": 3},
	"eltorro": {"hp": 6, "attack": 1, "cost": 3},
}

static func get_stats(character_name: String) -> Dictionary:
	var key = character_name.to_lower().replace(" ", "")
	if STATS.has(key):
		return STATS[key]
	# Default stats
	return {"hp": 1, "attack": 1, "cost": 3}
