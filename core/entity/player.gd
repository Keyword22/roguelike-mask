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

	if actual_damage > 0:
		var reactive_result = _check_reactive_on_hit()
		if reactive_result:
			return actual_damage

	if health <= 0:
		health = 0
		if not _check_reactive_on_death():
			die()
	return actual_damage

func _check_reactive_on_hit() -> bool:
	if not mask_inventory.equipped_mask:
		return false
	var mask = mask_inventory.equipped_mask
	if mask.reactive_effect == "teleport_on_hit":
		EventBus.mask_ability_used.emit(mask, self)
		_reactive_teleport()
		_break_reactive_mask()
		return true
	return false

func _check_reactive_on_death() -> bool:
	if not mask_inventory.equipped_mask:
		return false
	var mask = mask_inventory.equipped_mask
	if mask.reactive_effect == "revive":
		health = 1
		EventBus.message_logged.emit("¡La máscara de " + mask.mask_name + " te revive!", Color.GOLD)
		EventBus.mask_ability_used.emit(mask, self)
		_break_reactive_mask()
		return true
	return false

func _reactive_teleport() -> void:
	var level = GameState.current_level
	var valid_positions: Array[Vector2i] = []
	var search_radius = 8

	for y in range(-search_radius, search_radius + 1):
		for x in range(-search_radius, search_radius + 1):
			if x == 0 and y == 0:
				continue
			var dist = abs(x) + abs(y)
			if dist < 5:
				continue
			var pos = grid_position + Vector2i(x, y)
			if level.is_walkable(pos) and GameState.get_entity_at(pos) == null:
				valid_positions.append(pos)

	if valid_positions.size() > 0:
		var new_pos = valid_positions[randi() % valid_positions.size()]
		set_grid_position(new_pos)
		EventBus.message_logged.emit("¡Te teletransportas lejos del peligro!", Color.MAGENTA)

func _break_reactive_mask() -> void:
	var mask_name = mask_inventory.equipped_mask.mask_name
	mask_inventory.remove_mask(mask_inventory.equipped_index)
	EventBus.message_logged.emit("¡La máscara de " + mask_name + " se rompe!", Color.ORANGE)
	EventBus.ui_update_requested.emit()

func die() -> void:
	GameState.game_over(false)
	super.die()

func can_phase_through_walls() -> bool:
	if mask_inventory.equipped_mask:
		return mask_inventory.equipped_mask.can_still_phase()
	return false

func use_phase() -> void:
	if mask_inventory.equipped_mask and mask_inventory.equipped_mask.phase_uses > 0:
		var broke = mask_inventory.equipped_mask.use_phase()
		EventBus.message_logged.emit("¡Atraviesas la pared! (Usos restantes: " + str(mask_inventory.equipped_mask.phase_uses_remaining) + ")", Color.LIGHT_BLUE)
		if broke:
			_break_reactive_mask()
		EventBus.ui_update_requested.emit()

func get_display_char() -> String:
	if mask_inventory.equipped_mask:
		return mask_inventory.equipped_mask.display_char
	return "@"

func get_display_color() -> Color:
	if mask_inventory.equipped_mask:
		return mask_inventory.equipped_mask.color
	return Color.YELLOW
