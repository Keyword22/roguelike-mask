class_name LevelGenerator
extends RefCounted

var level: Level
var min_room_size: int = 5
var max_room_size: int = 12
var max_rooms: int = 15
var room_margin: int = 2
var min_spawn_exit_distance: int = 20
var corridor_connections: Array = []

func generate(width: int, height: int) -> Level:
	level = Level.new()
	level.initialize(width, height)

	_generate_rooms()
	_connect_rooms()
	_place_stairs_with_distance()
	_place_locked_door_and_key()

	return level

func _generate_rooms() -> void:
	var attempts = 0
	while level.rooms.size() < max_rooms and attempts < 500:
		var room = _try_create_room()
		if room != Rect2i():
			level.rooms.append(room)
			_carve_room(room)
		attempts += 1

func _try_create_room() -> Rect2i:
	var w = randi_range(min_room_size, max_room_size)
	var h = randi_range(min_room_size, max_room_size)
	var x = randi_range(1, level.width - w - 1)
	var y = randi_range(1, level.height - h - 1)

	var room = Rect2i(x, y, w, h)

	for existing in level.rooms:
		var expanded = Rect2i(
			existing.position.x - room_margin,
			existing.position.y - room_margin,
			existing.size.x + room_margin * 2,
			existing.size.y + room_margin * 2
		)
		if expanded.intersects(room):
			return Rect2i()

	return room

func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			level.set_tile(Vector2i(x, y), Level.TileType.FLOOR)

func _connect_rooms() -> void:
	if level.rooms.size() < 2:
		return

	corridor_connections.clear()
	var connected: Array[int] = [0]
	var unconnected: Array[int] = []
	for i in range(1, level.rooms.size()):
		unconnected.append(i)

	while unconnected.size() > 0:
		var best_from: int = -1
		var best_to: int = -1
		var best_dist: float = INF

		for c_idx in connected:
			for u_idx in unconnected:
				var dist = _room_distance(level.rooms[c_idx], level.rooms[u_idx])
				if dist < best_dist:
					best_dist = dist
					best_from = c_idx
					best_to = u_idx

		if best_to != -1:
			var corridor_tiles = _connect_two_rooms(level.rooms[best_from], level.rooms[best_to])
			corridor_connections.append({
				"from": best_from,
				"to": best_to,
				"tiles": corridor_tiles
			})
			connected.append(best_to)
			unconnected.erase(best_to)

func _room_distance(room_a: Rect2i, room_b: Rect2i) -> float:
	var center_a = Vector2(room_a.position.x + room_a.size.x / 2.0, room_a.position.y + room_a.size.y / 2.0)
	var center_b = Vector2(room_b.position.x + room_b.size.x / 2.0, room_b.position.y + room_b.size.y / 2.0)
	return center_a.distance_to(center_b)

func _connect_two_rooms(room_a: Rect2i, room_b: Rect2i) -> Array:
	var center_a = Vector2i(room_a.position.x + room_a.size.x / 2, room_a.position.y + room_a.size.y / 2)
	var center_b = Vector2i(room_b.position.x + room_b.size.x / 2, room_b.position.y + room_b.size.y / 2)

	var tiles: Array = []
	var width = _get_corridor_width()

	if randi() % 2 == 0:
		tiles.append_array(_carve_horizontal_tunnel(center_a.x, center_b.x, center_a.y, width))
		tiles.append_array(_carve_vertical_tunnel(center_a.y, center_b.y, center_b.x, width))
	else:
		tiles.append_array(_carve_vertical_tunnel(center_a.y, center_b.y, center_a.x, width))
		tiles.append_array(_carve_horizontal_tunnel(center_a.x, center_b.x, center_b.y, width))

	return tiles

func _get_corridor_width() -> int:
	var roll = randi() % 100
	if roll < 40:
		return 1
	elif roll < 75:
		return 2
	else:
		return 3

func _carve_horizontal_tunnel(x1: int, x2: int, y: int, width: int = 1) -> Array:
	var tiles: Array = []
	var start_x = min(x1, x2)
	var end_x = max(x1, x2)
	var half_width = width / 2
	for x in range(start_x, end_x + 1):
		for dy in range(-half_width, half_width + 1):
			var pos = Vector2i(x, y + dy)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.TileType.FLOOR)
				tiles.append(pos)
	return tiles

func _carve_vertical_tunnel(y1: int, y2: int, x: int, width: int = 1) -> Array:
	var tiles: Array = []
	var start_y = min(y1, y2)
	var end_y = max(y1, y2)
	var half_width = width / 2
	for y in range(start_y, end_y + 1):
		for dx in range(-half_width, half_width + 1):
			var pos = Vector2i(x + dx, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.TileType.FLOOR)
				tiles.append(pos)
	return tiles

func _place_stairs_with_distance() -> void:
	if level.rooms.size() < 2:
		return

	var best_spawn_room = 0
	var best_exit_room = 1
	var best_distance = 0

	for i in range(level.rooms.size()):
		for j in range(level.rooms.size()):
			if i == j:
				continue
			var room_i = level.rooms[i]
			var room_j = level.rooms[j]
			var pos_i = Vector2i(room_i.position.x + room_i.size.x / 2, room_i.position.y + room_i.size.y / 2)
			var pos_j = Vector2i(room_j.position.x + room_j.size.x / 2, room_j.position.y + room_j.size.y / 2)
			var dist = _calculate_path_distance(pos_i, pos_j)
			if dist > best_distance:
				best_distance = dist
				best_spawn_room = i
				best_exit_room = j

	spawn_room_index = best_spawn_room
	var spawn_room = level.rooms[best_spawn_room]
	var exit_room = level.rooms[best_exit_room]

	var up_pos = Vector2i(
		spawn_room.position.x + spawn_room.size.x / 2,
		spawn_room.position.y + spawn_room.size.y / 2
	)
	level.set_tile(up_pos, Level.TileType.STAIRS_UP)
	level.stairs_up_pos = up_pos

	var down_pos = Vector2i(
		exit_room.position.x + exit_room.size.x / 2,
		exit_room.position.y + exit_room.size.y / 2
	)
	level.set_tile(down_pos, Level.TileType.STAIRS_DOWN)
	level.stairs_down_pos = down_pos

var spawn_room_index: int = 0

func _place_locked_door_and_key() -> void:
	if corridor_connections.size() < 2:
		return

	var exit_room_index = _find_room_containing(level.stairs_down_pos)
	if exit_room_index == -1:
		return

	var door_corridor = _find_corridor_blocking_path_to_exit(exit_room_index)
	if door_corridor == null:
		return

	var door_pos = _find_door_position_in_corridor(door_corridor["tiles"])
	if door_pos == Vector2i(-1, -1):
		return

	level.set_tile(door_pos, Level.TileType.DOOR_LOCKED)

	var reachable_rooms = _get_rooms_reachable_without_door(door_corridor)
	if reachable_rooms.size() == 0:
		level.set_tile(door_pos, Level.TileType.FLOOR)
		return

	var key_room_index = reachable_rooms[randi() % reachable_rooms.size()]
	if key_room_index == spawn_room_index:
		for idx in reachable_rooms:
			if idx != spawn_room_index:
				key_room_index = idx
				break

	var key_room = level.rooms[key_room_index]
	level.key_position = level.get_spawn_position_in_room(key_room)

func _find_room_containing(pos: Vector2i) -> int:
	for i in range(level.rooms.size()):
		var room = level.rooms[i]
		if pos.x >= room.position.x and pos.x < room.position.x + room.size.x:
			if pos.y >= room.position.y and pos.y < room.position.y + room.size.y:
				return i
	return -1

func _find_corridor_blocking_path_to_exit(exit_room: int) -> Dictionary:
	for corridor in corridor_connections:
		if corridor["to"] == exit_room or corridor["from"] == exit_room:
			if corridor["tiles"].size() > 0:
				return corridor
	for corridor in corridor_connections:
		if corridor["tiles"].size() > 3:
			return corridor
	return {}

func _find_door_position_in_corridor(tiles: Array) -> Vector2i:
	if tiles.size() < 3:
		return Vector2i(-1, -1)

	var mid_index = tiles.size() / 2
	for i in range(mid_index, tiles.size()):
		var pos = tiles[i]
		if _is_valid_door_position(pos):
			return pos

	for i in range(mid_index - 1, -1, -1):
		var pos = tiles[i]
		if _is_valid_door_position(pos):
			return pos

	return Vector2i(-1, -1)

func _is_valid_door_position(pos: Vector2i) -> bool:
	var horizontal_walls = (
		level.get_tile(Vector2i(pos.x, pos.y - 1)) == Level.TileType.WALL and
		level.get_tile(Vector2i(pos.x, pos.y + 1)) == Level.TileType.WALL
	)
	var vertical_walls = (
		level.get_tile(Vector2i(pos.x - 1, pos.y)) == Level.TileType.WALL and
		level.get_tile(Vector2i(pos.x + 1, pos.y)) == Level.TileType.WALL
	)
	return horizontal_walls or vertical_walls

func _get_rooms_reachable_without_door(blocked_corridor: Dictionary) -> Array:
	var reachable: Array = [spawn_room_index]
	var to_check: Array = [spawn_room_index]

	while to_check.size() > 0:
		var current = to_check.pop_front()
		for corridor in corridor_connections:
			if corridor == blocked_corridor:
				continue
			var other_room = -1
			if corridor["from"] == current:
				other_room = corridor["to"]
			elif corridor["to"] == current:
				other_room = corridor["from"]
			if other_room != -1 and other_room not in reachable:
				reachable.append(other_room)
				to_check.append(other_room)

	return reachable

func _calculate_path_distance(from: Vector2i, to: Vector2i) -> int:
	var open_set: Array = [from]
	var g_score: Dictionary = {from: 0}
	var came_from: Dictionary = {}

	while open_set.size() > 0:
		var current = open_set[0]
		var current_g = g_score.get(current, 999999)
		for pos in open_set:
			if g_score.get(pos, 999999) < current_g:
				current = pos
				current_g = g_score.get(pos, 999999)

		if current == to:
			return current_g

		open_set.erase(current)

		var neighbors = [
			Vector2i(current.x + 1, current.y),
			Vector2i(current.x - 1, current.y),
			Vector2i(current.x, current.y + 1),
			Vector2i(current.x, current.y - 1)
		]

		for neighbor in neighbors:
			if not level.is_walkable(neighbor):
				continue
			var tentative_g = current_g + 1
			if tentative_g < g_score.get(neighbor, 999999):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				if neighbor not in open_set:
					open_set.append(neighbor)

	return abs(from.x - to.x) + abs(from.y - to.y)

func get_player_spawn_position() -> Vector2i:
	if level.stairs_up_pos != Vector2i(-1, -1):
		var dirs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for dir in dirs:
			var pos = level.stairs_up_pos + dir
			if level.is_walkable(pos):
				return pos
	if level.rooms.size() > 0:
		var room = level.rooms[0]
		return Vector2i(
			room.position.x + room.size.x / 2 + 1,
			room.position.y + room.size.y / 2
		)
	return Vector2i(1, 1)
