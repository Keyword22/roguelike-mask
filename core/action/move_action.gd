class_name MoveAction
extends Action

var direction: Vector2i

func _init(e: Entity, dir: Vector2i) -> void:
	super._init(e)
	direction = dir

func execute() -> bool:
	if not is_valid():
		return false

	var new_pos = entity.grid_position + direction
	var level = GameState.current_level

	if not level:
		return false

	var target = GameState.get_entity_at(new_pos)
	if target and target != entity:
		var attack_action = AttackAction.new(entity, target)
		return attack_action.execute()

	var can_move = level.is_walkable(new_pos)

	if not can_move and entity is Player:
		if entity.can_phase_through_walls():
			can_move = level.is_in_bounds(new_pos)

	if can_move:
		entity.set_grid_position(new_pos)
		_check_stairs(new_pos)
		_check_mask_pickup(new_pos)
		return true

	return false

func _check_stairs(pos: Vector2i) -> void:
	var level = GameState.current_level
	if level and entity is Player:
		if level.is_stairs_down(pos):
			EventBus.stairs_entered.emit(entity, "down")

func _check_mask_pickup(pos: Vector2i) -> void:
	if entity is Player:
		var level = GameState.current_level
		if level and level.has_mask_at(pos):
			var mask = level.pickup_mask_at(pos)
			if mask:
				entity.mask_inventory.add_mask(mask)
				EventBus.mask_picked_up.emit(mask, entity)
				EventBus.message_logged.emit("Picked up " + mask.mask_name + " mask!", Color.GREEN)
