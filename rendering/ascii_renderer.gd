class_name AsciiRenderer
extends Node2D

const TILE_SIZE: int = 32
const FONT_SIZE: int = 16

var level: Level
var entity_labels: Dictionary = {}
var tile_labels: Array = []
var mask_labels: Dictionary = {}

var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	EventBus.entity_moved.connect(_on_entity_moved)
	EventBus.entity_spawned.connect(_on_entity_spawned)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.mask_dropped.connect(_on_mask_dropped)
	EventBus.mask_picked_up.connect(_on_mask_picked_up)

func render_level(lvl: Level) -> void:
	level = lvl
	_clear_tiles()
	_create_tile_labels()

func _clear_tiles() -> void:
	for child in get_children():
		child.queue_free()
	tile_labels.clear()
	mask_labels.clear()
	entity_labels.clear()

func _clear_all() -> void:
	_clear_tiles()

func _create_tile_labels() -> void:
	for y in level.height:
		for x in level.width:
			var pos = Vector2i(x, y)
			var tile = level.get_tile(pos)
			var label = _create_label(_get_tile_char(tile), _get_tile_color(tile))
			label.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			tile_labels.append(label)

func _get_tile_char(tile: int) -> String:
	match tile:
		Level.TileType.WALL:
			return "#"
		Level.TileType.FLOOR:
			return "."
		Level.TileType.STAIRS_DOWN:
			return ">"
		Level.TileType.STAIRS_UP:
			return "<"
	return "?"

func _get_tile_color(tile: int) -> Color:
	match tile:
		Level.TileType.WALL:
			return Color(0.4, 0.4, 0.4)
		Level.TileType.FLOOR:
			return Color(0.3, 0.3, 0.3)
		Level.TileType.STAIRS_DOWN:
			return Color(0.8, 0.8, 0.2)
		Level.TileType.STAIRS_UP:
			return Color(0.2, 0.8, 0.8)
	return Color.WHITE

func _create_label(char: String, color: Color) -> Label:
	var label = Label.new()
	label.text = char
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	add_child(label)
	return label

func render_entity(entity: Entity) -> void:
	if entity_labels.has(entity):
		return

	var char = entity.display_char
	var color = entity.display_color

	if entity is Player:
		char = entity.get_display_char()
		color = entity.get_display_color()

	var label = _create_label(char, color)
	label.position = Vector2(entity.grid_position.x * TILE_SIZE, entity.grid_position.y * TILE_SIZE)
	label.z_index = 1
	entity_labels[entity] = label

func update_entity_position(entity: Entity) -> void:
	if not entity_labels.has(entity):
		return

	var label = entity_labels[entity]
	label.position = Vector2(entity.grid_position.x * TILE_SIZE, entity.grid_position.y * TILE_SIZE)

	if entity is Player:
		label.text = entity.get_display_char()
		label.add_theme_color_override("font_color", entity.get_display_color())

func remove_entity(entity: Entity) -> void:
	if entity_labels.has(entity):
		var label = entity_labels[entity]
		if is_instance_valid(label):
			label.queue_free()
		entity_labels.erase(entity)

func _on_entity_spawned(entity: Entity) -> void:
	render_entity(entity)

func _on_entity_moved(entity: Entity, _from: Vector2i, _to: Vector2i) -> void:
	update_entity_position(entity)

func _on_entity_died(entity: Entity) -> void:
	remove_entity(entity)

func _on_mask_dropped(mask: Mask, pos: Vector2i) -> void:
	if level:
		level.drop_mask_at(mask.duplicate_mask(), pos)
	var key = str(pos.x) + "," + str(pos.y)
	var label = _create_label("M", mask.color)
	label.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
	label.z_index = 1
	mask_labels[key] = label

func _on_mask_picked_up(_mask: Mask, _entity: Entity) -> void:
	var player = GameState.player
	if player:
		var key = str(player.grid_position.x) + "," + str(player.grid_position.y)
		if mask_labels.has(key):
			var label = mask_labels[key]
			if is_instance_valid(label):
				label.queue_free()
			mask_labels.erase(key)

func get_camera_center() -> Vector2:
	var player = GameState.player
	if player:
		return Vector2(player.grid_position.x * TILE_SIZE, player.grid_position.y * TILE_SIZE)
	return Vector2.ZERO
