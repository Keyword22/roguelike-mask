class_name AIGhost
extends AIController

var detection_range: int = 12

func get_action() -> Action:
	if not entity or not entity.is_alive():
		return null

	var distance = get_distance_to_player()

	if distance > detection_range:
		return WaitAction.new(entity)

	if is_player_adjacent():
		return AttackAction.new(entity, GameState.player)

	var direction = get_direction_to_player()
	if direction != Vector2i.ZERO:
		var target_pos = entity.grid_position + direction
		if _can_move_to(target_pos):
			return MoveAction.new(entity, direction)

		var alt_dirs = _get_alternate_directions(direction)
		for alt_dir in alt_dirs:
			var alt_pos = entity.grid_position + alt_dir
			if _can_move_to(alt_pos):
				return MoveAction.new(entity, alt_dir)

	return WaitAction.new(entity)

func _can_move_to(pos: Vector2i) -> bool:
	if not GameState.current_level.is_in_bounds(pos):
		return false
	if GameState.get_entity_at(pos) != null:
		return false
	return true

func _get_alternate_directions(primary: Vector2i) -> Array:
	var alts = []
	if primary.x != 0:
		alts.append(Vector2i(0, 1))
		alts.append(Vector2i(0, -1))
	if primary.y != 0:
		alts.append(Vector2i(1, 0))
		alts.append(Vector2i(-1, 0))
	return alts
