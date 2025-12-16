class_name AbilityBase
extends Resource

func execute(_owner: UnitInstance, _context: Dictionary = {}) -> bool:
	return false

func get_description(_level: int, base_desc: String) -> String:
	return base_desc
