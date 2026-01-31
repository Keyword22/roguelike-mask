class_name Mask
extends Resource

@export var mask_name: String = "Unknown"
@export var display_char: String = "?"
@export var color: Color = Color.WHITE
@export var description: String = ""

@export var health_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0

@export var can_phase: bool = false
@export var ability_name: String = ""
@export var ability_cooldown: int = 0
@export var sprite_id: String = ""

var current_cooldown: int = 0

func has_ability() -> bool:
	return ability_name != ""

func can_use_ability() -> bool:
	return has_ability() and current_cooldown == 0

func use_ability() -> void:
	current_cooldown = ability_cooldown

func tick_cooldown() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1

func reset_cooldown() -> void:
	current_cooldown = 0

func duplicate_mask() -> Mask:
	var new_mask = Mask.new()
	new_mask.mask_name = mask_name
	new_mask.display_char = display_char
	new_mask.color = color
	new_mask.description = description
	new_mask.health_bonus = health_bonus
	new_mask.attack_bonus = attack_bonus
	new_mask.defense_bonus = defense_bonus
	new_mask.can_phase = can_phase
	new_mask.ability_name = ability_name
	new_mask.ability_cooldown = ability_cooldown
	new_mask.sprite_id = sprite_id
	return new_mask
