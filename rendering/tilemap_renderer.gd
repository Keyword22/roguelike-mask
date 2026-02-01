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

var current_terrain_floor: int = 0
var current_terrain_wall: int = 1

const FLOOR_TERRAIN_PER_LEVEL: Array[int] = [0, 2, 4, 6, 8]
const WALL_TERRAIN_PER_LEVEL: Array[int] = [1, 3, 5, 7, 9]

var damage_font: Font

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	EventBus.entity_moved.connect(_on_entity_moved)
	EventBus.entity_spawned.connect(_on_entity_spawned)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.mask_dropped.connect(_on_mask_dropped)
	EventBus.mask_picked_up.connect(_on_mask_picked_up)
	EventBus.mask_equipped.connect(_on_mask_equipped)
	EventBus.entity_attacked.connect(_on_entity_attacked)
	EventBus.entity_healed.connect(_on_entity_healed)

	_preload_sprites()
	_preload_player_sprites()
	_load_damage_font()

func _load_damage_font() -> void:
	var font_path = "res://ui/font/Retro Gaming.ttf"
	if ResourceLoader.exists(font_path):
		damage_font = load(font_path)

func _preload_sprites() -> void:
	var paths = {
		"player": "res://sprites/player.png",
		"goblin": "res://sprites/goblin.png",
		"slime": "res://sprites/slime.png",
		"skeleton": "res://sprites/skeleton.png",
		"ghost": "res://sprites/ghost.png",
		"fairy": "res://sprites/fairy.png",
		"demon": "res://sprites/demon.png",
		"mask": "res://sprites/mask.png",
		"stairs_down": "res://sprites/stairs_down.png",
		"stairs_up": "res://sprites/stairs_up.png",
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
	_setup_terrains_for_floor(GameState.current_floor)

	if tileset_resource:
		_render_level_with_terrains()
	else:
		_render_level_with_labels()

	_create_fog_overlay()
	_update_fov()

func _setup_terrains_for_floor(floor_num: int) -> void:
	var floor_index = clampi(floor_num - 1, 0, FLOOR_TERRAIN_PER_LEVEL.size() - 1)

	var desired_floor_terrain = FLOOR_TERRAIN_PER_LEVEL[floor_index]
	var desired_wall_terrain = WALL_TERRAIN_PER_LEVEL[floor_index]

	if tileset_resource and _terrain_exists(desired_floor_terrain) and _terrain_exists(desired_wall_terrain):
		current_terrain_floor = desired_floor_terrain
		current_terrain_wall = desired_wall_terrain
	else:
		current_terrain_floor = FLOOR_TERRAIN_PER_LEVEL[0]
		current_terrain_wall = WALL_TERRAIN_PER_LEVEL[0]

func _terrain_exists(terrain_index: int) -> bool:
	if not tileset_resource:
		return false
	if tileset_resource.get_terrain_sets_count() == 0:
		return false
	return terrain_index < tileset_resource.get_terrains_count(TERRAIN_SET_ID)

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

	tile_map.set_cells_terrain_connect(floor_cells, TERRAIN_SET_ID, current_terrain_floor)
	tile_map.set_cells_terrain_connect(wall_cells, TERRAIN_SET_ID, current_terrain_wall)

	_place_stairs()

func _place_stairs() -> void:
	for y in level.height:
		for x in level.width:
			var pos = Vector2i(x, y)
			var tile = level.get_tile(pos)
			if tile == Level.TileType.STAIRS_DOWN:
				_place_stair_at(pos, "stairs_down", ">", Color(0.9, 0.9, 0.2))
			elif tile == Level.TileType.STAIRS_UP:
				_place_stair_at(pos, "stairs_up", "<", Color(0.2, 0.9, 0.9))

func _place_stair_at(pos: Vector2i, sprite_key: String, fallback_char: String, fallback_color: Color) -> void:
	if has_sprite(sprite_key):
		var sprite = Sprite2D.new()
		sprite.texture = sprite_cache[sprite_key]
		sprite.centered = false
		sprite.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
		sprite.z_index = 1
		add_child(sprite)
	else:
		var label = Label.new()
		label.text = fallback_char
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", fallback_color)
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

func refresh_fov() -> void:
	_update_fov()

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
	const PADDING = 30

	func _draw() -> void:
		if not renderer or not renderer.level:
			return
		var lvl = renderer.level

		for y in range(-PADDING, lvl.height + PADDING):
			for x in range(-PADDING, lvl.width + PADDING):
				var pos = Vector2i(x, y)
				var rect = Rect2(x * TilemapRenderer.TILE_SIZE, y * TilemapRenderer.TILE_SIZE, TilemapRenderer.TILE_SIZE, TilemapRenderer.TILE_SIZE)

				if not lvl.is_in_bounds(pos):
					draw_rect(rect, TilemapRenderer.COLOR_UNEXPLORED)
				elif not lvl.is_tile_explored(pos):
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
	if entity is Fairy:
		return "fairy"
	if entity is Demon:
		return "demon"
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

func _on_entity_attacked(_attacker: Entity, target: Entity, damage: int) -> void:
	if damage == 0:
		spawn_floating_text(target.grid_position, "MISS", Color.GRAY)
	else:
		spawn_floating_text(target.grid_position, str(damage), Color.RED)

func _on_entity_healed(entity: Entity, amount: int) -> void:
	spawn_floating_text(entity.grid_position, "+" + str(amount), Color.LIME_GREEN)

func spawn_floating_text(grid_pos: Vector2i, text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	if damage_font:
		label.add_theme_font_override("font", damage_font)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100

	var start_pos = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE / 2, grid_pos.y * TILE_SIZE)
	label.position = start_pos - Vector2(label.size.x / 2, 0)
	label.pivot_offset = label.size / 2

	add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", start_pos.y - 30, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
