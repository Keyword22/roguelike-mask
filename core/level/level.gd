class_name Level
extends Node2D

var width: int = 80
var height: int = 40
var tiles: Array = []
var rooms: Array = []
var stairs_down_pos: Vector2i = Vector2i(-1, -1)
var stairs_up_pos: Vector2i = Vector2i(-1, -1)
var dropped_masks: Dictionary = {}
var visible_tiles: Dictionary = {}
var explored_tiles: Dictionary = {}

enum TileType { WALL, FLOOR, STAIRS_DOWN, STAIRS_UP }

func _ready() -> void:
	GameState.set_level(self)

func initialize(w: int, h: int) -> void:
	width = w
	height = h
	tiles.clear()
	for y in height:
		var row = []
		for x in width:
			row.append(TileType.WALL)
		tiles.append(row)

func get_tile(pos: Vector2i) -> int:
	if not is_in_bounds(pos):
		return TileType.WALL
	return tiles[pos.y][pos.x]

func set_tile(pos: Vector2i, tile_type: int) -> void:
	if is_in_bounds(pos):
		tiles[pos.y][pos.x] = tile_type

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func is_walkable(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	var tile = get_tile(pos)
	return tile != TileType.WALL

func is_stairs_down(pos: Vector2i) -> bool:
	return get_tile(pos) == TileType.STAIRS_DOWN

func is_stairs_up(pos: Vector2i) -> bool:
	return get_tile(pos) == TileType.STAIRS_UP

func get_random_floor_position() -> Vector2i:
	var attempts = 0
	while attempts < 1000:
		var x = randi_range(1, width - 2)
		var y = randi_range(1, height - 2)
		var pos = Vector2i(x, y)
		if is_walkable(pos) and GameState.get_entity_at(pos) == null:
			return pos
		attempts += 1
	return Vector2i(-1, -1)

func get_spawn_position_in_room(room: Rect2i) -> Vector2i:
	var attempts = 0
	while attempts < 100:
		var x = randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
		var y = randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
		var pos = Vector2i(x, y)
		if is_walkable(pos) and GameState.get_entity_at(pos) == null:
			return pos
		attempts += 1
	return get_random_floor_position()

func drop_mask_at(mask: Mask, pos: Vector2i) -> void:
	var key = str(pos.x) + "," + str(pos.y)
	dropped_masks[key] = mask

func has_mask_at(pos: Vector2i) -> bool:
	var key = str(pos.x) + "," + str(pos.y)
	return dropped_masks.has(key)

func pickup_mask_at(pos: Vector2i) -> Mask:
	var key = str(pos.x) + "," + str(pos.y)
	if dropped_masks.has(key):
		var mask = dropped_masks[key]
		dropped_masks.erase(key)
		return mask
	return null

func get_all_dropped_masks() -> Dictionary:
	return dropped_masks

func is_tile_visible(pos: Vector2i) -> bool:
	return visible_tiles.has(pos)

func is_tile_explored(pos: Vector2i) -> bool:
	return explored_tiles.has(pos)

func compute_fov(origin: Vector2i, radius: int) -> void:
	visible_tiles.clear()
	_mark_visible(origin)

	for octant in 8:
		_cast_light_in_octant(origin, radius, 1, 1.0, 0.0, OCTANT_TRANSFORMS[octant])

func _mark_visible(pos: Vector2i) -> void:
	if is_in_bounds(pos):
		visible_tiles[pos] = true
		explored_tiles[pos] = true

func _blocks_light(pos: Vector2i) -> bool:
	return get_tile(pos) == TileType.WALL

const OCTANT_TRANSFORMS = [
	[1, 0, 0, 1],
	[0, 1, 1, 0],
	[0, -1, 1, 0],
	[-1, 0, 0, 1],
	[-1, 0, 0, -1],
	[0, -1, -1, 0],
	[0, 1, -1, 0],
	[1, 0, 0, -1],
]

func _cast_light_in_octant(origin: Vector2i, max_radius: int, current_row: int, visible_slope_start: float, visible_slope_end: float, transform: Array) -> void:
	if visible_slope_start < visible_slope_end:
		return

	var next_visible_slope_start = visible_slope_start

	for row_distance in range(current_row, max_radius + 1):
		var is_previous_tile_blocked = false
		var row_offset = -row_distance

		for col_offset in range(-row_distance, 1):
			var tile_slope_left = (col_offset - 0.5) / (row_offset + 0.5)
			var tile_slope_right = (col_offset + 0.5) / (row_offset - 0.5)

			if visible_slope_start < tile_slope_right:
				continue
			elif visible_slope_end > tile_slope_left:
				break

			var world_x = origin.x + col_offset * transform[0] + row_offset * transform[1]
			var world_y = origin.y + col_offset * transform[2] + row_offset * transform[3]
			var tile_pos = Vector2i(world_x, world_y)

			var distance_to_tile = Vector2(col_offset, row_offset).length()
			if distance_to_tile <= max_radius:
				_mark_visible(tile_pos)

			var is_current_tile_blocked = _blocks_light(tile_pos)

			if is_previous_tile_blocked:
				if is_current_tile_blocked:
					next_visible_slope_start = tile_slope_right
					continue
				else:
					is_previous_tile_blocked = false
					visible_slope_start = next_visible_slope_start
			elif is_current_tile_blocked and row_distance < max_radius:
				is_previous_tile_blocked = true
				_cast_light_in_octant(origin, max_radius, row_distance + 1, visible_slope_start, tile_slope_left, transform)
				next_visible_slope_start = tile_slope_right

		if is_previous_tile_blocked:
			break
