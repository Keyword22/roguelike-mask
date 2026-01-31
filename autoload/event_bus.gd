extends Node

signal entity_moved(entity, from_pos, to_pos)
signal entity_attacked(attacker, target, damage)
signal entity_healed(entity, amount)
signal entity_died(entity)
signal entity_spawned(entity)

signal mask_dropped(mask, position)
signal mask_picked_up(mask, entity)
signal mask_equipped(mask, entity)
signal mask_ability_used(mask, entity)

signal level_generated(level)
signal floor_changed(floor_number)
signal stairs_entered(entity, direction)

signal turn_started(phase)
signal turn_ended()
signal player_turn_started()
signal enemy_turn_started()

signal message_logged(text, color)
signal ui_update_requested()

signal game_over(victory)
