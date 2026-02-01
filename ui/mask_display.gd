class_name MaskDisplay
extends VBoxContainer

const MAX_SLOTS = 4
const SLOT_SIZE = 48

var slots_container: HBoxContainer
var slot_backgrounds: Array[TextureRect] = []
var slot_icons: Array[Control] = []
var slot_highlights: Array[TextureRect] = []

var mask_name_label: Label
var stats_label: Label
var ability_label: Label
var effect_label: Label

var slot_texture: Texture2D
var highlight_texture: Texture2D
var sprite_cache: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_load_textures()
	_setup_ui()
	EventBus.mask_equipped.connect(_on_mask_equipped)
	EventBus.mask_picked_up.connect(_on_mask_picked_up)
	EventBus.ui_update_requested.connect(_update)

func _load_textures() -> void:
	if ResourceLoader.exists("res://ui/mask_slot.png"):
		slot_texture = load("res://ui/mask_slot.png")
	if ResourceLoader.exists("res://ui/mask_slot_highlight.png"):
		highlight_texture = load("res://ui/mask_slot_highlight.png")

	# Load mask sprites (same as enemy sprites)
	var mask_sprites = {
		"Goblin": "res://sprites/goblin.png",
		"Slime": "res://sprites/slime.png",
		"Esqueleto": "res://sprites/skeleton.png",
		"Fantasma": "res://sprites/ghost.png",
		"Hada": "res://sprites/fairy.png",
		"Demonio": "res://sprites/demon.png",
	}
	for key in mask_sprites:
		if ResourceLoader.exists(mask_sprites[key]):
			sprite_cache[key] = load(mask_sprites[key])

func _setup_ui() -> void:
	# Title
	var title = Label.new()
	title.text = "Máscaras [E]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Slots row
	slots_container = HBoxContainer.new()
	slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_container.add_theme_constant_override("separation", 4)
	add_child(slots_container)

	for i in range(MAX_SLOTS):
		var slot = _create_slot(i)
		slots_container.add_child(slot)

	# Separator
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 8)
	add_child(separator)

	# Mask name
	mask_name_label = Label.new()
	mask_name_label.text = "Ninguna"
	mask_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mask_name_label)

	# Stats
	stats_label = Label.new()
	stats_label.text = ""
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	add_child(stats_label)

	# Ability
	ability_label = Label.new()
	ability_label.text = ""
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(ability_label)

	# Effect/cooldown
	effect_label = Label.new()
	effect_label.text = ""
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	add_child(effect_label)

func _create_slot(index: int) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)

	# Slot background
	var bg = TextureRect.new()
	if slot_texture:
		bg.texture = slot_texture
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	bg.position = Vector2(0, 0)
	container.add_child(bg)
	slot_backgrounds.append(bg)

	# Mask icon (will be set dynamically)
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	icon_container.position = Vector2(0, 0)
	container.add_child(icon_container)
	slot_icons.append(icon_container)

	# Highlight overlay
	var highlight = TextureRect.new()
	if highlight_texture:
		highlight.texture = highlight_texture
	highlight.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	highlight.custom_minimum_size = Vector2(SLOT_SIZE + 4, SLOT_SIZE + 4)
	highlight.position = Vector2(-2, -2)
	highlight.visible = false
	container.add_child(highlight)
	slot_highlights.append(highlight)

	return container

func _update() -> void:
	var player = GameState.player
	if not player or not player.mask_inventory:
		_clear_display()
		return

	var inv = player.mask_inventory

	# Update slots
	for i in range(MAX_SLOTS):
		_update_slot(i, inv)

	# Update description for equipped mask
	if inv.equipped_mask:
		var mask = inv.equipped_mask
		mask_name_label.text = mask.mask_name

		var stats = []
		if mask.attack_bonus != 0:
			stats.append("ATQ+" + str(mask.attack_bonus))
		if mask.defense_bonus != 0:
			stats.append("DEF+" + str(mask.defense_bonus))
		if mask.health_bonus != 0:
			stats.append("VDA+" + str(mask.health_bonus))
		stats_label.text = " ".join(stats) if stats.size() > 0 else ""

		if mask.has_ability():
			ability_label.text = "[Q] " + mask.ability_name
			effect_label.text = "(¡Se rompe!)"
		elif mask.can_phase and mask.phase_uses > 0:
			ability_label.text = "Atravesar muros"
			effect_label.text = "Usos: " + str(mask.phase_uses_remaining) + "/" + str(mask.phase_uses)
		elif mask.has_reactive_effect():
			match mask.reactive_effect:
				"teleport_on_hit":
					ability_label.text = "Al recibir daño:"
					effect_label.text = "Teletransporte"
				"revive":
					ability_label.text = "Al morir:"
					effect_label.text = "Revivir con 1 VDA"
				_:
					ability_label.text = ""
					effect_label.text = ""
		else:
			ability_label.text = ""
			effect_label.text = ""
	else:
		_clear_description()

func _update_slot(index: int, inv: MaskInventory) -> void:
	var icon_container = slot_icons[index]
	var highlight = slot_highlights[index]

	# Clear previous icon
	for child in icon_container.get_children():
		child.queue_free()

	if index < inv.masks.size():
		var mask = inv.masks[index]

		# Add mask icon
		if sprite_cache.has(mask.mask_name):
			var sprite = TextureRect.new()
			sprite.texture = sprite_cache[mask.mask_name]
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.custom_minimum_size = Vector2(SLOT_SIZE - 4, SLOT_SIZE - 4)
			sprite.position = Vector2(2, 2)
			icon_container.add_child(sprite)
		else:
			# ASCII fallback
			var label = Label.new()
			label.text = mask.display_char
			label.add_theme_color_override("font_color", mask.color)
			label.add_theme_font_size_override("font_size", 18)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
			icon_container.add_child(label)

		# Show highlight if equipped
		highlight.visible = (index == inv.equipped_index)
	else:
		# Empty slot
		highlight.visible = false

func _clear_display() -> void:
	for i in range(MAX_SLOTS):
		var icon_container = slot_icons[i]
		for child in icon_container.get_children():
			child.queue_free()
		slot_highlights[i].visible = false
	_clear_description()

func _clear_description() -> void:
	mask_name_label.text = "Ninguna"
	stats_label.text = ""
	ability_label.text = ""
	effect_label.text = ""

func _on_mask_equipped(_mask: Mask, _entity) -> void:
	_update()

func _on_mask_picked_up(_mask: Mask, _entity) -> void:
	_update()
