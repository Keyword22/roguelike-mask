class_name PauseMenu
extends CanvasLayer

signal resume_game
signal quit_to_menu

var game_theme: Theme

func _ready() -> void:
	_load_theme()
	_setup_ui()
	visible = false

func _load_theme() -> void:
	var font_path = "res://ui/font/Retro Gaming.ttf"
	if ResourceLoader.exists(font_path):
		var font = load(font_path)
		game_theme = Theme.new()
		game_theme.set_default_font(font)
		game_theme.set_default_font_size(16)

func _setup_ui() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	var panel = PanelContainer.new()
	if game_theme:
		panel.theme = game_theme
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -100
	panel.offset_right = 100
	panel.offset_top = -80
	panel.offset_bottom = 80
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "Continuar"
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	var quit_btn = Button.new()
	quit_btn.text = "Volver al Menú"
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

func show_pause() -> void:
	visible = true
	get_tree().paused = true

func hide_pause() -> void:
	visible = false
	get_tree().paused = false

func _on_resume() -> void:
	hide_pause()
	resume_game.emit()

func _on_quit() -> void:
	hide_pause()
	quit_to_menu.emit()
