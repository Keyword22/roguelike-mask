class_name HealthBar
extends HBoxContainer

var health_label: Label
var bar: ProgressBar

func _ready() -> void:
	_setup_ui()
	EventBus.ui_update_requested.connect(_update)
	EventBus.mask_equipped.connect(_on_mask_equipped)

func _setup_ui() -> void:
	var title = Label.new()
	title.text = "HP: "
	add_child(title)

	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(100, 20)
	bar.show_percentage = false
	add_child(bar)

	health_label = Label.new()
	health_label.text = "0/0"
	add_child(health_label)

func _update() -> void:
	var player = GameState.player
	if player:
		bar.max_value = player.max_health
		bar.value = player.health
		health_label.text = " " + str(player.health) + "/" + str(player.max_health)

func _on_mask_equipped(_mask: Mask, _entity) -> void:
	_update()
