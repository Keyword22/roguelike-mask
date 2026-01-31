class_name Enemy
extends Entity

@export var mask_drop: Mask = null
@export var mask_drop_chance: float = 1.0

var ai_controller: AIController = null

func _ready() -> void:
	super._ready()
	ai_controller = AIChase.new()
	ai_controller.entity = self

func get_action():
	if ai_controller:
		return ai_controller.get_action()
	return WaitAction.new(self)

func die() -> void:
	_try_drop_mask()
	super.die()

func _try_drop_mask() -> void:
	if mask_drop and randf() <= mask_drop_chance:
		EventBus.mask_dropped.emit(mask_drop, grid_position)
