class_name GameUI
extends CanvasLayer

var health_bar: HealthBar
var mask_display: MaskDisplay
var message_log: MessageLog
var floor_label: Label

var attack_label: Label
var defense_label: Label
var key_icon: TextureRect

var game_font: Font
var game_theme: Theme

const PANEL_MARGIN: int = 18
var panel_texture: Texture2D

func _ready() -> void:
	_load_font()
	_load_panel_texture()
	_setup_ui()
	EventBus.floor_changed.connect(_on_floor_changed)
	EventBus.ui_update_requested.connect(_update_stats)
	EventBus.key_picked_up.connect(_on_key_picked_up)

func _load_font() -> void:
	var font_path = "res://ui/font/Retro Gaming.ttf"
	if ResourceLoader.exists(font_path):
		var font_file = load(font_path) as FontFile
		if font_file:
			font_file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			font_file.hinting = TextServer.HINTING_NONE
		game_font = font_file
		game_theme = Theme.new()
		game_theme.set_default_font(game_font)
		game_theme.set_default_font_size(16)

func _load_panel_texture() -> void:
	var panel_path = "res://ui/panel.png"
	if ResourceLoader.exists(panel_path):
		panel_texture = load(panel_path)

func _create_nine_patch_panel() -> NinePatchRect:
	var panel = NinePatchRect.new()
	if panel_texture:
		panel.texture = panel_texture
		panel.patch_margin_left = PANEL_MARGIN
		panel.patch_margin_right = PANEL_MARGIN
		panel.patch_margin_top = PANEL_MARGIN
		panel.patch_margin_bottom = PANEL_MARGIN
	else:
		panel.modulate = Color(0.2, 0.2, 0.2, 0.8)
	return panel

func _load_icon(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _setup_ui() -> void:
	_setup_top_panel()
	_setup_right_panel()
	_setup_bottom_panel()

func _setup_top_panel() -> void:
	var top_panel = _create_nine_patch_panel()
	top_panel.anchor_left = 0
	top_panel.anchor_top = 0
	top_panel.offset_left = 10
	top_panel.offset_top = 10
	top_panel.custom_minimum_size = Vector2(700, 60)
	add_child(top_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	top_panel.add_child(margin)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 25)
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	if game_theme:
		top_hbox.theme = game_theme
	margin.add_child(top_hbox)

	health_bar = HealthBar.new()
	top_hbox.add_child(health_bar)

	# Attack with icon and label
	var attack_container = HBoxContainer.new()
	attack_container.add_theme_constant_override("separation", 5)
	attack_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_child(attack_container)

	var attack_icon = TextureRect.new()
	attack_icon.texture = _load_icon("res://ui/icon_attack.png")
	attack_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	attack_icon.custom_minimum_size = Vector2(20, 20)
	attack_container.add_child(attack_icon)

	var atk_text = Label.new()
	atk_text.text = "ATQ:"
	atk_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	attack_container.add_child(atk_text)

	attack_label = Label.new()
	attack_label.text = "0"
	attack_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	attack_container.add_child(attack_label)

	# Defense with icon and label
	var defense_container = HBoxContainer.new()
	defense_container.add_theme_constant_override("separation", 5)
	defense_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_child(defense_container)

	var defense_icon = TextureRect.new()
	defense_icon.texture = _load_icon("res://ui/icon_defense.png")
	defense_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	defense_icon.custom_minimum_size = Vector2(20, 20)
	defense_container.add_child(defense_icon)

	var def_text = Label.new()
	def_text.text = "DEF:"
	def_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	defense_container.add_child(def_text)

	defense_label = Label.new()
	defense_label.text = "0"
	defense_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	defense_container.add_child(defense_label)

	# Key icon
	key_icon = TextureRect.new()
	key_icon.texture = _load_icon("res://ui/icon_key_empty.png")
	key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_icon.custom_minimum_size = Vector2(24, 24)
	top_hbox.add_child(key_icon)

	# Floor label
	floor_label = Label.new()
	floor_label.text = "Piso: 1/5"
	floor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_hbox.add_child(floor_label)


func _setup_right_panel() -> void:
	var right_panel = _create_nine_patch_panel()
	right_panel.anchor_left = 1.0
	right_panel.anchor_top = 0
	right_panel.offset_top = 10
	right_panel.offset_right = -10
	add_child(right_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	if game_theme:
		margin.theme = game_theme
	right_panel.add_child(margin)

	mask_display = MaskDisplay.new()
	mask_display.custom_minimum_size = Vector2(170, 0)
	margin.add_child(mask_display)

	# Position from right edge
	right_panel.offset_left = -230

func _setup_bottom_panel() -> void:
	var bottom_panel = _create_nine_patch_panel()
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 10
	bottom_panel.offset_bottom = -10
	bottom_panel.offset_top = -160
	bottom_panel.offset_right = 650
	add_child(bottom_panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	if game_theme:
		margin.theme = game_theme
	bottom_panel.add_child(margin)

	message_log = MessageLog.new()
	message_log.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(message_log)

func _on_floor_changed(floor_num: int) -> void:
	floor_label.text = "Piso: " + str(floor_num) + "/" + str(GameState.max_floors)
	_reset_key_icon()

func _reset_key_icon() -> void:
	var empty_key = _load_icon("res://ui/icon_key_empty.png")
	if empty_key:
		key_icon.texture = empty_key
	key_icon.modulate = Color(0.5, 0.5, 0.5, 1.0)

func _on_key_picked_up(_pos: Vector2i) -> void:
	var full_key = _load_icon("res://ui/icon_key.png")
	if full_key:
		key_icon.texture = full_key
	key_icon.modulate = Color.WHITE

func _update_stats() -> void:
	var player = GameState.player
	if player:
		attack_label.text = str(player.get_total_attack())
		defense_label.text = str(player.get_total_defense())
