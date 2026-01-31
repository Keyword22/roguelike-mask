class_name Skeleton
extends Enemy

func _ready() -> void:
	display_char = "S"
	display_color = Color.WHITE
	entity_name = "Esqueleto"

	max_health = 10
	health = max_health
	attack = 3
	defense = 1

	var skeleton_mask = Mask.new()
	skeleton_mask.mask_name = "Esqueleto"
	skeleton_mask.display_char = "S"
	skeleton_mask.color = Color.WHITE
	skeleton_mask.attack_bonus = 1
	skeleton_mask.defense_bonus = 1
	skeleton_mask.ability_name = "Lanzar Hueso"
	skeleton_mask.ability_cooldown = 3
	mask_drop = skeleton_mask

	super._ready()
