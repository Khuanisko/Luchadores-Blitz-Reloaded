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
	FRIEND_TOOK_DAMAGE
}

# Winner Enum
enum Winner {
	PLAYER,
	ENEMY,
	DRAW,
	NONE # Struggle continues
}
