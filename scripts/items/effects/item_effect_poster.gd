class_name ItemEffectPoster
extends ItemEffect

func execute(_target: UnitInstance) -> void:
	# Poster effect is global, so we ignore the specific target unit
	# It works if used on a unit OR if used on the shopkeeper (target=null)
	
	print("Poster Item Used! Requesting Shop Reroll & Next Unit Buff...")
	
	# 1. Flag next unit for buff
	GameData.next_purchase_stats.hp += 1
	GameData.next_purchase_stats.attack += 1
	
	# 2. Reroll Shop
	GameData.reroll_shop_requested.emit()
