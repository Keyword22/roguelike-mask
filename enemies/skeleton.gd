class_name Skeleton
extends Enemy

var has_resurrected: bool = false

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
	skeleton_mask.reactive_effect = "revive"
	skeleton_mask.sprite_id = "skeleton"
	mask_drop = skeleton_mask

	super._ready()

func die() -> void:
	if not has_resurrected:
		has_resurrected = true
		health = max_health / 2
		EventBus.message_logged.emit("¡El Esqueleto se reconstruye!", Color.WHITE)
		return
	super.die()
