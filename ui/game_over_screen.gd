class_name GameOverScreen
extends CanvasLayer

signal restart_game
signal quit_to_menu

var title_label: Label
var message_label: Label

func _ready() -> void:
	_setup_ui()
	visible = false

func _setup_ui() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	var panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -150
	panel.offset_right = 150
	panel.offset_top = -100
	panel.offset_bottom = 100
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = "FIN DEL JUEGO"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title_label)

	message_label = Label.new()
	message_label.text = ""
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(message_label)

	var restart_btn = Button.new()
	restart_btn.text = "Jugar de Nuevo"
	restart_btn.pressed.connect(_on_restart)
	vbox.add_child(restart_btn)

	var quit_btn = Button.new()
	quit_btn.text = "Menú Principal"
	quit_btn.pressed.connect(_on_quit)
	vbox.add_child(quit_btn)

func show_game_over(victory: bool) -> void:
	visible = true
	if victory:
		title_label.text = "¡VICTORIA!"
		title_label.add_theme_color_override("font_color", Color.GOLD)
		message_label.text = "¡Conquistaste los 5 pisos!\nLas máscaras son tuyas."
	else:
		title_label.text = "FIN DEL JUEGO"
		title_label.add_theme_color_override("font_color", Color.RED)
		message_label.text = "Fuiste derrotado en el piso " + str(GameState.current_floor) + "."

func _on_restart() -> void:
	visible = false
	restart_game.emit()

func _on_quit() -> void:
	visible = false
	quit_to_menu.emit()
