class_name BattleTypes

# Event Types in the Battle Log
enum EventType {
	ROUND_START,
	SPAWN_UNIT,
	ABILITY_TRIGGER,
	ATTACK,
	DAMAGE,
	DEATH,
	ROUND_END
}

# Ability Triggers (Moved from BattleArena to global types)
enum AbilityTrigger {
	START_OF_BATTLE,
	ENTRANCE,
	ATTACK,
	KILL,
	FRIEND_TOOK_DAMAGE,
	DEATH,
	ON_KO,
	ON_TAG_IN
}

# Winner Enum
enum Winner {
	PLAYER,
	ENEMY,
	DRAW,
	NONE # Struggle continues
}

# Faction Enum
enum Faction {
	INDEPENDENT=0,
	OGS=1,
	TECHNICOS=2,
	LUCHADORES_UNIDOS=3,
	LOS_RUDOS=4,
	LOS_BANDITOS=5
}

# Unit Class Enum
enum UnitClass {
	LUCHADOR=0,
	STRIKER=1,
	TECHNICIAN=2,
	HIGH_FLYER=3,
	POWER_HOUSE=4,
	BRAWLER=5,
	FAN=6
}

static func get_faction_name(faction: Faction) -> String:
	match faction:
		Faction.INDEPENDENT: return "Independent"
		Faction.OGS: return "OG's"
		Faction.TECHNICOS: return "Technicos"
		Faction.LUCHADORES_UNIDOS: return "Luchadores Unidos"
		Faction.LOS_RUDOS: return "Los Rudos"
		Faction.LOS_BANDITOS: return "Los Banditos"
		_: return "Unknown"

static func get_class_name(u_class: UnitClass) -> String:
	match u_class:
		UnitClass.LUCHADOR: return "Luchador"
		UnitClass.STRIKER: return "Striker"
		UnitClass.TECHNICIAN: return "Technician"
		UnitClass.HIGH_FLYER: return "High Flyer"
		UnitClass.POWER_HOUSE: return "Power House"
		UnitClass.BRAWLER: return "Brawler"
		UnitClass.FAN: return "Fan"
		_: return "Unknown"
