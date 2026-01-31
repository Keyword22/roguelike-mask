class_name MaskDisplay
extends VBoxContainer

var mask_label: Label
var ability_label: Label
var stats_label: Label
var cooldown_label: Label

func _ready() -> void:
	_setup_ui()
	EventBus.mask_equipped.connect(_on_mask_equipped)
	EventBus.mask_picked_up.connect(_on_mask_picked_up)
	EventBus.ui_update_requested.connect(_update)

func _setup_ui() -> void:
	mask_label = Label.new()
	mask_label.text = "Mask: None"
	add_child(mask_label)

	stats_label = Label.new()
	stats_label.text = ""
	add_child(stats_label)

	ability_label = Label.new()
	ability_label.text = ""
	add_child(ability_label)

	cooldown_label = Label.new()
	cooldown_label.text = ""
	add_child(cooldown_label)

func _update() -> void:
	var player = GameState.player
	if not player or not player.mask_inventory:
		return

	var inv = player.mask_inventory
	if inv.equipped_mask:
		var mask = inv.equipped_mask
		mask_label.text = "Mask: " + mask.mask_name + " (" + str(inv.equipped_index + 1) + "/" + str(inv.get_mask_count()) + ")"

		var stats = []
		if mask.attack_bonus != 0:
			stats.append("ATK+" + str(mask.attack_bonus))
		if mask.defense_bonus != 0:
			stats.append("DEF+" + str(mask.defense_bonus))
		if mask.health_bonus != 0:
			stats.append("HP+" + str(mask.health_bonus))
		if mask.can_phase:
			stats.append("Phase")
		stats_label.text = " ".join(stats)

		if mask.has_ability():
			ability_label.text = "Ability: " + mask.ability_name + " [Q]"
			if mask.current_cooldown > 0:
				cooldown_label.text = "Cooldown: " + str(mask.current_cooldown)
			else:
				cooldown_label.text = "Ready!"
		else:
			ability_label.text = ""
			cooldown_label.text = ""
	else:
		mask_label.text = "Mask: None (collect from enemies)"
		stats_label.text = ""
		ability_label.text = ""
		cooldown_label.text = ""

func _on_mask_equipped(_mask: Mask, _entity) -> void:
	_update()

func _on_mask_picked_up(_mask: Mask, _entity) -> void:
	_update()
