class_name GameUI
extends CanvasLayer

var health_bar: HealthBar
var mask_display: MaskDisplay
var message_log: MessageLog
var floor_label: Label
var stats_label: Label

var game_font: Font
var game_theme: Theme

func _ready() -> void:
	_load_font()
	_setup_ui()
	EventBus.floor_changed.connect(_on_floor_changed)
	EventBus.ui_update_requested.connect(_update_stats)

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

func _setup_ui() -> void:
	var top_panel = PanelContainer.new()
	if game_theme:
		top_panel.theme = game_theme
	top_panel.anchor_right = 1.0
	top_panel.offset_bottom = 60
	add_child(top_panel)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 30)
	top_panel.add_child(top_hbox)

	health_bar = HealthBar.new()
	top_hbox.add_child(health_bar)

	stats_label = Label.new()
	stats_label.text = "ATQ: 0 DEF: 0"
	top_hbox.add_child(stats_label)

	floor_label = Label.new()
	floor_label.text = "Piso: 1/5"
	top_hbox.add_child(floor_label)

	var right_panel = PanelContainer.new()
	if game_theme:
		right_panel.theme = game_theme
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_bottom = 1.0
	right_panel.offset_left = -220
	right_panel.offset_top = 70
	right_panel.offset_bottom = -150
	right_panel.clip_contents = true
	add_child(right_panel)

	mask_display = MaskDisplay.new()
	mask_display.custom_minimum_size = Vector2(200, 0)
	right_panel.add_child(mask_display)

	var bottom_panel = PanelContainer.new()
	if game_theme:
		bottom_panel.theme = game_theme
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_top = -140
	add_child(bottom_panel)

	message_log = MessageLog.new()
	message_log.custom_minimum_size = Vector2(0, 120)
	bottom_panel.add_child(message_log)

func _on_floor_changed(floor_num: int) -> void:
	floor_label.text = "Piso: " + str(floor_num) + "/" + str(GameState.max_floors)

func _update_stats() -> void:
	var player = GameState.player
	if player:
		stats_label.text = "ATQ: " + str(player.get_total_attack()) + " DEF: " + str(player.get_total_defense())
