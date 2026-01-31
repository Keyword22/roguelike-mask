class_name Level
extends Node2D

var width: int = 80
var height: int = 40
var tiles: Array = []
var rooms: Array = []
var stairs_down_pos: Vector2i = Vector2i(-1, -1)
var stairs_up_pos: Vector2i = Vector2i(-1, -1)
var dropped_masks: Dictionary = {}

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
