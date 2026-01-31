extends Node

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: State = State.MENU
var current_floor: int = 1
var max_floors: int = 5

var player: Node = null
var current_level: Node = null
var entities: Array = []

func _ready() -> void:
	pass

func start_game() -> void:
	current_state = State.PLAYING
	current_floor = 1
	entities.clear()

func set_player(p: Node) -> void:
	player = p

func set_level(level: Node) -> void:
	current_level = level

func register_entity(entity: Node) -> void:
	if entity not in entities:
		entities.append(entity)

func unregister_entity(entity: Node) -> void:
	entities.erase(entity)

func get_entity_at(pos: Vector2i) -> Node:
	for entity in entities:
		if entity.grid_position == pos:
			return entity
	return null

func get_enemies() -> Array:
	var enemies: Array = []
	for entity in entities:
		if entity != player and entity.is_alive():
			enemies.append(entity)
	return enemies

func next_floor() -> void:
	current_floor += 1
	if current_floor > max_floors:
		EventBus.game_over.emit(true)
	else:
		EventBus.floor_changed.emit(current_floor)

func game_over(victory: bool) -> void:
	current_state = State.GAME_OVER
	EventBus.game_over.emit(victory)

func reset() -> void:
	current_state = State.MENU
	current_floor = 1
	player = null
	current_level = null
	entities.clear()
