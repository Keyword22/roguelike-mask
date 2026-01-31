class_name Fairy
extends Enemy

func _ready() -> void:
	display_char = "f"
	display_color = Color.MAGENTA
	entity_name = "Hada"

	max_health = 4
	health = max_health
	attack = 1
	defense = 0

	var fairy_mask = Mask.new()
	fairy_mask.mask_name = "Hada"
	fairy_mask.display_char = "f"
	fairy_mask.color = Color.MAGENTA
	fairy_mask.defense_bonus = 1
	fairy_mask.health_bonus = 2
	fairy_mask.ability_name = "Centelleo"
	fairy_mask.ability_cooldown = 0
	fairy_mask.sprite_id = "fairy"
	mask_drop = fairy_mask

	super._ready()
