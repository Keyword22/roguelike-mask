class_name Action
extends RefCounted

var entity: Entity

func _init(e: Entity) -> void:
	entity = e

func execute() -> bool:
	return false

func is_valid() -> bool:
	return entity != null and entity.is_alive()
