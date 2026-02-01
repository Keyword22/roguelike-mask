class_name AICharge
extends AIController

var charge_range: int = 5

func get_action() -> Action:
	if not entity or not entity.is_alive():
		return null

	var distance = get_distance_to_player()
	var player = GameState.player

	if distance > charge_range + 3:
		return WaitAction.new(entity)

	if is_player_adjacent():
		return AttackAction.new(entity, player)

	if distance <= charge_range and distance > 1:
		var charge_result = _try_charge()
		if charge_result:
			return charge_result

	var direction = get_direction_to_player()
	if direction != Vector2i.ZERO:
		var target_pos = entity.grid_position + direction
		if GameState.current_level.is_walkable(target_pos) and GameState.get_entity_at(target_pos) == null:
			return MoveAction.new(entity, direction)

		var alt_dirs = _get_alternate_directions(direction)
		for alt_dir in alt_dirs:
			var alt_pos = entity.grid_position + alt_dir
			if GameState.current_level.is_walkable(alt_pos) and GameState.get_entity_at(alt_pos) == null:
				return MoveAction.new(entity, alt_dir)

	return WaitAction.new(entity)

func _try_charge() -> Action:
	var player = GameState.player
	var diff = player.grid_position - entity.grid_position

	var charge_dir = Vector2i.ZERO
	if abs(diff.x) > abs(diff.y) and diff.y == 0:
		charge_dir = Vector2i(sign(diff.x), 0)
	elif abs(diff.y) > abs(diff.x) and diff.x == 0:
		charge_dir = Vector2i(0, sign(diff.y))
	else:
		return null

	var path_clear = true
	var charge_distance = max(abs(diff.x), abs(diff.y))

	for i in range(1, charge_distance):
		var check_pos = entity.grid_position + charge_dir * i
		if not GameState.current_level.is_walkable(check_pos):
			path_clear = false
			break
		var ent = GameState.get_entity_at(check_pos)
		if ent and ent != player:
			path_clear = false
			break

	if path_clear:
		var final_pos = entity.grid_position + charge_dir * (charge_distance - 1)
		entity.set_grid_position(final_pos)
		EventBus.message_logged.emit("¡" + entity.entity_name + " carga hacia ti!", Color.ORANGE)
		return AttackAction.new(entity, player)

	return null

func _get_alternate_directions(primary: Vector2i) -> Array:
	var alts = []
	if primary.x != 0:
		alts.append(Vector2i(0, 1))
		alts.append(Vector2i(0, -1))
	if primary.y != 0:
		alts.append(Vector2i(1, 0))
		alts.append(Vector2i(-1, 0))
	return alts
