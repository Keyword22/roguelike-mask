class_name Slime
extends Enemy

var is_mini: bool = false

func _ready() -> void:
	display_char = "s"
	display_color = Color.LIME_GREEN
	entity_name = "Slime"

	if is_mini:
		max_health = 4
		attack = 1
		display_color = Color.GREEN
		entity_name = "Mini Slime"
		mask_drop = null
	else:
		max_health = 12
		attack = 2
		var slime_mask = Mask.new()
		slime_mask.mask_name = "Slime"
		slime_mask.display_char = "s"
		slime_mask.color = Color.LIME_GREEN
		slime_mask.health_bonus = 5
		slime_mask.ability_name = "Curación"
		slime_mask.sprite_id = "slime"
		mask_drop = slime_mask

	health = max_health
	defense = 0

	super._ready()

func die() -> void:
	if not is_mini:
		_split()
	super.die()

func _split() -> void:
	var level = GameState.current_level
	var spawn_positions: Array[Vector2i] = []
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for dir in directions:
		var pos = grid_position + dir
		if level.is_walkable(pos) and GameState.get_entity_at(pos) == null:
			spawn_positions.append(pos)
		if spawn_positions.size() >= 2:
			break

	for pos in spawn_positions:
		var mini = Slime.new()
		mini.is_mini = true
		mini.grid_position = pos
		get_parent().add_child(mini)

	if spawn_positions.size() > 0:
		EventBus.message_logged.emit("¡El Slime se divide en " + str(spawn_positions.size()) + " Mini Slimes!", Color.LIME_GREEN)
