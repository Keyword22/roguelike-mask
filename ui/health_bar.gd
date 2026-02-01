class_name HealthBar
extends HBoxContainer

var health_icon: TextureRect
var health_label: Label
var bar: ProgressBar

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_setup_ui()
	EventBus.ui_update_requested.connect(_update)
	EventBus.mask_equipped.connect(_on_mask_equipped)

func _setup_ui() -> void:
	health_icon = TextureRect.new()
	var icon_path = "res://ui/icon_health.png"
	if ResourceLoader.exists(icon_path):
		health_icon.texture = load(icon_path)
	health_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	health_icon.custom_minimum_size = Vector2(20, 20)
	add_child(health_icon)

	var title = Label.new()
	title.text = "VDA:"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(100, 16)
	bar.show_percentage = false
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Style the bar red
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.8, 0.2, 0.2)
	style_fill.corner_radius_top_left = 2
	style_fill.corner_radius_top_right = 2
	style_fill.corner_radius_bottom_left = 2
	style_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", style_fill)

	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2)
	style_bg.corner_radius_top_left = 2
	style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_left = 2
	style_bg.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", style_bg)

	add_child(bar)

	health_label = Label.new()
	health_label.text = "0/0"
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(health_label)

func _update() -> void:
	var player = GameState.player
	if player:
		bar.max_value = player.max_health
		bar.value = player.health
		health_label.text = str(player.health) + "/" + str(player.max_health)

func _on_mask_equipped(_mask: Mask, _entity) -> void:
	_update()
