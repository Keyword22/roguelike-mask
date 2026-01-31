class_name MessageLog
extends VBoxContainer

const MAX_MESSAGES: int = 5

var messages: Array[Label] = []

func _ready() -> void:
	EventBus.message_logged.connect(_add_message)

func _add_message(text: String, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	messages.append(label)

	while messages.size() > MAX_MESSAGES:
		var old = messages.pop_front()
		if is_instance_valid(old):
			old.queue_free()
