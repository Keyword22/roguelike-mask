class_name MaskInventory
extends Node

const MAX_MASKS: int = 4

var masks: Array[Mask] = []
var equipped_mask: Mask = null
var equipped_index: int = -1

func add_mask(mask: Mask) -> bool:
	if has_mask_of_type(mask.mask_name):
		return false
	if masks.size() >= MAX_MASKS:
		return false
	masks.append(mask)
	if equipped_mask == null:
		equip_mask(masks.size() - 1)
	return true

func has_mask_of_type(mask_name: String) -> bool:
	for m in masks:
		if m.mask_name == mask_name:
			return true
	return false

func remove_mask(index: int) -> Mask:
	if index < 0 or index >= masks.size():
		return null
	var mask = masks[index]
	masks.remove_at(index)
	if equipped_index == index:
		equipped_mask = null
		equipped_index = -1
		if masks.size() > 0:
			equip_mask(0)
		else:
			EventBus.mask_equipped.emit(null, get_parent())
	elif equipped_index > index:
		equipped_index -= 1
	_update_player_stats()
	return mask

func equip_mask(index: int) -> void:
	if index < 0 or index >= masks.size():
		return
	equipped_index = index
	equipped_mask = masks[index]
	_update_player_stats()
	EventBus.mask_equipped.emit(equipped_mask, get_parent())

func cycle_mask() -> void:
	if masks.size() == 0:
		return
	var new_index = (equipped_index + 1) % masks.size()
	equip_mask(new_index)

func get_mask_count() -> int:
	return masks.size()

func has_masks() -> bool:
	return masks.size() > 0

func _update_player_stats() -> void:
	var player = get_parent()
	if player and player is Player:
		player.recalculate_stats()

func tick_all_cooldowns() -> void:
	for mask in masks:
		mask.tick_cooldown()
