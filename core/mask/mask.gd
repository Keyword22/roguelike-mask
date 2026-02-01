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
@export var phase_uses: int = -1
@export var ability_name: String = ""
@export var ability_cooldown: int = 0
@export var sprite_id: String = ""
@export var reactive_effect: String = ""

var current_cooldown: int = 0
var phase_uses_remaining: int = -1

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

func init_uses() -> void:
	if phase_uses > 0:
		phase_uses_remaining = phase_uses

func use_phase() -> bool:
	if phase_uses_remaining > 0:
		phase_uses_remaining -= 1
		return phase_uses_remaining <= 0
	return false

func can_still_phase() -> bool:
	if phase_uses < 0:
		return can_phase
	return can_phase and phase_uses_remaining > 0

func has_reactive_effect() -> bool:
	return reactive_effect != ""

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
	new_mask.phase_uses = phase_uses
	new_mask.ability_name = ability_name
	new_mask.ability_cooldown = ability_cooldown
	new_mask.sprite_id = sprite_id
	new_mask.reactive_effect = reactive_effect
	new_mask.init_uses()
	return new_mask
