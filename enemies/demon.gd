class_name Demon
extends Enemy

func _ready() -> void:
	display_char = "D"
	display_color = Color.DARK_RED
	entity_name = "Demonio"

	max_health = 16
	health = max_health
	attack = 4
	defense = 2

	var demon_mask = Mask.new()
	demon_mask.mask_name = "Demonio"
	demon_mask.display_char = "D"
	demon_mask.color = Color.DARK_RED
	demon_mask.attack_bonus = 3
	demon_mask.ability_name = "Explosión"
	demon_mask.sprite_id = "demon"
	mask_drop = demon_mask

	super._ready()
	ai_controller = AIRanged.new()
	ai_controller.entity = self
	ai_controller.attack_range = 5
	ai_controller.flee_when_close = false
