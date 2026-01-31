class_name TilemapRenderer
extends Node2D

const TILE_SIZE: int = 32
const FONT_SIZE: int = 16

@export var tileset_resource: TileSet

var level: Level
var tile_map: TileMapLayer
var entity_nodes: Dictionary = {}
var mask_nodes: Dictionary = {}

var sprite_cache: Dictionary = {}
var player_sprite_cache: Dictionary = {}
var player_node: AnimatedSprite2D = null
var fog_overlay: Node2D = null

const COLOR_UNEXPLORED = Color(0, 0, 0, 1)
const COLOR_EXPLORED = Color(0.1, 0.08, 0.05, 0.7)
const FOV_RADIUS = 8

const TERRAIN_SET_ID: int = 0
const TERRAIN_FLOOR: int = 0
const TERRAIN_WALL: int = 1

func _ready() -> void:
	EventBus.entity_moved.connect(_on_entity_moved)
	EventBus.entity_spawned.connect(_on_entity_spawned)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.mask_dropped.connect(_on_mask_dropped)
	EventBus.mask_picked_up.connect(_on_mask_picked_up)
	EventBus.mask_equipped.connect(_on_mask_equipped)

	_preload_sprites()
	_preload_player_sprites()

func _preload_sprites() -> void:
	var paths = {
		"player": "res://sprites/player.png",
		"goblin": "res://sprites/goblin.png",
		"slime": "res://sprites/slime.png",
		"skeleton": "res://sprites/skeleton.png",
		"ghost": "res://sprites/ghost.png",
		"mask": "res://sprites/mask.png",
	}

	for key in paths:
		if ResourceLoader.exists(paths[key]):
			sprite_cache[key] = load(paths[key])

func has_sprite(key: String) -> bool:
	return sprite_cache.has(key)

func _preload_player_sprites() -> void:
	var base_path = "res://sprites/player/base.png"
	var fallback_path = "res://sprites/player/fallback.png"

	if ResourceLoader.exists(base_path):
		player_sprite_cache["base"] = load(base_path)
	if ResourceLoader.exists(fallback_path):
		player_sprite_cache["fallback"] = load(fallback_path)

func _get_player_texture(sprite_id: String) -> Texture2D:
	if player_sprite_cache.has(sprite_id):
		return player_sprite_cache[sprite_id]

	var path = "res://sprites/player/" + sprite_id + ".png"
	if ResourceLoader.exists(path):
		player_sprite_cache[sprite_id] = load(path)
		return player_sprite_cache[sprite_id]

	if player_sprite_cache.has("fallback"):
		return player_sprite_cache["fallback"]

	return player_sprite_cache.get("base", null)

func _create_player_sprite_frames(texture: Texture2D) -> SpriteFrames:
	var frames = SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 1)
	var idle_atlas = AtlasTexture.new()
	idle_atlas.atlas = texture
	idle_atlas.region = Rect2(0, 0, TILE_SIZE, TILE_SIZE)
	frames.add_frame("idle", idle_atlas)

	var frame_count = texture.get_width() / TILE_SIZE

	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 4)
	for i in frame_count:
		var walk_atlas = AtlasTexture.new()
		walk_atlas.atlas = texture
		walk_atlas.region = Rect2(i * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE)
		frames.add_frame("walk", walk_atlas)

	if frames.has_animation("default"):
		frames.remove_animation("default")

	return frames

func render_level(lvl: Level) -> void:
	level = lvl
	_clear_all()

	if tileset_resource:
		_render_level_with_terrains()
	else:
		_render_level_with_labels()

	_create_fog_overlay()
	_update_fov()

func _clear_all() -> void:
	for child in get_children():
		child.queue_free()

	tile_map = null
	fog_overlay = null
	player_node = null
	mask_nodes.clear()
	entity_nodes.clear()

func _render_level_with_terrains() -> void:
	tile_map = TileMapLayer.new()
	tile_map.tile_set = tileset_resource
	add_child(tile_map)

	var floor_cells: Array[Vector2i] = []
	var wall_cells: Array[Vector2i] = []

	for y in level.height:
		for x in level.width:
			var pos = Vector2i(x, y)
			var tile = level.get_tile(pos)
			if tile == Level.TileType.WALL:
				wall_cells.append(pos)
			else:
				floor_cells.append(pos)

	tile_map.set_cells_terrain_connect(floor_cells, TERRAIN_SET_ID, TERRAIN_FLOOR)
	tile_map.set_cells_terrain_connect(wall_cells, TERRAIN_SET_ID, TERRAIN_WALL)

	_place_stairs()

var stairs_down_atlas: Vector2i = Vector2i(-1, -1)
var stairs_up_atlas: Vector2i = Vector2i(-1, -1)

func _place_stairs() -> void:
	if stairs_down_atlas == Vector2i(-1, -1) and stairs_up_atlas == Vector2i(-1, -1):
		_place_stairs_as_labels()
		return

	for y in level.height:
		for x in level.width:
			var pos = Vector2i(x, y)
			var tile = level.get_tile(pos)
			if tile == Level.TileType.STAIRS_DOWN and stairs_down_atlas != Vector2i(-1, -1):
				tile_map.set_cell(pos, 0, stairs_down_atlas)
			elif tile == Level.TileType.STAIRS_UP and stairs_up_atlas != Vector2i(-1, -1):
				tile_map.set_cell(pos, 0, stairs_up_atlas)

func _place_stairs_as_labels() -> void:
	for y in level.height:
		for x in level.width:
			var pos = Vector2i(x, y)
			var tile = level.get_tile(pos)
			if tile == Level.TileType.STAIRS_DOWN:
				var label = Label.new()
				label.text = ">"
				label.add_theme_font_size_override("font_size", FONT_SIZE)
				label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.2))
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
				label.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
				label.z_index = 1
				add_child(label)
			elif tile == Level.TileType.STAIRS_UP:
				var label = Label.new()
				label.text = "<"
				label.add_theme_font_size_override("font_size", FONT_SIZE)
				label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9))
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
				label.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
				label.z_index = 1
				add_child(label)

func _render_level_with_labels() -> void:
	tile_map = TileMapLayer.new()
	add_child(tile_map)

	for y in level.height:
		for x in level.width:
			var pos = Vector2i(x, y)
			var tile = level.get_tile(pos)
			_create_tile_label(pos, tile)

func _create_tile_label(pos: Vector2i, tile: int) -> void:
	var label = Label.new()
	label.text = _get_tile_char(tile)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", _get_tile_color(tile))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	label.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
	add_child(label)

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

func _create_fog_overlay() -> void:
	fog_overlay = FogOverlay.new()
	fog_overlay.renderer = self
	fog_overlay.z_index = 10
	add_child(fog_overlay)

func _update_fov() -> void:
	if not level or not GameState.player:
		return
	level.compute_fov(GameState.player.grid_position, FOV_RADIUS)
	_update_entity_visibility()
	if fog_overlay:
		fog_overlay.queue_redraw()

func _update_entity_visibility() -> void:
	for entity in entity_nodes:
		var node = entity_nodes[entity]
		if entity is Player:
			continue
		node.visible = level.is_tile_visible(entity.grid_position)

	for key in mask_nodes:
		var parts = key.split(",")
		var pos = Vector2i(int(parts[0]), int(parts[1]))
		mask_nodes[key].visible = level.is_tile_visible(pos)

class FogOverlay extends Node2D:
	var renderer: TilemapRenderer

	func _draw() -> void:
		if not renderer or not renderer.level:
			return
		var lvl = renderer.level
		for y in lvl.height:
			for x in lvl.width:
				var pos = Vector2i(x, y)
				var rect = Rect2(x * TilemapRenderer.TILE_SIZE, y * TilemapRenderer.TILE_SIZE, TilemapRenderer.TILE_SIZE, TilemapRenderer.TILE_SIZE)
				if not lvl.is_tile_explored(pos):
					draw_rect(rect, TilemapRenderer.COLOR_UNEXPLORED)
				elif not lvl.is_tile_visible(pos):
					draw_rect(rect, TilemapRenderer.COLOR_EXPLORED)

func render_entity(entity: Entity) -> void:
	if entity_nodes.has(entity):
		return

	var node: CanvasItem

	if entity is Player:
		node = _create_player_animated_sprite(entity)
		player_node = node as AnimatedSprite2D
	else:
		var sprite_key = _get_entity_sprite_key(entity)
		if has_sprite(sprite_key):
			node = _create_sprite(sprite_key)
		else:
			node = _create_entity_label(entity)

	_set_node_position(node, entity.grid_position)
	node.z_index = 1
	entity_nodes[entity] = node

func _create_player_animated_sprite(player: Player) -> AnimatedSprite2D:
	var sprite_id = "base"
	if player.mask_inventory.equipped_mask and player.mask_inventory.equipped_mask.sprite_id != "":
		sprite_id = player.mask_inventory.equipped_mask.sprite_id

	var texture = _get_player_texture(sprite_id)
	if texture == null:
		var label = _create_entity_label(player)
		return null

	var anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = _create_player_sprite_frames(texture)
	anim_sprite.centered = false
	anim_sprite.play("idle")
	add_child(anim_sprite)
	return anim_sprite

func _update_player_sprite(player: Player) -> void:
	if player_node == null:
		return

	var sprite_id = "base"
	if player.mask_inventory.equipped_mask and player.mask_inventory.equipped_mask.sprite_id != "":
		sprite_id = player.mask_inventory.equipped_mask.sprite_id

	var texture = _get_player_texture(sprite_id)
	if texture:
		player_node.sprite_frames = _create_player_sprite_frames(texture)
		player_node.play("idle")

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

func _create_sprite(key: String) -> Sprite2D:
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

	var label = Label.new()
	label.text = char
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	add_child(label)
	return label

func _set_node_position(node: CanvasItem, grid_pos: Vector2i) -> void:
	var pixel_pos = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	if node is Control:
		(node as Control).position = pixel_pos
	else:
		(node as Node2D).position = pixel_pos

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
		if entity is Player:
			player_node = null

func _on_entity_spawned(entity: Entity) -> void:
	render_entity(entity)
	if entity is Player:
		_update_fov()
	elif level and not level.is_tile_visible(entity.grid_position):
		entity_nodes[entity].visible = false

func _on_entity_moved(entity: Entity, from: Vector2i, to: Vector2i) -> void:
	if entity is Player and player_node:
		_tween_player_move(from, to)
		_update_fov()
	else:
		update_entity_position(entity)

var player_tween: Tween

func _tween_player_move(from: Vector2i, to: Vector2i) -> void:
	var from_pos = Vector2(from.x * TILE_SIZE, from.y * TILE_SIZE)
	var to_pos = Vector2(to.x * TILE_SIZE, to.y * TILE_SIZE)

	if player_tween and player_tween.is_valid():
		player_tween.kill()

	player_node.position = from_pos
	player_node.play("walk")

	player_tween = create_tween()
	player_tween.tween_property(player_node, "position", to_pos, 0.5).set_trans(Tween.TRANS_LINEAR)
	player_tween.tween_callback(func():
		if player_node and is_instance_valid(player_node):
			player_node.play("idle")
	)

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
		var label = Label.new()
		label.text = "M"
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", mask.color)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		add_child(label)
		node = label

	_set_node_position(node, pos)
	node.z_index = 1
	mask_nodes[key] = node

func _on_mask_picked_up(_mask: Mask, _entity: Entity) -> void:
	var p = GameState.player
	if p:
		var key = str(p.grid_position.x) + "," + str(p.grid_position.y)
		if mask_nodes.has(key):
			var node = mask_nodes[key]
			if is_instance_valid(node):
				node.queue_free()
			mask_nodes.erase(key)

func _on_mask_equipped(mask: Mask, entity: Entity) -> void:
	if entity is Player:
		_update_player_sprite(entity as Player)
