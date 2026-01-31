class_name AIController
extends RefCounted

var entity: Entity

func get_action() -> Action:
	return WaitAction.new(entity)

func get_distance_to_player() -> int:
	var player = GameState.player
	if not player:
		return 999
	var diff = player.grid_position - entity.grid_position
	return abs(diff.x) + abs(diff.y)

func get_direction_to_player() -> Vector2i:
	var player = GameState.player
	if not player:
		return Vector2i.ZERO

	var diff = player.grid_position - entity.grid_position
	var dir = Vector2i.ZERO

	if abs(diff.x) > abs(diff.y):
		dir.x = sign(diff.x)
	elif diff.y != 0:
		dir.y = sign(diff.y)
	else:
		dir.x = sign(diff.x)

	return dir

func is_player_adjacent() -> bool:
	return get_distance_to_player() == 1
