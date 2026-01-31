class_name Player
extends Entity

var mask_inventory: MaskInventory

var base_max_health: int = 20
var base_attack: int = 3
var base_defense: int = 1

func _ready() -> void:
	display_char = "@"
	display_color = Color.YELLOW
	entity_name = "Jugador"

	max_health = base_max_health
	health = max_health
	attack = base_attack
	defense = base_defense

	mask_inventory = MaskInventory.new()
	add_child(mask_inventory)

	GameState.set_player(self)
	super._ready()

func get_total_attack() -> int:
	var bonus = 0
	if mask_inventory.equipped_mask:
		bonus = mask_inventory.equipped_mask.attack_bonus
	return base_attack + bonus

func get_total_defense() -> int:
	var bonus = 0
	if mask_inventory.equipped_mask:
		bonus = mask_inventory.equipped_mask.defense_bonus
	return base_defense + bonus

func get_total_max_health() -> int:
	var bonus = 0
	if mask_inventory.equipped_mask:
		bonus = mask_inventory.equipped_mask.health_bonus
	return base_max_health + bonus

func recalculate_stats() -> void:
	var old_max = max_health
	max_health = get_total_max_health()
	attack = get_total_attack()
	defense = get_total_defense()

	if max_health > old_max:
		health += (max_health - old_max)
	elif health > max_health:
		health = max_health

func take_damage(amount: int) -> int:
	var actual_damage = max(0, amount - get_total_defense())
	health -= actual_damage
	if health <= 0:
		health = 0
		die()
	return actual_damage

func die() -> void:
	GameState.game_over(false)
	super.die()

func can_phase_through_walls() -> bool:
	if mask_inventory.equipped_mask:
		return mask_inventory.equipped_mask.can_phase
	return false

func get_display_char() -> String:
	if mask_inventory.equipped_mask:
		return mask_inventory.equipped_mask.display_char
	return "@"

func get_display_color() -> Color:
	if mask_inventory.equipped_mask:
		return mask_inventory.equipped_mask.color
	return Color.YELLOW
