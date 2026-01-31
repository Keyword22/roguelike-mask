class_name HybridRenderer
extends Node2D

const TILE_SIZE: int = 32
const FONT_SIZE: int = 16

var level: Level
var tile_map: TileMapLayer
var entity_nodes: Dictionary = {}
var mask_nodes: Dictionary = {}
var tile_labels: Array = []

var use_tilemap_for_level: bool = true
var sprite_cache: Dictionary = {}

func _ready() -> void:
	EventBus.entity_moved.connect(_on_entity_moved)
	EventBus.entity_spawned.connect(_on_entity_spawned)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.mask_dropped.connect(_on_mask_dropped)
	EventBus.mask_picked_up.connect(_on_mask_picked_up)

	_preload_sprites()

func _preload_sprites() -> void:
	var paths = {
		"player": "res://sprites/player.png",
		"goblin": "res://sprites/goblin.png",
		"slime": "res://sprites/slime.png",
		"skeleton": "res://sprites/skeleton.png",
		"ghost": "res://sprites/ghost.png",
		"mask": "res://sprites/mask.png",
		"tileset": "res://sprites/tileset.png"
	}

	for key in paths:
		if ResourceLoader.exists(paths[key]):
			sprite_cache[key] = load(paths[key])

func has_sprite(key: String) -> bool:
	return sprite_cache.has(key)

func render_level(lvl: Level) -> void:
	level = lvl
	_clear_all()

	if has_sprite("tileset"):
		_render_level_with_tilemap()
	else:
		_render_level_with_labels()

func _clear_all() -> void:
	for child in get_children():
		child.queue_free()

	tile_map = null
	tile_labels.clear()
	mask_nodes.clear()
	entity_nodes.clear()

func _render_level_with_tilemap() -> void:
	tile_map = TileMapLayer.new()
	add_child(tile_map)

	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source = TileSetAtlasSource.new()
	source.texture = sprite_cache["tileset"]
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Atlas layout esperado:
	# (0,0)=muro, (1,0)=suelo, (2,0)=escaleras_abajo, (3,0)=escaleras_arriba
	for x in 4:
		source.create_tile(Vector2i(x, 0))

	tileset.add_source(source, 0)
	tile_map.tile_set = tileset

	for y in level.height:
		for x in level.width:
			var tile = level.get_tile(Vector2i(x, y))
			var atlas_coord = _tile_to_atlas_coord(tile)
			tile_map.set_cell(Vector2i(x, y), 0, atlas_coord)

func _tile_to_atlas_coord(tile: int) -> Vector2i:
	match tile:
		Level.TileType.WALL: return Vector2i(0, 0)
		Level.TileType.FLOOR: return Vector2i(1, 0)
		Level.TileType.STAIRS_DOWN: return Vector2i(2, 0)
		Level.TileType.STAIRS_UP: return Vector2i(3, 0)
	return Vector2i(0, 0)

func _render_level_with_labels() -> void:
	for y in level.height:
		for x in level.width:
			var pos = Vector2i(x, y)
			var tile = level.get_tile(pos)
			var label = _create_label(_get_tile_char(tile), _get_tile_color(tile))
			label.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			tile_labels.append(label)

func _get_tile_char(tile: int) -> String:
	match tile:
		Level.TileType.WALL: return "#"
		Level.TileType.FLOOR: return "."
		Level.TileType.STAIRS_DOWN: return ">"
		Level.TileType.STAIRS_UP: return "<"
	return "?"

func _get_tile_color(tile: int) -> Color:
	match tile:
		Level.TileType.WALL: return Color(0.4, 0.4, 0.4)
		Level.TileType.FLOOR: return Color(0.3, 0.3, 0.3)
		Level.TileType.STAIRS_DOWN: return Color(0.8, 0.8, 0.2)
		Level.TileType.STAIRS_UP: return Color(0.2, 0.8, 0.8)
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
	if entity_nodes.has(entity):
		return

	var sprite_key = _get_entity_sprite_key(entity)
	var node: CanvasItem

	if has_sprite(sprite_key):
		node = _create_sprite(sprite_key, entity)
	else:
		node = _create_entity_label(entity)

	_set_node_position(node, entity.grid_position)
	node.z_index = 1
	entity_nodes[entity] = node

func _set_node_position(node: CanvasItem, grid_pos: Vector2i) -> void:
	var pixel_pos = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	if node is Control:
		(node as Control).position = pixel_pos
	else:
		(node as Node2D).position = pixel_pos

func _get_entity_sprite_key(entity: Entity) -> String:
	if entity is Player:
		return "player"
	if entity is Goblin:
		return "goblin"
	if entity is Slime:
		return "slime"
	if entity is Skeleton:
		return "skeleton"
	if entity is Ghost:
		return "ghost"
	return ""

func _create_sprite(key: String, entity: Entity) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = sprite_cache[key]
	sprite.centered = false

	if sprite.texture.get_width() != TILE_SIZE:
		var scale_factor = float(TILE_SIZE) / sprite.texture.get_width()
		sprite.scale = Vector2(scale_factor, scale_factor)

	add_child(sprite)
	return sprite

func _create_entity_label(entity: Entity) -> Label:
	var char = entity.display_char
	var color = entity.display_color

	if entity is Player:
		char = entity.get_display_char()
		color = entity.get_display_color()

	return _create_label(char, color)

func update_entity_position(entity: Entity) -> void:
	if not entity_nodes.has(entity):
		return

	var node = entity_nodes[entity]
	_set_node_position(node, entity.grid_position)

	if entity is Player and node is Label:
		(node as Label).text = entity.get_display_char()
		(node as Label).add_theme_color_override("font_color", entity.get_display_color())

func remove_entity(entity: Entity) -> void:
	if entity_nodes.has(entity):
		var node = entity_nodes[entity]
		if is_instance_valid(node):
			node.queue_free()
		entity_nodes.erase(entity)

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
	var node: CanvasItem

	if has_sprite("mask"):
		var sprite = Sprite2D.new()
		sprite.texture = sprite_cache["mask"]
		sprite.centered = false
		sprite.modulate = mask.color
		add_child(sprite)
		node = sprite
	else:
		node = _create_label("M", mask.color)

	_set_node_position(node, pos)
	node.z_index = 1
	mask_nodes[key] = node

func _on_mask_picked_up(_mask: Mask, _entity: Entity) -> void:
	var player = GameState.player
	if player:
		var key = str(player.grid_position.x) + "," + str(player.grid_position.y)
		if mask_nodes.has(key):
			var node = mask_nodes[key]
			if is_instance_valid(node):
				node.queue_free()
			mask_nodes.erase(key)
