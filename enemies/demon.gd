class_name Demon
extends Enemy

func _ready() -> void:
	display_char = "D"
	display_color = Color.DARK_RED
	entity_name = "Demonio"

	max_health = 14
	health = max_health
	attack = 5
	defense = 1

	var demon_mask = Mask.new()
	demon_mask.mask_name = "Demonio"
	demon_mask.display_char = "D"
	demon_mask.color = Color.DARK_RED
	demon_mask.attack_bonus = 3
	demon_mask.ability_name = "Explosión"
	demon_mask.ability_cooldown = 0
	demon_mask.sprite_id = "demon"
	mask_drop = demon_mask

	super._ready()
