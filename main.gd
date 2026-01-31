extends Node2D

var renderer: TilemapRenderer
var game_ui: GameUI
var main_menu: MainMenu
var pause_menu: PauseMenu
var game_over_screen: GameOverScreen
var camera: Camera2D

var player: Player
var current_level: Level

var move_repeat_timer: float = 0.0
const MOVE_REPEAT_DELAY: float = 0.15
const MOVE_INITIAL_DELAY: float = 0.25
var move_held_time: float = 0.0

const ENEMY_TYPES = [
	preload("res://enemies/goblin.gd"),
	preload("res://enemies/slime.gd"),
	preload("res://enemies/skeleton.gd"),
	preload("res://enemies/ghost.gd")
]

func _ready() -> void:
	_setup_camera()
	_setup_renderer()
	_setup_ui()
	_connect_signals()
	_show_main_menu()

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2(2, 2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

func _setup_renderer() -> void:
	renderer = TilemapRenderer.new()
	renderer.tileset_resource = load("res://tilesets/dungeon.tres")
	add_child(renderer)

func _setup_ui() -> void:
	game_ui = GameUI.new()
	game_ui.visible = false
	add_child(game_ui)

	main_menu = MainMenu.new()
	main_menu.start_game.connect(_on_start_game)
	main_menu.quit_game.connect(_on_quit_game)
	add_child(main_menu)

	pause_menu = PauseMenu.new()
	pause_menu.resume_game.connect(_on_resume_game)
	pause_menu.quit_to_menu.connect(_on_quit_to_menu)
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu)

	game_over_screen = GameOverScreen.new()
	game_over_screen.restart_game.connect(_on_restart_game)
	game_over_screen.quit_to_menu.connect(_on_quit_to_menu)
	add_child(game_over_screen)

func _connect_signals() -> void:
	EventBus.game_over.connect(_on_game_over)
	EventBus.floor_changed.connect(_on_floor_changed)
	EventBus.stairs_entered.connect(_on_stairs_entered)
	EventBus.entity_moved.connect(_on_entity_moved)

func _show_main_menu() -> void:
	main_menu.visible = true
	game_ui.visible = false
	GameState.current_state = GameState.State.MENU

func _on_start_game() -> void:
	main_menu.visible = false
	game_ui.visible = true
	_start_new_game()

func _on_quit_game() -> void:
	get_tree().quit()

func _on_resume_game() -> void:
	GameState.current_state = GameState.State.PLAYING

func _on_quit_to_menu() -> void:
	_cleanup_game()
	_show_main_menu()

func _on_restart_game() -> void:
	_cleanup_game()
	_start_new_game()

func _on_game_over(victory: bool) -> void:
	game_over_screen.show_game_over(victory)

func _on_floor_changed(_floor_num: int) -> void:
	_generate_new_floor()

func _on_stairs_entered(_entity, direction: String) -> void:
	if direction == "down":
		GameState.next_floor()

func _on_entity_moved(entity, _from, _to) -> void:
	if entity is Player:
		_update_camera()

func _start_new_game() -> void:
	GameState.start_game()
	_generate_new_floor()
	EventBus.message_logged.emit("¡Bienvenido a la mazmorra! Encuentra las escaleras (>) para descender.", Color.CYAN)
	EventBus.message_logged.emit("¡Derrota enemigos para obtener sus máscaras!", Color.CYAN)

func _cleanup_game() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null
		GameState.current_level = null

	for entity in GameState.entities.duplicate():
		if is_instance_valid(entity):
			entity.queue_free()

	player = null
	renderer._clear_all()
	GameState.reset()

func _generate_new_floor() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null
		GameState.current_level = null

	for entity in GameState.entities.duplicate():
		if is_instance_valid(entity) and entity != player:
			entity.queue_free()

	GameState.entities.clear()

	var generator = LevelGenerator.new()
	current_level = generator.generate(60, 30)
	add_child(current_level)

	renderer.render_level(current_level)

	_spawn_player(generator.get_player_spawn_position())
	_spawn_enemies()
	_update_camera()

	EventBus.level_generated.emit(current_level)

func _spawn_player(pos: Vector2i) -> void:
	if player and is_instance_valid(player):
		player.grid_position = pos
		GameState.register_entity(player)
		renderer.render_entity(player)
		renderer.update_entity_position(player)
	else:
		player = Player.new()
		player.grid_position = pos
		add_child(player)

func _spawn_enemies() -> void:
	var floor_num = GameState.current_floor
	var enemy_count = 5 + floor_num * 2

	var available_types = []
	available_types.append(ENEMY_TYPES[0])
	available_types.append(ENEMY_TYPES[1])
	if floor_num >= 2:
		available_types.append(ENEMY_TYPES[2])
	if floor_num >= 3:
		available_types.append(ENEMY_TYPES[3])

	for room_idx in range(1, current_level.rooms.size()):
		if room_idx >= enemy_count:
			break
		var room = current_level.rooms[room_idx]
		var pos = current_level.get_spawn_position_in_room(room)
		if pos != Vector2i(-1, -1):
			var enemy_type = available_types[randi() % available_types.size()]
			var enemy = enemy_type.new()
			enemy.grid_position = pos
			add_child(enemy)

func _update_camera() -> void:
	if player:
		camera.position = Vector2(
			player.grid_position.x * AsciiRenderer.TILE_SIZE,
			player.grid_position.y * AsciiRenderer.TILE_SIZE
		)

func _process(delta: float) -> void:
	if GameState.current_state != GameState.State.PLAYING:
		return
	if pause_menu.visible:
		return
	if not TurnManager.is_player_turn():
		return

	var direction = _get_held_move_direction()
	if direction != Vector2i.ZERO:
		move_held_time += delta
		move_repeat_timer -= delta

		if move_repeat_timer <= 0:
			var delay = MOVE_INITIAL_DELAY if move_held_time < MOVE_INITIAL_DELAY else MOVE_REPEAT_DELAY
			move_repeat_timer = delay
			var action = MoveAction.new(player, direction)
			TurnManager.execute_player_action(action)
	else:
		move_held_time = 0.0
		move_repeat_timer = 0.0

func _get_held_move_direction() -> Vector2i:
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		return Vector2i(0, -1)
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		return Vector2i(0, 1)
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if GameState.current_state != GameState.State.PLAYING:
		return

	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			pause_menu.hide_pause()
		else:
			pause_menu.show_pause()
			GameState.current_state = GameState.State.PAUSED
		return

	if pause_menu.visible:
		return

	if not TurnManager.is_player_turn():
		return

	if event.is_action_pressed("wait"):
		var action = WaitAction.new(player)
		TurnManager.execute_player_action(action)
	elif event.is_action_pressed("cycle_mask"):
		player.mask_inventory.cycle_mask()
		EventBus.ui_update_requested.emit()
	elif event.is_action_pressed("use_ability"):
		_use_mask_ability()

func _use_mask_ability() -> void:
	if not player.mask_inventory.equipped_mask:
		EventBus.message_logged.emit("¡No tienes máscara equipada!", Color.GRAY)
		return

	var mask = player.mask_inventory.equipped_mask
	if not mask.has_ability():
		EventBus.message_logged.emit("Esta máscara no tiene habilidad activa.", Color.GRAY)
		return

	if not mask.can_use_ability():
		EventBus.message_logged.emit("Habilidad en enfriamiento: " + str(mask.current_cooldown) + " turnos.", Color.GRAY)
		return

	match mask.ability_name:
		"Embestida":
			_ability_rush()
		"División":
			_ability_split()
		"Lanzar Hueso":
			_ability_bone_throw()
		"Fase":
			EventBus.message_logged.emit("¡Fase es pasiva - atraviesa muros!", Color.CYAN)
			return

	EventBus.mask_ability_used.emit(mask, player)
	_break_equipped_mask()
	TurnManager.execute_player_action(WaitAction.new(player))

func _ability_rush() -> void:
	var enemies = GameState.get_enemies()
	var closest_enemy = null
	var closest_dist = 999

	for enemy in enemies:
		var dist = abs(enemy.grid_position.x - player.grid_position.x) + abs(enemy.grid_position.y - player.grid_position.y)
		if dist < closest_dist and dist <= 5:
			closest_dist = dist
			closest_enemy = enemy

	if closest_enemy:
		var dir = closest_enemy.grid_position - player.grid_position
		var move_dir = Vector2i(sign(dir.x), sign(dir.y))
		if abs(dir.x) > abs(dir.y):
			move_dir.y = 0
		else:
			move_dir.x = 0

		for i in range(closest_dist - 1):
			var new_pos = player.grid_position + move_dir
			if current_level.is_walkable(new_pos) and GameState.get_entity_at(new_pos) == null:
				player.set_grid_position(new_pos)
			else:
				break

		EventBus.message_logged.emit("¡Embestida hacia " + closest_enemy.entity_name + "!", Color.GREEN)
	else:
		EventBus.message_logged.emit("¡No hay enemigo cercano para embestir!", Color.GRAY)

func _ability_split() -> void:
	var heal_amount = player.heal(player.max_health / 4)
	EventBus.message_logged.emit("¡Regeneración de limo cura " + str(heal_amount) + " VDA!", Color.LIME_GREEN)

func _ability_bone_throw() -> void:
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var hit_enemy = null

	for dir in directions:
		for dist in range(1, 6):
			var check_pos = player.grid_position + dir * dist
			if not current_level.is_walkable(check_pos):
				break
			var entity = GameState.get_entity_at(check_pos)
			if entity and entity != player:
				hit_enemy = entity
				break
		if hit_enemy:
			break

	if hit_enemy:
		var damage = player.get_total_attack()
		var actual_damage = hit_enemy.take_damage(damage)
		EventBus.entity_attacked.emit(player, hit_enemy, actual_damage)
		EventBus.message_logged.emit("¡Lanzar hueso golpea a " + hit_enemy.entity_name + " por " + str(actual_damage) + "!", Color.WHITE)
	else:
		renderer.spawn_floating_text(player.grid_position, "MISS", Color.GRAY)
		AudioManager.play_sfx_by_name("miss")
		EventBus.message_logged.emit("¡Lanzar hueso falla!", Color.GRAY)

func _break_equipped_mask() -> void:
	var mask_name = player.mask_inventory.equipped_mask.mask_name
	player.mask_inventory.remove_mask(player.mask_inventory.equipped_index)
	EventBus.message_logged.emit("¡La máscara de " + mask_name + " se rompe!", Color.ORANGE)
	EventBus.ui_update_requested.emit()
