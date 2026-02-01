class_name Ghost
extends Enemy

func _ready() -> void:
	display_char = "G"
	display_color = Color.LIGHT_BLUE
	entity_name = "Fantasma"

	max_health = 8
	health = max_health
	attack = 3
	defense = 1

	var ghost_mask = Mask.new()
	ghost_mask.mask_name = "Fantasma"
	ghost_mask.display_char = "G"
	ghost_mask.color = Color.LIGHT_BLUE
	ghost_mask.defense_bonus = 2
	ghost_mask.can_phase = true
	ghost_mask.phase_uses = 5
	ghost_mask.sprite_id = "ghost"
	mask_drop = ghost_mask

	super._ready()
	ai_controller = AIGhost.new()
	ai_controller.entity = self
