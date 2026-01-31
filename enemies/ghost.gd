class_name Ghost
extends Enemy

func _ready() -> void:
	display_char = "G"
	display_color = Color.LIGHT_BLUE
	entity_name = "Fantasma"

	max_health = 6
	health = max_health
	attack = 2
	defense = 2

	var ghost_mask = Mask.new()
	ghost_mask.mask_name = "Fantasma"
	ghost_mask.display_char = "G"
	ghost_mask.color = Color.LIGHT_BLUE
	ghost_mask.defense_bonus = 3
	ghost_mask.can_phase = true
	ghost_mask.ability_name = "Fase"
	ghost_mask.ability_cooldown = 0
	ghost_mask.sprite_id = "ghost"
	mask_drop = ghost_mask

	super._ready()
