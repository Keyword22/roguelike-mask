extends Node

enum Phase { PLAYER_INPUT, PLAYER_ACTION, ENEMY_TURN, WORLD_UPDATE }

var current_phase: Phase = Phase.PLAYER_INPUT
var is_processing: bool = false

func _ready() -> void:
	pass

func is_player_turn() -> bool:
	return current_phase == Phase.PLAYER_INPUT

func execute_player_action(action) -> void:
	if is_processing:
		return

	is_processing = true
	current_phase = Phase.PLAYER_ACTION
	EventBus.turn_started.emit(current_phase)

	action.execute()

	await get_tree().create_timer(0.05).timeout

	await _process_enemy_turn()
	await _process_world_update()

	current_phase = Phase.PLAYER_INPUT
	is_processing = false
	EventBus.turn_ended.emit()
	EventBus.player_turn_started.emit()

func _process_enemy_turn() -> void:
	current_phase = Phase.ENEMY_TURN
	EventBus.enemy_turn_started.emit()

	var enemies = GameState.get_enemies()
	for enemy in enemies:
		if enemy.is_alive():
			var action = enemy.get_action()
			if action:
				action.execute()
				await get_tree().create_timer(0.02).timeout

func _process_world_update() -> void:
	current_phase = Phase.WORLD_UPDATE
	EventBus.ui_update_requested.emit()
