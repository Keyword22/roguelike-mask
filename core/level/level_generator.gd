class_name LevelGenerator
extends RefCounted

var level: Level
var min_room_size: int = 5
var max_room_size: int = 12
var max_rooms: int = 15
var room_margin: int = 2

func generate(width: int, height: int) -> Level:
	level = Level.new()
	level.initialize(width, height)

	_generate_rooms()
	_connect_rooms()
	_place_stairs()

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
			_connect_two_rooms(level.rooms[best_from], level.rooms[best_to])
			connected.append(best_to)
			unconnected.erase(best_to)

func _room_distance(room_a: Rect2i, room_b: Rect2i) -> float:
	var center_a = Vector2(room_a.position.x + room_a.size.x / 2.0, room_a.position.y + room_a.size.y / 2.0)
	var center_b = Vector2(room_b.position.x + room_b.size.x / 2.0, room_b.position.y + room_b.size.y / 2.0)
	return center_a.distance_to(center_b)

func _connect_two_rooms(room_a: Rect2i, room_b: Rect2i) -> void:
	var center_a = Vector2i(room_a.position.x + room_a.size.x / 2, room_a.position.y + room_a.size.y / 2)
	var center_b = Vector2i(room_b.position.x + room_b.size.x / 2, room_b.position.y + room_b.size.y / 2)

	if randi() % 2 == 0:
		_carve_horizontal_tunnel(center_a.x, center_b.x, center_a.y)
		_carve_vertical_tunnel(center_a.y, center_b.y, center_b.x)
	else:
		_carve_vertical_tunnel(center_a.y, center_b.y, center_a.x)
		_carve_horizontal_tunnel(center_a.x, center_b.x, center_b.y)

var corridor_width: int = 3

func _carve_horizontal_tunnel(x1: int, x2: int, y: int) -> void:
	var start_x = min(x1, x2)
	var end_x = max(x1, x2)
	var half_width = corridor_width / 2
	for x in range(start_x, end_x + 1):
		for dy in range(-half_width, half_width + 1):
			var pos = Vector2i(x, y + dy)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.TileType.FLOOR)

func _carve_vertical_tunnel(y1: int, y2: int, x: int) -> void:
	var start_y = min(y1, y2)
	var end_y = max(y1, y2)
	var half_width = corridor_width / 2
	for y in range(start_y, end_y + 1):
		for dx in range(-half_width, half_width + 1):
			var pos = Vector2i(x + dx, y)
			if level.is_in_bounds(pos):
				level.set_tile(pos, Level.TileType.FLOOR)

func _place_stairs() -> void:
	if level.rooms.size() < 2:
		return

	var first_room = level.rooms[0]
	var last_room = level.rooms[level.rooms.size() - 1]

	var up_pos = Vector2i(
		first_room.position.x + first_room.size.x / 2,
		first_room.position.y + first_room.size.y / 2
	)
	level.set_tile(up_pos, Level.TileType.STAIRS_UP)
	level.stairs_up_pos = up_pos

	var down_pos = Vector2i(
		last_room.position.x + last_room.size.x / 2,
		last_room.position.y + last_room.size.y / 2
	)
	level.set_tile(down_pos, Level.TileType.STAIRS_DOWN)
	level.stairs_down_pos = down_pos

func get_player_spawn_position() -> Vector2i:
	if level.rooms.size() > 0:
		var room = level.rooms[0]
		return Vector2i(
			room.position.x + room.size.x / 2 + 1,
			room.position.y + room.size.y / 2
		)
	return Vector2i(1, 1)
