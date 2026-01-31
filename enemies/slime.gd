class_name Slime
extends Enemy

func _ready() -> void:
	display_char = "s"
	display_color = Color.LIME_GREEN
	entity_name = "Slime"

	max_health = 12
	health = max_health
	attack = 2
	defense = 0

	var slime_mask = Mask.new()
	slime_mask.mask_name = "Slime"
	slime_mask.display_char = "s"
	slime_mask.color = Color.LIME_GREEN
	slime_mask.health_bonus = 5
	slime_mask.ability_name = "División"
	slime_mask.ability_cooldown = 8
	slime_mask.sprite_id = "slime"
	mask_drop = slime_mask

	super._ready()
