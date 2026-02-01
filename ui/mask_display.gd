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
	mask_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(mask_label)

	stats_label = Label.new()
	stats_label.text = ""
	add_child(stats_label)

	ability_label = Label.new()
	ability_label.text = ""
	ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD
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
		var count_text = ""
		if inv.get_mask_count() > 1:
			count_text = " [E]"
		mask_label.text = mask.mask_name + " (" + str(inv.equipped_index + 1) + "/" + str(inv.get_mask_count()) + ")" + count_text

		var stats = []
		if mask.attack_bonus != 0:
			stats.append("ATQ+" + str(mask.attack_bonus))
		if mask.defense_bonus != 0:
			stats.append("DEF+" + str(mask.defense_bonus))
		if mask.health_bonus != 0:
			stats.append("VDA+" + str(mask.health_bonus))
		if mask.can_phase:
			stats.append("Fase")
		stats_label.text = " ".join(stats)

		if mask.has_ability():
			ability_label.text = "[Q] " + mask.ability_name
			cooldown_label.text = "(¡Se rompe!)"
		elif mask.can_phase and mask.phase_uses > 0:
			ability_label.text = "Atravesar muros"
			cooldown_label.text = "Usos: " + str(mask.phase_uses_remaining) + "/" + str(mask.phase_uses)
		elif mask.has_reactive_effect():
			match mask.reactive_effect:
				"teleport_on_hit":
					ability_label.text = "Al recibir daño:"
					cooldown_label.text = "Teletransporte"
				"revive":
					ability_label.text = "Al morir:"
					cooldown_label.text = "Revivir con 1 VDA"
				_:
					ability_label.text = ""
					cooldown_label.text = ""
		else:
			ability_label.text = ""
			cooldown_label.text = ""
	else:
		mask_label.text = "Máscara: Ninguna"
		stats_label.text = ""
		ability_label.text = ""
		cooldown_label.text = ""

func _on_mask_equipped(_mask: Mask, _entity) -> void:
	_update()

func _on_mask_picked_up(_mask: Mask, _entity) -> void:
	_update()
