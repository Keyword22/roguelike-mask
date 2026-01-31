class_name MainMenu
extends CanvasLayer

signal start_game
signal quit_game

var game_theme: Theme

func _ready() -> void:
	_load_theme()
	_setup_ui()

func _load_theme() -> void:
	var font_path = "res://ui/font/Retro Gaming.ttf"
	if ResourceLoader.exists(font_path):
		var font = load(font_path)
		game_theme = Theme.new()
		game_theme.set_default_font(font)
		game_theme.set_default_font_size(16)

func _setup_ui() -> void:
	var panel = PanelContainer.new()
	if game_theme:
		panel.theme = game_theme
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -150
	panel.offset_right = 150
	panel.offset_top = -150
	panel.offset_bottom = 150
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "MÁSCARA ROGUELIKE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Derrota enemigos. Usa sus máscaras.\nObtén su poder."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var start_btn = Button.new()
	start_btn.text = "Iniciar Juego"
	start_btn.pressed.connect(_on_start)
	vbox.add_child(start_btn)

	var controls = Label.new()
	controls.text = "WASD/Flechas: Mover\nEspacio: Esperar\nE/Tab: Cambiar Máscara\nQ/Shift: Usar Habilidad\nEsc: Pausa"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(controls)

	var quit_btn = Button.new()
	quit_btn.text = "Salir"
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

func _on_start() -> void:
	start_game.emit()

func _on_quit() -> void:
	quit_game.emit()
