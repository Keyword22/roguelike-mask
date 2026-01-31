class_name Entity
extends Node2D

@export var display_char: String = "?"
@export var display_color: Color = Color.WHITE
@export var entity_name: String = "Entidad"

@export var max_health: int = 10
@export var health: int = 10
@export var attack: int = 1
@export var defense: int = 0

var grid_position: Vector2i = Vector2i.ZERO
var _initialized: bool = false

func _ready() -> void:
	_initialized = true
	GameState.register_entity(self)
	EventBus.entity_spawned.emit(self)

func set_grid_position(pos: Vector2i) -> void:
	var old_pos = grid_position
	grid_position = pos
	if _initialized:
		EventBus.entity_moved.emit(self, old_pos, pos)

func is_alive() -> bool:
	return health > 0

func take_damage(amount: int) -> int:
	var actual_damage = max(0, amount - defense)
	health -= actual_damage
	if health <= 0:
		health = 0
		die()
	return actual_damage

func heal(amount: int) -> int:
	var old_health = health
	health = min(health + amount, max_health)
	return health - old_health

func die() -> void:
	EventBus.entity_died.emit(self)
	GameState.unregister_entity(self)
	queue_free()

func get_action():
	return null
