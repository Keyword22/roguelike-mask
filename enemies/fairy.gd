class_name Fairy
extends Enemy

func _ready() -> void:
	display_char = "f"
	display_color = Color.MAGENTA
	entity_name = "Hada"

	max_health = 4
	health = max_health
	attack = 2
	defense = 0

	var fairy_mask = Mask.new()
	fairy_mask.mask_name = "Hada"
	fairy_mask.display_char = "f"
	fairy_mask.color = Color.MAGENTA
	fairy_mask.defense_bonus = 1
	fairy_mask.reactive_effect = "teleport_on_hit"
	fairy_mask.sprite_id = "fairy"
	mask_drop = fairy_mask

	super._ready()
	ai_controller = AIRanged.new()
	ai_controller.entity = self
	ai_controller.attack_range = 4
	ai_controller.flee_when_close = false

func take_damage(amount: int) -> int:
	var dmg = super.take_damage(amount)
	if is_alive() and dmg > 0:
		_teleport_away()
	return dmg

func _teleport_away() -> void:
	var level = GameState.current_level
	var valid_positions: Array[Vector2i] = []

	for y in range(-8, 9):
		for x in range(-8, 9):
			var dist = abs(x) + abs(y)
			if dist < 4 or dist > 8:
				continue
			var pos = grid_position + Vector2i(x, y)
			if level.is_walkable(pos) and GameState.get_entity_at(pos) == null:
				valid_positions.append(pos)

	if valid_positions.size() > 0:
		var new_pos = valid_positions[randi() % valid_positions.size()]
		set_grid_position(new_pos)
		EventBus.message_logged.emit("¡El Hada se teletransporta lejos!", Color.MAGENTA)
