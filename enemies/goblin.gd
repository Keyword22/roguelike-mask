class_name Goblin
extends Enemy

func _ready() -> void:
	display_char = "g"
	display_color = Color.GREEN
	entity_name = "Goblin"

	max_health = 8
	health = max_health
	attack = 3
	defense = 0

	var goblin_mask = Mask.new()
	goblin_mask.mask_name = "Goblin"
	goblin_mask.display_char = "g"
	goblin_mask.color = Color.GREEN
	goblin_mask.attack_bonus = 2
	goblin_mask.ability_name = "Embestida"
	goblin_mask.ability_cooldown = 5
	goblin_mask.sprite_id = "goblin"
	mask_drop = goblin_mask

	super._ready()
