class_name AIRanged
extends AIController

var attack_range: int = 5
var flee_when_close: bool = false
var preferred_distance: int = 3

func get_action() -> Action:
	if not entity or not entity.is_alive():
		return null

	var distance = get_distance_to_player()
	var player = GameState.player

	if distance > attack_range + 3:
		return WaitAction.new(entity)

	if distance <= attack_range and _has_line_of_sight():
		if flee_when_close and distance <= 2:
			var flee_dir = _get_flee_direction()
			if flee_dir != Vector2i.ZERO:
				return MoveAction.new(entity, flee_dir)
		return RangedAttackAction.new(entity, player)

	var direction = get_direction_to_player()
	if direction != Vector2i.ZERO:
		var target_pos = entity.grid_position + direction
		if GameState.current_level.is_walkable(target_pos) and GameState.get_entity_at(target_pos) == null:
			return MoveAction.new(entity, direction)

	return WaitAction.new(entity)

func _has_line_of_sight() -> bool:
	var player = GameState.player
	if not player:
		return false

	var start = entity.grid_position
	var end = player.grid_position
	var diff = end - start

	var steps = max(abs(diff.x), abs(diff.y))
	if steps == 0:
		return true

	for i in range(1, steps):
		var t = float(i) / float(steps)
		var check_x = int(round(start.x + diff.x * t))
		var check_y = int(round(start.y + diff.y * t))
		var check_pos = Vector2i(check_x, check_y)

		if not GameState.current_level.is_walkable(check_pos):
			return false

	return true

func _get_flee_direction() -> Vector2i:
	var player = GameState.player
	if not player:
		return Vector2i.ZERO

	var diff = entity.grid_position - player.grid_position
	var flee_dir = Vector2i(sign(diff.x), sign(diff.y))

	if abs(diff.x) > abs(diff.y):
		flee_dir.y = 0
	else:
		flee_dir.x = 0

	var target_pos = entity.grid_position + flee_dir
	if GameState.current_level.is_walkable(target_pos) and GameState.get_entity_at(target_pos) == null:
		return flee_dir

	var alts = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for alt in alts:
		var alt_pos = entity.grid_position + alt
		if GameState.current_level.is_walkable(alt_pos) and GameState.get_entity_at(alt_pos) == null:
			var alt_diff = alt_pos - player.grid_position
			if abs(alt_diff.x) + abs(alt_diff.y) > get_distance_to_player():
				return alt

	return Vector2i.ZERO
